import 'package:clinapp/features/orders/domain/orders_models.dart';

/// Contrato de repositorio para la pantalla Pedidos y seguimiento en vivo.
abstract interface class OrdersRepository {
  /// Obtiene los pedidos activos y el historial paginado.
  Future<OrdersPageData> fetchOrders({int page = 0, int pageSize = 4});

  /// Suscripción Realtime a cambios de estado y ubicación del repartidor en pedidos activos.
  Stream<OrdersRealtimeEvent> watchActiveOrders();

  /// Suscripción Realtime específica a un único pedido por ID (`postgres_changes` + broadcast).
  Stream<OrdersRealtimeEvent> watchOrder(String orderId);

  /// Suscripción Realtime a los mensajes de chat de un pedido.
  Stream<List<ChatMessage>> watchChatMessages(String orderId);

  /// Envía un mensaje de chat para un pedido específico.
  Future<void> sendChatMessage({
    required String orderId,
    required String content,
  });

  /// Revalida los precios vigentes y disponibilidad de productos en el servidor.
  Future<ReorderValidationResult> revalidateOrderForRepeat(OrderSummary order);
}
