import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clinapp/features/search/data/supabase_search_repository.dart';
import 'package:clinapp/features/search/domain/search_models.dart';
import 'package:clinapp/features/search/domain/search_repository.dart';

/// Estado reactivo de la pantalla Buscar.
@immutable
class SearchViewState {
  const SearchViewState({
    required this.recentSearches,
    required this.allMerchants,
    this.query = '',
    this.activeFilters = const <SearchFilter>{SearchFilter.openNow},
  });

  final String query;
  final List<String> recentSearches;
  final Set<SearchFilter> activeFilters;
  final List<SearchMerchantItem> allMerchants;

  List<SearchMerchantItem> get visibleMerchants {
    return allMerchants.where((SearchMerchantItem merchant) {
      return merchant.matchesQuery(query) &&
          merchant.matchesFilters(activeFilters);
    }).toList();
  }

  SearchViewState copyWith({
    String? query,
    List<String>? recentSearches,
    Set<SearchFilter>? activeFilters,
    List<SearchMerchantItem>? allMerchants,
  }) {
    return SearchViewState(
      query: query ?? this.query,
      recentSearches: recentSearches ?? this.recentSearches,
      activeFilters: activeFilters ?? this.activeFilters,
      allMerchants: allMerchants ?? this.allMerchants,
    );
  }
}

/// Controlador de la pantalla Buscar con debounce en la entrada de texto.
class SearchController extends AsyncNotifier<SearchViewState> {
  static const Duration debounceDuration = Duration(milliseconds: 250);
  Timer? _debounceTimer;

  @override
  Future<SearchViewState> build() async {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    final SearchRepository repository = ref.watch(searchRepositoryProvider);
    final SearchCatalogData catalog = await repository.fetchSearchCatalog();
    return SearchViewState(
      recentSearches: catalog.recentSearches,
      allMerchants: catalog.merchants,
    );
  }

  /// Actualiza la consulta aplicando un debounce de [debounceDuration].
  void updateQueryDebounced(String nextQuery) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      applyQueryImmediately(nextQuery);
    });
  }

  /// Aplica la consulta de forma inmediata (al tocar un chip o enviar).
  void applyQueryImmediately(String nextQuery) {
    _debounceTimer?.cancel();
    final SearchViewState? current = state.value;
    if (current == null) {
      return;
    }
    final String trimmed = nextQuery.trim();
    List<String> updatedRecents = current.recentSearches;
    if (trimmed.isNotEmpty && !current.recentSearches.contains(trimmed)) {
      updatedRecents = <String>[trimmed, ...current.recentSearches];
    }
    state = AsyncData<SearchViewState>(
      current.copyWith(query: nextQuery, recentSearches: updatedRecents),
    );
  }

  void removeRecentSearch(String term) {
    final SearchViewState? current = state.value;
    if (current == null) {
      return;
    }
    final List<String> updated = current.recentSearches
        .where((String item) => item != term)
        .toList();
    state = AsyncData<SearchViewState>(
      current.copyWith(recentSearches: updated),
    );
  }

  void clearRecentSearches() {
    final SearchViewState? current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData<SearchViewState>(
      current.copyWith(recentSearches: const <String>[]),
    );
  }

  void toggleFilter(SearchFilter filter) {
    final SearchViewState? current = state.value;
    if (current == null) {
      return;
    }
    final Set<SearchFilter> nextFilters = Set<SearchFilter>.of(
      current.activeFilters,
    );
    if (nextFilters.contains(filter)) {
      nextFilters.remove(filter);
    } else {
      nextFilters.add(filter);
    }
    state = AsyncData<SearchViewState>(
      current.copyWith(activeFilters: nextFilters),
    );
  }

  void resetAllFiltersAndQuery() {
    _debounceTimer?.cancel();
    final SearchViewState? current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData<SearchViewState>(
      current.copyWith(
        query: '',
        activeFilters: const <SearchFilter>{SearchFilter.openNow},
      ),
    );
  }

  Future<void> toggleFavorite(String merchantId) async {
    final SearchViewState? current = state.value;
    if (current == null) {
      return;
    }
    final int index = current.allMerchants.indexWhere(
      (SearchMerchantItem m) => m.id == merchantId,
    );
    if (index < 0) {
      return;
    }
    final SearchMerchantItem target = current.allMerchants[index];
    final bool optimisticValue = !target.isFavorite;

    // 1. Actualización optimista inmediata
    final List<SearchMerchantItem> optimisticMerchants =
        List<SearchMerchantItem>.of(current.allMerchants);
    optimisticMerchants[index] = target.copyWith(isFavorite: optimisticValue);
    state = AsyncData<SearchViewState>(
      current.copyWith(allMerchants: optimisticMerchants),
    );

    // 2. Persistencia con rollback ante fallos
    try {
      final SearchRepository repository = ref.read(searchRepositoryProvider);
      final bool confirmedFavorite = await repository.toggleFavorite(
        merchantId: merchantId,
        currentValue: target.isFavorite,
      );

      if (confirmedFavorite != optimisticValue) {
        final List<SearchMerchantItem> confirmedMerchants =
            List<SearchMerchantItem>.of(
              state.value?.allMerchants ?? optimisticMerchants,
            );
        confirmedMerchants[index] = target.copyWith(
          isFavorite: confirmedFavorite,
        );
        state = AsyncData<SearchViewState>(
          current.copyWith(allMerchants: confirmedMerchants),
        );
      }
    } catch (e) {
      // Rollback al estado anterior
      final List<SearchMerchantItem> rollbackMerchants =
          List<SearchMerchantItem>.of(current.allMerchants);
      rollbackMerchants[index] = target;
      state = AsyncData<SearchViewState>(
        current.copyWith(allMerchants: rollbackMerchants),
      );
      rethrow;
    }
  }

  Future<void> refresh() async {
    _debounceTimer?.cancel();
    state = const AsyncLoading<SearchViewState>();
    state = await AsyncValue.guard(() async {
      final SearchRepository repository = ref.read(searchRepositoryProvider);
      final SearchCatalogData catalog = await repository.fetchSearchCatalog();
      return SearchViewState(
        recentSearches: catalog.recentSearches,
        allMerchants: catalog.merchants,
      );
    });
  }
}

/// Provider del controlador de la pantalla Buscar.
final AsyncNotifierProvider<SearchController, SearchViewState>
searchControllerProvider =
    AsyncNotifierProvider<SearchController, SearchViewState>(
      SearchController.new,
      retry: (int retryCount, Object error) => null,
    );
