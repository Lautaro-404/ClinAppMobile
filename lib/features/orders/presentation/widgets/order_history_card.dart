import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/core/utils/date_formatter.dart';
import 'package:clinapp/features/orders/domain/orders_models.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';
import 'package:clinapp/shared/widgets/price_text.dart';
import 'package:clinapp/shared/widgets/status_badge.dart';

/// Tarjeta de pedido en el historial con resumen de ítems, precio, repetición y recibo.
class OrderHistoryCard extends StatelessWidget {
  const OrderHistoryCard({
    required this.order,
    required this.onReorderTap,
    required this.onReceiptTap,
    super.key,
  });

  final OrderSummary order;
  final VoidCallback onReorderTap;
  final VoidCallback onReceiptTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final String formattedDate = DateFormatter.dateAndTime(order.createdAt);
    final bool isDelivered = order.status == OrderStatus.entregado;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Fila superior: comercio, fecha y estado.
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: AppRadii.baseAll,
                  color: palette.glassFill2,
                  border: Border.all(color: palette.rimMedium),
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.utensils,
                    size: 20,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      order.merchantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLg.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              StatusBadge(
                label: isDelivered
                    ? AppStrings.ordersStatusDelivered
                    : AppStrings.ordersStatusCancelled,
                tone: isDelivered
                    ? StatusBadgeTone.success
                    : StatusBadgeTone.danger,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Cápsula interna con resumen de ítems y monto formateado en pesos.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: palette.glassFill2,
              borderRadius: AppRadii.pillAll,
              border: Border.all(color: palette.rimMedium),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    order.itemsSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySm.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                PriceText(
                  cents: order.totalCents,
                  style: AppTypography.currencyDisplay.copyWith(fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Acciones: Pedir de nuevo y Ver recibo.
          Row(
            children: <Widget>[
              Expanded(
                child: GlassButton.secondary(
                  label: AppStrings.ordersReorderButton,
                  leadingIcon: LucideIcons.rotateCcw,
                  onPressed: onReorderTap,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GlassButton.icon(
                icon: LucideIcons.receipt,
                semanticLabel: AppStrings.ordersReceiptSemantics,
                onPressed: onReceiptTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
