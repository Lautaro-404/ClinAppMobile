import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/utils/storage_image_resolver.dart';
import 'package:clinapp/features/home/domain/home_models.dart';

/// DTO para la tabla `categories`.
class CategoryDto {
  const CategoryDto({
    required this.id,
    required this.name,
    required this.emoji,
  });

  factory CategoryDto.fromJson(Map<String, Object?> json) {
    return CategoryDto(
      id: _readString(json['id']),
      name: _readString(json['name']),
      emoji: _readString(json['emoji'], fallback: '🍽️'),
    );
  }

  final String id;
  final String name;
  final String emoji;

  CategoryItem toDomain() => CategoryItem(id: id, name: name, emoji: emoji);
}

/// DTO para `merchants` o `merchants_catalog_view`.
class MerchantSummaryDto {
  const MerchantSummaryDto({
    required this.id,
    required this.name,
    required this.description,
    required this.tiempoEstimadoMin,
    required this.costoEnvioBaseCents,
    required this.rating,
    required this.reviewCount,
    required this.categoryIds,
    this.bannerUrl,
    this.isOpen = true,
  });

  factory MerchantSummaryDto.fromJson(Map<String, Object?> json) {
    final int baseEta = _readInt(json['tiempo_estimado_min'], fallback: 25);
    final List<String> categories = <String>[];

    // Maneja array JSON directo (desde la vista) o relación anidada (desde PostgREST directo)
    final Object? rawCategoryIds = json['category_ids'];
    if (rawCategoryIds is List<Object?>) {
      for (final Object? item in rawCategoryIds) {
        if (item is String && item.isNotEmpty) {
          categories.add(item);
        }
      }
    } else {
      final Object? rawMerchantCategories = json['merchant_categories'];
      if (rawMerchantCategories is List<Object?>) {
        for (final Object? item in rawMerchantCategories) {
          if (item is Map<String, Object?>) {
            final String catId = _readString(item['category_id']);
            if (catId.isNotEmpty) {
              categories.add(catId);
            }
          }
        }
      }
    }

    // Rating y opiniones agregadas
    double rating = 4.9;
    int reviewCount = 0;
    if (json.containsKey('rating') && json['rating'] != null) {
      rating = _readDouble(json['rating'], fallback: 4.9);
      reviewCount = _readInt(json['review_count'], fallback: 1);
    } else {
      // Fallback si viene de reviews relacionales directas
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
          reviewCount = count;
        }
      }
    }

    final bool isOpenValue = json.containsKey('is_open')
        ? json['is_open'] == true
        : _readString(json['estado']) == 'activo';

    return MerchantSummaryDto(
      id: _readString(json['id']),
      name: _readString(json['name']),
      description: _readString(json['description'], fallback: 'Destacado'),
      tiempoEstimadoMin: baseEta,
      costoEnvioBaseCents: _readInt(json['costo_envio_base']),
      rating: rating,
      reviewCount: reviewCount > 0 ? reviewCount : 1,
      categoryIds: categories,
      bannerUrl: _readNullableString(json['banner_url']),
      isOpen: isOpenValue,
    );
  }

  final String id;
  final String name;
  final String description;
  final int tiempoEstimadoMin;
  final int costoEnvioBaseCents;
  final double rating;
  final int reviewCount;
  final List<String> categoryIds;
  final String? bannerUrl;
  final bool isOpen;

  MerchantSummary toDomain({required bool isFavorite, SupabaseClient? client}) {
    final int minEta = (tiempoEstimadoMin - 5).clamp(10, 90);
    final int maxEta = (tiempoEstimadoMin + 5).clamp(15, 120);
    final String? resolvedBanner = StorageImageResolver.resolveMerchantImage(
      bannerUrl,
      client: client,
    );

    return MerchantSummary(
      id: id,
      name: name,
      tagLabel: description.isNotEmpty ? description : 'Destacado',
      rating: rating,
      reviewCount: reviewCount,
      minMinutes: minEta,
      maxMinutes: maxEta,
      deliveryFeeCents: costoEnvioBaseCents,
      categoryIds: categoryIds,
      accentColor: AppColors.accent,
      bannerUrl: resolvedBanner,
      isPromoTag: costoEnvioBaseCents == 0,
      isFavorite: isFavorite,
    );
  }
}

