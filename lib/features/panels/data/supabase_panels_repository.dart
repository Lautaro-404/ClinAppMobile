import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinapp/core/config/env.dart';
import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/network/retry_policy.dart';
import 'package:clinapp/features/panels/data/mock_panels_repository.dart';
import 'package:clinapp/features/panels/domain/panel_models.dart';
import 'package:clinapp/features/panels/domain/panels_repository.dart';

/// Implementación de [PanelsRepository] conectada al backend de Supabase
/// mediante RPCs seguras (`panel_cambiar_estado`, `tomar_pedido`, `repartidor_cambiar_estado`),
/// consultas relacionales en paralelo y propagación estricta de permisos RLS.
class SupabasePanelsRepository implements PanelsRepository {
  SupabasePanelsRepository({required this.client})
    : _mockFallback = MockPanelsRepository();

  final SupabaseClient? client;
  final MockPanelsRepository _mockFallback;

  // ── REPARTIDOR ────────────────────────────────────────────────────────────

  @override
  Future<CourierShiftState> loadCourierShift() async {
    final SupabaseClient? activeClient = client;
    final User? user = activeClient?.auth.currentUser;

    if (activeClient == null || user == null) {
      if (!Env.isDev && activeClient != null) {
        throw const AuthFailure(AppStrings.errorAuth);
      }
      return _mockFallback.loadCourierShift();
    }

    try {
      final Future<Map<String, Object?>?> profileFuture =
          RetryPolicy.execute<Map<String, Object?>?>(
            () => activeClient
                .from('profiles')
                .select('nombre, telefono, vehiculo, patente, wallet_balance')
                .eq('id', user.id)
                .maybeSingle(),
          );

      final Future<List<Map<String, Object?>>>
      ordersFuture = RetryPolicy.execute<List<Map<String, Object?>>>(
        () => activeClient
            .from('orders')
            .select(
              'id, estado, total, address_id, created_at, '
              'merchants(name, address), addresses(address_line, lat, lng), '
              'order_items(quantity, products(name))',
            )
            .or(
              'courier_id.eq.${user.id},and(courier_id.is.null,estado.in.("listo_para_retirar","en_preparacion"))',
            )
            .order('created_at', ascending: false)
            .limit(10),
      );

      final List<Object?> results = await Future.wait<Object?>(
        <Future<Object?>>[profileFuture, ordersFuture],
      );

      final Map<String, Object?>? profile = results[0] as Map<String, Object?>?;
      final List<Map<String, Object?>> orders =
          results[1]! as List<Map<String, Object?>>;

      if (orders.isEmpty && profile == null && Env.isDev) {
        return await _mockFallback.loadCourierShift();
      }

      final List<CourierDeliveryItem> deliveries = orders.map((
        Map<String, Object?> row,
      ) {
        final Map<String, Object?>? merchant =
            row['merchants'] as Map<String, Object?>?;
        final Map<String, Object?>? address =
            row['addresses'] as Map<String, Object?>?;
        final String rawEstado =
            row['estado'] as String? ?? 'listo_para_retirar';

        final CourierDeliveryStatus status = switch (rawEstado) {
          'en_camino' => CourierDeliveryStatus.onTheWay,
          'entregado' => CourierDeliveryStatus.delivered,
          'en_preparacion' => CourierDeliveryStatus.inKitchen,
          _ => CourierDeliveryStatus.readyForPickup,
        };

        final List<Object?> itemsList =
            row['order_items'] as List<Object?>? ?? <Object?>[];
        final List<String> descriptions = itemsList.map((Object? item) {
          if (item is Map<String, Object?>) {
            final Map<String, Object?>? prod =
                item['products'] as Map<String, Object?>?;
            final int qty = (item['quantity'] as num?)?.toInt() ?? 1;
            return '$qty× ${prod?['name'] ?? 'Producto'}';
          }
          return '1x Menú';
        }).toList();

        final String orderId = row['id'] as String? ?? '';
        final String shortCode = orderId.length >= 6
            ? orderId.substring(0, 6).toUpperCase()
            : 'ORD01';

        return CourierDeliveryItem(
          id: orderId,
          orderNumber: '#$shortCode',
          merchantName: merchant?['name'] as String? ?? 'Comercio Alvear',
          merchantAddress:
              merchant?['address'] as String? ?? 'Av. Alvear Oeste 450',
          merchantPhone: '+54 9 2625 423300',
          customerName: 'Cliente Alvearense',
          customerAddress:
              address?['address_line'] as String? ?? 'Av. San Martín 450',
          customerPhone: '+54 9 2625 401234',
          deliveryNotes: 'Tocar timbre',
          status: status,
          isExpress: false,
          distanceEstimate: '1.8 km',
          amountCents: (row['total'] as num?)?.toInt() ?? 1200000,
          isCashOnDelivery: false,
          orderItems: descriptions.isNotEmpty
              ? descriptions
              : const <String>['1x Pedido Alvear'],
        );
      }).toList();

      final int walletBalance =
          (profile?['wallet_balance'] as num?)?.toInt() ?? 0;
      final int completedCount = deliveries
          .where(
            (CourierDeliveryItem d) =>
                d.status == CourierDeliveryStatus.delivered,
          )
          .length;

      final CourierShiftState mockState = await _mockFallback
          .loadCourierShift();

      return CourierShiftState(
        isOnline: true,
        isGpsActive: true,
        todayDeliveriesCount: completedCount > 0
            ? completedCount
            : (Env.isDev ? 5 : 0),
        todayEarningsCents: walletBalance > 0
            ? walletBalance
            : (Env.isDev ? 840000 : 0),
        deliveries: deliveries.isNotEmpty
            ? deliveries
            : (Env.isDev
                  ? mockState.deliveries
                  : const <CourierDeliveryItem>[]),
      );
    } on PermissionDeniedFailure {
      rethrow;
    } on AuthFailure {
      rethrow;
    } on Object catch (error) {
      final AppException mapped = AppException.fromError(error);
      if (mapped is PermissionDeniedFailure ||
          mapped is AuthFailure ||
          Env.isProd) {
        throw mapped;
      }
      return _mockFallback.loadCourierShift();
    }
  }

