import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'package:clinapp/core/theme/app_colors.dart';

/// Estados posibles de un pedido (`public.orders.estado`).
enum OrderStatus {
  creado,
  pagoPendiente,
  confirmado,
  aceptadoPorLocal,
  enPreparacion,
  listoParaRetirar,
  enCamino,
  entregado,
  cancelado,
  rechazado;

  static OrderStatus fromDb(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'creado':
        return OrderStatus.creado;
      case 'pago_pendiente':
        return OrderStatus.pagoPendiente;
      case 'confirmado':
        return OrderStatus.confirmado;
      case 'aceptado_por_local':
        return OrderStatus.aceptadoPorLocal;
      case 'en_preparacion':
        return OrderStatus.enPreparacion;
      case 'listo_para_retirar':
        return OrderStatus.listoParaRetirar;
      case 'en_camino':
        return OrderStatus.enCamino;
      case 'entregado':
        return OrderStatus.entregado;
      case 'cancelado':
        return OrderStatus.cancelado;
      case 'rechazado':
        return OrderStatus.rechazado;
      default:
        return OrderStatus.creado;
    }
  }

  String toDb() {
    switch (this) {
      case OrderStatus.creado:
        return 'creado';
      case OrderStatus.pagoPendiente:
        return 'pago_pendiente';
      case OrderStatus.confirmado:
        return 'confirmado';
      case OrderStatus.aceptadoPorLocal:
        return 'aceptado_por_local';
      case OrderStatus.enPreparacion:
        return 'en_preparacion';
      case OrderStatus.listoParaRetirar:
        return 'listo_para_retirar';
      case OrderStatus.enCamino:
        return 'en_camino';
      case OrderStatus.entregado:
        return 'entregado';
      case OrderStatus.cancelado:
        return 'cancelado';
      case OrderStatus.rechazado:
        return 'rechazado';
    }
  }

  bool get isTerminal =>
      this == OrderStatus.entregado ||
      this == OrderStatus.cancelado ||
      this == OrderStatus.rechazado;

  bool get isActive => !isTerminal;

  bool get isCancelled =>
      this == OrderStatus.cancelado || this == OrderStatus.rechazado;

  /// Índice visual en el stepper de 5 pasos (0..4). Retorna -1 si fue cancelado o rechazado.
  int get stepperIndex {
    switch (this) {
      case OrderStatus.creado:
      case OrderStatus.pagoPendiente:
      case OrderStatus.confirmado:
        return 0;
      case OrderStatus.aceptadoPorLocal:
      case OrderStatus.enPreparacion:
        return 1;
      case OrderStatus.listoParaRetirar:
        return 2;
      case OrderStatus.enCamino:
        return 3;
      case OrderStatus.entregado:
        return 4;
      case OrderStatus.cancelado:
      case OrderStatus.rechazado:
        return -1;
    }
  }
}

/// Los 5 pasos visuales del stepper de seguimiento.
enum OrderStep { confirmed, preparing, ready, onTheWay, delivered }

/// Información del repartidor asignado (`public.profiles` + `courier_locations`).
@immutable
class CourierInfo {
  const CourierInfo({
    required this.id,
    required this.name,
    required this.vehicle,
    required this.plate,
    required this.phone,
    required this.lat,
    required this.lng,
    this.isOnline = true,
  });

  final String id;
  final String name;
  final String vehicle;
  final String plate;
  final String phone;
  final double lat;
  final double lng;
  final bool isOnline;

  CourierInfo copyWith({
    String? id,
    String? name,
    String? vehicle,
    String? plate,
    String? phone,
    double? lat,
    double? lng,
    bool? isOnline,
  }) {
    return CourierInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      vehicle: vehicle ?? this.vehicle,
      plate: plate ?? this.plate,
      phone: phone ?? this.phone,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

/// Ítem individual de un pedido (`public.order_items`).
@immutable
class OrderLineItem {
  const OrderLineItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPriceCents,
    required this.totalPriceCents,
  });

  final String productId;
  final String name;
  final int quantity;
  final int unitPriceCents;
  final int totalPriceCents;
}

