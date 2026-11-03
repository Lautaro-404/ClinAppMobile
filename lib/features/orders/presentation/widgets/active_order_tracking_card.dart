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
import 'package:clinapp/features/orders/presentation/widgets/live_tracking_map_preview.dart';
import 'package:clinapp/features/orders/presentation/widgets/order_stepper.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';

/// Tarjeta principal de seguimiento del pedido activo con stepper, mapa y acciones.
class ActiveOrderTrackingCard extends StatelessWidget {
  const ActiveOrderTrackingCard({
    required this.order,
    required this.onLiveTrackingTap,
    required this.onContactCourierTap,
    required this.onCallCourierTap,
    required this.onChatCourierTap,
    super.key,
  });

  final OrderSummary order;
  final VoidCallback onLiveTrackingTap;
  final VoidCallback onContactCourierTap;
  final VoidCallback onCallCourierTap;
  final VoidCallback onChatCourierTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final String arrivalTime = order.estimatedArrivalAt != null
        ? DateFormatter.timeHs(order.estimatedArrivalAt!)
        : '22:15 hs';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Encabezado del pedido activo.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            AppStrings.cityName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '·',
                          style: TextStyle(color: palette.textTertiary),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          order.shortCode,
                          style: AppTypography.labelSm.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.merchantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headlineMd.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.itemsSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 4,
                  vertical: AppSpacing.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: palette.glassFill2,
                  borderRadius: AppRadii.pillAll,
                  border: Border.all(color: palette.rimMedium),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      AppStrings.ordersEstimatedArrival.toUpperCase(),
                      style: AppTypography.labelSm.copyWith(
                        color: palette.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      arrivalTime,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Stepper multisensorial.
          OrderStepper(
            status: order.status,
            remainingMinutes: order.remainingMinutes ?? 18,
            isExpress: order.isExpress,
          ),
          const SizedBox(height: AppSpacing.md),
          // Mapa integrado de seguimiento.
          LiveTrackingMapPreview(
            deliveryAddress: order.deliveryAddress,
            courier: order.courier,
            onCallCourier: onCallCourierTap,
            onChatCourier: onChatCourierTap,
          ),
          const SizedBox(height: AppSpacing.md),
          // Botones de acción.
          GlassButton.primary(
            label: AppStrings.ordersLiveTrackingCta,
            leadingIcon: LucideIcons.compass,
            expand: true,
            onPressed: onLiveTrackingTap,
          ),
          const SizedBox(height: AppSpacing.sm),
          GlassButton.secondary(
            label: AppStrings.ordersContactCourierCta,
            leadingIcon: LucideIcons.messageCircle,
            expand: true,
            onPressed: onContactCourierTap,
          ),
        ],
      ),
    );
  }
}