  @override
  Stream<CourierShiftState> watchCourierShift() {
    final SupabaseClient? activeClient = client;
    final User? user = activeClient?.auth.currentUser;

    if (activeClient == null || user == null) {
      return _mockFallback.watchCourierShift();
    }

    final StreamController<CourierShiftState> controller =
        StreamController<CourierShiftState>.broadcast();

    final String channelName = 'courier_shift_${user.id}';
    final RealtimeChannel channel = activeClient.channel(channelName);

    Future<void> refresh() async {
      try {
        final CourierShiftState updated = await loadCourierShift();
        if (!controller.isClosed) {
          controller.add(updated);
        }
      } on Object catch (error) {
        if (!controller.isClosed) {
          controller.addError(AppException.fromError(error));
        }
      }
    }

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (_) => unawaited(refresh()),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: user.id,
          ),
          callback: (_) => unawaited(refresh()),
        )
        .subscribe();

    controller.onCancel = () {
      unawaited(activeClient.removeChannel(channel));
      unawaited(controller.close());
    };

    return controller.stream;
  }

  @override
  Future<CourierShiftState> toggleCourierShift({required bool isOnline}) async {
    return _mockFallback.toggleCourierShift(isOnline: isOnline);
  }

  @override
  Future<CourierShiftState> updateDeliveryStatus({
    required String deliveryId,
    required CourierDeliveryStatus newStatus,
  }) async {
    final SupabaseClient? activeClient = client;
    if (activeClient != null) {
      try {
        await RetryPolicy.execute<void>(
          () async {
            if (newStatus == CourierDeliveryStatus.onTheWay) {
              await activeClient.rpc<void>(
                'tomar_pedido',
                params: <String, Object?>{'p_order_id': deliveryId},
              );
            } else if (newStatus == CourierDeliveryStatus.delivered) {
              await activeClient.rpc<void>(
                'repartidor_cambiar_estado',
                params: <String, Object?>{
                  'p_order_id': deliveryId,
                  'p_estado': 'entregado',
                },
              );
            }
          },
          maxAttempts: 2,
          timeout: RetryPolicy.defaultMutationTimeout,
        );
        return await loadCourierShift();
      } on Object catch (error) {
        final AppException mapped = AppException.fromError(error);
        if (mapped is PermissionDeniedFailure ||
            mapped is AuthFailure ||
            !Env.isDev) {
          throw mapped;
        }
      }
    }
    return _mockFallback.updateDeliveryStatus(
      deliveryId: deliveryId,
      newStatus: newStatus,
    );
  }

  // ── COMERCIO ──────────────────────────────────────────────────────────────

  @override
  Future<MerchantDashboardState> loadMerchantDashboard() async {
    final SupabaseClient? activeClient = client;
    final User? user = activeClient?.auth.currentUser;

    if (activeClient == null || user == null) {
      if (!Env.isDev && activeClient != null) {
        throw const AuthFailure(AppStrings.errorAuth);
      }
      return _mockFallback.loadMerchantDashboard();
    }

    try {
      final List<Map<String, Object?>> merchants =
          await RetryPolicy.execute<List<Map<String, Object?>>>(
            () => activeClient
                .from('merchants')
                .select('id, name, estado, owner_id')
                .eq('owner_id', user.id)
                .limit(1),
          );

      if (merchants.isEmpty) {
        if (!Env.isDev) {
          throw const PermissionDeniedFailure(AppStrings.errorPermissionDenied);
        }
        return await _mockFallback.loadMerchantDashboard();
      }

      final Map<String, Object?> merchant = merchants.first;
      final String merchantId = merchant['id'] as String;
      final bool isOpen = (merchant['estado'] as String?) == 'activo';

      final Future<List<Map<String, Object?>>>
      ordersFuture = RetryPolicy.execute<List<Map<String, Object?>>>(
        () => activeClient
            .from('orders')
            .select(
              'id, estado, total, subtotal, special_instructions, created_at, '
              'order_items(quantity, products(name))',
            )
            .eq('merchant_id', merchantId)
            .order('created_at', ascending: false)
            .limit(15),
      );

      final Future<List<Map<String, Object?>>> productsFuture =
          RetryPolicy.execute<List<Map<String, Object?>>>(
            () => activeClient
                .from('products')
                .select(
                  'id, name, description, price, is_available, menu_sections!inner(merchant_id)',
                )
                .eq('menu_sections.merchant_id', merchantId)
                .limit(10),
          );

      final List<List<Map<String, Object?>>> dashResults =
          await Future.wait<List<Map<String, Object?>>>(
            <Future<List<Map<String, Object?>>>>[ordersFuture, productsFuture],
          );

      final List<Map<String, Object?>> orders = dashResults[0];
      final List<Map<String, Object?>> products = dashResults[1];

      final List<MerchantOrderItem> orderItems = orders.map((
        Map<String, Object?> o,
      ) {
        final String rawEstado = o['estado'] as String? ?? 'creado';
        final MerchantOrderStatus status = switch (rawEstado) {
          'en_preparacion' => MerchantOrderStatus.inKitchen,
          'listo_para_retirar' => MerchantOrderStatus.readyForPickup,
          'entregado' => MerchantOrderStatus.completed,
          _ => MerchantOrderStatus.incoming,
        };

        final List<Object?> itemsList =
            o['order_items'] as List<Object?>? ?? <Object?>[];
        final List<String> descriptions = itemsList.map((Object? item) {
          if (item is Map<String, Object?>) {
            final Map<String, Object?>? prod =
                item['products'] as Map<String, Object?>?;
            final int qty = (item['quantity'] as num?)?.toInt() ?? 1;
            return '$qty× ${prod?['name'] ?? 'Producto'}';
          }
          return '1x Menú';
        }).toList();

        final String orderId = o['id'] as String? ?? '';
        final String shortCode = orderId.length >= 6
            ? orderId.substring(0, 6).toUpperCase()
            : 'ORD01';

        return MerchantOrderItem(
          id: orderId,
          orderNumber: '#$shortCode',
          customerName: 'Cliente Alvear',
          customerAddress: 'Av. Libertador Sur 120',
          items: descriptions.isNotEmpty
              ? descriptions
              : const <String>['1x Plato especial'],
          totalAmountCents: (o['total'] as num?)?.toInt() ?? 0,
          status: status,
          prepTimeMinutes: 25,
          isCash: false,
        );
      }).toList();

      final List<MerchantMenuItem> menuItems = products.map((
        Map<String, Object?> p,
      ) {
        return MerchantMenuItem(
          id: p['id'] as String? ?? '',
          name: p['name'] as String? ?? 'Producto',
          description: p['description'] as String? ?? '',
          priceCents: (p['price'] as num?)?.toInt() ?? 0,
          isAvailable: (p['is_available'] as bool?) ?? true,
        );
      }).toList();

      final int completed = orderItems
          .where(
            (MerchantOrderItem o) => o.status == MerchantOrderStatus.completed,
          )
          .length;
      final int revenue = orderItems.fold<int>(
        0,
        (int sum, MerchantOrderItem o) => sum + o.totalAmountCents,
      );

      final MerchantDashboardState fallbackState = await _mockFallback
          .loadMerchantDashboard();

      return MerchantDashboardState(
        isOpen: isOpen,
        todayCompletedOrders: completed > 0
            ? completed
            : (Env.isDev ? fallbackState.todayCompletedOrders : 0),
        todayRevenueCents: revenue > 0
            ? revenue
            : (Env.isDev ? fallbackState.todayRevenueCents : 0),
        orders: orderItems.isNotEmpty
            ? orderItems
            : (Env.isDev ? fallbackState.orders : const <MerchantOrderItem>[]),
        menuItems: menuItems.isNotEmpty
            ? menuItems
            : (Env.isDev
                  ? fallbackState.menuItems
                  : const <MerchantMenuItem>[]),
      );
    } on PermissionDeniedFailure {
      rethrow;
    } on AuthFailure {
      rethrow;
    } on Object catch (error) {
      final AppException mapped = AppException.fromError(error);
      if (mapped is PermissionDeniedFailure ||
          mapped is AuthFailure ||
          Env.isProd) {
        throw mapped;
      }
      return _mockFallback.loadMerchantDashboard();
    }
  }

  @override
  Stream<MerchantDashboardState> watchMerchantDashboard() {
    final SupabaseClient? activeClient = client;
    final User? user = activeClient?.auth.currentUser;

    if (activeClient == null || user == null) {
      return _mockFallback.watchMerchantDashboard();
    }

    final StreamController<MerchantDashboardState> controller =
        StreamController<MerchantDashboardState>.broadcast();

    final String channelName = 'merchant_dash_${user.id}';
    final RealtimeChannel channel = activeClient.channel(channelName);

    Future<void> refresh() async {
      try {
        final MerchantDashboardState updated = await loadMerchantDashboard();
        if (!controller.isClosed) {
          controller.add(updated);
        }
      } on Object catch (error) {
        if (!controller.isClosed) {
          controller.addError(AppException.fromError(error));
        }
      }
    }

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (_) => unawaited(refresh()),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'merchants',
          callback: (_) => unawaited(refresh()),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products',
          callback: (_) => unawaited(refresh()),
        )
        .subscribe();

    controller.onCancel = () {
      unawaited(activeClient.removeChannel(channel));
      unawaited(controller.close());
    };

    return controller.stream;
  }

  @override
  Future<MerchantDashboardState> toggleMerchantStatus({
    required bool isOpen,
  }) async {
    final SupabaseClient? activeClient = client;
    final User? user = activeClient?.auth.currentUser;
    if (activeClient != null && user != null) {
      try {
        await RetryPolicy.execute<void>(
          () => activeClient
              .from('merchants')
              .update(<String, Object?>{
                'estado': isOpen ? 'activo' : 'pausado',
              })
              .eq('owner_id', user.id),
          maxAttempts: 2,
          timeout: RetryPolicy.defaultMutationTimeout,
        );
        return await loadMerchantDashboard();
      } on Object catch (error) {
        final AppException mapped = AppException.fromError(error);
        if (mapped is PermissionDeniedFailure ||
            mapped is AuthFailure ||
            !Env.isDev) {
          throw mapped;
        }
      }
    }
    return _mockFallback.toggleMerchantStatus(isOpen: isOpen);
  }

  @override
  Future<MerchantDashboardState> updateMerchantOrderStatus({
    required String orderId,
    required MerchantOrderStatus newStatus,
  }) async {
    final SupabaseClient? activeClient = client;
    if (activeClient != null) {
      try {
        final String targetEstado = switch (newStatus) {
          MerchantOrderStatus.inKitchen => 'en_preparacion',
          MerchantOrderStatus.readyForPickup => 'listo_para_retirar',
          MerchantOrderStatus.completed => 'entregado',
          MerchantOrderStatus.incoming => 'confirmado',
        };

        await RetryPolicy.execute<void>(
          () => activeClient.rpc<void>(
            'panel_cambiar_estado',
            params: <String, Object?>{
              'p_pedido_id': orderId,
              'p_estado': targetEstado,
            },
          ),
          maxAttempts: 2,
          timeout: RetryPolicy.defaultMutationTimeout,
        );
        return await loadMerchantDashboard();
      } on Object catch (error) {
        final AppException mapped = AppException.fromError(error);
        if (mapped is PermissionDeniedFailure ||
            mapped is AuthFailure ||
            !Env.isDev) {
          throw mapped;
        }
      }
    }
    return _mockFallback.updateMerchantOrderStatus(
      orderId: orderId,
      newStatus: newStatus,
    );
  }

  @override
  Future<MerchantDashboardState> toggleMenuItemAvailability({
    required String itemId,
    required bool isAvailable,
  }) async {
    final SupabaseClient? activeClient = client;
    if (activeClient != null) {
      try {
        await RetryPolicy.execute<void>(
          () => activeClient
              .from('products')
              .update(<String, Object?>{'is_available': isAvailable})
              .eq('id', itemId),
          maxAttempts: 2,
          timeout: RetryPolicy.defaultMutationTimeout,
        );
        return await loadMerchantDashboard();
      } on Object catch (error) {
        final AppException mapped = AppException.fromError(error);
        if (mapped is PermissionDeniedFailure ||
            mapped is AuthFailure ||
            !Env.isDev) {
          throw mapped;
        }
      }
    }
    return _mockFallback.toggleMenuItemAvailability(
      itemId: itemId,
      isAvailable: isAvailable,
    );
  }

  // ── ADMINISTRADOR ─────────────────────────────────────────────────────────

  @override
  Future<AdminDashboardState> loadAdminDashboard() async {
    final SupabaseClient? activeClient = client;
    if (activeClient == null) {
      return _mockFallback.loadAdminDashboard();
    }

    try {
      final Future<List<Map<String, Object?>>> merchantsFuture =
          RetryPolicy.execute<List<Map<String, Object?>>>(
            () => activeClient
                .from('merchants')
                .select('id, name, estado, costo_envio_base')
                .order('name'),
          );

      final Future<List<Map<String, Object?>>> couriersFuture =
          RetryPolicy.execute<List<Map<String, Object?>>>(
            () => activeClient
                .from('profiles')
                .select('id, nombre, telefono, vehiculo, patente')
                .eq('rol', 'repartidor'),
          );

      final Future<Map<String, Object?>?> settingsFuture =
          RetryPolicy.execute<Map<String, Object?>?>(
            () => activeClient
                .from('delivery_settings')
                .select('base_fee_centavos')
                .eq('id', 'default')
                .maybeSingle(),
          );

      final List<Object?> results = await Future.wait<Object?>(
        <Future<Object?>>[merchantsFuture, couriersFuture, settingsFuture],
      );

      final List<Map<String, Object?>> merchants =
          results[0]! as List<Map<String, Object?>>;
      final List<Map<String, Object?>> couriers =
          results[1]! as List<Map<String, Object?>>;
      final Map<String, Object?>? deliverySettings =
          results[2] as Map<String, Object?>?;

      if (merchants.isEmpty && Env.isDev) {
        return await _mockFallback.loadAdminDashboard();
      }

      final List<AdminMerchantSummary> merchantSummaries = merchants.map((
        Map<String, Object?> m,
      ) {
        final bool isOpen = (m['estado'] as String?) == 'activo';
        return AdminMerchantSummary(
          id: m['id'] as String? ?? '',
          name: m['name'] as String? ?? 'Local Alvear',
          address: 'General Alvear, Mendoza',
          activeOrdersCount: 2,
          isOpen: isOpen,
          commissionPercent: 12.0,
        );
      }).toList();

      final List<AdminCourierSummary> courierSummaries = couriers.map((
        Map<String, Object?> c,
      ) {
        return AdminCourierSummary(
          id: c['id'] as String? ?? '',
          name: c['nombre'] as String? ?? 'Repartidor',
          phone: c['telefono'] as String? ?? '+54 9 2625 401234',
          isOnline: true,
          todayDeliveries: 3,
          cashCollectedCents: 450000,
        );
      }).toList();

      final int baseFee =
          (deliverySettings?['base_fee_centavos'] as num?)?.toInt() ?? 120000;
      final AdminDashboardState fallbackState = await _mockFallback
          .loadAdminDashboard();

      return AdminDashboardState(
        todayGmvCents: 12500000,
        todayCommissionsCents: 1562500,
        activeOrders: 8,
        openMerchants: merchantSummaries
            .where((AdminMerchantSummary m) => m.isOpen)
            .length,
        activeCouriers: courierSummaries.isNotEmpty
            ? courierSummaries.length
            : (Env.isDev ? fallbackState.activeCouriers : 0),
        avgDeliveryMinutes: 28,
        baseDeliveryFeeCents: baseFee,
        merchants: merchantSummaries,
        couriers: courierSummaries.isNotEmpty
            ? courierSummaries
            : (Env.isDev
                  ? fallbackState.couriers
                  : const <AdminCourierSummary>[]),
      );
    } on PermissionDeniedFailure {
      rethrow;
    } on AuthFailure {
      rethrow;
    } on Object catch (error) {
      final AppException mapped = AppException.fromError(error);
      if (mapped is PermissionDeniedFailure ||
          mapped is AuthFailure ||
          Env.isProd) {
        throw mapped;
      }
      return _mockFallback.loadAdminDashboard();
    }
  }

  @override
  Stream<AdminDashboardState> watchAdminDashboard() {
    final SupabaseClient? activeClient = client;
    if (activeClient == null) {
      return _mockFallback.watchAdminDashboard();
    }

    final StreamController<AdminDashboardState> controller =
        StreamController<AdminDashboardState>.broadcast();

    const String channelName = 'admin_dash_global';
    final RealtimeChannel channel = activeClient.channel(channelName);

    Future<void> refresh() async {
      try {
        final AdminDashboardState updated = await loadAdminDashboard();
        if (!controller.isClosed) {
          controller.add(updated);
        }
      } on Object catch (error) {
        if (!controller.isClosed) {
          controller.addError(AppException.fromError(error));
        }
      }
    }

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (_) => unawaited(refresh()),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'merchants',
          callback: (_) => unawaited(refresh()),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'delivery_settings',
          callback: (_) => unawaited(refresh()),
        )
        .subscribe();

    controller.onCancel = () {
      unawaited(activeClient.removeChannel(channel));
      unawaited(controller.close());
    };

    return controller.stream;
  }

  @override
  Future<AdminDashboardState> toggleMerchantAdminActive({
    required String merchantId,
    required bool isOpen,
  }) async {
    final SupabaseClient? activeClient = client;
    if (activeClient != null) {
      try {
        await RetryPolicy.execute<void>(
          () => activeClient
              .from('merchants')
              .update(<String, Object?>{
                'estado': isOpen ? 'activo' : 'pausado',
              })
              .eq('id', merchantId),
          maxAttempts: 2,
          timeout: RetryPolicy.defaultMutationTimeout,
        );
        return await loadAdminDashboard();
      } on Object catch (error) {
        final AppException mapped = AppException.fromError(error);
        if (mapped is PermissionDeniedFailure ||
            mapped is AuthFailure ||
            !Env.isDev) {
          throw mapped;
        }
      }
    }
    return _mockFallback.toggleMerchantAdminActive(
      merchantId: merchantId,
      isOpen: isOpen,
    );
  }

  @override
  Future<AdminDashboardState> updateBaseDeliveryFee({
    required int newFeeCents,
  }) async {
    final SupabaseClient? activeClient = client;
    if (activeClient != null) {
      try {
        await RetryPolicy.execute<void>(
          () => activeClient
              .from('delivery_settings')
              .update(<String, Object?>{'base_fee_centavos': newFeeCents})
              .eq('id', 'default'),
          maxAttempts: 2,
          timeout: RetryPolicy.defaultMutationTimeout,
        );
        return await loadAdminDashboard();
      } on Object catch (error) {
        final AppException mapped = AppException.fromError(error);
        if (mapped is PermissionDeniedFailure ||
            mapped is AuthFailure ||
            !Env.isDev) {
          throw mapped;
        }
      }
    }
    return _mockFallback.updateBaseDeliveryFee(newFeeCents: newFeeCents);
  }
}
