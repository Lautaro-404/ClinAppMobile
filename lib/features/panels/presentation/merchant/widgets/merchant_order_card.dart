import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/core/utils/money_formatter.dart';
import 'package:clinapp/features/panels/domain/panel_models.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';

/// Tarjeta Liquid Glass para un pedido en la cocina/mostrador del local.
class MerchantOrderCard extends StatelessWidget {
  const MerchantOrderCard({
    super.key,
    required this.order,
    required this.onAcceptKitchen,
    required this.onMarkReady,
    required this.onDispatch,
  });

  final MerchantOrderItem order;
  final VoidCallback onAcceptKitchen;
  final VoidCallback onMarkReady;
  final VoidCallback onDispatch;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    final Color statusColor = switch (order.status) {
      MerchantOrderStatus.incoming => AppColors.accent,
      MerchantOrderStatus.inKitchen => const Color(0xFFF59E0B),
      MerchantOrderStatus.readyForPickup => AppColors.success,
      MerchantOrderStatus.completed => AppColors.success,
    };

    final String statusLabel = switch (order.status) {
      MerchantOrderStatus.incoming => 'Nuevo pedido',
      MerchantOrderStatus.inKitchen =>
        'En cocina (${order.prepTimeMinutes} min)',
      MerchantOrderStatus.readyForPickup => AppStrings.courierStatusReadyPickup,
      MerchantOrderStatus.completed => AppStrings.catalogStatusDelivered,
    };

    return Container(
      decoration: BoxDecoration(
        color: palette.glassFill1,
        borderRadius: AppRadii.cardAll,
        border: Border.all(
          color: statusColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: palette.cardShadows,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      order.orderNumber,
                      style: AppTypography.headlineMd.copyWith(
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      '${order.customerName} · ${order.customerAddress}',
                      style: AppTypography.bodySm.copyWith(
                        color: palette.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.18),
                  borderRadius: AppRadii.pillAll,
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusLabel,
                  style: AppTypography.labelSm.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Lista de ítems del pedido
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: palette.glassFill1,
              borderRadius: AppRadii.baseAll,
              border: Border.all(color: palette.rimSoft),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ...order.items.map(
                  (String item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          LucideIcons.dot,
                          size: 16,
                          color: AppColors.accent,
                        ),
                        Expanded(
                          child: Text(
                            item,
                            style: AppTypography.bodySm.copyWith(
                              fontWeight: FontWeight.w600,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (order.assignedRiderName != null) ...<Widget>[
                  const Divider(height: 12),
                  Row(
                    children: <Widget>[
                      const Icon(
                        LucideIcons.bike,
                        size: 14,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${AppStrings.merchantAssignedRider}: ${order.assignedRiderName}',
                        style: AppTypography.labelSm.copyWith(
                          color: palette.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Fila de método de pago y monto
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    order.isCash
                        ? LucideIcons.banknote
                        : LucideIcons.creditCard,
                    size: 16,
                    color: order.isCash ? AppColors.success : AppColors.accent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.isCash ? 'Efectivo en mano' : 'Mercado Pago (Pagado)',
                    style: AppTypography.labelSm.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                MoneyFormatter.format(order.totalAmountCents),
                style: AppTypography.headlineMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Botones de acción según la etapa
          if (order.status == MerchantOrderStatus.incoming)
            Row(
              children: <Widget>[
                Expanded(
                  child: GlassButton.primary(
                    label: AppStrings.merchantActionAcceptKitchen,
                    leadingIcon: LucideIcons.flame,
                    expand: true,
                    onPressed: onAcceptKitchen,
                  ),
                ),
              ],
            )
          else if (order.status == MerchantOrderStatus.inKitchen)
            GlassButton.primary(
              label: AppStrings.merchantActionMarkReady,
              leadingIcon: LucideIcons.bellRing,
              expand: true,
              onPressed: onMarkReady,
            )
          else if (order.status == MerchantOrderStatus.readyForPickup)
            GlassButton.primary(
              label: AppStrings.merchantActionDispatch,
              leadingIcon: LucideIcons.packageCheck,
              expand: true,
              onPressed: onDispatch,
            ),
        ],
      ),
    );
  }
}
