import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinapp/core/config/env.dart';
import 'package:clinapp/core/config/supabase_provider.dart';
import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/network/retry_policy.dart';
import 'package:clinapp/features/home/data/dtos/home_dtos.dart';
import 'package:clinapp/features/home/data/seed_home_repository.dart';
import 'package:clinapp/features/home/domain/home_models.dart';
import 'package:clinapp/features/home/domain/home_repository.dart';

/// Columnas explícitas seleccionadas en la vista de catálogo de Home (evita SELECT *).
const String _homeCatalogViewColumns =
    'id, name, description, banner_url, estado, tiempo_estimado_min, '
    'costo_envio_base, rating, review_count, category_ids';

/// Implementación de [HomeRepository] conectada al backend de Supabase
/// con DTOs tipados, consultas en paralelo y fallback controlado a [SeedHomeRepository].
class SupabaseHomeRepository implements HomeRepository {
  SupabaseHomeRepository({
    required this.client,
    HomeRepository? fallbackRepository,
  }) : _fallback = fallbackRepository ?? SeedHomeRepository();

  final SupabaseClient? client;
  final HomeRepository _fallback;
  final Set<String> _localFavorites = <String>{};

  @override
  Future<HomeFeedData> fetchHomeFeed() async {
    final SupabaseClient? activeClient = client;
    if (activeClient == null) {
      return _fallback.fetchHomeFeed();
    }

    try {
      // Bloque 1: Consultas de catálogo público en paralelo (1 RTT en vez de 3 secuenciales).
      final Future<List<Map<String, Object?>>> categoriesFuture =
          RetryPolicy.execute<List<Map<String, Object?>>>(
            () => activeClient
                .from('categories')
                .select('id, name, emoji')
                .order('name'),
          );

      final Future<List<Map<String, Object?>>> merchantsFuture =
          _fetchMerchantRows(activeClient);

      final Future<PromoBannerData?> bannerFuture = _fetchPromoBanner(
        activeClient,
      );

      // Bloque 2: Datos del usuario autenticado en paralelo si hay sesión activa.
      final User? currentUser = activeClient.auth.currentUser;
      final Future<_AuthenticatedUserHomeData> userDataFuture =
          currentUser != null
          ? _fetchAuthenticatedUserData(activeClient, currentUser.id)
          : Future<_AuthenticatedUserHomeData>.value(
              _AuthenticatedUserHomeData(
                favoriteIds: <String>{..._localFavorites},
                userName: AppStrings.homeDefaultUserName,
                deliveryAddress: AppStrings.homeDefaultAddress,
                lastOrder: null,
              ),
            );

      final List<Object?> results = await Future.wait<Object?>(
        <Future<Object?>>[
          categoriesFuture,
          merchantsFuture,
          bannerFuture,
          userDataFuture,
        ],
      );

      final List<Map<String, Object?>> categoryRows =
          results[0]! as List<Map<String, Object?>>;
      final List<Map<String, Object?>> merchantRows =
          results[1]! as List<Map<String, Object?>>;
      final PromoBannerData? promoBanner = results[2] as PromoBannerData?;
      final _AuthenticatedUserHomeData userData =
          results[3]! as _AuthenticatedUserHomeData;

      final List<CategoryItem> categories = categoryRows
          .map((Map<String, Object?> r) => CategoryDto.fromJson(r).toDomain())
          .where((CategoryItem c) => c.id.isNotEmpty)
          .toList();

      final List<MerchantSummary> merchants = merchantRows
          .map((Map<String, Object?> row) {
            final MerchantSummaryDto dto = MerchantSummaryDto.fromJson(row);
            return dto.toDomain(
              isFavorite: userData.favoriteIds.contains(dto.id),
              client: activeClient,
            );
          })
          .where((MerchantSummary m) => m.id.isNotEmpty)
          .toList();

      // Si no hay datos en la DB remota en modo dev, recurre al seed
      if (categories.isEmpty && merchants.isEmpty && Env.isDev) {
        return await _fallback.fetchHomeFeed();
      }

      final HomeFeedData fallbackFeed = await _fallback.fetchHomeFeed();
      return HomeFeedData(
        userName: userData.userName,
        deliveryAddress: userData.deliveryAddress,
        isOnline: true,
        categories: categories.isNotEmpty
            ? categories
            : fallbackFeed.categories,
        promoBanner: promoBanner ?? fallbackFeed.promoBanner,
        lastOrder:
            userData.lastOrder ?? (Env.isDev ? fallbackFeed.lastOrder : null),
        merchants: merchants.isNotEmpty
            ? merchants
            : (Env.isDev ? fallbackFeed.merchants : const <MerchantSummary>[]),
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
        return await _fallback.fetchHomeFeed();
      } on Object {
        throw mapped;
      }
    }
  }

  Future<List<Map<String, Object?>>> _fetchMerchantRows(
    SupabaseClient activeClient,
  ) async {
    try {
      return await RetryPolicy.execute<List<Map<String, Object?>>>(
        () => activeClient
            .from('merchants_catalog_view')
            .select(_homeCatalogViewColumns)
            .eq('estado', 'activo')
            .order('rating', ascending: false)
            .limit(20),
      );
    } on PermissionDeniedFailure {
      rethrow;
    } on Object {
      return RetryPolicy.execute<List<Map<String, Object?>>>(
        () => activeClient
            .from('merchants')
            .select(
              'id, name, description, banner_url, tiempo_estimado_min, '
              'costo_envio_base, estado, merchant_categories(category_id), '
              'reviews(rating)',
            )
            .eq('estado', 'activo')
            .limit(20),
      );
    }
  }

