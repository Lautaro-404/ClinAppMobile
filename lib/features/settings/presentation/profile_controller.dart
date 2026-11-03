import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/features/auth/domain/auth_models.dart';
import 'package:clinapp/features/auth/presentation/auth_controller.dart';
import 'package:clinapp/features/home/domain/home_models.dart';
import 'package:clinapp/features/settings/data/supabase_settings_repository.dart';
import 'package:clinapp/features/settings/domain/settings_models.dart';
import 'package:clinapp/features/settings/domain/settings_repository.dart';

/// Estado consolidado para la pantalla de Perfil y Configuración.
@immutable
class ProfileViewState {
  const ProfileViewState({required this.session, required this.dashboard});

  final AuthUserSession? session;
  final ProfileDashboardData dashboard;

  ProfileViewState copyWith({
    AuthUserSession? session,
    ProfileDashboardData? dashboard,
  }) {
    return ProfileViewState(
      session: session ?? this.session,
      dashboard: dashboard ?? this.dashboard,
    );
  }
}

/// Controlador de datos y acciones de la pantalla de Perfil.
class ProfileController extends AsyncNotifier<ProfileViewState> {
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  @override
  Future<ProfileViewState> build() async {
    final AuthUserSession? session = await ref.watch(
      authControllerProvider.future,
    );

    final ProfileDashboardData dashboard = await _repository.loadDashboardData(
      session?.userId ?? 'alvear-dev-user-001',
    );

    return ProfileViewState(session: session, dashboard: dashboard);
  }

  /// Actualiza los datos del perfil (nombre y teléfono).
  Future<void> updateProfile({String? fullName, String? phone}) async {
    final ProfileViewState? current = state.value;
    if (current == null || current.session == null) return;

    await _repository.updateProfile(
      userId: current.session!.userId,
      fullName: fullName,
      phone: phone,
    );

    final AuthUserSession updatedSession = current.session!.copyWith(
      fullName: fullName,
      phone: phone,
    );

    state = AsyncData<ProfileViewState>(
      current.copyWith(session: updatedSession),
    );
  }

  /// Sube un avatar y actualiza la sesión y la base de datos.
  Future<String?> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final ProfileViewState? current = state.value;
    if (current == null || current.session == null) return null;

    final String? publicUrl = await _repository.uploadAvatar(
      userId: current.session!.userId,
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );

    if (publicUrl != null) {
      final AuthUserSession updatedSession = current.session!.copyWith(
        avatarUrl: publicUrl,
      );
      state = AsyncData<ProfileViewState>(
        current.copyWith(session: updatedSession),
      );
    }

