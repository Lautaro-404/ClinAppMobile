import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinapp/core/config/env.dart';
import 'package:clinapp/core/config/supabase_provider.dart';
import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/core/network/retry_policy.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/utils/delivery_zone_validator.dart';
import 'package:clinapp/core/utils/storage_image_resolver.dart';
import 'package:clinapp/features/home/domain/home_models.dart';
import 'package:clinapp/features/settings/data/seed_settings_repository.dart';
import 'package:clinapp/features/settings/domain/settings_models.dart';
import 'package:clinapp/features/settings/domain/settings_repository.dart';

/// Implementación del repositorio de perfil y ajustes con Supabase,
/// validación de zonas de entrega, RLS y fallback controlado a [SeedSettingsRepository].
class SupabaseSettingsRepository implements SettingsRepository {
  SupabaseSettingsRepository({
    required this.client,
    SettingsRepository? fallbackRepository,
  }) : _fallback = fallbackRepository ?? SeedSettingsRepository();

  final SupabaseClient? client;
  final SettingsRepository _fallback;

  @override
  Future<ProfileDashboardData> loadDashboardData(String userId) async {
    final SupabaseClient? activeClient = client;
    if (activeClient == null) {
      return _fallback.loadDashboardData(userId);
    }

    try {
      // Ejecutar las 4 consultas del panel de perfil en paralelo (1 RTT en vez de 4 secuenciales)
      final Future<UserProfileMetrics> metricsFuture = _fetchMetrics(
        activeClient,
        userId,
      );
      final Future<List<SavedAddressItem>> addressesFuture = getAddresses(
        userId,
      );
      final Future<List<MerchantSummary>> favoritesFuture =
          getFavoriteMerchants(userId);
      final Future<List<UserNotificationItem>> notificationsFuture =
          _fetchNotifications(activeClient, userId);

      final List<Object?> results = await Future.wait<Object?>(
        <Future<Object?>>[
          metricsFuture,
          addressesFuture,
          favoritesFuture,
          notificationsFuture,
        ],
      );

      final UserProfileMetrics metrics = results[0]! as UserProfileMetrics;
      final List<SavedAddressItem> addresses =
          results[1]! as List<SavedAddressItem>;
      final List<MerchantSummary> favorites =
          results[2]! as List<MerchantSummary>;
      final List<UserNotificationItem> notifications =
          results[3]! as List<UserNotificationItem>;

      final ProfileDashboardData fallbackData = await _fallback
          .loadDashboardData(userId);

      return ProfileDashboardData(
        metrics: metrics,
        addresses: addresses.isNotEmpty
            ? addresses
            : (Env.isDev ? fallbackData.addresses : const <SavedAddressItem>[]),
        favorites: favorites.isNotEmpty
            ? favorites
            : (Env.isDev ? fallbackData.favorites : const <MerchantSummary>[]),
        notifications: notifications.isNotEmpty
            ? notifications
            : (Env.isDev
                  ? fallbackData.notifications
                  : const <UserNotificationItem>[]),
        coupons: fallbackData.coupons,
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
      return _fallback.loadDashboardData(userId);
    }
  }

  Future<UserProfileMetrics> _fetchMetrics(
    SupabaseClient activeClient,
    String userId,
  ) async {
    try {
      final List<Map<String, Object?>> rpcRows =
          await RetryPolicy.execute<List<Map<String, Object?>>>(
            () => activeClient
                .rpc<PostgrestList>('get_user_profile_metrics')
                .select(
                  'orders_count, total_spent_cents, clinpay_balance_cents, points, rating_text',
                ),
          );

      if (rpcRows.isNotEmpty) {
        final Map<String, Object?> row = rpcRows.first;
        return UserProfileMetrics(
          ordersCount: _readInt(row['orders_count'], fallback: 0),
          totalSpentCents: _readInt(row['total_spent_cents'], fallback: 0),
          ratingText: _readString(row['rating_text'], fallback: '5,0'),
          clinpayBalanceCents: _readInt(
            row['clinpay_balance_cents'],
            fallback: 0,
          ),
          points: _readInt(row['points'], fallback: 0),
        );
      }
    } on PermissionDeniedFailure {
      rethrow;
    } on Object {
      // Fallback relacional si la RPC aún no fue migrada
      try {
        final Future<List<Map<String, Object?>>> ordersFuture =
            RetryPolicy.execute<List<Map<String, Object?>>>(
              () => activeClient
                  .from('orders')
                  .select('id, total')
                  .eq('user_id', userId),
            );
        final Future<Map<String, Object?>?> profileFuture =
            RetryPolicy.execute<Map<String, Object?>?>(
              () => activeClient
                  .from('profiles')
                  .select('wallet_balance, puntos')
                  .eq('id', userId)
                  .maybeSingle(),
            );

        final List<Object?> relResults = await Future.wait<Object?>(
          <Future<Object?>>[ordersFuture, profileFuture],
        );
        final List<Map<String, Object?>> orders =
            relResults[0]! as List<Map<String, Object?>>;
        final Map<String, Object?>? profile =
            relResults[1] as Map<String, Object?>?;

        int totalSpent = 0;
        for (final Map<String, Object?> o in orders) {
          totalSpent += _readInt(o['total']);
        }

        return UserProfileMetrics(
          ordersCount: orders.length,
          totalSpentCents: totalSpent,
          ratingText: '5,0',
          clinpayBalanceCents: _readInt(profile?['wallet_balance']),
          points: _readInt(profile?['puntos']),
        );
      } on PermissionDeniedFailure {
        rethrow;
      } on Object {
        return UserProfileMetrics.initial;
      }
    }
    return UserProfileMetrics.initial;
  }

  Future<List<UserNotificationItem>> _fetchNotifications(
    SupabaseClient activeClient,
    String userId,
  ) async {
    try {
      final List<Map<String, Object?>> notifRows =
          await RetryPolicy.execute<List<Map<String, Object?>>>(
            () => activeClient
                .from('notifications')
                .select('id, title, message, is_read, created_at')
                .eq('user_id', userId)
                .order('created_at', ascending: false)
                .limit(10),
          );

      return notifRows.map((Map<String, Object?> row) {
        return UserNotificationItem(
          id: _readString(row['id']),
          title: _readString(row['title'], fallback: 'Aviso'),
          message: _readString(row['message']),
          timeAgo: 'Reciente',
          isRead: row['is_read'] == true,
        );
      }).toList();
    } on PermissionDeniedFailure {
      rethrow;
    } on Object {
      return const <UserNotificationItem>[];
    }
  }

  @override
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final SupabaseClient? activeClient = client;
    if (activeClient == null) {
      return _fallback.updateProfile(
        userId: userId,
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
      );
    }

    try {
      final Map<String, Object?> updates = <String, Object?>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (fullName != null) updates['nombre'] = fullName.trim();
      if (phone != null) updates['telefono'] = phone.trim();
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl.trim();

      await RetryPolicy.execute<void>(
        () => activeClient.from('profiles').update(updates).eq('id', userId),
        maxAttempts: 2,
        timeout: RetryPolicy.defaultMutationTimeout,
      );
    } on Object catch (error) {
      throw AppException.fromError(error);
    }
  }

