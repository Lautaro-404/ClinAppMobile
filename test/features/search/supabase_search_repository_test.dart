import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clinapp/core/config/supabase_provider.dart';
import 'package:clinapp/features/search/data/dtos/search_dtos.dart';
import 'package:clinapp/features/search/data/seed_search_repository.dart';
import 'package:clinapp/features/search/data/supabase_search_repository.dart';
import 'package:clinapp/features/search/domain/search_models.dart';
import 'package:clinapp/features/search/domain/search_repository.dart';

class _FakeSearchRepository implements SearchRepository {
  int fetchCount = 0;

  @override
  Future<SearchCatalogData> fetchSearchCatalog({String? query}) async {
    fetchCount++;
    return const SearchCatalogData(
      recentSearches: <String>['Empanadas'],
      merchants: <SearchMerchantItem>[],
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
  group('Search Repositories & DTOs Tests', () {
    test(
      'SeedSearchRepository retorna catálogo semilla de General Alvear',
      () async {
        final SeedSearchRepository repo = SeedSearchRepository();
        final SearchCatalogData catalog = await repo.fetchSearchCatalog();

        expect(catalog.recentSearches.length, 4);
        expect(catalog.merchants.length, 3);
        expect(catalog.merchants.first.name, 'La Esquina del Sándwich');
        expect(
          catalog.merchants.first.signatureDish?.name,
          'Lomo Especial Alvear',
        );
        expect(catalog.merchants.first.signatureDish?.priceCents, 890000);
      },
    );

    test(
      'SeedSearchRepository filtra en memoria cuando se pasa query',
      () async {
        final SeedSearchRepository repo = SeedSearchRepository();

        final SearchCatalogData asadoResult = await repo.fetchSearchCatalog(
          query: 'asado',
        );
        expect(asadoResult.merchants.length, 1);
        expect(asadoResult.merchants.first.name, 'Parrilla Don Manuel');

        final SearchCatalogData nonExistent = await repo.fetchSearchCatalog(
          query: 'sushi',
        );
        expect(nonExistent.merchants, isEmpty);
      },
    );

    test('SeedSearchRepository alterna favoritos en memoria', () async {
      final SeedSearchRepository repo = SeedSearchRepository();
      const String merchantId = 'm-parrilla-don-manuel';

      final bool fav1 = await repo.toggleFavorite(
        merchantId: merchantId,
        currentValue: false,
      );
      expect(fav1, isTrue);

      final SearchCatalogData cat1 = await repo.fetchSearchCatalog();
      final SearchMerchantItem parrilla = cat1.merchants.firstWhere(
        (m) => m.id == merchantId,
      );
      expect(parrilla.isFavorite, isTrue);
    });

    test(
      'SupabaseSearchRepository con cliente null delega en fallbackRepository',
      () async {
        final _FakeSearchRepository fakeFallback = _FakeSearchRepository();
        final SupabaseSearchRepository repo = SupabaseSearchRepository(
          client: null,
          fallbackRepository: fakeFallback,
        );

        final SearchCatalogData catalog = await repo.fetchSearchCatalog();
        expect(catalog.recentSearches, <String>['Empanadas']);
        expect(fakeFallback.fetchCount, 1);
      },
    );

    test('searchRepositoryProvider selecciona SeedSearchRepository si no está configurado', () {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          isBackendConfiguredProvider.overrideWithValue(false),
          supabaseClientProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final SearchRepository repo = container.read(searchRepositoryProvider);
      expect(repo, isA<SeedSearchRepository>());
    });

    test(
      'SignatureDishDto y SearchMerchantItemDto deserializan correctamente',
      () {
        final SearchMerchantItemDto dto = SearchMerchantItemDto.fromJson(
          <String, Object?>{
            'id': 'm-search-1',
            'name': 'Don Manuel',
            'description': 'Parrilla criolla',
            'tiempo_estimado_min': 35,
            'costo_envio_base': 0,
            'rating': 4.9,
            'is_open': true,
            'signature_dish_name': 'Bife de chorizo',
            'signature_dish_price': 1400000,
          },
        );

        final SearchMerchantItem domain = dto.toDomain(isFavorite: false);

        expect(domain.id, 'm-search-1');
        expect(domain.name, 'Don Manuel');
        expect(domain.deliveryFeeCents, 0);
        expect(domain.rating, 4.9);
        expect(domain.isOpen, isTrue);
        expect(domain.signatureDish?.name, 'Bife de chorizo');
        expect(domain.signatureDish?.priceCents, 1400000);
        expect(domain.searchKeywords, contains('Bife de chorizo'));
      },
    );
  });
}
