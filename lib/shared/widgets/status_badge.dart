import 'package:flutter/material.dart';

import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';

/// Variantes semánticas de [StatusBadge].
enum StatusBadgeTone { success, warning, danger, accent }

/// Insignia tipo píldora para estados ("EN LÍNEA", "Entregado", "En cocina").
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    super.key,
    this.tone = StatusBadgeTone.success,
    this.showDot = true,
    this.icon,
  });

  final String label;
  final StatusBadgeTone tone;
  final bool showDot;
  final IconData? icon;

  Color get _foreground => switch (tone) {
    StatusBadgeTone.success => AppColors.success,
    StatusBadgeTone.warning => AppColors.warning,
    StatusBadgeTone.danger => AppColors.danger,
    StatusBadgeTone.accent => AppColors.accent,
  };

  @override
  Widget build(BuildContext context) {
    final Color fg = _foreground;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.18),
        borderRadius: AppRadii.pillAll,
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: AppSpacing.xs),
            ] else if (showDot) ...<Widget>[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.xs + 2),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSm.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
