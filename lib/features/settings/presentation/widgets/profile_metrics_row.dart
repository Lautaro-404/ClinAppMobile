import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/core/utils/money_formatter.dart';
import 'package:clinapp/features/settings/domain/settings_models.dart';

/// Fila de 3 tarjetas de métricas del usuario (Pedidos, Total gastado, Calificación).
class ProfileMetricsRow extends StatelessWidget {
  const ProfileMetricsRow({super.key, required this.metrics});

  final UserProfileMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Row(
      children: <Widget>[
        // Métrica 1: Pedidos
        Expanded(
          child: _MetricCard(
            palette: palette,
            valueWidget: Text(
              '${metrics.ordersCount}',
              style: AppTypography.headlineMd.copyWith(
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
              ),
            ),
            label: AppStrings.profileMetricOrders,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Métrica 2: Total gastado
        Expanded(
          child: _MetricCard(
            palette: palette,
            valueWidget: Text(
              MoneyFormatter.format(metrics.totalSpentCents),
              style: AppTypography.headlineMd.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
            label: AppStrings.profileMetricSpent,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Métrica 3: Calificación
        Expanded(
          child: _MetricCard(
            palette: palette,
            valueWidget: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  metrics.ratingText,
                  style: AppTypography.headlineMd.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  LucideIcons.star,
                  size: 16,
                  color: AppColors.success,
                ),
              ],
            ),
            label: AppStrings.profileMetricRating,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.palette,
    required this.valueWidget,
    required this.label,
  });

  final AppPalette palette;
  final Widget valueWidget;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: palette.glassFill1,
        borderRadius: AppRadii.baseAll,
        border: Border.all(color: palette.rimSoft),
        boxShadow: palette.cardShadows,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FittedBox(fit: BoxFit.scaleDown, child: valueWidget),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(color: palette.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
