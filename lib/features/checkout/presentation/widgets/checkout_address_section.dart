import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/features/checkout/domain/checkout_models.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';
import 'package:clinapp/shared/widgets/glass_text_field.dart';

/// Tarjeta Liquid Glass con la dirección de entrega en General Alvear,
/// tiempo estimado y campo de notas para el repartidor.
class CheckoutAddressSection extends StatelessWidget {
  const CheckoutAddressSection({
    required this.address,
    required this.notesController,
    required this.onChangeAddressTap,
    required this.onNotesChanged,
    super.key,
  });

  final DeliveryAddressOption address;
  final TextEditingController notesController;
  final VoidCallback onChangeAddressTap;
  final ValueChanged<String> onNotesChanged;

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
                LucideIcons.navigation,
                color: AppColors.accent,
                size: AppSpacing.md,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  AppStrings.checkoutAddressTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLg.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: AppStrings.checkoutAddressChange,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: onChangeAddressTap,
                    borderRadius: AppRadii.pillAll,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: AppSpacing.minTapTarget,
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: palette.glassFill2,
                            borderRadius: AppRadii.pillAll,
                            border: Border.all(color: palette.rimMedium),
                          ),
                          child: Text(
                            AppStrings.checkoutAddressChange,
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.accentGlow,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: palette.glassFill2,
              borderRadius: AppRadii.baseAll,
              border: Border.all(color: palette.rimMedium),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: AppSpacing.xl,
                  height: AppSpacing.xl,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.mapPin,
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
                        address.addressLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMd.copyWith(
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        address.city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySm.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: <Widget>[
                          const Icon(
                            LucideIcons.clock,
                            color: AppColors.success,
                            size: AppSpacing.md,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              '${AppStrings.checkoutEstimatedDeliveryPrefix}${address.etaRangeText}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
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
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.checkoutRiderNotesLabel,
            style: AppTypography.labelSm.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          GlassTextField(
            controller: notesController,
            hintText: AppStrings.checkoutRiderNotesHint,
            leadingIcon: LucideIcons.filePenLine,
            onChanged: onNotesChanged,
          ),
        ],
      ),
    );
  }
}
