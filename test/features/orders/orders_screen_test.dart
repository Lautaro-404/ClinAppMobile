import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_theme.dart';
import 'package:clinapp/core/utils/date_formatter.dart';
import 'package:clinapp/features/orders/data/supabase_orders_repository.dart';
import 'package:clinapp/features/orders/domain/orders_models.dart';
import 'package:clinapp/features/orders/domain/orders_repository.dart';
import 'package:clinapp/features/orders/presentation/active_orders_count_provider.dart';
import 'package:clinapp/features/orders/presentation/orders_screen.dart';
import 'package:clinapp/features/orders/presentation/widgets/active_order_tracking_card.dart';
import 'package:clinapp/features/orders/presentation/widgets/order_history_card.dart';
import 'package:clinapp/features/orders/presentation/widgets/order_stepper.dart';

class _FakeOrdersRepository implements OrdersRepository {
  _FakeOrdersRepository({
    this.initialActive = const <OrderSummary>[],
    this.initialHistory = const <OrderSummary>[],
    this.hasMore = false,
  });

  final List<OrderSummary> initialActive;
  final List<OrderSummary> initialHistory;
  final bool hasMore;

  final StreamController<OrdersRealtimeEvent> realtimeController =
      StreamController<OrdersRealtimeEvent>.broadcast();

  bool revalidateCalled = false;
  int fetchOrdersCount = 0;

  @override
  Future<OrdersPageData> fetchOrders({int page = 0, int pageSize = 4}) async {
    fetchOrdersCount++;
    if (page == 0) {
      return OrdersPageData(
        activeOrders: initialActive,
        historyOrders: initialHistory,
        hasMoreHistory: hasMore,
        currentPage: 0,
      );
    }
    return OrdersPageData(
      activeOrders: <OrderSummary>[],
      historyOrders: <OrderSummary>[
        OrderSummary(
          id: 'ord-hist-page-2',
          shortCode: '#3001',
          merchantId: 'm-extra',
          merchantName: 'Parrilla El Quincho',
          itemsSummary: '1x Asado para dos',
          status: OrderStatus.entregado,
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          subtotalCents: 1800000,
          deliveryFeeCents: 100000,
          totalCents: 1900000,
        ),
      ],
      hasMoreHistory: false,
      currentPage: page,
    );
  }

  @override
  Stream<OrdersRealtimeEvent> watchActiveOrders() {
    return realtimeController.stream;
  }

  @override
  Stream<OrdersRealtimeEvent> watchOrder(String orderId) {
    return realtimeController.stream;
  }

  @override
  Stream<List<ChatMessage>> watchChatMessages(String orderId) {
    return Stream<List<ChatMessage>>.value(<ChatMessage>[
      ChatMessage(
        id: 'msg-test-1',
        orderId: orderId,
        senderId: 'courier-test',
        content: 'Voy en camino',
        createdAt: DateTime.now(),
        senderName: 'Joaquín',
      ),
    ]);
  }

  @override
  Future<void> sendChatMessage({
    required String orderId,
    required String content,
  }) async {}

  @override
  Future<ReorderValidationResult> revalidateOrderForRepeat(
    OrderSummary order,
  ) async {
    revalidateCalled = true;
    return ReorderValidationResult(
      orderId: order.id,
      merchantName: order.merchantName,
      revalidatedSubtotalCents: order.subtotalCents,
      priceChanged: false,
      availableItemCount: order.items.length,
    );
  }
}

class _ThrowingOrdersRepository implements OrdersRepository {
  @override
  Future<OrdersPageData> fetchOrders({int page = 0, int pageSize = 4}) async {
    throw const ServerFailure(AppStrings.errorServer);
  }

  @override
  Stream<OrdersRealtimeEvent> watchActiveOrders() {
    return const Stream<OrdersRealtimeEvent>.empty();
  }

  @override
  Stream<OrdersRealtimeEvent> watchOrder(String orderId) {
    return const Stream<OrdersRealtimeEvent>.empty();
  }

  @override
  Stream<List<ChatMessage>> watchChatMessages(String orderId) {
    return const Stream<List<ChatMessage>>.empty();
  }

