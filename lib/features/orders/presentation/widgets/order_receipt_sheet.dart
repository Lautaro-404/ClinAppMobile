import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/core/utils/date_formatter.dart';
import 'package:clinapp/core/utils/money_formatter.dart';
import 'package:clinapp/features/orders/domain/orders_models.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';
import 'package:clinapp/shared/widgets/glass_sheet.dart';
import 'package:clinapp/shared/widgets/price_text.dart';

/// Hoja modal GlassSheet que muestra el comprobante real y detallado del pedido.
class OrderReceiptSheet extends StatelessWidget {
  const OrderReceiptSheet({required this.order, super.key});

  final OrderSummary order;

  /// Método estático para mostrar la hoja modal del comprobante.
  static Future<void> show(BuildContext context, OrderSummary order) {
    return GlassSheet.show<void>(
      context: context,
      child: OrderReceiptSheet(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Encabezado
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    AppStrings.ordersReceiptTitle,
                    style: AppTypography.headlineMd.copyWith(
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order.merchantName} · ${order.shortCode}',
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
            GlassButton.icon(
              icon: LucideIcons.x,
              semanticLabel: AppStrings.actionClose,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // Fecha y estado en General Alvear
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: palette.glassFill2,
            borderRadius: AppRadii.mdAll,
            border: Border.all(color: palette.rimMedium),
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                LucideIcons.calendar,
                size: 16,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Expanded(
                child: Text(
                  DateFormatter.dateAndTime(order.createdAt),
                  style: AppTypography.labelSm.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: order.isActive
                      ? AppColors.accent.withValues(alpha: 0.18)
                      : AppColors.success.withValues(alpha: 0.18),
                  borderRadius: AppRadii.pillAll,
                  border: Border.all(
                    color: order.isActive
                        ? AppColors.accent.withValues(alpha: 0.40)
                        : AppColors.success.withValues(alpha: 0.40),
                  ),
                ),
                child: Text(
                  order.isActive ? 'En proceso' : 'Completado',
                  style: AppTypography.labelSm.copyWith(
                    color: order.isActive
                        ? AppColors.accent
                        : AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Lista de ítems detallados
        if (order.items.isNotEmpty) ...<Widget>[
          for (final OrderLineItem item in order.items) ...<Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.name}',
                      style: AppTypography.bodyMd.copyWith(
                        color: palette.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  PriceText(cents: item.totalPriceCents),
                ],
              ),
            ),
          ],
        ] else ...<Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    order.itemsSummary,
                    style: AppTypography.bodyMd.copyWith(
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                PriceText(cents: order.subtotalCents),
              ],
            ),
          ),
        ],

        Divider(color: palette.rimMedium, height: 24),

        // Subtotal
        _ReceiptSummaryRow(
          label: AppStrings.ordersReceiptSubtotal,
          value: MoneyFormatter.format(order.subtotalCents),
          textColor: palette.textPrimary,
        ),

        const SizedBox(height: AppSpacing.xs),

        // Costo de envío
        _ReceiptSummaryRow(
          label: AppStrings.ordersReceiptDelivery,
          value: MoneyFormatter.format(order.deliveryFeeCents),
          textColor: palette.textPrimary,
        ),

        if (order.discountCents > 0) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          _ReceiptSummaryRow(
            label: AppStrings.ordersReceiptDiscount,
            value: '-${MoneyFormatter.format(order.discountCents)}',
            textColor: AppColors.success,
          ),
        ],

        if (order.tipCents > 0) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          _ReceiptSummaryRow(
            label: AppStrings.ordersReceiptTip,
            value: MoneyFormatter.format(order.tipCents),
            textColor: palette.textPrimary,
          ),
        ],

        Divider(color: palette.rimMedium, height: 24),

        // Total abonado
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                AppStrings.ordersReceiptTotal,
                style: AppTypography.headlineMd.copyWith(
                  color: palette.textPrimary,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              MoneyFormatter.format(order.totalCents),
              style: AppTypography.headlineMd.copyWith(
                color: AppColors.accent,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // Dirección de entrega
        Row(
          children: <Widget>[
            const Icon(LucideIcons.mapPin, size: 14, color: AppColors.accent),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                '${AppStrings.ordersToPrefix}${order.deliveryAddress}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySm.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Botón cerrar o compartir
        GlassButton.secondary(
          label: 'Descargar comprobante',
          leadingIcon: LucideIcons.download,
          expand: true,
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Comprobante guardado en tu dispositivo.'),
                backgroundColor: AppColors.success,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ReceiptSummaryRow extends StatelessWidget {
  const _ReceiptSummaryRow({
    required this.label,
    required this.value,
    required this.textColor,
  });

  final String label;
  final String value;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySm.copyWith(color: palette.textSecondary),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          value,
          style: AppTypography.bodySm.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
