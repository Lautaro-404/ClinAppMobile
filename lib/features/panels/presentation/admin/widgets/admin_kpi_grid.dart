import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';

/// Grilla de indicadores clave (KPIs) en tiempo real para el administrador.
class AdminKpiGrid extends StatelessWidget {
  const AdminKpiGrid({
    super.key,
    required this.activeOrders,
    required this.activeCouriers,
    required this.openMerchants,
    required this.avgDeliveryMinutes,
  });

  final int activeOrders;
  final int activeCouriers;
  final int openMerchants;
  final int avgDeliveryMinutes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _KpiTile(
                icon: LucideIcons.shoppingBag,
                iconColor: AppColors.accent,
                label: AppStrings.adminKpiActiveOrders,
                value: '$activeOrders',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _KpiTile(
                icon: LucideIcons.bike,
                iconColor: AppColors.success,
                label: AppStrings.adminKpiActiveCouriers,
                value: '$activeCouriers',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: _KpiTile(
                icon: LucideIcons.store,
                iconColor: const Color(0xFF6366F1),
                label: AppStrings.adminKpiOpenMerchants,
                value: '$openMerchants',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _KpiTile(
                icon: LucideIcons.clock,
                iconColor: const Color(0xFFF59E0B),
                label: AppStrings.adminKpiAvgDeliveryTime,
                value: '$avgDeliveryMinutes min',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: AppRadii.smAll,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.headlineMd.copyWith(
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          Text(
            label,
            style: AppTypography.bodySm.copyWith(
              color: palette.textSecondary,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
