import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';

/// Banner de asistencia rápida y soporte local en General Alvear.
class OrderSupportBanner extends StatelessWidget {
  const OrderSupportBanner({required this.onSupportTap, super.key});

  final VoidCallback onSupportTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.glassFill2,
        borderRadius: AppRadii.cardAll,
        border: Border.all(color: palette.rimMedium),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.35),
              ),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.headset,
                size: 20,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  AppStrings.ordersSupportTitle,
                  style: AppTypography.labelMd.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  AppStrings.ordersSupportSubtitle,
                  style: AppTypography.bodySm.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GlassButton.secondary(
            label: AppStrings.ordersSupportAction,
            onPressed: onSupportTap,
          ),
        ],
      ),
    );
  }
}