/// DTO para promociones (`marketing_banners` o `coupons`).
class PromoBannerDto {
  const PromoBannerDto({
    required this.id,
    required this.badgeLabel,
    required this.title,
    required this.couponPrefix,
    required this.couponCode,
    required this.ctaLabel,
  });

  factory PromoBannerDto.fromBannerJson(Map<String, Object?> json) {
    return PromoBannerDto(
      id: _readString(json['id']),
      badgeLabel: AppStrings.homePromoDefaultBadge,
      title: _readString(
        json['title'],
        fallback: AppStrings.homePromoDefaultTitle,
      ),
      couponPrefix: AppStrings.homePromoCouponPrefix,
      couponCode: _readString(json['subtitle'], fallback: 'ALVEARYA'),
      ctaLabel: AppStrings.homePromoCta,
    );
  }

  factory PromoBannerDto.fromCouponJson(Map<String, Object?> json) {
    final int percentage = _readInt(json['porcentaje'], fallback: 20);
    final String code = _readString(json['codigo'], fallback: 'ALVEARYA');
    return PromoBannerDto(
      id: _readString(json['id']),
      badgeLabel: '$percentage% OFF',
      title: 'Descuento especial en tu pedido',
      couponPrefix: AppStrings.homePromoCouponPrefix,
      couponCode: code,
      ctaLabel: AppStrings.homePromoCta,
    );
  }

  final String id;
  final String badgeLabel;
  final String title;
  final String couponPrefix;
  final String couponCode;
  final String ctaLabel;

  PromoBannerData toDomain() => PromoBannerData(
    id: id,
    badgeLabel: badgeLabel,
    title: title,
    couponPrefix: couponPrefix,
    couponCode: couponCode,
    ctaLabel: ctaLabel,
  );
}

/// DTO para el último pedido entregado del usuario (`orders`).
class LastOrderDto {
  const LastOrderDto({
    required this.orderId,
    required this.merchantId,
    required this.merchantName,
    required this.itemsSummary,
    required this.totalCents,
    required this.deliveredAt,
    this.onTime = true,
  });

  factory LastOrderDto.fromJson(Map<String, Object?> json) {
    final String orderId = _readString(json['id']);
    final String merchantId = _readString(json['merchant_id']);
    String merchantName = 'Comercio Alvearense';
    final Object? rawMerchant = json['merchants'];
    if (rawMerchant is Map<String, Object?>) {
      merchantName = _readString(rawMerchant['name'], fallback: merchantName);
    }

    final List<String> summaryParts = <String>[];
    final Object? rawItems = json['order_items'];
    if (rawItems is List<Object?>) {
      for (final Object? item in rawItems) {
        if (item is Map<String, Object?>) {
          final int qty = _readInt(item['quantity'], fallback: 1);
          String prodName = 'Producto';
          final Object? prod = item['products'];
          if (prod is Map<String, Object?>) {
            prodName = _readString(prod['name'], fallback: prodName);
          }
          summaryParts.add('$qty $prodName');
        }
      }
    }

    final String itemsSummary = summaryParts.isNotEmpty
        ? summaryParts.join(', ')
        : 'Pedido anterior';

    final String rawCreatedAt = _readString(json['created_at']);
    final DateTime deliveredAt =
        DateTime.tryParse(rawCreatedAt) ??
        DateTime.now().subtract(const Duration(days: 1));

    return LastOrderDto(
      orderId: orderId,
      merchantId: merchantId,
      merchantName: merchantName,
      itemsSummary: itemsSummary,
      totalCents: _readInt(json['total']),
      deliveredAt: deliveredAt,
    );
  }

  final String orderId;
  final String merchantId;
  final String merchantName;
  final String itemsSummary;
  final int totalCents;
  final DateTime deliveredAt;
  final bool onTime;

  LastOrderSummary toDomain() => LastOrderSummary(
    orderId: orderId,
    merchantId: merchantId,
    merchantName: merchantName,
    itemsSummary: itemsSummary,
    totalCents: totalCents,
    deliveredAt: deliveredAt,
    onTime: onTime,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Utilidades de casteo seguro para DTOs
// ─────────────────────────────────────────────────────────────────────────────

String _readString(Object? value, {String fallback = ''}) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return fallback;
}

String? _readNullableString(Object? value) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return null;
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