  Future<PromoBannerData?> _fetchPromoBanner(
    SupabaseClient activeClient,
  ) async {
    try {
      final Map<String, Object?>? bannerRow =
          await RetryPolicy.execute<Map<String, Object?>?>(
            () => activeClient
                .from('marketing_banners')
                .select('id, title, subtitle, image_url')
                .eq('active', true)
                .order('sort_order')
                .limit(1)
                .maybeSingle(),
          );

      if (bannerRow != null) {
        return PromoBannerDto.fromBannerJson(bannerRow).toDomain();
      }

      if (activeClient.auth.currentUser != null) {
        final Map<String, Object?>? couponRow =
            await RetryPolicy.execute<Map<String, Object?>?>(
              () => activeClient
                  .from('coupons')
                  .select('id, codigo, porcentaje')
                  .eq('activo', true)
                  .order('created_at', ascending: false)
                  .limit(1)
                  .maybeSingle(),
            );
        if (couponRow != null) {
          return PromoBannerDto.fromCouponJson(couponRow).toDomain();
        }
      }
    } on Object {
      return null;
    }
    return null;
  }

  Future<_AuthenticatedUserHomeData> _fetchAuthenticatedUserData(
    SupabaseClient activeClient,
    String userId,
  ) async {
    final Future<Set<String>> favsFuture = () async {
      try {
        final List<Map<String, Object?>> favRows =
            await RetryPolicy.execute<List<Map<String, Object?>>>(
              () => activeClient
                  .from('favorites')
                  .select('merchant_id')
                  .eq('user_id', userId),
            );
        return favRows
            .map(
              (Map<String, Object?> r) => (r['merchant_id'] ?? '').toString(),
            )
            .where((String id) => id.isNotEmpty)
            .toSet();
      } on Object {
        return <String>{..._localFavorites};
      }
    }();

    final Future<String> nameFuture = () async {
      try {
        final Map<String, Object?>? profileRow =
            await RetryPolicy.execute<Map<String, Object?>?>(
              () => activeClient
                  .from('profiles')
                  .select('nombre')
                  .eq('id', userId)
                  .maybeSingle(),
            );
        final String fetchedName = (profileRow?['nombre'] ?? '')
            .toString()
            .trim();
        if (fetchedName.isNotEmpty) {
          return fetchedName.split(' ').first;
        }
      } on Object {
        // Fallback al nombre predeterminado
      }
      return AppStrings.homeDefaultUserName;
    }();

    final Future<String> addressFuture = () async {
      try {
        final Map<String, Object?>? addressRow =
            await RetryPolicy.execute<Map<String, Object?>?>(
              () => activeClient
                  .from('addresses')
                  .select('address_line')
                  .eq('profile_id', userId)
                  .order('is_default', ascending: false)
                  .limit(1)
                  .maybeSingle(),
            );
        final String fetchedAddress = (addressRow?['address_line'] ?? '')
            .toString()
            .trim();
        if (fetchedAddress.isNotEmpty) {
          return fetchedAddress;
        }
      } on Object {
        // Fallback a dirección predeterminada
      }
      return AppStrings.homeDefaultAddress;
    }();

    final Future<LastOrderSummary?> lastOrderFuture = () async {
      try {
        final Map<String, Object?>? orderRow =
            await RetryPolicy.execute<Map<String, Object?>?>(
              () => activeClient
                  .from('orders')
                  .select(
                    'id, merchant_id, total, created_at, estado, '
                    'merchants(name), '
                    'order_items(quantity, products(name))',
                  )
                  .eq('user_id', userId)
                  .eq('estado', 'entregado')
                  .order('created_at', ascending: false)
                  .limit(1)
                  .maybeSingle(),
            );
        if (orderRow != null) {
          return LastOrderDto.fromJson(orderRow).toDomain();
        }
      } on Object {
        return null;
      }
      return null;
    }();

    final List<Object?> userResults = await Future.wait<Object?>(
      <Future<Object?>>[favsFuture, nameFuture, addressFuture, lastOrderFuture],
    );

    return _AuthenticatedUserHomeData(
      favoriteIds: userResults[0]! as Set<String>,
      userName: userResults[1]! as String,
      deliveryAddress: userResults[2]! as String,
      lastOrder: userResults[3] as LastOrderSummary?,
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

class _AuthenticatedUserHomeData {
  const _AuthenticatedUserHomeData({
    required this.favoriteIds,
    required this.userName,
    required this.deliveryAddress,
    required this.lastOrder,
  });

  final Set<String> favoriteIds;
  final String userName;
  final String deliveryAddress;
  final LastOrderSummary? lastOrder;
}

/// Provider del repositorio de Inicio.
final Provider<HomeRepository> homeRepositoryProvider =
    Provider<HomeRepository>((Ref ref) {
      final bool isConfigured = ref.watch(isBackendConfiguredProvider);
      final SupabaseClient? client = ref.watch(supabaseClientProvider);
      final SeedHomeRepository seedRepo = SeedHomeRepository();

      if (!isConfigured || client == null) {
        return seedRepo;
      }

      return SupabaseHomeRepository(
        client: client,
        fallbackRepository: seedRepo,
      );
    });
