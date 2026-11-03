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
import 'package:clinapp/shared/widgets/glass_button.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';
import 'package:clinapp/shared/widgets/glass_text_field.dart';

/// Tarjeta Liquid Glass para ingresar y validar cupones de descuento.
class CheckoutCouponSection extends StatelessWidget {
  const CheckoutCouponSection({
    required this.controller,
    required this.appliedCoupon,
    required this.couponError,
    required this.isValidating,
    required this.onApplyTap,
    required this.onRemoveTap,
    super.key,
  });

  final TextEditingController controller;
  final AppliedCoupon? appliedCoupon;
  final String? couponError;
  final bool isValidating;
  final VoidCallback onApplyTap;
  final VoidCallback onRemoveTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                LucideIcons.ticket,
                color: AppColors.accent,
                size: AppSpacing.md,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  AppStrings.checkoutCouponTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLg.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
              ),
              if (appliedCoupon != null)
                Semantics(
                  button: true,
                  label: AppStrings.checkoutCouponRemove,
                  child: InkWell(
                    onTap: onRemoveTap,
                    borderRadius: AppRadii.pillAll,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Text(
                        AppStrings.checkoutCouponRemove,
                        style: AppTypography.labelSm.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: GlassTextField(
                  controller: controller,
                  hintText: AppStrings.checkoutCouponHint,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onApplyTap(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GlassButton.secondary(
                label: AppStrings.checkoutCouponApply,
                isLoading: isValidating,
                onPressed: isValidating ? null : onApplyTap,
              ),
            ],
          ),
          if (couponError != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                const Icon(
                  LucideIcons.circleAlert,
                  color: AppColors.danger,
                  size: AppSpacing.md,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    couponError!,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (appliedCoupon != null &&
              appliedCoupon!.discountCents > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.successBloom,
                borderRadius: AppRadii.baseAll,
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    LucideIcons.badgeCheck,
                    color: AppColors.success,
                    size: AppSpacing.md,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${AppStrings.checkoutCouponAppliedPrefix}${appliedCoupon!.code}${AppStrings.checkoutCouponAppliedSuffix}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '-${MoneyFormatter.format(appliedCoupon!.discountCents)}',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