  @override
  Future<void> sendChatMessage({
    required String orderId,
    required String content,
  }) async {
    throw const ServerFailure(AppStrings.errorServer);
  }

  @override
  Future<ReorderValidationResult> revalidateOrderForRepeat(OrderSummary order) {
    throw const ServerFailure(AppStrings.errorServer);
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_AR');
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(DateFormatter.zoneName));
  });

  group('Dominio: OrderStatus y stepper mapping', () {
    test('mapea todos los estados a OrderStep y stepperIndex de 5 pasos', () {
      expect(OrderStatus.fromDb('creado').stepperIndex, 0);
      expect(OrderStatus.fromDb('pago_pendiente').stepperIndex, 0);
      expect(OrderStatus.fromDb('confirmado').stepperIndex, 0);

      expect(OrderStatus.fromDb('aceptado_por_local').stepperIndex, 1);
      expect(OrderStatus.fromDb('en_preparacion').stepperIndex, 1);

      expect(OrderStatus.fromDb('listo_para_retirar').stepperIndex, 2);

      expect(OrderStatus.fromDb('en_camino').stepperIndex, 3);
      expect(OrderStatus.fromDb('entregado').stepperIndex, 4);

      expect(OrderStatus.fromDb('cancelado').stepperIndex, -1);
      expect(OrderStatus.fromDb('rechazado').stepperIndex, -1);
      expect(OrderStatus.cancelado.isCancelled, isTrue);
      expect(OrderStatus.rechazado.isCancelled, isTrue);

      expect(OrderStatus.confirmado.isActive, isTrue);
      expect(OrderStatus.enCamino.isActive, isTrue);
      expect(OrderStatus.entregado.isTerminal, isTrue);
      expect(OrderStatus.cancelado.isTerminal, isTrue);
      expect(OrderStatus.rechazado.isTerminal, isTrue);
    });
  });

  group('OrdersScreen (Etapa 6)', () {
    late _FakeOrdersRepository fakeRepo;
    late OrderSummary sampleActive;
    late OrderSummary sampleHistory;

    setUp(() {
      sampleActive = OrderSummary(
        id: 'ord-active-4829',
        shortCode: '#4829',
        merchantId: 'm1111111-1111-4111-8111-111111111111',
        merchantName: 'Pizzería La Alvearense',
        itemsSummary: '2x Fugazzeta Rellena + Fainá',
        items: const <OrderLineItem>[
          OrderLineItem(
            productId: 'p1',
            name: 'Fugazzeta Rellena',
            quantity: 2,
            unitPriceCents: 1420000,
            totalPriceCents: 2840000,
          ),
          OrderLineItem(
            productId: 'p2',
            name: 'Fainá Clásica',
            quantity: 1,
            unitPriceCents: 150000,
            totalPriceCents: 150000,
          ),
        ],
        status: OrderStatus.enCamino,
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
        estimatedArrivalAt: DateTime.now().add(const Duration(minutes: 18)),
        remainingMinutes: 18,
        isExpress: true,
        deliveryAddress: 'Av. San Martín 450',
        subtotalCents: 2990000,
        deliveryFeeCents: 120000,
        totalCents: 3110000,
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

      sampleHistory = OrderSummary(
        id: 'ord-hist-4210',
        shortCode: '#4210',
        merchantId: 'm3333333-3333-4333-8333-333333333333',
        merchantName: 'Burgers Alvear Craft',
        itemsSummary: '2x Doble Bacon Smash + Papas',
        items: const <OrderLineItem>[
          OrderLineItem(
            productId: 'p3',
            name: 'Doble Bacon Smash',
            quantity: 2,
            unitPriceCents: 630000,
            totalPriceCents: 1260000,
          ),
        ],
        status: OrderStatus.entregado,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        deliveryAddress: 'Av. San Martín 450',
        subtotalCents: 1460000,
        deliveryFeeCents: 0,
        totalCents: 1460000,
      );

      fakeRepo = _FakeOrdersRepository(
        initialActive: <OrderSummary>[sampleActive],
        initialHistory: <OrderSummary>[sampleHistory],
        hasMore: true,
      );
    });

    testWidgets('renderiza pedido activo con stepper, repartidor y mapa', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [ordersRepositoryProvider.overrideWithValue(fakeRepo)],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(body: OrdersScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text(AppStrings.ordersTitle), findsOneWidget);
      expect(find.byType(ActiveOrderTrackingCard), findsOneWidget);
      expect(find.text('Pizzería La Alvearense'), findsOneWidget);
      expect(find.text('#4829'), findsOneWidget);
      expect(find.text('Joaquín en moto'), findsOneWidget);
      expect(find.text('Honda Wave 110 · A391KOP'), findsOneWidget);

      // Stepper y mapa.
      expect(find.byType(OrderStepper), findsOneWidget);
      expect(find.text('En camino'), findsOneWidget);
      expect(find.text(AppStrings.ordersLiveTrackingCta), findsOneWidget);
      expect(find.text(AppStrings.ordersContactCourierCta), findsOneWidget);

      // Previsualización de historial bajo el pedido activo.
      expect(find.text('Burgers Alvear Craft'), findsOneWidget);
      expect(find.text(r'$14.600'), findsOneWidget);
      expect(find.text(AppStrings.ordersSupportTitle), findsOneWidget);
    });

    testWidgets('cambia a tab Historial y realiza paginación con Cargar más', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [ordersRepositoryProvider.overrideWithValue(fakeRepo)],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(body: OrdersScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Tocamos tab Historial.
      await tester.tap(find.text(AppStrings.ordersHistoryTab));
      await tester.pumpAndSettle();

      // No se muestra la tarjeta de pedido activo en este tab.
      expect(find.byType(ActiveOrderTrackingCard), findsNothing);
      expect(find.byType(OrderHistoryCard), findsOneWidget);

      // Botón cargar más.
      expect(find.text(AppStrings.ordersLoadMore), findsOneWidget);
      await tester.tap(find.text(AppStrings.ordersLoadMore));
      await tester.pumpAndSettle();

      expect(fakeRepo.fetchOrdersCount, 2);
      expect(find.text('Parrilla El Quincho'), findsOneWidget);
      expect(find.text(r'$19.000'), findsOneWidget);
    });

    testWidgets('abre hojas GlassSheet de seguimiento, chat y recibo', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [ordersRepositoryProvider.overrideWithValue(fakeRepo)],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(body: OrdersScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Seguimiento en vivo.
      await tester.tap(find.text(AppStrings.ordersLiveTrackingCta));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.ordersLiveSheetTitle), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(AppStrings.actionClose).first);
      await tester.pumpAndSettle();

      // Chat con repartidor.
      await tester.tap(find.text(AppStrings.ordersContactCourierCta));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.ordersChatSheetTitle), findsOneWidget);
      await tester.tap(find.text(AppStrings.ordersSendMessage));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(AppStrings.actionClose).first);
      await tester.pumpAndSettle();

      // Recibo del historial.
      await tester.tap(
        find.bySemanticsLabel(AppStrings.ordersReceiptSemantics),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.ordersReceiptTitle), findsOneWidget);
      expect(find.text(AppStrings.ordersReceiptTotal), findsOneWidget);
    });

    testWidgets('actualiza en vivo por Realtime y cancela al desmontar', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      late ProviderContainer container;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container = ProviderContainer(
            overrides: [ordersRepositoryProvider.overrideWithValue(fakeRepo)],
          ),
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(body: OrdersScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(container.read(activeOrdersCountProvider), 1);
      expect(fakeRepo.realtimeController.hasListener, isTrue);

      // Emitimos cambio de estado por Realtime a "entregado".
      fakeRepo.realtimeController.add(
        const OrdersRealtimeEvent(
          orderId: 'ord-active-4829',
          updatedStatus: OrderStatus.entregado,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // El badge de pedidos activos baja a 0.
      expect(container.read(activeOrdersCountProvider), 0);

      // Al desmontar la pantalla, la suscripción se cancela.
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      expect(fakeRepo.realtimeController.hasListener, isFalse);
    });

    testWidgets('muestra ErrorState y botón de reintento si falla la carga', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ordersRepositoryProvider.overrideWithValue(
              _ThrowingOrdersRepository(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(body: OrdersScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text(AppStrings.errorServer), findsOneWidget);
      expect(find.text(AppStrings.actionRetry), findsOneWidget);
    });
  });
}
