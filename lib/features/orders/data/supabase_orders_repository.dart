import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinapp/core/config/env.dart';
import 'package:clinapp/core/config/supabase_provider.dart';
import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/network/retry_policy.dart';
import 'package:clinapp/features/orders/domain/orders_models.dart';
import 'package:clinapp/features/orders/domain/orders_repository.dart';

/// Implementación de [OrdersRepository] con Supabase y fallback al seed
/// local de General Alvear.
class SupabaseOrdersRepository implements OrdersRepository {
  SupabaseOrdersRepository({required this.client});

  final SupabaseClient? client;

  @override
  Future<OrdersPageData> fetchOrders({int page = 0, int pageSize = 4}) async {
    final SupabaseClient? activeClient = client;
    if (activeClient == null) {
      return _buildSeedOrders(page: page, pageSize: pageSize);
    }

    try {
      final User? user = activeClient.auth.currentUser;
      if (user == null) {
        if (!Env.isDev) {
          throw const AuthFailure(AppStrings.errorAuth);
        }
        return _buildSeedOrders(page: page, pageSize: pageSize);
      }

      // Ejecutar pedidos activos e historial paginado en paralelo (1 RTT en vez de 2).
      final int from = page * pageSize;
      final int to = from + pageSize - 1;

      final Future<List<Map<String, Object?>>> activeFuture =
          RetryPolicy.execute<List<Map<String, Object?>>>(
            () => activeClient
                .from('orders')
                .select(
                  'id, estado, subtotal, envio, propina, descuento, total, created_at, '
                  'merchants(id, name), addresses(address_line, lat, lng), '
                  'order_items(product_id, quantity, unit_price, total_price, products(name))',
                )
                .eq('user_id', user.id)
                .not('estado', 'in', '("entregado","cancelado","rechazado")')
                .order('created_at', ascending: false),
          );

      final Future<List<Map<String, Object?>>> historyFuture =
          RetryPolicy.execute<List<Map<String, Object?>>>(
            () => activeClient
                .from('orders')
                .select(
                  'id, estado, subtotal, envio, propina, descuento, total, created_at, '
                  'merchants(id, name), addresses(address_line), '
                  'order_items(product_id, quantity, unit_price, total_price, products(name))',
                )
                .eq('user_id', user.id)
                .inFilter('estado', <String>[
                  'entregado',
                  'cancelado',
                  'rechazado',
                ])
                .order('created_at', ascending: false)
                .range(from, to),
          );

      final List<List<Map<String, Object?>>> queryResults =
          await Future.wait<List<Map<String, Object?>>>(
            <Future<List<Map<String, Object?>>>>[activeFuture, historyFuture],
          );

      final List<Map<String, Object?>> activeRows = queryResults[0];
      final List<Map<String, Object?>> historyRows = queryResults[1];

      if (activeRows.isEmpty && historyRows.isEmpty && page == 0 && Env.isDev) {
        return _buildSeedOrders(page: page, pageSize: pageSize);
      }

      final List<OrderSummary> activeOrders = activeRows
          .map((Map<String, Object?> r) => _mapOrderRow(r, isActive: true))
          .toList();

      final List<OrderSummary> historyOrders = historyRows
          .map((Map<String, Object?> r) => _mapOrderRow(r, isActive: false))
          .toList();

      final bool hasMoreHistory = historyRows.length >= pageSize;

      return OrdersPageData(
        activeOrders: activeOrders,
        historyOrders: historyOrders,
        hasMoreHistory: hasMoreHistory,
        currentPage: page,
      );
    } on Object catch (error) {
      throw AppException.fromError(error);
    }
  }

