import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';

/// Barra de estado operativo y tiempo de cocina para el comercio.
class MerchantStatusBar extends StatelessWidget {
  const MerchantStatusBar({
    super.key,
    required this.isOpen,
    required this.onToggleOpen,
  });

  final bool isOpen;
  final ValueChanged<bool> onToggleOpen;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs + 2),
            decoration: BoxDecoration(
              color: isOpen
                  ? const Color.fromRGBO(16, 185, 129, 0.15)
                  : palette.glassFill2,
              borderRadius: AppRadii.pillAll,
            ),
            child: Icon(
              LucideIcons.chefHat,
              color: isOpen ? AppColors.success : palette.textTertiary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  AppStrings.merchantAvgPrepTime,
                  style: AppTypography.labelMd.copyWith(
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(232, 82, 58, 0.20),
                        borderRadius: AppRadii.pillAll,
                      ),
                      child: Text(
                        AppStrings.merchantHighDemandTag,
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isOpen,
            activeThumbColor: AppColors.accent,
            onChanged: onToggleOpen,
          ),
        ],
      ),
    );
  }
}
