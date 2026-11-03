import 'dart:typed_data';

import 'package:clinapp/features/home/domain/home_models.dart';
import 'package:clinapp/features/settings/domain/settings_models.dart';

/// Contrato del repositorio de configuraciones y perfil del usuario autenticado.
abstract interface class SettingsRepository {
  /// Carga métricas, direcciones, favoritos, notificaciones y cupones del usuario.
  Future<ProfileDashboardData> loadDashboardData(String userId);

  /// Actualiza los datos personales del usuario (nombre, teléfono, avatar).
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
  });

  /// Sube un avatar de usuario al bucket `avatars` en Supabase Storage y retorna la URL pública.
  Future<String?> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  });

  /// Obtiene la lista de direcciones guardadas del usuario.
  Future<List<SavedAddressItem>> getAddresses(String userId);

  /// Agrega una nueva dirección de entrega validando la zona de General Alvear.
  Future<SavedAddressItem> addAddress({
    required String userId,
    required String addressLine,
    required String city,
    String title = 'Casa',
    double? lat,
    double? lng,
    bool isDefault = false,
  });

  /// Actualiza una dirección existente.
  Future<void> updateAddress({
    required String addressId,
    required String userId,
    String? addressLine,
    String? city,
    String? title,
    double? lat,
    double? lng,
    bool? isDefault,
  });

  /// Elimina una dirección de entrega.
  Future<void> deleteAddress({
    required String addressId,
    required String userId,
  });

  /// Establece una dirección como predeterminada.
  Future<void> setDefaultAddress({
    required String addressId,
    required String userId,
  });

  /// Obtiene los comercios favoritos del usuario.
  Future<List<MerchantSummary>> getFavoriteMerchants(String userId);

  /// Alterna el estado de favorito de un comercio.
  Future<bool> toggleFavorite({
    required String userId,
    required String merchantId,
    required bool currentValue,
  });

  /// Marca o limpia las notificaciones del usuario.
  Future<void> clearNotifications(String userId);
}