/// Resumen de un pedido (`public.orders`).
@immutable
class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.shortCode,
    required this.merchantId,
    required this.merchantName,
    required this.itemsSummary,
    required this.status,
    required this.createdAt,
    required this.subtotalCents,
    required this.deliveryFeeCents,
    required this.totalCents,
    this.items = const <OrderLineItem>[],
    this.discountCents = 0,
    this.tipCents = 0,
    this.estimatedArrivalAt,
    this.remainingMinutes,
    this.isExpress = true,
    this.deliveryAddress = 'Av. San Martín 450',
    this.courier,
    this.accentColor = AppColors.accent,
  });

  final String id;
  final String shortCode;
  final String merchantId;
  final String merchantName;
  final String itemsSummary;
  final List<OrderLineItem> items;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? estimatedArrivalAt;
  final int? remainingMinutes;
  final bool isExpress;
  final String deliveryAddress;
  final int subtotalCents;
  final int deliveryFeeCents;
  final int discountCents;
  final int tipCents;
  final int totalCents;
  final CourierInfo? courier;
  final Color accentColor;

  bool get isActive => status.isActive;

  OrderSummary copyWith({
    OrderStatus? status,
    int? remainingMinutes,
    DateTime? estimatedArrivalAt,
    CourierInfo? courier,
  }) {
    return OrderSummary(
      id: id,
      shortCode: shortCode,
      merchantId: merchantId,
      merchantName: merchantName,
      itemsSummary: itemsSummary,
      items: items,
      status: status ?? this.status,
      createdAt: createdAt,
      estimatedArrivalAt: estimatedArrivalAt ?? this.estimatedArrivalAt,
      remainingMinutes: remainingMinutes ?? this.remainingMinutes,
      isExpress: isExpress,
      deliveryAddress: deliveryAddress,
      subtotalCents: subtotalCents,
      deliveryFeeCents: deliveryFeeCents,
      discountCents: discountCents,
      tipCents: tipCents,
      totalCents: totalCents,
      courier: courier ?? this.courier,
      accentColor: accentColor,
    );
  }
}

/// Resultado de revalidación de precios en el servidor al repetir un pedido.
@immutable
class ReorderValidationResult {
  const ReorderValidationResult({
    required this.orderId,
    required this.merchantName,
    required this.revalidatedSubtotalCents,
    required this.priceChanged,
    required this.availableItemCount,
  });

  final String orderId;
  final String merchantName;
  final int revalidatedSubtotalCents;
  final bool priceChanged;
  final int availableItemCount;
}

/// Evento emitido en tiempo real por el stream de pedidos y repartidor.
@immutable
class OrdersRealtimeEvent {
  const OrdersRealtimeEvent({
    required this.orderId,
    this.updatedStatus,
    this.courierLat,
    this.courierLng,
    this.remainingMinutes,
  });

  final String orderId;
  final OrderStatus? updatedStatus;
  final double? courierLat;
  final double? courierLng;
  final int? remainingMinutes;
}

/// Página de pedidos cargada por el repositorio.
@immutable
class OrdersPageData {
  const OrdersPageData({
    required this.activeOrders,
    required this.historyOrders,
    required this.hasMoreHistory,
    required this.currentPage,
  });

  final List<OrderSummary> activeOrders;
  final List<OrderSummary> historyOrders;
  final bool hasMoreHistory;
  final int currentPage;
}

/// Mensaje en tiempo real del chat de un pedido (`public.chat_messages`).
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.senderName = 'Repartidor',
    this.isMine = false,
  });

  final String id;
  final String orderId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final String senderName;
  final bool isMine;

  factory ChatMessage.fromJson(
    Map<String, Object?> json, {
    String? currentUserId,
  }) {
    final String sender = json['sender_id'] as String? ?? '';
    return ChatMessage(
      id: json['id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      senderId: sender,
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)?.toLocal() ??
                DateTime.now()
          : DateTime.now(),
      isMine: currentUserId != null && currentUserId == sender,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'order_id': orderId,
    'sender_id': senderId,
    'content': content,
    'created_at': createdAt.toIso8601String(),
  };
}
