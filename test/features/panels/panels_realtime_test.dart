import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clinapp/features/panels/data/mock_panels_repository.dart';
import 'package:clinapp/features/panels/domain/panel_models.dart';
import 'package:clinapp/features/panels/domain/panels_repository.dart';
import 'package:clinapp/features/panels/presentation/controllers/admin_panel_controller.dart';
import 'package:clinapp/features/panels/presentation/controllers/courier_panel_controller.dart';
import 'package:clinapp/features/panels/presentation/controllers/merchant_panel_controller.dart';

class _FakePanelsRealtimeRepository implements PanelsRepository {
  final StreamController<CourierShiftState> courierController =
      StreamController<CourierShiftState>.broadcast();
  final StreamController<MerchantDashboardState> merchantController =
      StreamController<MerchantDashboardState>.broadcast();
  final StreamController<AdminDashboardState> adminController =
      StreamController<AdminDashboardState>.broadcast();

  bool watchCourierCalled = false;
  bool watchMerchantCalled = false;
  bool watchAdminCalled = false;

  final CourierShiftState initialCourierShift = const CourierShiftState(
    isOnline: true,
    isGpsActive: true,
    todayDeliveriesCount: 3,
    todayEarningsCents: 720000,
    deliveries: <CourierDeliveryItem>[],
  );

  final MerchantDashboardState initialMerchantState =
      const MerchantDashboardState(
        isOpen: true,
        orders: <MerchantOrderItem>[],
        menuItems: <MerchantMenuItem>[],
        todayRevenueCents: 5000000,
        todayCompletedOrders: 4,
      );

  final AdminDashboardState initialAdminState = const AdminDashboardState(
    activeOrders: 5,
    activeCouriers: 3,
    openMerchants: 6,
    avgDeliveryMinutes: 24,
    todayGmvCents: 10000000,
    todayCommissionsCents: 1200000,
    baseDeliveryFeeCents: 150000,
    merchants: <AdminMerchantSummary>[],
    couriers: <AdminCourierSummary>[],
  );

  @override
  Future<CourierShiftState> loadCourierShift() async => initialCourierShift;

  @override
  Stream<CourierShiftState> watchCourierShift() {
    watchCourierCalled = true;
    return courierController.stream;
  }

  @override
  Future<CourierShiftState> toggleCourierShift({
    required bool isOnline,
  }) async => initialCourierShift.copyWith(isOnline: isOnline);

  @override
  Future<CourierShiftState> updateDeliveryStatus({
    required String deliveryId,
    required CourierDeliveryStatus newStatus,
  }) async => initialCourierShift;

  @override
  Future<MerchantDashboardState> loadMerchantDashboard() async =>
      initialMerchantState;

  @override
  Stream<MerchantDashboardState> watchMerchantDashboard() {
    watchMerchantCalled = true;
    return merchantController.stream;
  }

  @override
  Future<MerchantDashboardState> toggleMerchantStatus({
    required bool isOpen,
  }) async => initialMerchantState.copyWith(isOpen: isOpen);

  @override
  Future<MerchantDashboardState> updateMerchantOrderStatus({
    required String orderId,
    required MerchantOrderStatus newStatus,
  }) async => initialMerchantState;

  @override
  Future<MerchantDashboardState> toggleMenuItemAvailability({
    required String itemId,
    required bool isAvailable,
  }) async => initialMerchantState;

  @override
  Future<AdminDashboardState> loadAdminDashboard() async => initialAdminState;

  @override
  Stream<AdminDashboardState> watchAdminDashboard() {
    watchAdminCalled = true;
    return adminController.stream;
  }

  @override
  Future<AdminDashboardState> toggleMerchantAdminActive({
    required String merchantId,
    required bool isOpen,
  }) async => initialAdminState;

  @override
  Future<AdminDashboardState> updateBaseDeliveryFee({
    required int newFeeCents,
  }) async => initialAdminState.copyWith(baseDeliveryFeeCents: newFeeCents);
}

void main() {
  late _FakePanelsRealtimeRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = _FakePanelsRealtimeRepository();
    container = ProviderContainer(
      overrides: [panelsRepositoryProvider.overrideWithValue(fakeRepo)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('CourierPanelController se suscribe a Realtime y actualiza estado al recibir evento', () async {
    final AsyncValue<CourierPanelViewState> state = await container
        .read(courierPanelControllerProvider.future)
        .then((CourierPanelViewState s) => AsyncData<CourierPanelViewState>(s));

    expect(state.value?.shift.todayDeliveriesCount, 3);
    expect(fakeRepo.watchCourierCalled, isTrue);

    // Emite actualización en tiempo real (ej. nueva entrega completada)
    fakeRepo.courierController.add(
      fakeRepo.initialCourierShift.copyWith(
        todayDeliveriesCount: 4,
        todayEarningsCents: 960000,
      ),
    );

    // Esperar tick de microtarea
    await Future<void>.delayed(Duration.zero);

    final CourierPanelViewState? current = container
        .read(courierPanelControllerProvider)
        .value;
    expect(current?.shift.todayDeliveriesCount, 4);
    expect(current?.shift.todayEarningsCents, 960000);
  });

  test('MerchantPanelController se suscribe a Realtime y actualiza pedidos entrantes', () async {
    await container.read(merchantPanelControllerProvider.future);
    expect(fakeRepo.watchMerchantCalled, isTrue);

    // Emite pedido entrante en tiempo real
    fakeRepo.merchantController.add(
      fakeRepo.initialMerchantState.copyWith(
        todayCompletedOrders: 5,
        orders: const <MerchantOrderItem>[
          MerchantOrderItem(
            id: 'ord-incoming-1',
            orderNumber: '#IN01',
            customerName: 'Cliente Alvear',
            customerAddress: 'Av. Alvear Oeste 450',
            items: <String>['2x Empanadas Mendocinas'],
            status: MerchantOrderStatus.incoming,
            prepTimeMinutes: 20,
            totalAmountCents: 240000,
            isCash: false,
          ),
        ],
      ),
    );

    await Future<void>.delayed(Duration.zero);

    final MerchantPanelViewState? current = container
        .read(merchantPanelControllerProvider)
        .value;
    expect(current?.dashboard.todayCompletedOrders, 5);
    expect(current?.dashboard.orders.first.orderNumber, '#IN01');
  });

  test(
    'AdminPanelController se suscribe a Realtime y actualiza KPIs globales',
    () async {
      await container.read(adminPanelControllerProvider.future);
      expect(fakeRepo.watchAdminCalled, isTrue);

      // Emite actualización de métricas globales en tiempo real
      fakeRepo.adminController.add(
        fakeRepo.initialAdminState.copyWith(
          activeOrders: 9,
          todayGmvCents: 15400000,
        ),
      );

      await Future<void>.delayed(Duration.zero);

      final AdminPanelViewState? current = container
          .read(adminPanelControllerProvider)
          .value;
      expect(current?.dashboard.activeOrders, 9);
      expect(current?.dashboard.todayGmvCents, 15400000);
    },
  );
}
