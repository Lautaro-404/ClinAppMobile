import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinapp/core/config/env.dart';
import 'package:clinapp/core/config/supabase_provider.dart';
import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/network/retry_policy.dart';
import 'package:clinapp/features/search/data/dtos/search_dtos.dart';
import 'package:clinapp/features/search/data/seed_search_repository.dart';
import 'package:clinapp/features/search/domain/search_models.dart';
import 'package:clinapp/features/search/domain/search_repository.dart';

/// Columnas explícitas de la vista de catálogo requeridas por SearchMerchantItemDto (evita SELECT *).
const String _searchCatalogViewColumns =
    'id, name, description, estado, tiempo_estimado_min, '
    'costo_envio_base, rating, is_open, signature_dish_name, signature_dish_price';

/// Implementación de [SearchRepository] conectada al backend de Supabase
/// con consultas explícitas, ejecución en paralelo y fallback controlado a [SeedSearchRepository].
class SupabaseSearchRepository implements SearchRepository {
  SupabaseSearchRepository({
    required this.client,
    SearchRepository? fallbackRepository,
  }) : _fallback = fallbackRepository ?? SeedSearchRepository();

  final SupabaseClient? client;
  final SearchRepository _fallback;
  final Set<String> _localFavorites = <String>{};

  static const List<String> _defaultRecentSearches = <String>[
    'Lomito completo',
    'Helado dulce de leche',
    'Cerveza artesanal',
    'Pastas caseras',
  ];

  @override
  Future<SearchCatalogData> fetchSearchCatalog({String? query}) async {
    final SupabaseClient? activeClient = client;
    if (activeClient == null) {
      return _fallback.fetchSearchCatalog(query: query);
    }

    try {
      final String trimmedQuery = query?.trim() ?? '';
      final User? currentUser = activeClient.auth.currentUser;

      // Ejecutar consulta de catálogo y favoritos en paralelo
      final Future<List<Map<String, Object?>>> merchantsFuture =
          _fetchMerchantRows(activeClient, trimmedQuery);
      final Future<Set<String>> favoritesFuture = currentUser != null
          ? _fetchUserFavorites(activeClient, currentUser.id)
          : Future<Set<String>>.value(<String>{..._localFavorites});

      final List<Object?> results = await Future.wait<Object?>(
        <Future<Object?>>[merchantsFuture, favoritesFuture],
      );

      final List<Map<String, Object?>> merchantRows =
          results[0]! as List<Map<String, Object?>>;
      final Set<String> favoriteIds = results[1]! as Set<String>;

      final List<SearchMerchantItem> merchants = merchantRows
          .map((Map<String, Object?> row) {
            final SearchMerchantItemDto dto = SearchMerchantItemDto.fromJson(
              row,
            );
            return dto.toDomain(
              isFavorite: favoriteIds.contains(dto.id),
              client: activeClient,
            );
          })
          .where((SearchMerchantItem m) => m.id.isNotEmpty)
          .toList();

      if (merchants.isEmpty && trimmedQuery.isEmpty && Env.isDev) {
        return await _fallback.fetchSearchCatalog();
      }

      return SearchCatalogData(
        recentSearches: _defaultRecentSearches,
        merchants: merchants,
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
      try {
        return await _fallback.fetchSearchCatalog(query: query);
      } on Object {
        throw mapped;
      }
    }
  }

  Future<List<Map<String, Object?>>> _fetchMerchantRows(
    SupabaseClient activeClient,
    String trimmedQuery,
  ) async {
    try {
      return await RetryPolicy.execute<List<Map<String, Object?>>>(() {
        var queryBuilder = activeClient
            .from('merchants_catalog_view')
            .select(_searchCatalogViewColumns)
            .eq('estado', 'activo');

        if (trimmedQuery.isNotEmpty) {
          queryBuilder = queryBuilder.or(
            'name.ilike.%$trimmedQuery%,description.ilike.%$trimmedQuery%,signature_dish_name.ilike.%$trimmedQuery%',
          );
        }

        return queryBuilder.limit(30);
      });
    } on PermissionDeniedFailure {
      rethrow;
    } on Object {
      return RetryPolicy.execute<List<Map<String, Object?>>>(() {
        var queryBuilder = activeClient
            .from('merchants')
            .select(
              'id, name, description, estado, tiempo_estimado_min, '
              'costo_envio_base, reviews(rating), '
              'menu_sections(products(name, price, is_available))',
            )
            .eq('estado', 'activo');

        if (trimmedQuery.isNotEmpty) {
          queryBuilder = queryBuilder.or(
            'name.ilike.%$trimmedQuery%,description.ilike.%$trimmedQuery%',
          );
        }

        return queryBuilder.limit(30);
      });
    }
  }

  Future<Set<String>> _fetchUserFavorites(
    SupabaseClient activeClient,
    String userId,
  ) async {
    try {
      final List<Map<String, Object?>> favRows =
          await RetryPolicy.execute<List<Map<String, Object?>>>(
            () => activeClient
                .from('favorites')
                .select('merchant_id')
                .eq('user_id', userId),
          );
      return favRows
          .map((Map<String, Object?> r) => (r['merchant_id'] ?? '').toString())
          .where((String id) => id.isNotEmpty)
          .toSet();
    } on Object {
      return <String>{..._localFavorites};
    }
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

    final SupabaseClient? activeClient = client;
    final User? user = activeClient?.auth.currentUser;
    if (activeClient == null || user == null) {
      if (!Env.isDev && activeClient != null) {
        throw const AuthFailure(AppStrings.errorAuth);
      }
      return _fallback.toggleFavorite(
        merchantId: merchantId,
        currentValue: currentValue,
      );
    }

    try {
      await RetryPolicy.execute<void>(
        () async {
          if (nextValue) {
            await activeClient.from('favorites').upsert(<String, Object>{
              'user_id': user.id,
              'merchant_id': merchantId,
            }, onConflict: 'user_id, merchant_id');
          } else {
            await activeClient
                .from('favorites')
                .delete()
                .eq('user_id', user.id)
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
}

/// Provider del repositorio de la pantalla Buscar.
final Provider<SearchRepository> searchRepositoryProvider =
    Provider<SearchRepository>((Ref ref) {
      final bool isConfigured = ref.watch(isBackendConfiguredProvider);
      final SupabaseClient? client = ref.watch(supabaseClientProvider);
      final SeedSearchRepository seedRepo = SeedSearchRepository();

      if (!isConfigured || client == null) {
        return seedRepo;
      }

      return SupabaseSearchRepository(
        client: client,
        fallbackRepository: seedRepo,
      );
    });
