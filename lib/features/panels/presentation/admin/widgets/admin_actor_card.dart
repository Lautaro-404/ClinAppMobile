import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/core/utils/money_formatter.dart';
import 'package:clinapp/features/panels/domain/panel_models.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';

/// Tarjeta Liquid Glass para gestionar un comercio o repartidor desde el panel de administración.
class AdminActorCard extends StatelessWidget {
  const AdminActorCard.merchant({
    super.key,
    required this.merchant,
    required this.onToggleActive,
  }) : courier = null;

  const AdminActorCard.courier({super.key, required this.courier})
    : merchant = null,
      onToggleActive = null;

  final AdminMerchantSummary? merchant;
  final AdminCourierSummary? courier;
  final ValueChanged<bool>? onToggleActive;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    if (merchant != null) {
      final AdminMerchantSummary m = merchant!;
      return GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: m.isOpen
                    ? const Color.fromRGBO(16, 185, 129, 0.15)
                    : palette.glassFill2,
                borderRadius: AppRadii.baseAll,
              ),
              child: Icon(
                LucideIcons.store,
                color: m.isOpen ? AppColors.success : palette.textTertiary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    m.name,
                    style: AppTypography.headlineMd.copyWith(
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                  Text(
                    m.address,
                    style: AppTypography.bodySm.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: <Widget>[
                      Text(
                        '${m.activeOrdersCount} pedidos activos · Comisión ${m.commissionPercent.toStringAsFixed(0)}%',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: m.isOpen,
              activeThumbColor: AppColors.accent,
              onChanged: onToggleActive,
            ),
          ],
        ),
      );
    }

    final AdminCourierSummary c = courier!;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: c.isOnline
                  ? const Color.fromRGBO(16, 185, 129, 0.15)
                  : palette.glassFill2,
              borderRadius: AppRadii.baseAll,
            ),
            child: Icon(
              LucideIcons.bike,
              color: c.isOnline ? AppColors.success : palette.textTertiary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      c.name,
                      style: AppTypography.headlineMd.copyWith(
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: c.isOnline
                            ? const Color.fromRGBO(16, 185, 129, 0.15)
                            : palette.glassFill2,
                        borderRadius: AppRadii.pillAll,
                      ),
                      child: Text(
                        c.isOnline ? 'En calle' : 'Desconectado',
                        style: AppTypography.labelSm.copyWith(
                          color: c.isOnline
                              ? AppColors.success
                              : palette.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Tel: ${c.phone}',
                  style: AppTypography.bodySm.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${c.todayDeliveries} entregas hoy · Efectivo: ${MoneyFormatter.format(c.cashCollectedCents)}',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
