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

/// Tarjeta Liquid Glass para una entrega del repartidor con prioridades visuales.
class CourierDeliveryCard extends StatelessWidget {
  const CourierDeliveryCard({
    super.key,
    required this.delivery,
    required this.onPickedUp,
    required this.onDelivered,
    required this.onOpenMerchantInfo,
    required this.onOpenMapRoute,
    required this.onContactCustomer,
  });

  final CourierDeliveryItem delivery;
  final VoidCallback onPickedUp;
  final VoidCallback onDelivered;
  final VoidCallback onOpenMerchantInfo;
  final VoidCallback onOpenMapRoute;
  final VoidCallback onContactCustomer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    final Color statusColor = switch (delivery.status) {
      CourierDeliveryStatus.onTheWay => AppColors.success,
      CourierDeliveryStatus.readyForPickup => AppColors.accent,
      CourierDeliveryStatus.inKitchen => const Color(0xFFF59E0B),
      CourierDeliveryStatus.delivered => AppColors.success,
    };

    final String statusLabel = switch (delivery.status) {
      CourierDeliveryStatus.onTheWay => AppStrings.courierStatusOnTheWay,
      CourierDeliveryStatus.readyForPickup =>
        AppStrings.courierStatusReadyPickup,
      CourierDeliveryStatus.inKitchen => AppStrings.courierStatusInKitchen,
      CourierDeliveryStatus.delivered => AppStrings.catalogStatusDelivered,
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
          // Header de la tarjeta
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      delivery.merchantName,
                      style: AppTypography.headlineMd.copyWith(
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      delivery.orderNumber,
                      style: AppTypography.labelSm.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
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

          // Bloque de Origen / Retiro
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: palette.glassFill2,
              borderRadius: AppRadii.smAll,
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  LucideIcons.store,
                  size: 16,
                  color: AppColors.accent,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '${AppStrings.courierPickupPoint}: ${delivery.merchantAddress}',
                    style: AppTypography.bodySm.copyWith(
                      color: palette.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: onOpenMerchantInfo,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  child: Text(
                    AppStrings.courierActionViewMerchant,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Bloque Destino destacado
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
                Row(
                  children: <Widget>[
                    const Icon(
                      LucideIcons.mapPin,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.courierDeliveryPoint,
                      style: AppTypography.labelSm.copyWith(
                        color: palette.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  delivery.customerAddress,
                  style: AppTypography.labelMd.copyWith(
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: <Widget>[
                    const Icon(
                      LucideIcons.user,
                      size: 14,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      delivery.customerName,
                      style: AppTypography.bodySm.copyWith(
                        fontWeight: FontWeight.w600,
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
                        color: palette.glassFill2,
                        borderRadius: AppRadii.pillAll,
                      ),
                      child: Text(
                        delivery.deliveryNotes,
                        style: AppTypography.labelSm.copyWith(
                          fontSize: 10,
                          color: palette.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                // Botones rápidos de contacto y ruta
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(color: palette.rimSoft),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadii.pillAll,
                          ),
                        ),
                        icon: const Icon(LucideIcons.navigation, size: 14),
                        label: Text(
                          AppStrings.courierActionViewRoute,
                          style: AppTypography.labelSm.copyWith(
                            color: palette.textPrimary,
                          ),
                        ),
                        onPressed: onOpenMapRoute,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(color: palette.rimSoft),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadii.pillAll,
                          ),
                        ),
                        icon: const Icon(LucideIcons.phone, size: 14),
                        label: Text(
                          AppStrings.courierActionCall,
                          style: AppTypography.labelSm.copyWith(
                            color: palette.textPrimary,
                          ),
                        ),
                        onPressed: onContactCustomer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Mini Snapshot de ruta
          Row(
            children: <Widget>[
              Icon(LucideIcons.compass, size: 14, color: palette.textTertiary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  delivery.distanceEstimate,
                  style: AppTypography.bodySm.copyWith(
                    color: palette.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: palette.glassFill2,
                  borderRadius: AppRadii.pillAll,
                ),
                child: Text(
                  AppStrings.courierNoTollsBadge,
                  style: AppTypography.labelSm.copyWith(
                    fontSize: 10,
                    color: palette.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Cobro / Método de pago
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    delivery.isCashOnDelivery
                        ? LucideIcons.banknote
                        : LucideIcons.creditCard,
                    size: 16,
                    color: delivery.isCashOnDelivery
                        ? AppColors.success
                        : AppColors.accent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    delivery.isCashOnDelivery
                        ? AppStrings.courierCashToCollect
                        : AppStrings.courierPaidOnline,
                    style: AppTypography.labelSm.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                MoneyFormatter.format(delivery.amountCents),
                style: AppTypography.headlineMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: delivery.isCashOnDelivery
                      ? AppColors.success
                      : palette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Botón de acción principal según el estado
          if (delivery.status == CourierDeliveryStatus.onTheWay)
            GlassButton.primary(
              label: AppStrings.courierActionOrderDelivered,
              leadingIcon: LucideIcons.checkCircle,
              expand: true,
              onPressed: onDelivered,
            )
          else if (delivery.status == CourierDeliveryStatus.readyForPickup)
            GlassButton.primary(
              label: AppStrings.courierActionOrderPickedUp,
              leadingIcon: LucideIcons.packageCheck,
              expand: true,
              onPressed: onPickedUp,
            )
          else if (delivery.status == CourierDeliveryStatus.inKitchen)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: AppRadii.baseAll,
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    LucideIcons.clock,
                    size: 16,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      AppStrings.courierKitchenNotice,
                      style: AppTypography.bodySm.copyWith(
                        color: palette.textPrimary,
                        fontSize: 11,
                      ),
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