  @override
  Stream<OrdersRealtimeEvent> watchActiveOrders() {
    final SupabaseClient? activeClient = client;
    if (activeClient == null) {
      return const Stream<OrdersRealtimeEvent>.empty();
    }

    final StreamController<OrdersRealtimeEvent> controller =
        StreamController<OrdersRealtimeEvent>.broadcast();

    final User? user = activeClient.auth.currentUser;
    final String channelName = user != null
        ? 'realtime_orders_${user.id}'
        : 'realtime_orders_anon';

    final RealtimeChannel channel = activeClient.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (PostgresChangePayload payload) {
            final Map<String, Object?> newRecord = payload.newRecord;
            final String orderId = _readString(newRecord['id']);
            final String rawStatus = _readString(newRecord['estado']);
            if (orderId.isNotEmpty && rawStatus.isNotEmpty) {
              controller.add(
                OrdersRealtimeEvent(
                  orderId: orderId,
                  updatedStatus: OrderStatus.fromDb(rawStatus),
                ),
              );
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'courier_locations',
          callback: (PostgresChangePayload payload) {
            final Map<String, Object?> newRecord = payload.newRecord;
            final double lat = _readDouble(newRecord['lat']);
            final double lng = _readDouble(newRecord['lng']);
            if (lat != 0 && lng != 0) {
              controller.add(
                OrdersRealtimeEvent(
                  orderId: '',
                  courierLat: lat,
                  courierLng: lng,
                ),
              );
            }
          },
        )
        .subscribe();

    controller.onCancel = () {
      unawaited(activeClient.removeChannel(channel));
      unawaited(controller.close());
    };

    return controller.stream;
  }

  @override
  Stream<OrdersRealtimeEvent> watchOrder(String orderId) {
    final SupabaseClient? activeClient = client;
    if (activeClient == null || orderId.isEmpty) {
      return const Stream<OrdersRealtimeEvent>.empty();
    }

    final StreamController<OrdersRealtimeEvent> controller =
        StreamController<OrdersRealtimeEvent>.broadcast();

    final String channelName = 'order_tracking_$orderId';
    final RealtimeChannel channel = activeClient.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: orderId,
          ),
          callback: (PostgresChangePayload payload) {
            final Map<String, Object?> newRecord = payload.newRecord;
            final String rawStatus = _readString(newRecord['estado']);
            if (rawStatus.isNotEmpty) {
              controller.add(
                OrdersRealtimeEvent(
                  orderId: orderId,
                  updatedStatus: OrderStatus.fromDb(rawStatus),
                ),
              );
            }
          },
        )
        .onBroadcast(
          event: 'courier_location',
          callback: (Map<String, Object?> payload) {
            final double lat = _readDouble(payload['lat']);
            final double lng = _readDouble(payload['lng']);
            final int? remainingMin = payload['remaining_minutes'] != null
                ? _readInt(payload['remaining_minutes'])
                : null;
            if (lat != 0 && lng != 0) {
              controller.add(
                OrdersRealtimeEvent(
                  orderId: orderId,
                  courierLat: lat,
                  courierLng: lng,
                  remainingMinutes: remainingMin,
                ),
              );
            }
          },
        )
        .subscribe();

    controller.onCancel = () {
      unawaited(activeClient.removeChannel(channel));
      unawaited(controller.close());
    };

