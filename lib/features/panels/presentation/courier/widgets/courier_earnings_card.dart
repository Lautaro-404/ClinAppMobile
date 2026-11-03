import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/core/utils/money_formatter.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';

/// Tarjeta Liquid Glass con el resumen de ganancias del día del repartidor.
class CourierEarningsCard extends StatelessWidget {
  const CourierEarningsCard({
    super.key,
    required this.earningsCents,
    required this.deliveriesCount,
  });

  final int earningsCents;
  final int deliveriesCount;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadii.baseAll,
              border: Border.all(color: palette.rimStrong),
            ),
            child: const Icon(
              LucideIcons.wallet,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppStrings.courierEarningsTodayTitle,
                  style: AppTypography.labelMd.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
                Text(
                  MoneyFormatter.format(earningsCents),
                  style: AppTypography.headlineMd.copyWith(
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(16, 185, 129, 0.15),
              borderRadius: AppRadii.pillAll,
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '$deliveriesCount ${AppStrings.courierDeliveriesDoneCount}',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
