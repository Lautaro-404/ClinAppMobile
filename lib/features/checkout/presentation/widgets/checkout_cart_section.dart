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

/// Tarjeta Liquid Glass con el comercio seleccionado y la lista de ítems del carrito.
class CheckoutCartSection extends StatelessWidget {
  const CheckoutCartSection({
    required this.merchantName,
    required this.merchantTagline,
    required this.items,
    required this.totalItemsCount,
    required this.onQuantityChange,
    super.key,
  });

  final String merchantName;
  final String merchantTagline;
  final List<CheckoutCartItem> items;
  final int totalItemsCount;
  final void Function(String productId, int delta) onQuantityChange;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final String countLabel = totalItemsCount == 1
        ? '1 ${AppStrings.checkoutItemsSingleSuffix}'
        : '$totalItemsCount ${AppStrings.checkoutItemsPluralSuffix}';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: AppSpacing.xl,
                height: AppSpacing.xl,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.utensils,
                  color: AppColors.accent,
                  size: AppSpacing.md,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      merchantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLg.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      merchantTagline,
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: palette.glassFill2,
                  borderRadius: AppRadii.pillAll,
                ),
                child: Text(
                  countLabel,
                  style: AppTypography.labelSm.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (int i = 0; i < items.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _CartItemRow(
              item: items[i],
              onDecrease: () => onQuantityChange(items[i].productId, -1),
              onIncrease: () => onQuantityChange(items[i].productId, 1),
            ),
          ],
        ],
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.item,
    required this.onDecrease,
    required this.onIncrease,
  });

  final CheckoutCartItem item;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  IconData _iconForItem(String id) {
    if (id.contains('ensalada')) {
      return LucideIcons.salad;
    }
    if (id.contains('malbec') || id.contains('vino')) {
      return LucideIcons.wine;
    }
    return LucideIcons.flame;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: palette.glassFill2,
        borderRadius: AppRadii.baseAll,
        border: Border.all(color: palette.rimMedium),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: AppSpacing.minTapTarget,
            height: AppSpacing.minTapTarget,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  AppColors.accent.withValues(
                    alpha: palette.isDark ? 0.25 : 0.15,
                  ),
                  palette.surfaceRest,
                ],
              ),
              borderRadius: AppRadii.baseAll,
              border: Border.all(color: palette.rimMedium),
            ),
            child: Icon(
              _iconForItem(item.productId),
              color: AppColors.accentGlow,
              size: AppSpacing.lg,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMd.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  MoneyFormatter.format(item.lineTotalCents),
                  style: AppTypography.labelLg.copyWith(
                    color: AppColors.accentGlow,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            decoration: BoxDecoration(
              color: palette.surfaceRest.withValues(
                alpha: palette.isDark ? 0.85 : 0.95,
              ),
              borderRadius: AppRadii.pillAll,
              border: Border.all(color: palette.rimMedium),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _StepperIconButton(
                  icon: LucideIcons.minus,
                  semanticLabel:
                      '${AppStrings.checkoutDecreaseQtySemantics} ${item.name}',
                  onTap: onDecrease,
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: AppSpacing.md),
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelMd.copyWith(
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                _StepperIconButton(
                  icon: LucideIcons.plus,
                  semanticLabel:
                      '${AppStrings.checkoutIncreaseQtySemantics} ${item.name}',
                  onTap: onIncrease,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperIconButton extends StatelessWidget {
  const _StepperIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.pillAll,
          child: SizedBox(
            width: AppSpacing.minTapTarget,
            height: AppSpacing.minTapTarget,
            child: Center(
              child: Container(
                width: AppSpacing.lg,
                height: AppSpacing.lg,
                decoration: BoxDecoration(
                  color: palette.glassFill2,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: AppSpacing.md,
                  color: palette.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
