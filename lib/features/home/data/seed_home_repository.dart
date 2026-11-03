import 'package:flutter/painting.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/features/home/domain/home_models.dart';
import 'package:clinapp/features/home/domain/home_repository.dart';

/// Implementación autónoma de [HomeRepository] que provee datos semilla
/// de General Alvear para desarrollo offline, pruebas o fallback cuando
/// el backend no está disponible.
class SeedHomeRepository implements HomeRepository {
  SeedHomeRepository({Set<String>? initialFavorites})
    : _localFavorites = initialFavorites ?? <String>{};

  final Set<String> _localFavorites;

  static const String catPizzas = 'c0000001-0000-4000-8000-000000000001';
  static const String catBurgers = 'c0000002-0000-4000-8000-000000000002';
  static const String catEmpanadas = 'c0000003-0000-4000-8000-000000000003';
  static const String catIceCream = 'c0000004-0000-4000-8000-000000000004';
  static const String catDrinks = 'c0000005-0000-4000-8000-000000000005';
  static const String catPharmacy = 'c0000006-0000-4000-8000-000000000006';

  @override
  Future<HomeFeedData> fetchHomeFeed() async {
    final DateTime yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .copyWith(hour: 21, minute: 30);

    return HomeFeedData(
      userName: AppStrings.homeDefaultUserName,
      deliveryAddress: AppStrings.homeDefaultAddress,
      isOnline: true,
      categories: const <CategoryItem>[
        CategoryItem(id: catPizzas, name: 'Pizzas', emoji: '🍕'),
        CategoryItem(id: catBurgers, name: 'Hamburguesas', emoji: '🍔'),
        CategoryItem(id: catEmpanadas, name: 'Empanadas', emoji: '🥟'),
        CategoryItem(id: catIceCream, name: 'Helados', emoji: '🍦'),
        CategoryItem(id: catDrinks, name: 'Bebidas', emoji: '🍷'),
        CategoryItem(id: catPharmacy, name: 'Farmacia', emoji: '💊'),
      ],
      promoBanner: const PromoBannerData(
        id: 'promo-alvearya',
        badgeLabel: AppStrings.homePromoDefaultBadge,
        title: AppStrings.homePromoDefaultTitle,
        couponPrefix: AppStrings.homePromoCouponPrefix,
        couponCode: 'ALVEARYA',
        ctaLabel: AppStrings.homePromoCta,
      ),
      lastOrder: LastOrderSummary(
        orderId: 'ord-4820',
        merchantId: 'm2222222-2222-4222-8222-222222222222',
        merchantName: 'Empanadas Don Pedro',
        itemsSummary: '12 Empanadas mendocinas a cuchillo',
        totalCents: 1240000,
        deliveredAt: yesterday,
      ),
      merchants: <MerchantSummary>[
        MerchantSummary(
          id: 'm1111111-1111-4111-8111-111111111111',
          name: 'Pizzería La Alvearense',
          tagLabel: 'Pizzas a la piedra',
          rating: 4.9,
          reviewCount: 184,
          minMinutes: 20,
          maxMinutes: 30,
          deliveryFeeCents: 85000,
          categoryIds: const <String>[catPizzas],
          accentColor: AppColors.accent,
          isFavorite: _localFavorites.contains(
            'm1111111-1111-4111-8111-111111111111',
          ),
        ),
        MerchantSummary(
          id: 'm3333333-3333-4333-8333-333333333333',
          name: 'Burgers Alvear Craft',
          tagLabel: 'Super promo',
          isPromoTag: true,
          rating: 4.8,
          reviewCount: 320,
          minMinutes: 25,
          maxMinutes: 35,
          deliveryFeeCents: 0,
          categoryIds: const <String>[catBurgers],
          accentColor: const Color(0xFFD97706),
          isFavorite: _localFavorites.contains(
            'm3333333-3333-4333-8333-333333333333',
          ),
        ),
        MerchantSummary(
          id: 'm4444444-4444-4444-8444-444444444444',
          name: 'Heladería Colonial',
          tagLabel: 'Artesanal',
          rating: 4.9,
          reviewCount: 410,
          minMinutes: 15,
          maxMinutes: 25,
          deliveryFeeCents: 60000,
          categoryIds: const <String>[catIceCream],
          accentColor: AppColors.success,
          isFavorite: _localFavorites.contains(
            'm4444444-4444-4444-8444-444444444444',
          ),
        ),
      ],
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
