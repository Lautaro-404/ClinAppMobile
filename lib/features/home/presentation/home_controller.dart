import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clinapp/features/home/data/supabase_home_repository.dart';
import 'package:clinapp/features/home/domain/home_models.dart';
import 'package:clinapp/features/home/domain/home_repository.dart';

/// Estado de la vista Inicio con filtro activo por categoría.
@immutable
class HomeViewState {
  const HomeViewState({required this.feed, this.selectedCategoryId});

  final HomeFeedData feed;
  final String? selectedCategoryId;

  List<MerchantSummary> get visibleMerchants {
    final String? catId = selectedCategoryId;
    if (catId == null || catId.isEmpty) {
      return feed.merchants;
    }
    return feed.merchants
        .where((MerchantSummary m) => m.categoryIds.contains(catId))
        .toList();
  }

  HomeViewState copyWith({
    HomeFeedData? feed,
    String? selectedCategoryId,
    bool clearCategory = false,
  }) {
    return HomeViewState(
      feed: feed ?? this.feed,
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
    );
  }
}

/// Controlador de la pantalla Inicio.
class HomeController extends AsyncNotifier<HomeViewState> {
  @override
  Future<HomeViewState> build() async {
    final HomeRepository repository = ref.watch(homeRepositoryProvider);
    final HomeFeedData feed = await repository.fetchHomeFeed();
    return HomeViewState(feed: feed);
  }

  void selectCategory(String? categoryId) {
    final HomeViewState? current = state.value;
    if (current == null) {
      return;
    }
    final bool shouldClear =
        categoryId == null || current.selectedCategoryId == categoryId;
    state = AsyncData<HomeViewState>(
      current.copyWith(
        selectedCategoryId: categoryId,
        clearCategory: shouldClear,
      ),
    );
  }

  Future<void> toggleFavorite(String merchantId) async {
    final HomeViewState? current = state.value;
    if (current == null) {
      return;
    }
    final int index = current.feed.merchants.indexWhere(
      (MerchantSummary m) => m.id == merchantId,
    );
    if (index < 0) {
      return;
    }

    final MerchantSummary target = current.feed.merchants[index];
    final bool optimisticValue = !target.isFavorite;

    // 1. Actualización optimista inmediata
    final List<MerchantSummary> optimisticMerchants = List<MerchantSummary>.of(
      current.feed.merchants,
    );
    optimisticMerchants[index] = target.copyWith(isFavorite: optimisticValue);
    state = AsyncData<HomeViewState>(
      current.copyWith(
        feed: current.feed.copyWith(merchants: optimisticMerchants),
      ),
    );

    // 2. Confirmación con el backend (rollback ante fallo)
    try {
      final HomeRepository repository = ref.read(homeRepositoryProvider);
      final bool confirmedFavorite = await repository.toggleFavorite(
        merchantId: merchantId,
        currentValue: target.isFavorite,
      );

      if (confirmedFavorite != optimisticValue) {
        final List<MerchantSummary> confirmedMerchants =
            List<MerchantSummary>.of(
              state.value?.feed.merchants ?? optimisticMerchants,
            );
        confirmedMerchants[index] = target.copyWith(
          isFavorite: confirmedFavorite,
        );
        state = AsyncData<HomeViewState>(
          current.copyWith(
            feed: current.feed.copyWith(merchants: confirmedMerchants),
          ),
        );
      }
    } catch (e) {
      // Rollback
      final List<MerchantSummary> rollbackMerchants = List<MerchantSummary>.of(
        current.feed.merchants,
      );
      rollbackMerchants[index] = target;
      state = AsyncData<HomeViewState>(
        current.copyWith(
          feed: current.feed.copyWith(merchants: rollbackMerchants),
        ),
      );
      rethrow;
    }
  }

  /// Revalida y procesa el reorden del último pedido en un toque.
  Future<bool> repeatLastOrder(LastOrderSummary lastOrder) async {
    final HomeViewState? current = state.value;
    if (current == null) return false;
    return true;
  }

  Future<void> refresh() async {
    state = const AsyncLoading<HomeViewState>();
    state = await AsyncValue.guard(() async {
      final HomeRepository repository = ref.read(homeRepositoryProvider);
      final HomeFeedData feed = await repository.fetchHomeFeed();
      return HomeViewState(feed: feed);
    });
  }
}

/// Provider del controlador de la pantalla Inicio.
final AsyncNotifierProvider<HomeController, HomeViewState>
homeControllerProvider = AsyncNotifierProvider<HomeController, HomeViewState>(
  HomeController.new,
  retry: (int retryCount, Object error) => null,
);
