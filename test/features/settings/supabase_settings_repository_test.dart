import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clinapp/core/config/supabase_provider.dart';
import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/features/home/domain/home_models.dart';
import 'package:clinapp/features/settings/data/seed_settings_repository.dart';
import 'package:clinapp/features/settings/data/supabase_settings_repository.dart';
import 'package:clinapp/features/settings/domain/settings_models.dart';
import 'package:clinapp/features/settings/domain/settings_repository.dart';

class _FakeSettingsRepository implements SettingsRepository {
  int loadDashboardCount = 0;
  bool shouldThrow = false;

  @override
  Future<ProfileDashboardData> loadDashboardData(String userId) async {
    loadDashboardCount++;
    if (shouldThrow) {
      throw Exception('Fake DB error');
    }
    return const ProfileDashboardData(
      metrics: UserProfileMetrics.initial,
      addresses: <SavedAddressItem>[],
      favorites: <MerchantSummary>[],
    );
  }

  @override
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {}

  @override
  Future<String?> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    return 'https://example.com/avatar.jpg';
  }

  @override
  Future<List<SavedAddressItem>> getAddresses(String userId) async {
    return const <SavedAddressItem>[];
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
    return SavedAddressItem(
      id: 'addr-fake',
      title: title,
      addressLine: addressLine,
      city: city,
      isDefault: isDefault,
    );
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
  }) async {}

  @override
  Future<void> deleteAddress({
    required String addressId,
    required String userId,
  }) async {}

  @override
  Future<void> setDefaultAddress({
    required String addressId,
    required String userId,
  }) async {}

  @override
  Future<List<MerchantSummary>> getFavoriteMerchants(String userId) async {
    return const <MerchantSummary>[];
  }

  @override
  Future<bool> toggleFavorite({
    required String userId,
    required String merchantId,
    required bool currentValue,
  }) async {
    return !currentValue;
  }

  @override
  Future<void> clearNotifications(String userId) async {}
}

void main() {
  group('Settings & Profile Authenticated Data Tests', () {
    test(
      'SeedSettingsRepository carga métricas con saldo ClinPay y puntos',
      () async {
        final SeedSettingsRepository repo = SeedSettingsRepository();
        final ProfileDashboardData data = await repo.loadDashboardData(
          'test-user',
        );

        expect(data.metrics.ordersCount, 6);
        expect(data.metrics.totalSpentCents, 1200000);
        expect(data.metrics.clinpayBalanceCents, 450000);
        expect(data.metrics.points, 120);
        expect(data.addresses.length, 2);
        expect(data.favorites.length, 1);
        expect(data.favorites.first.name, 'Pizzería La Alvearense');
      },
    );

    test(
      'SeedSettingsRepository CRUD de direcciones con validación de zona',
      () async {
        final SeedSettingsRepository repo = SeedSettingsRepository();

        // Agregar dirección válida en Alvear
        final SavedAddressItem added = await repo.addAddress(
          userId: 'u1',
          addressLine: 'Av. Alvear Oeste 100',
          city: 'General Alvear',
          title: 'Depósito',
          lat: -34.9740,
          lng: -67.6960,
          isDefault: true,
        );
        expect(added.title, 'Depósito');
        expect(added.isDefault, isTrue);

        final List<SavedAddressItem> addresses = await repo.getAddresses('u1');
        expect(addresses.length, 3);
        expect(addresses.last.isDefault, isTrue);

        // Intentar agregar dirección fuera de la zona (ej. Buenos Aires)
        expect(
          () => repo.addAddress(
            userId: 'u1',
            addressLine: 'Av. Corrientes 1234',
            city: 'Buenos Aires',
            lat: -34.6037,
            lng: -58.3816,
          ),
          throwsA(isA<ValidationFailure>()),
        );

        // Cambiar dirección predeterminada
        await repo.setDefaultAddress(addressId: 'addr-01', userId: 'u1');
        final List<SavedAddressItem> updatedAddrs = await repo.getAddresses(
          'u1',
        );
        final SavedAddressItem defaultAddr = updatedAddrs.firstWhere(
          (SavedAddressItem a) => a.id == 'addr-01',
        );
        expect(defaultAddr.isDefault, isTrue);

        // Eliminar dirección
        await repo.deleteAddress(addressId: added.id, userId: 'u1');
        final List<SavedAddressItem> remaining = await repo.getAddresses('u1');
        expect(remaining.length, 2);
      },
    );

    test(
      'SeedSettingsRepository sube avatar y retorna URL pública de Storage',
      () async {
        final SeedSettingsRepository repo = SeedSettingsRepository();
        final Uint8List fakeBytes = Uint8List.fromList(<int>[1, 2, 3]);

        final String? url = await repo.uploadAvatar(
          userId: 'u-123',
          bytes: fakeBytes,
          fileName: 'avatar.jpg',
          mimeType: 'image/jpeg',
        );

        expect(url, contains('avatars/u-123/avatar.jpg'));
      },
    );

    test('SeedSettingsRepository alterna favoritos', () async {
      final SeedSettingsRepository repo = SeedSettingsRepository();
      const String merchantId = 'm1111111-1111-4111-8111-111111111111';

      // Quitar de favoritos
      final bool nextVal = await repo.toggleFavorite(
        userId: 'u-1',
        merchantId: merchantId,
        currentValue: true,
      );
      expect(nextVal, isFalse);

      final List<MerchantSummary> favs = await repo.getFavoriteMerchants('u-1');
      expect(favs, isEmpty);
    });

    test('SupabaseSettingsRepository con cliente null delega en fallbackRepository', () async {
      final _FakeSettingsRepository fakeFallback = _FakeSettingsRepository();
      final SupabaseSettingsRepository repo = SupabaseSettingsRepository(
        client: null,
        fallbackRepository: fakeFallback,
      );

      final ProfileDashboardData data = await repo.loadDashboardData(
        'test-user',
      );
      expect(fakeFallback.loadDashboardCount, 1);
      expect(data.metrics.ordersCount, 6);
    });

    test('settingsRepositoryProvider selecciona SeedSettingsRepository cuando no está configurado', () {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          isBackendConfiguredProvider.overrideWithValue(false),
          supabaseClientProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final SettingsRepository repo = container.read(
        settingsRepositoryProvider,
      );
      expect(repo, isA<SeedSettingsRepository>());
    });
  });
}
