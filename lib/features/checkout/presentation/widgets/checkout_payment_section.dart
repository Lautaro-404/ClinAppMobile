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

/// Tarjeta Liquid Glass con las opciones de método de pago.
class CheckoutPaymentSection extends StatelessWidget {
  const CheckoutPaymentSection({
    required this.selectedMethod,
    required this.onSelectMethod,
    this.clinpayBalanceCents = 450000,
    this.orderTotalCents = 0,
    super.key,
  });

  final CheckoutPaymentMethod selectedMethod;
  final ValueChanged<CheckoutPaymentMethod> onSelectMethod;
  final int clinpayBalanceCents;
  final int orderTotalCents;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool hasEnoughClinPay = clinpayBalanceCents >= orderTotalCents;
    final String formattedClinPayBalance = MoneyFormatter.format(
      clinpayBalanceCents,
    );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                LucideIcons.wallet,
                color: AppColors.accent,
                size: AppSpacing.md,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  AppStrings.checkoutPaymentTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLg.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    LucideIcons.lock,
                    color: AppColors.success,
                    size: AppSpacing.md,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    AppStrings.checkoutProtectedBadge,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _PaymentMethodTile(
            title: AppStrings.checkoutMethodCashTitle,
            subtitle: AppStrings.checkoutMethodCashSubtitle,
            icon: LucideIcons.coins,
            selected: selectedMethod == CheckoutPaymentMethod.cash,
            onTap: () => onSelectMethod(CheckoutPaymentMethod.cash),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PaymentMethodTile(
            title: AppStrings.checkoutMethodClinPayTitle,
            subtitle: hasEnoughClinPay
                ? '${AppStrings.checkoutClinPayBalanceAvailable}$formattedClinPayBalance'
                : AppStrings.checkoutClinPayInsufficientBalance,
            icon: LucideIcons.wallet,
            selected: selectedMethod == CheckoutPaymentMethod.clinPay,
            isWarning: !hasEnoughClinPay,
            onTap: () => onSelectMethod(CheckoutPaymentMethod.clinPay),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PaymentMethodTile(
            title: AppStrings.checkoutMethodMpTitle,
            subtitle:
                '${AppStrings.checkoutMethodMpSubtitle} · ${AppStrings.checkoutMethodMpPhase6Notice}',
            icon: LucideIcons.banknote,
            selected: selectedMethod == CheckoutPaymentMethod.mercadoPago,
            onTap: () => onSelectMethod(CheckoutPaymentMethod.mercadoPago),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.isWarning = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Semantics(
      button: true,
      selected: selected,
      label: '$title, $subtitle',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.baseAll,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTapTarget,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: selected ? palette.glassFill2 : palette.glassFill1,
                borderRadius: AppRadii.baseAll,
                border: Border.all(
                  color: selected ? AppColors.accent : palette.rimMedium,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: AppSpacing.xl,
                    height: AppSpacing.xl,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.accent.withValues(alpha: 0.20)
                          : palette.glassFill1,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: AppSpacing.md,
                      color: selected
                          ? AppColors.accent
                          : (isWarning
                                ? AppColors.warning
                                : palette.textSecondary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelMd.copyWith(
                            color: palette.textPrimary,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm.copyWith(
                            color: isWarning
                                ? AppColors.warning
                                : palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    width: AppSpacing.lg,
                    height: AppSpacing.lg,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.accent : palette.glassFill1,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? AppColors.accent : palette.rimMedium,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            LucideIcons.check,
                            size: AppSpacing.md,
                            color: AppColors.onAccent,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
