import 'dart:typed_data';

import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/utils/delivery_zone_validator.dart';
import 'package:clinapp/features/home/domain/home_models.dart';
import 'package:clinapp/features/settings/domain/settings_models.dart';
import 'package:clinapp/features/settings/domain/settings_repository.dart';

/// Implementación autónoma de [SettingsRepository] con datos semilla
/// del diseño de General Alvear para desarrollo local, pruebas y fallback.
class SeedSettingsRepository implements SettingsRepository {
  SeedSettingsRepository() {
    _addresses.addAll(<SavedAddressItem>[
      const SavedAddressItem(
        id: 'addr-01',
        title: 'Casa',
        addressLine: 'Av. San Martín 450, Dpto 2B',
        city: 'General Alvear',
        lat: -34.9750,
        lng: -67.6950,
        isDefault: true,
      ),
      const SavedAddressItem(
        id: 'addr-02',
        title: 'Trabajo',
        addressLine: 'Alpatacal 230',
        city: 'General Alvear',
        lat: -34.9780,
        lng: -67.6920,
      ),
    ]);

    _favorites.addAll(<MerchantSummary>[
      const MerchantSummary(
        id: 'm1111111-1111-4111-8111-111111111111',
        name: 'Pizzería La Alvearense',
        tagLabel: 'Pizzas a la piedra',
        rating: 4.9,
        reviewCount: 184,
        minMinutes: 20,
        maxMinutes: 30,
        deliveryFeeCents: 85000,
        categoryIds: <String>['c0000001-0000-4000-8000-000000000001'],
        accentColor: AppColors.accent,
        isFavorite: true,
      ),
    ]);
  }

  final List<SavedAddressItem> _addresses = <SavedAddressItem>[];
  final List<MerchantSummary> _favorites = <MerchantSummary>[];
  final UserProfileMetrics _metrics = UserProfileMetrics.initial;

  static const List<UserNotificationItem> _defaultNotifications =
      <UserNotificationItem>[
        UserNotificationItem(
          id: 'notif-01',
          title: '¡Tu pedido está en cocina!',
          message: 'Parrilla Don Manuel está preparando tu orden #4829.',
          timeAgo: 'Hace 15 min',
          isRead: false,
        ),
        UserNotificationItem(
          id: 'notif-02',
          title: 'Cupón de bienvenida activado',
          message: 'Aprovechá \$2.000 de regalo en tu primer pedido.',
          timeAgo: 'Ayer',
          isRead: true,
        ),
      ];

  static const List<AvailableCouponItem> _defaultCoupons =
      <AvailableCouponItem>[
        AvailableCouponItem(
          id: 'cup-01',
          code: 'ALVEARYA',
          title: 'Envío gratis y \$2.800 de descuento',
          description: 'Válido para pedidos superiores a \$10.000 en Alvear.',
          discountAmountCents: 280000,
        ),
      ];

  @override
  Future<ProfileDashboardData> loadDashboardData(String userId) async {
    return ProfileDashboardData(
      metrics: _metrics,
      addresses: List<SavedAddressItem>.unmodifiable(_addresses),
      favorites: List<MerchantSummary>.unmodifiable(_favorites),
      notifications: _defaultNotifications,
      coupons: _defaultCoupons,
    );
  }

  @override
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    // En modo semilla, no requiere mutación de base de datos
  }

  @override
  Future<String?> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    return 'https://supabase.clinapp.com/storage/v1/object/public/avatars/$userId/$fileName';
  }

  @override
  Future<List<SavedAddressItem>> getAddresses(String userId) async {
    return List<SavedAddressItem>.unmodifiable(_addresses);
  }

  @override
  Future<SavedAddressItem> addAddress({
    required String userId,
    required String addressLine,
    required String city,
    String title = 'Casa',
    double? lat,
    double? lng,
    bool isDefault = false,
  }) async {
    final double targetLat = lat ?? DeliveryZoneValidator.defaultCenterLat;
    final double targetLng = lng ?? DeliveryZoneValidator.defaultCenterLng;

    if (!DeliveryZoneValidator.isInsideZone(lat: targetLat, lng: targetLng)) {
      throw const ValidationFailure(
        'La dirección se encuentra fuera de la zona de entrega de General Alvear.',
      );
    }

    if (isDefault) {
      for (int i = 0; i < _addresses.length; i++) {
        _addresses[i] = _addresses[i].copyWith(isDefault: false);
      }
    }

    final SavedAddressItem newAddr = SavedAddressItem(
      id: 'addr-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      addressLine: addressLine,
      city: city,
      lat: targetLat,
      lng: targetLng,
      isDefault: isDefault || _addresses.isEmpty,
    );

    _addresses.add(newAddr);
    return newAddr;
  }

  @override
  Future<void> updateAddress({
    required String addressId,
    required String userId,
    String? addressLine,
    String? city,
    String? title,
    double? lat,
    double? lng,
    bool? isDefault,
  }) async {
    final int index = _addresses.indexWhere(
      (SavedAddressItem a) => a.id == addressId,
    );
    if (index < 0) return;

    if (lat != null && lng != null) {
      if (!DeliveryZoneValidator.isInsideZone(lat: lat, lng: lng)) {
        throw const ValidationFailure(
          'La dirección se encuentra fuera de la zona de entrega de General Alvear.',
        );
      }
    }

    if (isDefault == true) {
      for (int i = 0; i < _addresses.length; i++) {
        _addresses[i] = _addresses[i].copyWith(isDefault: false);
      }
    }

    final SavedAddressItem current = _addresses[index];
    _addresses[index] = current.copyWith(
      addressLine: addressLine,
      city: city,
      title: title,
      lat: lat,
      lng: lng,
      isDefault: isDefault,
    );
  }

  @override
  Future<void> deleteAddress({
    required String addressId,
    required String userId,
  }) async {
    _addresses.removeWhere((SavedAddressItem a) => a.id == addressId);
    if (_addresses.isNotEmpty &&
        !_addresses.any((SavedAddressItem a) => a.isDefault)) {
      _addresses[0] = _addresses[0].copyWith(isDefault: true);
    }
  }

  @override
  Future<void> setDefaultAddress({
    required String addressId,
    required String userId,
  }) async {
    for (int i = 0; i < _addresses.length; i++) {
      final bool matches = _addresses[i].id == addressId;
      _addresses[i] = _addresses[i].copyWith(isDefault: matches);
    }
  }

  @override
  Future<List<MerchantSummary>> getFavoriteMerchants(String userId) async {
    return List<MerchantSummary>.unmodifiable(_favorites);
  }

  @override
  Future<bool> toggleFavorite({
    required String userId,
    required String merchantId,
    required bool currentValue,
  }) async {
    final bool next = !currentValue;
    if (!next) {
      _favorites.removeWhere((MerchantSummary m) => m.id == merchantId);
    }
    return next;
  }

  @override
  Future<void> clearNotifications(String userId) async {
    // Limpia notificaciones en memoria
  }
}