    return publicUrl;
  }

  /// Agrega una dirección de entrega y valida la zona de Alvear.
  Future<SavedAddressItem?> addAddress({
    required String addressLine,
    String title = 'Casa',
    bool isDefault = false,
    double? lat,
    double? lng,
  }) async {
    final ProfileViewState? current = state.value;
    if (current == null || current.session == null) return null;

    final SavedAddressItem newAddr = await _repository.addAddress(
      userId: current.session!.userId,
      addressLine: addressLine,
      city: 'General Alvear',
      title: title,
      isDefault: isDefault,
      lat: lat,
      lng: lng,
    );

    final List<SavedAddressItem> updated = <SavedAddressItem>[
      ...current.dashboard.addresses,
      newAddr,
    ];

    state = AsyncData<ProfileViewState>(
      current.copyWith(
        dashboard: current.dashboard.copyWith(addresses: updated),
      ),
    );

    return newAddr;
  }

  /// Actualiza una dirección existente.
  Future<void> updateAddress({
    required String addressId,
    String? addressLine,
    String? title,
    bool? isDefault,
    double? lat,
    double? lng,
  }) async {
    final ProfileViewState? current = state.value;
    if (current == null || current.session == null) return;

    await _repository.updateAddress(
      addressId: addressId,
      userId: current.session!.userId,
      addressLine: addressLine,
      title: title,
      isDefault: isDefault,
      lat: lat,
      lng: lng,
    );

    final List<SavedAddressItem> updated = current.dashboard.addresses.map((
      SavedAddressItem a,
    ) {
      if (a.id == addressId) {
        return a.copyWith(
          addressLine: addressLine,
          title: title,
          isDefault: isDefault,
          lat: lat,
          lng: lng,
        );
      }
      if (isDefault == true) {
        return a.copyWith(isDefault: false);
      }
      return a;
    }).toList();

    state = AsyncData<ProfileViewState>(
      current.copyWith(
        dashboard: current.dashboard.copyWith(addresses: updated),
      ),
    );
  }

  /// Elimina una dirección de entrega.
  Future<void> deleteAddress(String addressId) async {
    final ProfileViewState? current = state.value;
    if (current == null || current.session == null) return;

    await _repository.deleteAddress(
      addressId: addressId,
      userId: current.session!.userId,
    );

    final List<SavedAddressItem> updated = current.dashboard.addresses
        .where((SavedAddressItem a) => a.id != addressId)
        .toList();

    state = AsyncData<ProfileViewState>(
      current.copyWith(
        dashboard: current.dashboard.copyWith(addresses: updated),
      ),
    );
  }

  /// Establece una dirección como predeterminada.
  Future<void> setDefaultAddress(String addressId) async {
    final ProfileViewState? current = state.value;
    if (current == null || current.session == null) return;

    await _repository.setDefaultAddress(
      addressId: addressId,
      userId: current.session!.userId,
    );

    final List<SavedAddressItem> updated = current.dashboard.addresses.map((
      SavedAddressItem a,
    ) {
      return a.copyWith(isDefault: a.id == addressId);
    }).toList();

    state = AsyncData<ProfileViewState>(
      current.copyWith(
        dashboard: current.dashboard.copyWith(addresses: updated),
      ),
    );
  }

  /// Alterna un comercio en favoritos con actualización optimista inmediata y rollback ante error.
  Future<void> toggleFavorite(String merchantId) async {
    final ProfileViewState? current = state.value;
    if (current == null || current.session == null) return;

    final List<MerchantSummary> originalFavorites = current.dashboard.favorites;
    final int index = originalFavorites.indexWhere(
      (MerchantSummary m) => m.id == merchantId,
    );
    final bool isFav = index >= 0;

    // 1. Actualización optimista inmediata en memoria
    List<MerchantSummary> optimisticFavorites;
    if (isFav) {
      optimisticFavorites = originalFavorites
          .where((MerchantSummary m) => m.id != merchantId)
          .toList();
    } else {
      optimisticFavorites = <MerchantSummary>[
        ...originalFavorites,
        MerchantSummary(
          id: merchantId,
          name: 'Comercio favorito',
          tagLabel: 'Favorito',
          rating: 4.9,
          reviewCount: 1,
          minMinutes: 20,
          maxMinutes: 30,
          deliveryFeeCents: 0,
          categoryIds: const <String>[],
          accentColor: AppColors.accent,
          isFavorite: true,
        ),
      ];
    }

    state = AsyncData<ProfileViewState>(
      current.copyWith(
        dashboard: current.dashboard.copyWith(favorites: optimisticFavorites),
      ),
    );

    // 2. Ejecución asíncrona con rollback ante fallo
    try {
      await _repository.toggleFavorite(
        userId: current.session!.userId,
        merchantId: merchantId,
        currentValue: isFav,
      );
    } catch (e) {
      // Rollback al estado original
      state = AsyncData<ProfileViewState>(
        current.copyWith(
          dashboard: current.dashboard.copyWith(favorites: originalFavorites),
        ),
      );
      rethrow;
    }
  }

  /// Limpia las notificaciones.
  Future<void> clearNotifications() async {
    final ProfileViewState? current = state.value;
    if (current == null || current.session == null) return;

    await _repository.clearNotifications(current.session!.userId);
    ref.invalidateSelf();
  }

  /// Recarga los datos del panel.
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Provider de la pantalla de perfil.
final AsyncNotifierProvider<ProfileController, ProfileViewState>
profileControllerProvider =
    AsyncNotifierProvider<ProfileController, ProfileViewState>(
      ProfileController.new,
    );
