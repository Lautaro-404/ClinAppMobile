import 'package:clinapp/features/panels/domain/panel_models.dart';

/// Contrato para las operaciones de los paneles de Repartidor, Local y Administrador.
abstract interface class PanelsRepository {
  /// Carga el estado del turno del repartidor.
  Future<CourierShiftState> loadCourierShift();

  /// Suscripción Realtime a cambios en el turno y pedidos asignados/disponibles del repartidor.
  Stream<CourierShiftState> watchCourierShift();

  /// Alterna el estado online/pausado del repartidor.
  Future<CourierShiftState> toggleCourierShift({required bool isOnline});

  /// Actualiza el estado de una entrega (ej. en camino, entregado).
  Future<CourierShiftState> updateDeliveryStatus({
    required String deliveryId,
    required CourierDeliveryStatus newStatus,
  });

  /// Carga el estado operativo del comercio.
  Future<MerchantDashboardState> loadMerchantDashboard();

  /// Suscripción Realtime a pedidos entrantes y cartas del comercio.
  Stream<MerchantDashboardState> watchMerchantDashboard();

  /// Alterna la apertura/pausa del comercio.
  Future<MerchantDashboardState> toggleMerchantStatus({required bool isOpen});

  /// Actualiza el estado de un pedido del comercio (ej. en cocina, listo, completado).
  Future<MerchantDashboardState> updateMerchantOrderStatus({
    required String orderId,
    required MerchantOrderStatus newStatus,
  });

  /// Alterna la disponibilidad de stock de un ítem del menú.
  Future<MerchantDashboardState> toggleMenuItemAvailability({
    required String itemId,
    required bool isAvailable,
  });

  /// Carga el resumen de métricas del panel de administración.
  Future<AdminDashboardState> loadAdminDashboard();

  /// Suscripción Realtime a métricas y cambios globales del panel administrador.
  Stream<AdminDashboardState> watchAdminDashboard();

  /// Alterna el estado operativo de un comercio desde el admin.
  Future<AdminDashboardState> toggleMerchantAdminActive({
    required String merchantId,
    required bool isOpen,
  });

  /// Actualiza la tarifa base de envío para General Alvear.
  Future<AdminDashboardState> updateBaseDeliveryFee({required int newFeeCents});
}
