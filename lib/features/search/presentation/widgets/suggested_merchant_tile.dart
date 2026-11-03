import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/core/utils/money_formatter.dart';
import 'package:clinapp/features/search/domain/search_models.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';
import 'package:clinapp/shared/widgets/price_text.dart';

/// Tarjeta horizontal de comercio sugerido con bloque de plato insignia.
class SuggestedMerchantTile extends StatelessWidget {
  const SuggestedMerchantTile({
    required this.merchant,
    required this.onTap,
    required this.onToggleFavorite,
    super.key,
  });

  final SearchMerchantItem merchant;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool isFreeDelivery = merchant.deliveryFeeCents == 0;
    final SignatureDish? dish = merchant.signatureDish;
    final String favoriteSemantics = merchant.isFavorite
        ? '${AppStrings.homeRemoveFavoriteSemantics} ${merchant.name}'
        : '${AppStrings.catalogFavoriteSemantics} ${merchant.name}';

    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _MerchantCoverThumbnail(
                accentColor: merchant.accentColor,
                rating: merchant.rating,
              ),
              const SizedBox(width: AppSpacing.md - 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            merchant.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelLg.copyWith(
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                        GlassButton.icon(
                          icon: LucideIcons.heart,
                          semanticLabel: favoriteSemantics,
                          onPressed: onToggleFavorite,
                        ),
                      ],
                    ),
                    Text(
                      merchant.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              LucideIcons.clock,
                              size: 13,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${merchant.etaRange}'
                              '${AppStrings.homeMinutesSuffix}',
                              style: AppTypography.bodySm.copyWith(
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          isFreeDelivery
                              ? AppStrings.homeFreeDelivery
                              : '${AppStrings.homeDeliveryPrefix}'
                                    '${MoneyFormatter.format(merchant.deliveryFeeCents)}',
                          style: AppTypography.bodySm.copyWith(
                            color: isFreeDelivery
                                ? AppColors.success
                                : palette.textSecondary,
                            fontWeight: isFreeDelivery
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (dish != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md - 4),
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.glassFill2,
                borderRadius: AppRadii.baseAll,
                border: Border.all(color: palette.rimMedium),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md - 4,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      dish.isChefRecommendation
                          ? LucideIcons.flame
                          : LucideIcons.utensils,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            dish.badgeLabel,
                            style: AppTypography.labelSm.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                          Text(
                            dish.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelMd.copyWith(
                              color: palette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    PriceText(
                      cents: dish.priceCents,
                      style: AppTypography.labelLg,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MerchantCoverThumbnail extends StatelessWidget {
  const _MerchantCoverThumbnail({
    required this.accentColor,
    required this.rating,
  });

  final Color accentColor;
  final double rating;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return SizedBox.square(
      dimension: 80,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadii.baseAll,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  accentColor.withValues(alpha: palette.isDark ? 0.45 : 0.25),
                  palette.surfaceRest,
                ],
              ),
              border: Border.all(color: palette.rimMedium),
            ),
            child: Center(
              child: Icon(
                LucideIcons.utensilsCrossed,
                size: 26,
                color: palette.textSecondary,
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.canvas.withValues(alpha: 0.85),
                borderRadius: AppRadii.pillAll,
                border: Border.all(color: palette.rimMedium),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      LucideIcons.star,
                      size: 10,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      rating.toStringAsFixed(1),
                      style: AppTypography.labelSm.copyWith(
                        fontSize: 10,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
