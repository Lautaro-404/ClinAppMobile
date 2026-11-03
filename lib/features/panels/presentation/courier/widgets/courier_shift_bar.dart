import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';

/// Barra de estado del turno activo con GPS y switch de disponibilidad.
class CourierShiftBar extends StatelessWidget {
  const CourierShiftBar({
    super.key,
    required this.isOnline,
    required this.assignedCount,
    required this.isGpsActive,
    required this.onToggleShift,
  });

  final bool isOnline;
  final int assignedCount;
  final bool isGpsActive;
  final ValueChanged<bool> onToggleShift;

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
              color: isOnline
                  ? const Color.fromRGBO(16, 185, 129, 0.15)
                  : palette.glassFill2,
              borderRadius: AppRadii.pillAll,
            ),
            child: Icon(
              LucideIcons.bike,
              color: isOnline ? AppColors.success : palette.textTertiary,
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
                  '${AppStrings.courierShiftActive} · $assignedCount ${AppStrings.courierShiftSubtitle}',
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
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isGpsActive
                            ? AppColors.success
                            : palette.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.courierGpsActive,
                      style: AppTypography.labelSm.copyWith(
                        color: palette.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isOnline,
            activeThumbColor: AppColors.accent,
            onChanged: onToggleShift,
          ),
        ],
      ),
    );
  }
}
