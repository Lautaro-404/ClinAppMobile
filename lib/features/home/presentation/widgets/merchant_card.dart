import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/core/utils/money_formatter.dart';
import 'package:clinapp/features/home/domain/home_models.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';
import 'package:clinapp/shared/widgets/rating_pill.dart';
import 'package:clinapp/shared/widgets/status_badge.dart';

/// Tarjeta de comercio de 28px en la sección "Cerca tuyo".
class MerchantCard extends StatelessWidget {
  const MerchantCard({
    required this.merchant,
    required this.onTap,
    required this.onToggleFavorite,
    super.key,
  });

  final MerchantSummary merchant;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool isFreeDelivery = merchant.deliveryFeeCents == 0;
    final String favoriteSemantics = merchant.isFavorite
        ? '${AppStrings.homeRemoveFavoriteSemantics} ${merchant.name}'
        : '${AppStrings.catalogFavoriteSemantics} ${merchant.name}';

    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: AppRadii.cardAll,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: 148,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadii.card),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        merchant.accentColor.withValues(
                          alpha: palette.isDark ? 0.42 : 0.25,
                        ),
                        palette.surfaceRest,
                        palette.canvas,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.store,
                      size: 44,
                      color: palette.textPrimary.withValues(alpha: 0.22),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.sm + 4,
                  left: AppSpacing.sm + 4,
                  child: StatusBadge(
                    label: merchant.isPromoTag
                        ? merchant.tagLabel.toUpperCase()
                        : merchant.tagLabel,
                    tone: merchant.isPromoTag
                        ? StatusBadgeTone.accent
                        : StatusBadgeTone.warning,
                    icon: merchant.isPromoTag ? LucideIcons.flame : null,
                    showDot: false,
                  ),
                ),
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: GlassButton.icon(
                    icon: LucideIcons.heart,
                    semanticLabel: favoriteSemantics,
                    onPressed: onToggleFavorite,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
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
                        style: AppTypography.headlineMd.copyWith(
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    RatingPill(
                      rating: merchant.rating,
                      reviewCount: merchant.reviewCount,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          LucideIcons.clock,
                          size: 15,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${merchant.etaRange}${AppStrings.homeMinutesSuffix}',
                          style: AppTypography.bodySm.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          isFreeDelivery
                              ? LucideIcons.circleCheck
                              : LucideIcons.bike,
                          size: 15,
                          color: isFreeDelivery
                              ? AppColors.success
                              : palette.textSecondary,
                        ),
                        const SizedBox(width: 4),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
