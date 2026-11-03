import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clinapp/core/config/supabase_provider.dart';
import 'package:clinapp/features/home/data/dtos/home_dtos.dart';
import 'package:clinapp/features/home/data/seed_home_repository.dart';
import 'package:clinapp/features/home/data/supabase_home_repository.dart';
import 'package:clinapp/features/home/domain/home_models.dart';
import 'package:clinapp/features/home/domain/home_repository.dart';

class _FakeHomeRepository implements HomeRepository {
  _FakeHomeRepository({this.shouldThrow = false});

  final bool shouldThrow;
  int fetchCallCount = 0;

  @override
  Future<HomeFeedData> fetchHomeFeed() async {
    fetchCallCount++;
    if (shouldThrow) {
      throw Exception('Fake DB error');
    }
    return const HomeFeedData(
      userName: 'Test User',
      deliveryAddress: 'San Martín 123',
      isOnline: true,
      categories: <CategoryItem>[
        CategoryItem(id: 'cat-1', name: 'Pizza', emoji: '🍕'),
      ],
      promoBanner: PromoBannerData(
        id: 'promo-1',
        badgeLabel: '20% OFF',
        title: 'Promo Test',
        couponPrefix: 'CUPON: ',
        couponCode: 'TEST',
        ctaLabel: 'Pedir',
      ),
      merchants: <MerchantSummary>[],
    );
  }

  @override
  Future<bool> toggleFavorite({
    required String merchantId,
    required bool currentValue,
  }) async {
    return !currentValue;
  }
}

void main() {
  group('Home Repositories & DTOs Tests', () {
    test(
      'SeedHomeRepository retorna feed completo de General Alvear',
      () async {
        final SeedHomeRepository repo = SeedHomeRepository();
        final HomeFeedData feed = await repo.fetchHomeFeed();

        expect(feed.userName, isNotEmpty);
        expect(feed.categories.length, 6);
        expect(feed.promoBanner.couponCode, 'ALVEARYA');
        expect(feed.lastOrder?.merchantName, 'Empanadas Don Pedro');
        expect(feed.merchants.length, 3);
        expect(feed.merchants.first.name, 'Pizzería La Alvearense');
        expect(feed.merchants.first.deliveryFeeCents, 85000);
      },
    );

    test('SeedHomeRepository alterna favoritos en memoria', () async {
      final SeedHomeRepository repo = SeedHomeRepository();
      const String merchantId = 'm1111111-1111-4111-8111-111111111111';

      final bool fav1 = await repo.toggleFavorite(
        merchantId: merchantId,
        currentValue: false,
      );
      expect(fav1, isTrue);

      final HomeFeedData feed1 = await repo.fetchHomeFeed();
      expect(feed1.merchants.first.isFavorite, isTrue);

      final bool fav2 = await repo.toggleFavorite(
        merchantId: merchantId,
        currentValue: true,
      );
      expect(fav2, isFalse);

      final HomeFeedData feed2 = await repo.fetchHomeFeed();
      expect(feed2.merchants.first.isFavorite, isFalse);
    });

    test(
      'SupabaseHomeRepository con cliente null delega en fallbackRepository',
      () async {
        final _FakeHomeRepository fakeFallback = _FakeHomeRepository();
        final SupabaseHomeRepository repo = SupabaseHomeRepository(
          client: null,
          fallbackRepository: fakeFallback,
        );

        final HomeFeedData feed = await repo.fetchHomeFeed();
        expect(feed.userName, 'Test User');
        expect(fakeFallback.fetchCallCount, 1);
      },
    );

    test(
      'SupabaseHomeRepository propaga error si el fallbackRepository falla',
      () async {
        final _FakeHomeRepository fakeFallback = _FakeHomeRepository(
          shouldThrow: true,
        );
        final SupabaseHomeRepository repo = SupabaseHomeRepository(
          client: null,
          fallbackRepository: fakeFallback,
        );

        expect(() => repo.fetchHomeFeed(), throwsA(isA<Exception>()));
      },
    );

    test('homeRepositoryProvider selecciona SeedHomeRepository cuando no está configurado', () {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          isBackendConfiguredProvider.overrideWithValue(false),
          supabaseClientProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final HomeRepository repo = container.read(homeRepositoryProvider);
      expect(repo, isA<SeedHomeRepository>());
    });

    test('CategoryDto deserializa correctamente con fallback de emoji', () {
      final CategoryDto dto = CategoryDto.fromJson(<String, Object?>{
        'id': 'cat-test',
        'name': 'Helados',
        'emoji': null,
      });

      expect(dto.id, 'cat-test');
      expect(dto.name, 'Helados');
      expect(dto.emoji, '🍽️');
      expect(dto.toDomain().name, 'Helados');
    });

    test(
      'MerchantSummaryDto normaliza montos en centavos y parsea category_ids',
      () {
        final MerchantSummaryDto dto = MerchantSummaryDto.fromJson(
          <String, Object?>{
            'id': 'm-1',
            'name': 'Pizzería Test',
            'description': 'Pizzas ricas',
            'tiempo_estimado_min': 30,
            'costo_envio_base': 120000,
            'rating': 4.75,
            'review_count': 12,
            'category_ids': <Object?>['cat-1', 'cat-2'],
            'banner_url': null,
            'is_open': true,
          },
        );

        final MerchantSummary domain = dto.toDomain(isFavorite: true);

        expect(domain.id, 'm-1');
        expect(domain.name, 'Pizzería Test');
        expect(domain.deliveryFeeCents, 120000);
        expect(domain.rating, 4.75);
        expect(domain.reviewCount, 12);
        expect(domain.categoryIds, <String>['cat-1', 'cat-2']);
        expect(domain.isFavorite, isTrue);
        expect(domain.minMinutes, 25);
        expect(domain.maxMinutes, 35);
      },
    );

    test('LastOrderDto deserializa productos anidados y total en centavos', () {
      final LastOrderDto dto = LastOrderDto.fromJson(<String, Object?>{
        'id': 'ord-100',
        'merchant_id': 'm-2',
        'total': 1500000,
        'created_at': '2026-10-30T20:00:00Z',
        'merchants': <String, Object?>{'name': 'Hamburguesas Alvear'},
        'order_items': <Object?>[
          <String, Object?>{
            'quantity': 2,
            'products': <String, Object?>{'name': 'Smash Doble'},
          },
        ],
      });

      final LastOrderSummary domain = dto.toDomain();
      expect(domain.orderId, 'ord-100');
      expect(domain.merchantName, 'Hamburguesas Alvear');
      expect(domain.itemsSummary, '2 Smash Doble');
      expect(domain.totalCents, 1500000);
    });
  });
}