    return controller.stream;
  }

  @override
  Stream<List<ChatMessage>> watchChatMessages(String orderId) {
    final SupabaseClient? activeClient = client;
    if (activeClient == null || orderId.isEmpty) {
      return Stream<List<ChatMessage>>.value(<ChatMessage>[
        ChatMessage(
          id: 'mock-msg-1',
          orderId: orderId,
          senderId: 'courier-mock',
          content: '¡Hola! Ya retiré tu pedido y voy para tu dirección.',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          senderName: 'Lautaro (Repartidor)',
          isMine: false,
        ),
      ]);
    }

    final StreamController<List<ChatMessage>> controller =
        StreamController<List<ChatMessage>>.broadcast();

    final User? currentUser = activeClient.auth.currentUser;
    final String currentUserId = currentUser?.id ?? '';
    final List<ChatMessage> messages = <ChatMessage>[];

    RetryPolicy.execute<List<Map<String, Object?>>>(
          () => activeClient
              .from('chat_messages')
              .select('id, order_id, sender_id, content, created_at')
              .eq('order_id', orderId)
              .order('created_at', ascending: true),
        )
        .then((List<Map<String, Object?>> rows) {
          for (final Map<String, Object?> r in rows) {
            messages.add(ChatMessage.fromJson(r, currentUserId: currentUserId));
          }
          if (!controller.isClosed) {
            controller.add(List<ChatMessage>.of(messages));
          }
        })
        .catchError((Object error) {
          if (!controller.isClosed) {
            controller.addError(AppException.fromError(error));
          }
        });

    final String channelName = 'chat_$orderId';
    final RealtimeChannel channel = activeClient.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'order_id',
            value: orderId,
          ),
          callback: (PostgresChangePayload payload) {
            final Map<String, Object?> newRecord = payload.newRecord;
            final ChatMessage msg = ChatMessage.fromJson(
              newRecord,
              currentUserId: currentUserId,
            );
            messages.add(msg);
            if (!controller.isClosed) {
              controller.add(List<ChatMessage>.of(messages));
            }
          },
        )
        .subscribe();

    controller.onCancel = () {
      unawaited(activeClient.removeChannel(channel));
      unawaited(controller.close());
    };

    return controller.stream;
  }

  @override
  Future<void> sendChatMessage({
    required String orderId,
    required String content,
  }) async {
    final SupabaseClient? activeClient = client;
    if (activeClient == null) {
      return;
    }

    final User? user = activeClient.auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      await RetryPolicy.execute<void>(
        () => activeClient.from('chat_messages').insert(<String, Object?>{
          'order_id': orderId,
          'sender_id': user.id,
          'content': content,
        }),
        maxAttempts: 2,
        timeout: RetryPolicy.defaultMutationTimeout,
      );
    } on Object catch (error) {
      throw AppException.fromError(error);
    }
  }

  @override
  Future<ReorderValidationResult> revalidateOrderForRepeat(
    OrderSummary order,
  ) async {
    final SupabaseClient? activeClient = client;
    if (activeClient == null) {
      return ReorderValidationResult(
        orderId: order.id,
        merchantName: order.merchantName,
        revalidatedSubtotalCents: order.subtotalCents,
        priceChanged: false,
        availableItemCount: order.items.length,
      );
    }

    try {
      final List<String> productIds = order.items
          .map((OrderLineItem i) => i.productId)
          .where((String id) => id.isNotEmpty)
          .toList();

      if (productIds.isEmpty) {
        return ReorderValidationResult(
          orderId: order.id,
          merchantName: order.merchantName,
          revalidatedSubtotalCents: order.subtotalCents,
          priceChanged: false,
          availableItemCount: 1,
        );
      }

      final List<Map<String, Object?>> products =
          await RetryPolicy.execute<List<Map<String, Object?>>>(
            () => activeClient
                .from('products')
                .select('id, price, is_available')
                .inFilter('id', productIds),
          );

      final Map<String, int> priceMap = <String, int>{};
      final Set<String> availableIds = <String>{};
      for (final Map<String, Object?> row in products) {
        final String pid = _readString(row['id']);
        final int price = _readInt(row['price']);
        final bool isAvailable = row['is_available'] == true;
        if (pid.isNotEmpty) {
          priceMap[pid] = price;
          if (isAvailable) {
            availableIds.add(pid);
          }
        }
      }

      int recalculatedSubtotal = 0;
      bool priceChanged = false;

      for (final OrderLineItem item in order.items) {
        final int? serverPrice = priceMap[item.productId];
        if (serverPrice != null) {
          if (serverPrice != item.unitPriceCents) {
            priceChanged = true;
          }
          recalculatedSubtotal += serverPrice * item.quantity;
        } else {
          recalculatedSubtotal += item.totalPriceCents;
        }
      }

      return ReorderValidationResult(
        orderId: order.id,
        merchantName: order.merchantName,
        revalidatedSubtotalCents: recalculatedSubtotal > 0
            ? recalculatedSubtotal
            : order.subtotalCents,
        priceChanged: priceChanged,
        availableItemCount: availableIds.length,
      );
    } on Object catch (error) {
      throw AppException.fromError(error);
    }
  }

  OrderSummary _mapOrderRow(
    Map<String, Object?> row, {
    required bool isActive,
  }) {
    final String id = _readString(row['id']);
    final String shortCode = id.length >= 4
        ? '#${id.substring(id.length - 4)}'
        : '#$id';

    final String rawStatus = _readString(row['estado']);
    final OrderStatus status = OrderStatus.fromDb(rawStatus);

    String merchantId = '';
    String merchantName = 'Comercio Alvearense';
    final Object? merchantData = row['merchants'];
    if (merchantData is Map<String, Object?>) {
      merchantId = _readString(merchantData['id']);
      merchantName = _readString(merchantData['name'], fallback: merchantName);
    }

    String addressLine = 'Av. San Martín 450';
    final Object? addressData = row['addresses'];
    if (addressData is Map<String, Object?>) {
      addressLine = _readString(
        addressData['address_line'],
        fallback: addressLine,
      );
    }

    final List<OrderLineItem> items = <OrderLineItem>[];
    final List<String> itemNames = <String>[];
    final Object? rawItems = row['order_items'];
    if (rawItems is List<Object?>) {
      for (final Object? item in rawItems) {
        if (item is Map<String, Object?>) {
          String name = 'Producto';
          final Object? prod = item['products'];
          if (prod is Map<String, Object?>) {
            name = _readString(prod['name'], fallback: name);
          }
          final int qty = _readInt(item['quantity'], fallback: 1);
          final int unitPrice = _readInt(item['unit_price']);
          final int totalPrice = _readInt(
            item['total_price'],
            fallback: unitPrice * qty,
          );
          items.add(
            OrderLineItem(
              productId: _readString(item['product_id']),
              name: name,
              quantity: qty,
              unitPriceCents: unitPrice,
              totalPriceCents: totalPrice,
            ),
          );
          itemNames.add('${qty}x $name');
        }
      }
    }

    final String summary = itemNames.isNotEmpty
        ? itemNames.join(' + ')
        : 'Pedido #$shortCode';

    final DateTime createdAt =
        DateTime.tryParse(_readString(row['created_at'])) ?? DateTime.now();

    final CourierInfo? courier = isActive
        ? const CourierInfo(
            id: 'c-joaquin',
            name: 'Joaquín en moto',
            vehicle: 'Honda Wave 110',
            plate: 'A391KOP',
            phone: '+54 9 2625 401122',
            lat: -34.9752,
            lng: -67.6970,
            isOnline: true,
          )
        : null;

    final int remainingMin = isActive ? 18 : 0;
    final DateTime arrival = isActive
        ? createdAt.add(const Duration(minutes: 35))
        : createdAt;

    return OrderSummary(
      id: id,
      shortCode: shortCode,
      merchantId: merchantId,
      merchantName: merchantName,
      itemsSummary: summary,
      items: items,
      status: status,
      createdAt: createdAt,
      estimatedArrivalAt: arrival,
      remainingMinutes: remainingMin,
      deliveryAddress: addressLine,
      subtotalCents: _readInt(row['subtotal']),
      deliveryFeeCents: _readInt(row['envio']),
      discountCents: _readInt(row['descuento']),
      tipCents: _readInt(row['propina']),
      totalCents: _readInt(row['total']),
      courier: courier,
    );
  }

  OrdersPageData _buildSeedOrders({required int page, required int pageSize}) {
    final DateTime now = DateTime.now();

    final OrderSummary activeOrder = OrderSummary(
      id: 'ord-active-4829',
      shortCode: '#4829',
      merchantId: 'm1111111-1111-4111-8111-111111111111',
      merchantName: 'Pizzería La Alvearense',
      itemsSummary: '2x Fugazzeta Rellena + Fainá',
      items: const <OrderLineItem>[
        OrderLineItem(
          productId: 'p1111111-1111-4111-8111-111111111102',
          name: 'Fugazzeta Rellena',
          quantity: 2,
          unitPriceCents: 1420000,
          totalPriceCents: 2840000,
        ),
        OrderLineItem(
          productId: 'p1111111-1111-4111-8111-111111111101',
          name: 'Fainá Clásica',
          quantity: 1,
          unitPriceCents: 150000,
          totalPriceCents: 150000,
        ),
      ],
      status: OrderStatus.enCamino,
      createdAt: now.subtract(const Duration(minutes: 20)),
      estimatedArrivalAt: now.add(const Duration(minutes: 18)),
      remainingMinutes: 18,
      isExpress: true,
      deliveryAddress: 'Av. San Martín 450',
      subtotalCents: 2990000,
      deliveryFeeCents: 120000,
      discountCents: 0,
      tipCents: 200000,
      totalCents: 3310000,
      courier: const CourierInfo(
        id: 'c-joaquin',
        name: 'Joaquín en moto',
        vehicle: 'Honda Wave 110',
        plate: 'A391KOP',
        phone: '+54 9 2625 401122',
        lat: -34.9752,
        lng: -67.6970,
        isOnline: true,
      ),
    );

    final List<OrderSummary> allHistory = <OrderSummary>[
      OrderSummary(
        id: 'ord-hist-4210',
        shortCode: '#4210',
        merchantId: 'm3333333-3333-4333-8333-333333333333',
        merchantName: 'Burgers Alvear Craft',
        itemsSummary: '2x Doble Bacon Smash + Papas',
        items: const <OrderLineItem>[
          OrderLineItem(
            productId: 'p3333333-3333-4333-8333-333333333301',
            name: 'Doble Bacon Smash',
            quantity: 2,
            unitPriceCents: 630000,
            totalPriceCents: 1260000,
          ),
          OrderLineItem(
            productId: 'p3333333-3333-4333-8333-333333333302',
            name: 'Papas Rústicas',
            quantity: 1,
            unitPriceCents: 200000,
            totalPriceCents: 200000,
          ),
        ],
        status: OrderStatus.entregado,
        createdAt: now.subtract(const Duration(days: 4, hours: 2)),
        deliveryAddress: 'Av. San Martín 450',
        subtotalCents: 1460000,
        deliveryFeeCents: 0,
        totalCents: 1460000,
      ),
      OrderSummary(
        id: 'ord-hist-3992',
        shortCode: '#3992',
        merchantId: 'm4444444-4444-4444-8444-444444444444',
        merchantName: 'Heladería Colonial',
        itemsSummary: '1 Kg Helado Artesanal (3 sabores)',
        items: const <OrderLineItem>[
          OrderLineItem(
            productId: 'p4444444-4444-4444-8444-444444444401',
            name: '1 Kg Helado Artesanal',
            quantity: 1,
            unitPriceCents: 920000,
            totalPriceCents: 920000,
          ),
        ],
        status: OrderStatus.entregado,
        createdAt: now.subtract(const Duration(days: 8, hours: 4)),
        deliveryAddress: 'Av. San Martín 450',
        subtotalCents: 920000,
        deliveryFeeCents: 60000,
        totalCents: 980000,
      ),
      OrderSummary(
        id: 'ord-hist-3811',
        shortCode: '#3811',
        merchantId: 'm2222222-2222-4222-8222-222222222222',
        merchantName: 'El Rincón del Repulgue',
        itemsSummary: '12x Empanadas mendocinas a cuchillo',
        items: const <OrderLineItem>[
          OrderLineItem(
            productId: 'p2222222-2222-4222-8222-222222222201',
            name: 'Docena Empanadas',
            quantity: 1,
            unitPriceCents: 1440000,
            totalPriceCents: 1440000,
          ),
        ],
        status: OrderStatus.entregado,
        createdAt: now.subtract(const Duration(days: 14, hours: 3)),
        deliveryAddress: 'Av. San Martín 450',
        subtotalCents: 1440000,
        deliveryFeeCents: 100000,
        totalCents: 1540000,
      ),
    ];

    final int start = page * pageSize;
    final int end = (start + pageSize).clamp(0, allHistory.length);
    final List<OrderSummary> pagedHistory = start < allHistory.length
        ? allHistory.sublist(start, end)
        : <OrderSummary>[];

    return OrdersPageData(
      activeOrders: <OrderSummary>[activeOrder],
      historyOrders: pagedHistory,
      hasMoreHistory: end < allHistory.length,
      currentPage: page,
    );
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return fallback;
  }

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return fallback;
  }

  static double _readDouble(Object? value, {double fallback = 0.0}) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return fallback;
  }
}

/// Provider del repositorio de Pedidos.
final Provider<OrdersRepository> ordersRepositoryProvider =
    Provider<OrdersRepository>((Ref ref) {
      final SupabaseClient? client = ref.watch(supabaseClientProvider);
      return SupabaseOrdersRepository(client: client);
    });
