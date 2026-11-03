import 'package:flutter/foundation.dart';

/// Estado de una entrega para el repartidor.
enum CourierDeliveryStatus { onTheWay, readyForPickup, inKitchen, delivered }

/// Elemento de entrega asignado a un repartidor.
@immutable
class CourierDeliveryItem {
  const CourierDeliveryItem({
    required this.id,
    required this.orderNumber,
    required this.merchantName,
    required this.merchantAddress,
    required this.merchantPhone,
    required this.customerName,
    required this.customerAddress,
    required this.customerPhone,
    required this.deliveryNotes,
    required this.status,
    required this.isExpress,
    required this.distanceEstimate,
    required this.amountCents,
    required this.isCashOnDelivery,
    required this.orderItems,
  });

  final String id;
  final String orderNumber;
  final String merchantName;
  final String merchantAddress;
  final String merchantPhone;
  final String customerName;
  final String customerAddress;
  final String customerPhone;
  final String deliveryNotes;
  final CourierDeliveryStatus status;
  final bool isExpress;
  final String distanceEstimate;
  final int amountCents;
  final bool isCashOnDelivery;
  final List<String> orderItems;

  CourierDeliveryItem copyWith({
    String? id,
    String? orderNumber,
    String? merchantName,
    String? merchantAddress,
    String? merchantPhone,
    String? customerName,
    String? customerAddress,
    String? customerPhone,
    String? deliveryNotes,
    CourierDeliveryStatus? status,
    bool? isExpress,
    String? distanceEstimate,
    int? amountCents,
    bool? isCashOnDelivery,
    List<String>? orderItems,
  }) {
    return CourierDeliveryItem(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      merchantName: merchantName ?? this.merchantName,
      merchantAddress: merchantAddress ?? this.merchantAddress,
      merchantPhone: merchantPhone ?? this.merchantPhone,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      status: status ?? this.status,
      isExpress: isExpress ?? this.isExpress,
      distanceEstimate: distanceEstimate ?? this.distanceEstimate,
      amountCents: amountCents ?? this.amountCents,
      isCashOnDelivery: isCashOnDelivery ?? this.isCashOnDelivery,
      orderItems: orderItems ?? this.orderItems,
    );
  }
}

/// Estado global del panel del repartidor.
@immutable
class CourierShiftState {
  const CourierShiftState({
    required this.isOnline,
    required this.isGpsActive,
    required this.todayDeliveriesCount,
    required this.todayEarningsCents,
    required this.deliveries,
  });

  final bool isOnline;
  final bool isGpsActive;
  final int todayDeliveriesCount;
  final int todayEarningsCents;
  final List<CourierDeliveryItem> deliveries;

  CourierShiftState copyWith({
    bool? isOnline,
    bool? isGpsActive,
    int? todayDeliveriesCount,
    int? todayEarningsCents,
    List<CourierDeliveryItem>? deliveries,
  }) {
    return CourierShiftState(
      isOnline: isOnline ?? this.isOnline,
      isGpsActive: isGpsActive ?? this.isGpsActive,
      todayDeliveriesCount: todayDeliveriesCount ?? this.todayDeliveriesCount,
      todayEarningsCents: todayEarningsCents ?? this.todayEarningsCents,
      deliveries: deliveries ?? this.deliveries,
    );
  }
}

/// Estado de preparación de un pedido para el comercio.
enum MerchantOrderStatus { incoming, inKitchen, readyForPickup, completed }

/// Pedido visible en el panel del comercio.
@immutable
class MerchantOrderItem {
  const MerchantOrderItem({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerAddress,
    required this.items,
    required this.status,
    required this.prepTimeMinutes,
    required this.totalAmountCents,
    required this.isCash,
    this.assignedRiderName,
  });

  final String id;
  final String orderNumber;
  final String customerName;
  final String customerAddress;
  final List<String> items;
  final MerchantOrderStatus status;
  final int prepTimeMinutes;
  final int totalAmountCents;
  final bool isCash;
  final String? assignedRiderName;

  MerchantOrderItem copyWith({
    String? id,
    String? orderNumber,
    String? customerName,
    String? customerAddress,
    List<String>? items,
    MerchantOrderStatus? status,
    int? prepTimeMinutes,
    int? totalAmountCents,
    bool? isCash,
    String? assignedRiderName,
  }) {
    return MerchantOrderItem(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      items: items ?? this.items,
      status: status ?? this.status,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      totalAmountCents: totalAmountCents ?? this.totalAmountCents,
      isCash: isCash ?? this.isCash,
      assignedRiderName: assignedRiderName ?? this.assignedRiderName,
    );
  }
}

