import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';

/// Píldora de calificación de comercio (`★ 4.9 (184)`).
class RatingPill extends StatelessWidget {
  const RatingPill({required this.rating, super.key, this.reviewCount});

  final double rating;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final String formattedRating = rating.toStringAsFixed(1);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.18),
        borderRadius: AppRadii.pillAll,
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs / 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(LucideIcons.star, size: 13, color: AppColors.accent),
            const SizedBox(width: AppSpacing.xs),
            Text(
              formattedRating,
              style: AppTypography.labelMd.copyWith(color: AppColors.accent),
            ),
            if (reviewCount != null) ...<Widget>[
              const SizedBox(width: AppSpacing.xs),
              Text(
                '($reviewCount)',
                style: AppTypography.labelSm.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
