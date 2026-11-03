import 'package:flutter/painting.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/features/search/domain/search_models.dart';
import 'package:clinapp/features/search/domain/search_repository.dart';

/// Implementación autónoma de [SearchRepository] con datos de catálogo semilla
/// de General Alvear para desarrollo local, pruebas o fallback cuando el backend no responde.
class SeedSearchRepository implements SearchRepository {
  SeedSearchRepository({Set<String>? initialFavorites})
    : _localFavorites = initialFavorites ?? <String>{};

  final Set<String> _localFavorites;

  static const List<String> _defaultRecentSearches = <String>[
    'Lomito completo',
    'Helado dulce de leche',
    'Cerveza artesanal',
    'Pastas caseras',
  ];

  @override
  Future<SearchCatalogData> fetchSearchCatalog({String? query}) async {
    final List<SearchMerchantItem> seedMerchants = <SearchMerchantItem>[
      SearchMerchantItem(
        id: 'm-esquina-sandwich',
        name: 'La Esquina del Sándwich',
        subtitle: 'Lomitería & Minutas',
        rating: 4.8,
        minMinutes: 20,
        maxMinutes: 30,
        deliveryFeeCents: 70000,
        accentColor: AppColors.accent,
        isFavorite: _localFavorites.contains('m-esquina-sandwich'),
        signatureDish: const SignatureDish(
          name: 'Lomo Especial Alvear',
          priceCents: 890000,
          badgeLabel: AppStrings.searchSignatureDishLabel,
        ),
        searchKeywords: const <String>[
          'lomito completo',
          'lomo',
          'sandwich',
          'papas',
          'cerveza artesanal',
        ],
      ),
      SearchMerchantItem(
        id: 'm-parrilla-don-manuel',
        name: 'Parrilla Don Manuel',
        subtitle: 'Carnes & Parrilla',
        rating: 4.9,
        minMinutes: 35,
        maxMinutes: 45,
        deliveryFeeCents: 0,
        accentColor: const Color(0xFFD97706),
        isFavorite: _localFavorites.contains('m-parrilla-don-manuel'),
        signatureDish: const SignatureDish(
          name: 'Ojo de bife con papas',
          priceCents: 1460000,
          badgeLabel: AppStrings.searchChefRecommendedLabel,
          isChefRecommendation: true,
        ),
        searchKeywords: const <String>[
          'parrilla',
          'asado',
          'vino',
          'pastas caseras',
          'bife',
        ],
      ),
      SearchMerchantItem(
        id: 'm-cafe-bakery-alvear',
        name: 'Café & Bakery Alvear',
        subtitle: 'Desayunos & Meriendas',
        rating: 4.7,
        minMinutes: 15,
        maxMinutes: 25,
        deliveryFeeCents: 50000,
        accentColor: AppColors.success,
        isFavorite: _localFavorites.contains('m-cafe-bakery-alvear'),
        searchKeywords: const <String>[
          'cafe',
          'medialunas',
          'helado dulce de leche',
          'postres',
        ],
      ),
    ];

    final List<SearchMerchantItem> filtered =
        (query == null || query.trim().isEmpty)
        ? seedMerchants
        : seedMerchants
              .where((SearchMerchantItem m) => m.matchesQuery(query))
              .toList();

    return SearchCatalogData(
      recentSearches: List<String>.of(_defaultRecentSearches),
      merchants: filtered,
    );
  }

  @override
  Future<bool> toggleFavorite({
    required String merchantId,
    required bool currentValue,
  }) async {
    final bool nextValue = !currentValue;
    if (nextValue) {
      _localFavorites.add(merchantId);
    } else {
      _localFavorites.remove(merchantId);
    }
    return nextValue;
  }
}
