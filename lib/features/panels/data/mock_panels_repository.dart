import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinapp/core/config/supabase_provider.dart';
import 'package:clinapp/features/panels/data/supabase_panels_repository.dart';
import 'package:clinapp/features/panels/domain/panel_models.dart';
import 'package:clinapp/features/panels/domain/panels_repository.dart';

/// Implementación mock en memoria para los paneles de General Alvear.
class MockPanelsRepository implements PanelsRepository {
  MockPanelsRepository() {
    _initData();
  }

  late CourierShiftState _courierShift;
  late MerchantDashboardState _merchantDashboard;
  late AdminDashboardState _adminDashboard;

  final StreamController<CourierShiftState> _courierShiftController =
      StreamController<CourierShiftState>.broadcast();
  final StreamController<MerchantDashboardState> _merchantDashboardController =
      StreamController<MerchantDashboardState>.broadcast();
  final StreamController<AdminDashboardState> _adminDashboardController =
      StreamController<AdminDashboardState>.broadcast();

  void _initData() {
    _courierShift = const CourierShiftState(
      isOnline: true,
      isGpsActive: true,
      todayDeliveriesCount: 8,
      todayEarningsCents: 3845000, // $38.450
      deliveries: <CourierDeliveryItem>[
        CourierDeliveryItem(
          id: '4892',
          orderNumber: '#4892 · Express',
          merchantName: 'Burger Bros',
          merchantAddress: 'Paso de los Andes 142',
          merchantPhone: '2625401122',
          customerName: 'Lautaro Ponzina',
          customerAddress:
              'Teresa De Calcuta 355, Barrio Smata, General Alvear',
          customerPhone: '2994706477',
          deliveryNotes: 'Puerta a la calle',
          status: CourierDeliveryStatus.onTheWay,
          isExpress: true,
          distanceEstimate: 'A 1.2 km de la entrega (~4 min)',
          amountCents: 1460000, // $14.600
          isCashOnDelivery: true,
          orderItems: <String>[
            '2x Burger Doble Cheddar',
            '1x Papas Fritas Rústicas',
            '1x Coca-Cola 500ml',
          ],
        ),
        CourierDeliveryItem(
          id: '4893',
          orderNumber: '#4893 · Esperando retiro',
          merchantName: 'Burger Bros',
          merchantAddress: 'Paso de los Andes 142',
          merchantPhone: '2625401122',
          customerName: 'Lautaro Ponzina',
          customerAddress: 'Av. Alvear Oeste 840, General Alvear',
          customerPhone: '2625663344',
          deliveryNotes: 'Timbre blanco al fondo',
          status: CourierDeliveryStatus.readyForPickup,
          isExpress: false,
          distanceEstimate: 'A 600 m del comercio (~2 min)',
          amountCents: 980000, // $9.800
          isCashOnDelivery: true,
          orderItems: <String>[
            '1x Burger Triple Bacon',
            '1x Cerveza Andes Origen 473ml',
          ],
        ),
        CourierDeliveryItem(
          id: '4895',
          orderNumber: '#4895 · Cocina',
          merchantName: 'Burger Bros',
          merchantAddress: 'Paso de los Andes 142',
          merchantPhone: '2625401122',
          customerName: 'Carla Morales',
          customerAddress: 'Patricias Mendocinas 210, General Alvear',
          customerPhone: '2625559988',
          deliveryNotes: 'Dejar en reja delantera',
          status: CourierDeliveryStatus.inKitchen,
          isExpress: false,
          distanceEstimate: 'En preparación (~8 min)',
          amountCents: 1120000, // $11.200
          isCashOnDelivery: false,
          orderItems: <String>[
            '1x Burger Cuádruple Smash',
            '1x Aros de Cebolla Crispy',
          ],
        ),
      ],
    );

    _merchantDashboard = const MerchantDashboardState(
      isOpen: true,
      todayRevenueCents: 18420000, // $184.200
      todayCompletedOrders: 19,
      orders: <MerchantOrderItem>[
        MerchantOrderItem(
          id: '5011',
          orderNumber: '#5011',
          customerName: 'Federico Gómez',
          customerAddress: 'Sarmiento 450, General Alvear',
          items: <String>['2x Combo Smash Doble', '1x Gaseosa 1.5L'],
          status: MerchantOrderStatus.incoming,
          prepTimeMinutes: 20,
          totalAmountCents: 1680000,
          isCash: false,
        ),
        MerchantOrderItem(
          id: '4895',
          orderNumber: '#4895',
          customerName: 'Carla Morales',
          customerAddress: 'Patricias Mendocinas 210, General Alvear',
          items: <String>[
            '1x Burger Cuádruple Smash',
            '1x Aros de Cebolla Crispy',
          ],
          status: MerchantOrderStatus.inKitchen,
          prepTimeMinutes: 8,
          totalAmountCents: 1120000,
          isCash: false,
          assignedRiderName: 'Rider #12 (Marcos G.)',
        ),
        MerchantOrderItem(
          id: '4893',
          orderNumber: '#4893',
          customerName: 'Lautaro Ponzina',
          customerAddress: 'Av. Alvear Oeste 840, General Alvear',
          items: <String>['1x Burger Triple Bacon', '1x Cerveza Andes 473ml'],
          status: MerchantOrderStatus.readyForPickup,
          prepTimeMinutes: 0,
          totalAmountCents: 980000,
          isCash: true,
          assignedRiderName: 'Rider #04 (Lautaro P.)',
        ),
      ],
      menuItems: <MerchantMenuItem>[
        MerchantMenuItem(
          id: 'm1',
          name: 'Burger Doble Cheddar',
          description:
              'Doble medallón 120g, queso cheddar fundido y pan de papa',
          priceCents: 780000,
          isAvailable: true,
        ),
        MerchantMenuItem(
          id: 'm2',
          name: 'Burger Triple Bacon',
          description:
              'Triple medallón, panceta crocante y salsa especial Clin',
          priceCents: 980000,
          isAvailable: true,
        ),
        MerchantMenuItem(
          id: 'm3',
          name: 'Burger Cuádruple Smash',
          description: 'Cuádruple carne ultra smashed con cuádruple cheddar',
          priceCents: 1120000,
          isAvailable: true,
        ),
        MerchantMenuItem(
          id: 'm4',
          name: 'Papas Rústicas Cheddar',
          description:
              'Papas naturales con crema de cheddar y cebollita de verdeo',
          priceCents: 450000,
          isAvailable: true,
        ),
        MerchantMenuItem(
          id: 'm5',
          name: 'Aros de Cebolla Crispy',
          description: 'Aros dorados rebozados con salsa barbacoa casera',
          priceCents: 380000,
          isAvailable: true,
        ),
        MerchantMenuItem(
          id: 'm6',
          name: 'Combo Clin Familiar',
          description: '4 hamburguesas dobles + 2 papas grandes + bebida 2.25L',
          priceCents: 2450000,
          isAvailable: false,
        ),
      ],
    );

    _adminDashboard = const AdminDashboardState(
      activeOrders: 14,
      activeCouriers: 8,
      openMerchants: 12,
      avgDeliveryMinutes: 22,
      todayGmvCents: 124580000, // $1.245.800
      todayCommissionsCents: 18687000, // $186.870
      baseDeliveryFeeCents: 150000, // $1.500
      merchants: <AdminMerchantSummary>[
        AdminMerchantSummary(
          id: 'm-bb',
          name: 'Burger Bros',
          address: 'Paso de los Andes 142',
          activeOrdersCount: 3,
          isOpen: true,
          commissionPercent: 15.0,
        ),
        AdminMerchantSummary(
          id: 'm-dj',
          name: 'Pizzería Don José',
          address: 'Av. Libertador Norte 320',
          activeOrdersCount: 4,
          isOpen: true,
          commissionPercent: 14.0,
        ),
        AdminMerchantSummary(
          id: 'm-hc',
          name: 'Heladería Colonial',
          address: 'Alvear Oeste 115',
          activeOrdersCount: 2,
          isOpen: true,
          commissionPercent: 12.0,
        ),
        AdminMerchantSummary(
          id: 'm-ea',
          name: 'Empanadas El Alvearense',
          address: 'Zeballos 88',
          activeOrdersCount: 5,
          isOpen: true,
          commissionPercent: 15.0,
        ),
      ],
      couriers: <AdminCourierSummary>[
        AdminCourierSummary(
          id: 'c-1',
          name: 'Lautaro Ponzina',
          phone: '2994706477',
          isOnline: true,
          todayDeliveries: 8,
          cashCollectedCents: 2440000,
        ),
        AdminCourierSummary(
          id: 'c-2',
          name: 'Marcos Giménez',
          phone: '2625441100',
          isOnline: true,
          todayDeliveries: 9,
          cashCollectedCents: 4200000,
        ),
        AdminCourierSummary(
          id: 'c-3',
          name: 'Lucas Rossi',
          phone: '2625998811',
          isOnline: true,
          todayDeliveries: 6,
          cashCollectedCents: 1850000,
        ),
        AdminCourierSummary(
          id: 'c-4',
          name: 'Martín Sosa',
          phone: '2625123456',
          isOnline: false,
          todayDeliveries: 4,
          cashCollectedCents: 1200000,
        ),
      ],
    );
  }

