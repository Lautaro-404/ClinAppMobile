import 'package:flutter/foundation.dart';

import 'package:clinapp/features/home/domain/home_models.dart';

/// Métricas clave del usuario en General Alvear.
@immutable
class UserProfileMetrics {
  const UserProfileMetrics({
    required this.ordersCount,
    required this.totalSpentCents,
    required this.ratingText,
    this.clinpayBalanceCents = 0,
    this.points = 0,
  });

  final int ordersCount;
  final int totalSpentCents;
  final String ratingText;
  final int clinpayBalanceCents;
  final int points;

  static const UserProfileMetrics initial = UserProfileMetrics(
    ordersCount: 6,
    totalSpentCents: 1200000, // $12.000 en centavos
    ratingText: '5,0',
    clinpayBalanceCents: 450000, // $4.500 en saldo ClinPay
    points: 120, // 120 puntos Clin
  );

  UserProfileMetrics copyWith({
    int? ordersCount,
    int? totalSpentCents,
    String? ratingText,
    int? clinpayBalanceCents,
    int? points,
  }) {
    return UserProfileMetrics(
      ordersCount: ordersCount ?? this.ordersCount,
      totalSpentCents: totalSpentCents ?? this.totalSpentCents,
      ratingText: ratingText ?? this.ratingText,
      clinpayBalanceCents: clinpayBalanceCents ?? this.clinpayBalanceCents,
      points: points ?? this.points,
    );
  }
}

/// Dirección guardada del usuario.
@immutable
class SavedAddressItem {
  const SavedAddressItem({
    required this.id,
    required this.title,
    required this.addressLine,
    required this.city,
    this.lat = -34.9750,
    this.lng = -67.6950,
    this.isDefault = false,
  });

  final String id;
  final String title;
  final String addressLine;
  final String city;
  final double lat;
  final double lng;
  final bool isDefault;

  SavedAddressItem copyWith({
    String? id,
    String? title,
    String? addressLine,
    String? city,
    double? lat,
    double? lng,
    bool? isDefault,
  }) {
    return SavedAddressItem(
      id: id ?? this.id,
      title: title ?? this.title,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

/// Notificación del historial de usuario.
@immutable
class UserNotificationItem {
  const UserNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final bool isRead;
}

/// Cupón disponible para el usuario.
@immutable
class AvailableCouponItem {
  const AvailableCouponItem({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.discountAmountCents,
  });

  final String id;
  final String code;
  final String title;
  final String description;
  final int discountAmountCents;
}

/// Datos consolidados del panel de Perfil.
@immutable
class ProfileDashboardData {
  const ProfileDashboardData({
    required this.metrics,
    this.addresses = const <SavedAddressItem>[],
    this.favorites = const <MerchantSummary>[],
    this.notifications = const <UserNotificationItem>[],
    this.coupons = const <AvailableCouponItem>[],
  });

  final UserProfileMetrics metrics;
  final List<SavedAddressItem> addresses;
  final List<MerchantSummary> favorites;
  final List<UserNotificationItem> notifications;
  final List<AvailableCouponItem> coupons;

  ProfileDashboardData copyWith({
    UserProfileMetrics? metrics,
    List<SavedAddressItem>? addresses,
    List<MerchantSummary>? favorites,
    List<UserNotificationItem>? notifications,
    List<AvailableCouponItem>? coupons,
  }) {
    return ProfileDashboardData(
      metrics: metrics ?? this.metrics,
      addresses: addresses ?? this.addresses,
      favorites: favorites ?? this.favorites,
      notifications: notifications ?? this.notifications,
      coupons: coupons ?? this.coupons,
    );
  }
}
