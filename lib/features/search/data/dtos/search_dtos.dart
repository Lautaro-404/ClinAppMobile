import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/features/search/domain/search_models.dart';

/// DTO para el plato insignia de un comercio.
class SignatureDishDto {
  const SignatureDishDto({
    required this.name,
    required this.priceCents,
    this.isChefRecommendation = false,
    this.badgeLabel,
  });

  factory SignatureDishDto.fromJson(Map<String, Object?> json) {
    final String name = _readString(json['name']);
    final int priceCents = _readInt(json['price'] ?? json['price_cents']);
    final bool isChef = json['is_chef_recommendation'] == true;

    return SignatureDishDto(
      name: name,
      priceCents: priceCents,
      isChefRecommendation: isChef,
      badgeLabel: isChef
          ? AppStrings.searchChefRecommendedLabel
          : AppStrings.searchSignatureDishLabel,
    );
  }

  final String name;
  final int priceCents;
  final bool isChefRecommendation;
  final String? badgeLabel;

  SignatureDish toDomain() {
    return SignatureDish(
      name: name,
      priceCents: priceCents,
      badgeLabel:
          badgeLabel ??
          (isChefRecommendation
              ? AppStrings.searchChefRecommendedLabel
              : AppStrings.searchSignatureDishLabel),
      isChefRecommendation: isChefRecommendation,
    );
  }
}

/// DTO para los comercios en la búsqueda (`merchants` o `merchants_catalog_view`).
class SearchMerchantItemDto {
  const SearchMerchantItemDto({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.rating,
    required this.tiempoEstimadoMin,
    required this.costoEnvioBaseCents,
    required this.isOpen,
    this.signatureDish,
    this.searchKeywords = const <String>[],
  });

  factory SearchMerchantItemDto.fromJson(Map<String, Object?> json) {
    final String id = _readString(json['id']);
    final String name = _readString(json['name']);
    final String subtitle = _readString(
      json['description'],
      fallback: 'Cocina local de General Alvear',
    );
    final int baseEta = _readInt(json['tiempo_estimado_min'], fallback: 25);
    final int deliveryFee = _readInt(json['costo_envio_base']);

    // Rating
    double rating = 4.8;
    if (json.containsKey('rating') && json['rating'] != null) {
      rating = _readDouble(json['rating'], fallback: 4.8);
    } else {
      final Object? rawReviews = json['reviews'];
      if (rawReviews is List<Object?> && rawReviews.isNotEmpty) {
        int sum = 0;
        int count = 0;
        for (final Object? r in rawReviews) {
          if (r is Map<String, Object?>) {
            final int stars = _readInt(r['rating']);
            if (stars > 0) {
              sum += stars;
              count++;
            }
          }
        }
        if (count > 0) {
          rating = sum / count;
        }
      }
    }

    final bool isOpen = json.containsKey('is_open')
        ? json['is_open'] == true
        : _readString(json['estado']) == 'activo';

    // Plato insignia y palabras clave
    SignatureDishDto? signatureDish;
    final List<String> keywords = <String>[];

    // Caso 1: Desde la vista optimizada
    final String signatureName = _readString(json['signature_dish_name']);
    if (signatureName.isNotEmpty) {
      final int dishPrice = _readInt(json['signature_dish_price']);
      signatureDish = SignatureDishDto(
        name: signatureName,
        priceCents: dishPrice,
      );
      keywords.add(signatureName);
    }

    // Caso 2: Desde PostgREST relacional directo con `menu_sections(products(...))`
    final Object? rawSections = json['menu_sections'];
    if (rawSections is List<Object?>) {
      for (final Object? sec in rawSections) {
        if (sec is Map<String, Object?>) {
          final Object? rawProducts = sec['products'];
          if (rawProducts is List<Object?>) {
            for (final Object? prod in rawProducts) {
              if (prod is Map<String, Object?>) {
                final String pName = _readString(prod['name']);
                final int pPrice = _readInt(prod['price']);
                if (pName.isNotEmpty) {
                  keywords.add(pName);
                  signatureDish ??= SignatureDishDto(
                    name: pName,
                    priceCents: pPrice,
                  );
                }
              }
            }
          }
        }
      }
    }

    return SearchMerchantItemDto(
      id: id,
      name: name,
      subtitle: subtitle,
      rating: rating,
      tiempoEstimadoMin: baseEta,
      costoEnvioBaseCents: deliveryFee,
      isOpen: isOpen,
      signatureDish: signatureDish,
      searchKeywords: keywords,
    );
  }

  final String id;
  final String name;
  final String subtitle;
  final double rating;
  final int tiempoEstimadoMin;
  final int costoEnvioBaseCents;
  final bool isOpen;
  final SignatureDishDto? signatureDish;
  final List<String> searchKeywords;

  SearchMerchantItem toDomain({
    required bool isFavorite,
    SupabaseClient? client,
  }) {
    final int minEta = (tiempoEstimadoMin - 5).clamp(10, 90);
    final int maxEta = (tiempoEstimadoMin + 5).clamp(15, 120);

    return SearchMerchantItem(
      id: id,
      name: name,
      subtitle: subtitle,
      rating: rating,
      minMinutes: minEta,
      maxMinutes: maxEta,
      deliveryFeeCents: costoEnvioBaseCents,
      accentColor: AppColors.accent,
      isOpen: isOpen,
      isFavorite: isFavorite,
      signatureDish: signatureDish?.toDomain(),
      searchKeywords: searchKeywords,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Utilidades de lectura segura
// ─────────────────────────────────────────────────────────────────────────────

String _readString(Object? value, {String fallback = ''}) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return fallback;
}

int _readInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

double _readDouble(Object? value, {double fallback = 0.0}) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}