  @override
  Future<CourierShiftState> loadCourierShift() async {
    return _courierShift;
  }

  @override
  Stream<CourierShiftState> watchCourierShift() {
    return _courierShiftController.stream;
  }

  @override
  Future<CourierShiftState> toggleCourierShift({required bool isOnline}) async {
    _courierShift = _courierShift.copyWith(isOnline: isOnline);
    _courierShiftController.add(_courierShift);
    return _courierShift;
  }

  @override
  Future<CourierShiftState> updateDeliveryStatus({
    required String deliveryId,
    required CourierDeliveryStatus newStatus,
  }) async {
    final List<CourierDeliveryItem> updatedList = _courierShift.deliveries.map((
      CourierDeliveryItem item,
    ) {
      if (item.id == deliveryId) {
        return item.copyWith(status: newStatus);
      }
      return item;
    }).toList();

    int earnings = _courierShift.todayEarningsCents;
    int count = _courierShift.todayDeliveriesCount;

    if (newStatus == CourierDeliveryStatus.delivered) {
      earnings += 240000; // Tarifa repartidor por entrega completada
      count += 1;
    }

    _courierShift = _courierShift.copyWith(
      deliveries: updatedList,
      todayEarningsCents: earnings,
      todayDeliveriesCount: count,
    );
    _courierShiftController.add(_courierShift);
    return _courierShift;
  }