  @override
  Future<String?> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    StorageImageResolver.validateAvatarUpload(bytes: bytes, mimeType: mimeType);

    final SupabaseClient? activeClient = client;
    if (activeClient == null) {
      return _fallback.uploadAvatar(
        userId: userId,
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );
    }

    try {
      final String extension = fileName.contains('.')
          ? fileName.split('.').last
          : 'jpg';
      final String storagePath =
          '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';

      await RetryPolicy.execute<void>(
        () => activeClient.storage
            .from(StorageImageResolver.avatarsBucket)
            .uploadBinary(
              storagePath,
              bytes,
              fileOptions: FileOptions(contentType: mimeType, upsert: true),
            ),
        maxAttempts: 2,
        timeout: RetryPolicy.defaultMutationTimeout,
      );

      final String publicUrl = activeClient.storage
          .from(StorageImageResolver.avatarsBucket)
          .getPublicUrl(storagePath);

      await RetryPolicy.execute<void>(
        () => activeClient
            .from('profiles')
            .update(<String, Object?>{'avatar_url': publicUrl})
            .eq('id', userId),
        maxAttempts: 2,
        timeout: RetryPolicy.defaultMutationTimeout,
      );

      return publicUrl;
    } on Object catch (error) {
      throw AppException.fromError(error);
    }
  }

  @override
  Future<List<SavedAddressItem>> getAddresses(String userId) async {
    final SupabaseClient? activeClient = client;
    if (activeClient == null) {
      return _fallback.getAddresses(userId);
    }

    try {
      final List<Map<String, Object?>> rows =
          await RetryPolicy.execute<List<Map<String, Object?>>>(
            () => activeClient
                .from('addresses')
                .select('id, address_line, city, lat, lng, is_default, title')
                .eq('profile_id', userId)
                .order('is_default', ascending: false),
          );

      return rows.map((Map<String, Object?> row) {
        return SavedAddressItem(
          id: _readString(row['id']),
          title: _readString(row['title'], fallback: 'Casa'),
          addressLine: _readString(row['address_line']),
          city: _readString(row['city'], fallback: 'General Alvear'),
          lat: _readDouble(
            row['lat'],
            fallback: DeliveryZoneValidator.defaultCenterLat,
          ),
          lng: _readDouble(
            row['lng'],
            fallback: DeliveryZoneValidator.defaultCenterLng,
          ),
          isDefault: row['is_default'] == true,
        );
      }).toList();
    } on PermissionDeniedFailure {
      rethrow;
    } on Object catch (error) {
      if (Env.isProd) {
        throw AppException.fromError(error);
      }
      return _fallback.getAddresses(userId);
    }
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

    final SupabaseClient? activeClient = client;
    if (activeClient == null) {
      return _fallback.addAddress(
        userId: userId,
        addressLine: addressLine,
        city: city,
        title: title,
        lat: targetLat,
        lng: targetLng,
        isDefault: isDefault,
      );
    }

    try {
      if (isDefault) {
        try {
          await RetryPolicy.execute<void>(
            () => activeClient
                .from('addresses')
                .update(<String, Object?>{'is_default': false})
                .eq('profile_id', userId),
            maxAttempts: 2,
            timeout: RetryPolicy.defaultMutationTimeout,
          );
        } on Object {
          // Si la columna aún no está migrada, continuar
        }
      }

      final Map<String, Object?> insertData = <String, Object?>{
        'profile_id': userId,
        'address_line': addressLine.trim(),
        'city': city.trim(),
        'lat': targetLat,
        'lng': targetLng,
        'title': title.trim(),
        'is_default': isDefault,
      };

      final Map<String, Object?> row =
          await RetryPolicy.execute<Map<String, Object?>>(
            () => activeClient
                .from('addresses')
                .insert(insertData)
                .select('id, title, address_line, city, lat, lng, is_default')
                .single(),
            maxAttempts: 2,
            timeout: RetryPolicy.defaultMutationTimeout,
          );

      return SavedAddressItem(
        id: _readString(row['id']),
        title: _readString(row['title'], fallback: title),
        addressLine: _readString(row['address_line'], fallback: addressLine),
        city: _readString(row['city'], fallback: city),
        lat: targetLat,
        lng: targetLng,
        isDefault: row['is_default'] == true || isDefault,
      );
    } on Object catch (error) {
      throw AppException.fromError(error);
    }
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
    if (lat != null && lng != null) {
      if (!DeliveryZoneValidator.isInsideZone(lat: lat, lng: lng)) {
        throw const ValidationFailure(
          'La dirección se encuentra fuera de la zona de entrega de General Alvear.',
        );
      }
    }

    final SupabaseClient? activeClient = client;
    if (activeClient == null) {
      return _fallback.updateAddress(
        addressId: addressId,
        userId: userId,
        addressLine: addressLine,
        city: city,
        title: title,
        lat: lat,
        lng: lng,
        isDefault: isDefault,
      );
    }

    try {
      if (isDefault == true) {
        await RetryPolicy.execute<void>(
          () => activeClient
              .from('addresses')
              .update(<String, Object?>{'is_default': false})
              .eq('profile_id', userId),
          maxAttempts: 2,
          timeout: RetryPolicy.defaultMutationTimeout,
        );
      }

      final Map<String, Object?> updates = <String, Object?>{};
      if (addressLine != null) updates['address_line'] = addressLine.trim();
      if (city != null) updates['city'] = city.trim();
      if (title != null) updates['title'] = title.trim();
      if (lat != null) updates['lat'] = lat;
      if (lng != null) updates['lng'] = lng;
      if (isDefault != null) updates['is_default'] = isDefault;

      if (updates.isNotEmpty) {
        await RetryPolicy.execute<void>(
          () => activeClient
              .from('addresses')
              .update(updates)
              .eq('id', addressId)
              .eq('profile_id', userId),
          maxAttempts: 2,
          timeout: RetryPolicy.defaultMutationTimeout,
        );
      }
    } on Object catch (error) {
      throw AppException.fromError(error);
    }
  }

  @override
  Future<void> deleteAddress({
    required String addressId,
    required String userId,
  }) async {
    final SupabaseClient? activeClient = client;
    if (activeClient == null) {
      return _fallback.deleteAddress(addressId: addressId, userId: userId);
    }

    try {
      await RetryPolicy.execute<void>(
        () => activeClient
            .from('addresses')
            .delete()
            .eq('id', addressId)
            .eq('profile_id', userId),
        maxAttempts: 2,
        timeout: RetryPolicy.defaultMutationTimeout,
      );
    } on Object catch (error) {
      throw AppException.fromError(error);
    }
  }

  @override
  Future<void> setDefaultAddress({
    required String addressId,
    required String userId,
  }) async {
    final SupabaseClient? activeClient = client;
    if (activeClient == null) {
      return _fallback.setDefaultAddress(addressId: addressId, userId: userId);
    }

    try {
      await RetryPolicy.execute<void>(
        () async {
          await activeClient
              .from('addresses')
              .update(<String, Object?>{'is_default': false})
              .eq('profile_id', userId);

          await activeClient
              .from('addresses')
              .update(<String, Object?>{'is_default': true})
              .eq('id', addressId)
              .eq('profile_id', userId);
        },
        maxAttempts: 2,
        timeout: RetryPolicy.defaultMutationTimeout,
      );
    } on Object catch (error) {
      throw AppException.fromError(error);
    }
  }

  @override
  Future<List<MerchantSummary>> getFavoriteMerchants(String userId) async {
    final SupabaseClient? activeClient = client;
    if (activeClient == null) {
      return _fallback.getFavoriteMerchants(userId);
    }

    try {
      try {
        final List<Map<String, Object?>> rows =
            await RetryPolicy.execute<List<Map<String, Object?>>>(
              () => activeClient
                  .rpc<PostgrestList>('get_user_favorites')
                  .select(
                    'merchant_id, name, description, banner_url, tiempo_estimado_min, costo_envio_base, rating, review_count',
                  ),
            );

        if (rows.isNotEmpty) {
          return rows.map((Map<String, Object?> row) {
            final String id = _readString(row['merchant_id']);
            final int baseEta = _readInt(
              row['tiempo_estimado_min'],
              fallback: 25,
            );
            final String? banner = StorageImageResolver.resolveMerchantImage(
              _readNullableString(row['banner_url']),
              client: activeClient,
              width: 780,
            );

            return MerchantSummary(
              id: id,
              name: _readString(row['name']),
              tagLabel: _readString(row['description'], fallback: 'Favorito'),
              rating: _readDouble(row['rating'], fallback: 4.9),
              reviewCount: _readInt(row['review_count'], fallback: 10),
              minMinutes: (baseEta - 5).clamp(10, 90),
              maxMinutes: (baseEta + 5).clamp(15, 120),
              deliveryFeeCents: _readInt(row['costo_envio_base']),
              categoryIds: const <String>[],
              accentColor: AppColors.accent,
              bannerUrl: banner,
              isFavorite: true,
            );
          }).toList();
        }
      } on PermissionDeniedFailure {
        rethrow;
      } on Object {
        // Fallback a consulta relacional directa si la RPC no está disponible
      }

      final List<Map<String, Object?>> favRows =
          await RetryPolicy.execute<List<Map<String, Object?>>>(
            () => activeClient
                .from('favorites')
                .select(
                  'merchant_id, merchants(id, name, description, banner_url, tiempo_estimado_min, costo_envio_base)',
                )
                .eq('user_id', userId),
          );

      return favRows.map((Map<String, Object?> f) {
        final Map<String, Object?>? m = f['merchants'] as Map<String, Object?>?;
        final String id = _readString(f['merchant_id']);
        final int baseEta = _readInt(m?['tiempo_estimado_min'], fallback: 25);
        final String? banner = StorageImageResolver.resolveMerchantImage(
          _readNullableString(m?['banner_url']),
          client: activeClient,
          width: 780,
        );

        return MerchantSummary(
          id: id,
          name: _readString(m?['name'], fallback: 'Comercio favorito'),
          tagLabel: _readString(m?['description'], fallback: 'Favorito'),
          rating: 4.9,
          reviewCount: 20,
          minMinutes: (baseEta - 5).clamp(10, 90),
          maxMinutes: (baseEta + 5).clamp(15, 120),
          deliveryFeeCents: _readInt(m?['costo_envio_base']),
          categoryIds: const <String>[],
          accentColor: AppColors.accent,
          bannerUrl: banner,
          isFavorite: true,
        );
      }).toList();
    } on PermissionDeniedFailure {
      rethrow;
    } on Object catch (error) {
      if (Env.isProd) {
        throw AppException.fromError(error);
      }
      return _fallback.getFavoriteMerchants(userId);
    }
  }

  @override
  Future<bool> toggleFavorite({
    required String userId,
    required String merchantId,
    required bool currentValue,
  }) async {
    final bool nextValue = !currentValue;
    final SupabaseClient? activeClient = client;

    if (activeClient == null) {
      return _fallback.toggleFavorite(
        userId: userId,
        merchantId: merchantId,
        currentValue: currentValue,
      );
    }

    try {
      await RetryPolicy.execute<void>(
        () async {
          if (nextValue) {
            await activeClient.from('favorites').upsert(<String, Object>{
              'user_id': userId,
              'merchant_id': merchantId,
            }, onConflict: 'user_id, merchant_id');
          } else {
            await activeClient
                .from('favorites')
                .delete()
                .eq('user_id', userId)
                .eq('merchant_id', merchantId);
          }
        },
        maxAttempts: 2,
        timeout: RetryPolicy.defaultMutationTimeout,
      );
      return nextValue;
    } on Object catch (error) {
      throw AppException.fromError(error);
    }
  }

  @override
  Future<void> clearNotifications(String userId) async {
    final SupabaseClient? activeClient = client;
    if (activeClient == null) {
      return _fallback.clearNotifications(userId);
    }

    try {
      await RetryPolicy.execute<void>(
        () => activeClient
            .from('notifications')
            .update(<String, Object?>{'is_read': true})
            .eq('user_id', userId),
        maxAttempts: 2,
        timeout: RetryPolicy.defaultMutationTimeout,
      );
    } on Object catch (error) {
      throw AppException.fromError(error);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Utilidades seguras de casteo
// ─────────────────────────────────────────────────────────────────────────────

String _readString(Object? value, {String fallback = ''}) {
  if (value is String && value.isNotEmpty) return value;
  return fallback;
}

String? _readNullableString(Object? value) {
  if (value is String && value.isNotEmpty) return value;
  return null;
}

int _readInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double _readDouble(Object? value, {double fallback = 0.0}) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.')) ?? fallback;
  }
  return fallback;
}

/// Provider del repositorio de perfil y ajustes.
final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>((Ref ref) {
      final bool isConfigured = ref.watch(isBackendConfiguredProvider);
      final SupabaseClient? client = ref.watch(supabaseClientProvider);
      final SeedSettingsRepository seedRepo = SeedSettingsRepository();

      if (!isConfigured || client == null) {
        return seedRepo;
      }

      return SupabaseSettingsRepository(
        client: client,
        fallbackRepository: seedRepo,
      );
    });
