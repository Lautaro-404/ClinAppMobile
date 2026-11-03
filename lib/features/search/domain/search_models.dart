import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Filtros rápidos combinables en la pantalla Buscar.
enum SearchFilter { openNow, freeDelivery, topRated, fastest }

/// Plato insignia o recomendado del chef de un comercio (`public.products`).
@immutable
class SignatureDish {
  const SignatureDish({
    required this.name,
    required this.priceCents,
    required this.badgeLabel,
    this.isChefRecommendation = false,
  });

  final String name;
  final int priceCents;
  final String badgeLabel;
  final bool isChefRecommendation;
}

/// Comercio sugerido o encontrado en la pantalla Buscar (`public.merchants`).
@immutable
class SearchMerchantItem {
  const SearchMerchantItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.rating,
    required this.minMinutes,
    required this.maxMinutes,
    required this.deliveryFeeCents,
    required this.accentColor,
    this.isOpen = true,
    this.isFavorite = false,
    this.signatureDish,
    this.searchKeywords = const <String>[],
  });

  final String id;
  final String name;
  final String subtitle;
  final double rating;
  final int minMinutes;
  final int maxMinutes;
  final int deliveryFeeCents;
  final Color accentColor;
  final bool isOpen;
  final bool isFavorite;
  final SignatureDish? signatureDish;
  final List<String> searchKeywords;

  String get etaRange => '$minMinutes-$maxMinutes';

  /// Evalúa si el comercio o sus platos coinciden con el texto [query].
  bool matchesQuery(String query) {
    final String normalized = _normalize(query);
    if (normalized.isEmpty) {
      return true;
    }
    if (_normalize(name).contains(normalized) ||
        _normalize(subtitle).contains(normalized)) {
      return true;
    }
    final SignatureDish? dish = signatureDish;
    if (dish != null && _normalize(dish.name).contains(normalized)) {
      return true;
    }
    for (final String keyword in searchKeywords) {
      if (_normalize(keyword).contains(normalized)) {
        return true;
      }
    }
    return false;
  }

  /// Evalúa si el comercio cumple todos los [activeFilters].
  bool matchesFilters(Set<SearchFilter> activeFilters) {
    if (activeFilters.contains(SearchFilter.openNow) && !isOpen) {
      return false;
    }
    if (activeFilters.contains(SearchFilter.freeDelivery) &&
        deliveryFeeCents > 0) {
      return false;
    }
    if (activeFilters.contains(SearchFilter.topRated) && rating < 4.8) {
      return false;
    }
    if (activeFilters.contains(SearchFilter.fastest) && maxMinutes > 30) {
      return false;
    }
    return true;
  }

  SearchMerchantItem copyWith({bool? isFavorite}) {
    return SearchMerchantItem(
      id: id,
      name: name,
      subtitle: subtitle,
      rating: rating,
      minMinutes: minMinutes,
      maxMinutes: maxMinutes,
      deliveryFeeCents: deliveryFeeCents,
      accentColor: accentColor,
      isOpen: isOpen,
      isFavorite: isFavorite ?? this.isFavorite,
      signatureDish: signatureDish,
      searchKeywords: searchKeywords,
    );
  }

  static String _normalize(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }
}

/// Catálogo inicial para la pantalla Buscar.
@immutable
class SearchCatalogData {
  const SearchCatalogData({
    required this.recentSearches,
    required this.merchants,
  });

  final List<String> recentSearches;
  final List<SearchMerchantItem> merchants;
}