  @override
  Future<MerchantDashboardState> loadMerchantDashboard() async {
    return _merchantDashboard;
  }

  @override
  Stream<MerchantDashboardState> watchMerchantDashboard() {
    return _merchantDashboardController.stream;
  }

  @override
  Future<MerchantDashboardState> toggleMerchantStatus({
    required bool isOpen,
  }) async {
    _merchantDashboard = _merchantDashboard.copyWith(isOpen: isOpen);
    _merchantDashboardController.add(_merchantDashboard);
    return _merchantDashboard;
  }

  @override
  Future<MerchantDashboardState> updateMerchantOrderStatus({
    required String orderId,
    required MerchantOrderStatus newStatus,
  }) async {
    final List<MerchantOrderItem> updatedOrders = _merchantDashboard.orders.map(
      (MerchantOrderItem o) {
        if (o.id == orderId) {
          return o.copyWith(status: newStatus);
        }
        return o;
      },
    ).toList();

    int revenue = _merchantDashboard.todayRevenueCents;
    int completed = _merchantDashboard.todayCompletedOrders;

    if (newStatus == MerchantOrderStatus.completed) {
      completed += 1;
      final MerchantOrderItem finished = _merchantDashboard.orders.firstWhere(
        (MerchantOrderItem o) => o.id == orderId,
      );
      revenue += finished.totalAmountCents;
    }

    _merchantDashboard = _merchantDashboard.copyWith(
      orders: updatedOrders,
      todayRevenueCents: revenue,
      todayCompletedOrders: completed,
    );
    _merchantDashboardController.add(_merchantDashboard);
    return _merchantDashboard;
  }

  @override
  Future<MerchantDashboardState> toggleMenuItemAvailability({
    required String itemId,
    required bool isAvailable,
  }) async {
    final List<MerchantMenuItem> updatedMenu = _merchantDashboard.menuItems.map(
      (MerchantMenuItem m) {
        if (m.id == itemId) {
          return m.copyWith(isAvailable: isAvailable);
        }
        return m;
      },
    ).toList();

    _merchantDashboard = _merchantDashboard.copyWith(menuItems: updatedMenu);
    _merchantDashboardController.add(_merchantDashboard);
    return _merchantDashboard;
  }

  @override
  Future<AdminDashboardState> loadAdminDashboard() async {
    return _adminDashboard;
  }

  @override
  Stream<AdminDashboardState> watchAdminDashboard() {
    return _adminDashboardController.stream;
  }

  @override
  Future<AdminDashboardState> toggleMerchantAdminActive({
    required String merchantId,
    required bool isOpen,
  }) async {
    final List<AdminMerchantSummary> updated = _adminDashboard.merchants.map((
      AdminMerchantSummary m,
    ) {
      if (m.id == merchantId) {
        return m.copyWith(isOpen: isOpen);
      }
      return m;
    }).toList();

    final int openCount = updated
        .where((AdminMerchantSummary m) => m.isOpen)
        .length;

    _adminDashboard = _adminDashboard.copyWith(
      merchants: updated,
      openMerchants: openCount,
    );
    _adminDashboardController.add(_adminDashboard);
    return _adminDashboard;
  }

  @override
  Future<AdminDashboardState> updateBaseDeliveryFee({
    required int newFeeCents,
  }) async {
    _adminDashboard = _adminDashboard.copyWith(
      baseDeliveryFeeCents: newFeeCents,
    );
    _adminDashboardController.add(_adminDashboard);
    return _adminDashboard;
  }
}

/// Provider del repositorio de paneles.
final Provider<PanelsRepository> panelsRepositoryProvider =
    Provider<PanelsRepository>((Ref ref) {
      final SupabaseClient? client = ref.watch(supabaseClientProvider);
      return SupabasePanelsRepository(client: client);
    });
