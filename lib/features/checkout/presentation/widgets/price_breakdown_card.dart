import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/core/utils/money_formatter.dart';
import 'package:clinapp/features/checkout/domain/checkout_models.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';

/// Tarjeta Liquid Glass con el desglose financiero del pedido.
/// Distingue entre estimación local y cotización verificada por el servidor.
class PriceBreakdownCard extends StatelessWidget {
  const PriceBreakdownCard({required this.quote, super.key});

  final CheckoutQuote quote;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool isFreeDelivery = quote.deliveryFeeCents == 0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            AppStrings.checkoutBreakdownTitle,
            style: AppTypography.labelLg.copyWith(color: palette.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  AppStrings.checkoutSubtotalLabel,
                  style: AppTypography.bodyMd.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                MoneyFormatter.format(quote.subtotalCents),
                style: AppTypography.bodyMd.copyWith(
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.xs,
                  children: <Widget>[
                    Text(
                      AppStrings.checkoutDeliveryLabel,
                      style: AppTypography.bodyMd.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                    if (isFreeDelivery)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.successBloom,
                          borderRadius: AppRadii.smAll,
                        ),
                        child: Text(
                          AppStrings.checkoutFreeBadge,
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                MoneyFormatter.format(quote.deliveryFeeCents),
                style: AppTypography.bodyMd.copyWith(
                  color: isFreeDelivery
                      ? AppColors.success
                      : palette.textPrimary,
                  fontWeight: isFreeDelivery
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
          if (quote.discountCents > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    AppStrings.checkoutDiscountLabel,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '-${MoneyFormatter.format(quote.discountCents)}',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: palette.glassFill2,
              borderRadius: AppRadii.baseAll,
              border: Border.all(color: palette.rimMedium),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            AppStrings.checkoutTotalLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headlineMd.copyWith(
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            AppStrings.checkoutTaxesIncluded,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySm.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          MoneyFormatter.format(quote.totalCents),
                          style: AppTypography.displayLg.copyWith(
                            color: AppColors.accentGlow,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: <Widget>[
                    Icon(
                      quote.isServerConfirmed
                          ? LucideIcons.shieldCheck
                          : LucideIcons.refreshCw,
                      size: AppSpacing.md,
                      color: quote.isServerConfirmed
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        quote.isServerConfirmed
                            ? AppStrings.checkoutServerVerifiedNote
                            : AppStrings.checkoutEstimatedNote,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSm.copyWith(
                          color: quote.isServerConfirmed
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
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