/// Plato o producto en la carta del comercio.
@immutable
class MerchantMenuItem {
  const MerchantMenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.priceCents,
    required this.isAvailable,
  });

  final String id;
  final String name;
  final String description;
  final int priceCents;
  final bool isAvailable;

  MerchantMenuItem copyWith({
    String? id,
    String? name,
    String? description,
    int? priceCents,
    bool? isAvailable,
  }) {
    return MerchantMenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      priceCents: priceCents ?? this.priceCents,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

/// Estado global del panel del comercio.
@immutable
class MerchantDashboardState {
  const MerchantDashboardState({
    required this.isOpen,
    required this.orders,
    required this.menuItems,
    required this.todayRevenueCents,
    required this.todayCompletedOrders,
  });

  final bool isOpen;
  final List<MerchantOrderItem> orders;
  final List<MerchantMenuItem> menuItems;
  final int todayRevenueCents;
  final int todayCompletedOrders;

  MerchantDashboardState copyWith({
    bool? isOpen,
    List<MerchantOrderItem>? orders,
    List<MerchantMenuItem>? menuItems,
    int? todayRevenueCents,
    int? todayCompletedOrders,
  }) {
    return MerchantDashboardState(
      isOpen: isOpen ?? this.isOpen,
      orders: orders ?? this.orders,
      menuItems: menuItems ?? this.menuItems,
      todayRevenueCents: todayRevenueCents ?? this.todayRevenueCents,
      todayCompletedOrders: todayCompletedOrders ?? this.todayCompletedOrders,
    );
  }
}

/// Resumen de un comercio para el panel de administración.
@immutable
class AdminMerchantSummary {
  const AdminMerchantSummary({
    required this.id,
    required this.name,
    required this.address,
    required this.activeOrdersCount,
    required this.isOpen,
    required this.commissionPercent,
  });

  final String id;
  final String name;
  final String address;
  final int activeOrdersCount;
  final bool isOpen;
  final double commissionPercent;

  AdminMerchantSummary copyWith({
    String? id,
    String? name,
    String? address,
    int? activeOrdersCount,
    bool? isOpen,
    double? commissionPercent,
  }) {
    return AdminMerchantSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      activeOrdersCount: activeOrdersCount ?? this.activeOrdersCount,
      isOpen: isOpen ?? this.isOpen,
      commissionPercent: commissionPercent ?? this.commissionPercent,
    );
  }
}

/// Resumen de un repartidor para el panel de administración.
@immutable
class AdminCourierSummary {
  const AdminCourierSummary({
    required this.id,
    required this.name,
    required this.phone,
    required this.isOnline,
    required this.todayDeliveries,
    required this.cashCollectedCents,
  });

  final String id;
  final String name;
  final String phone;
  final bool isOnline;
  final int todayDeliveries;
  final int cashCollectedCents;

  AdminCourierSummary copyWith({
    String? id,
    String? name,
    String? phone,
    bool? isOnline,
    int? todayDeliveries,
    int? cashCollectedCents,
  }) {
    return AdminCourierSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      isOnline: isOnline ?? this.isOnline,
      todayDeliveries: todayDeliveries ?? this.todayDeliveries,
      cashCollectedCents: cashCollectedCents ?? this.cashCollectedCents,
    );
  }
}

/// Estado global del panel de administración.
@immutable
class AdminDashboardState {
  const AdminDashboardState({
    required this.activeOrders,
    required this.activeCouriers,
    required this.openMerchants,
    required this.avgDeliveryMinutes,
    required this.todayGmvCents,
    required this.todayCommissionsCents,
    required this.baseDeliveryFeeCents,
    required this.merchants,
    required this.couriers,
  });

  final int activeOrders;
  final int activeCouriers;
  final int openMerchants;
  final int avgDeliveryMinutes;
  final int todayGmvCents;
  final int todayCommissionsCents;
  final int baseDeliveryFeeCents;
  final List<AdminMerchantSummary> merchants;
  final List<AdminCourierSummary> couriers;

  AdminDashboardState copyWith({
    int? activeOrders,
    int? activeCouriers,
    int? openMerchants,
    int? avgDeliveryMinutes,
    int? todayGmvCents,
    int? todayCommissionsCents,
    int? baseDeliveryFeeCents,
    List<AdminMerchantSummary>? merchants,
    List<AdminCourierSummary>? couriers,
  }) {
    return AdminDashboardState(
      activeOrders: activeOrders ?? this.activeOrders,
      activeCouriers: activeCouriers ?? this.activeCouriers,
      openMerchants: openMerchants ?? this.openMerchants,
      avgDeliveryMinutes: avgDeliveryMinutes ?? this.avgDeliveryMinutes,
      todayGmvCents: todayGmvCents ?? this.todayGmvCents,
      todayCommissionsCents:
          todayCommissionsCents ?? this.todayCommissionsCents,
      baseDeliveryFeeCents: baseDeliveryFeeCents ?? this.baseDeliveryFeeCents,
      merchants: merchants ?? this.merchants,
      couriers: couriers ?? this.couriers,
    );
  }
}
