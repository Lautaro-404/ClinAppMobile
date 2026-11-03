import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Categoría del carrusel horizontal (`public.categories`).
@immutable
class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.name,
    required this.emoji,
  });

  final String id;
  final String name;
  final String emoji;
}

/// Datos del banner promocional destacado (`public.marketing_banners` / `coupons`).
@immutable
class PromoBannerData {
  const PromoBannerData({
    required this.id,
    required this.badgeLabel,
    required this.title,
    required this.couponPrefix,
    required this.couponCode,
    required this.ctaLabel,
  });

  final String id;
  final String badgeLabel;
  final String title;
  final String couponPrefix;
  final String couponCode;
  final String ctaLabel;
}

/// Resumen del último pedido entregado del usuario (`public.orders`).
@immutable
class LastOrderSummary {
  const LastOrderSummary({
    required this.orderId,
    required this.merchantId,
    required this.merchantName,
    required this.itemsSummary,
    required this.totalCents,
    required this.deliveredAt,
    this.onTime = true,
  });

  final String orderId;
  final String merchantId;
  final String merchantName;
  final String itemsSummary;
  final int totalCents;
  final DateTime deliveredAt;
  final bool onTime;
}

/// Tarjeta de comercio en la sección "Cerca tuyo" (`public.merchants`).
@immutable
class MerchantSummary {
  const MerchantSummary({
    required this.id,
    required this.name,
    required this.tagLabel,
    required this.rating,
    required this.reviewCount,
    required this.minMinutes,
    required this.maxMinutes,
    required this.deliveryFeeCents,
    required this.categoryIds,
    required this.accentColor,
    this.bannerUrl,
    this.isPromoTag = false,
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final String tagLabel;
  final double rating;
  final int reviewCount;
  final int minMinutes;
  final int maxMinutes;

  /// Costo de envío en centavos (`0` equivale a "Envío gratis").
  final int deliveryFeeCents;
  final List<String> categoryIds;
  final Color accentColor;
  final String? bannerUrl;
  final bool isPromoTag;
  final bool isFavorite;

  String get etaRange => '$minMinutes-$maxMinutes';

  MerchantSummary copyWith({bool? isFavorite}) {
    return MerchantSummary(
      id: id,
      name: name,
      tagLabel: tagLabel,
      rating: rating,
      reviewCount: reviewCount,
      minMinutes: minMinutes,
      maxMinutes: maxMinutes,
      deliveryFeeCents: deliveryFeeCents,
      categoryIds: categoryIds,
      accentColor: accentColor,
      bannerUrl: bannerUrl,
      isPromoTag: isPromoTag,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// Datos agregados que consume la pantalla Inicio.
@immutable
class HomeFeedData {
  const HomeFeedData({
    required this.userName,
    required this.deliveryAddress,
    required this.isOnline,
    required this.categories,
    required this.promoBanner,
    required this.merchants,
    this.lastOrder,
  });

  final String userName;
  final String deliveryAddress;
  final bool isOnline;
  final List<CategoryItem> categories;
  final PromoBannerData promoBanner;
  final LastOrderSummary? lastOrder;
  final List<MerchantSummary> merchants;

  HomeFeedData copyWith({List<MerchantSummary>? merchants}) {
    return HomeFeedData(
      userName: userName,
      deliveryAddress: deliveryAddress,
      isOnline: isOnline,
      categories: categories,
      promoBanner: promoBanner,
      lastOrder: lastOrder,
      merchants: merchants ?? this.merchants,
    );
  }
}
