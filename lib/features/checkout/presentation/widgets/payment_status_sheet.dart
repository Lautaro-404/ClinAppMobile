import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/core/utils/money_formatter.dart';
import 'package:clinapp/features/checkout/domain/checkout_models.dart';
import 'package:clinapp/features/checkout/presentation/checkout_controller.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';

/// Contenido reactivo para la hoja modal `GlassSheet` de estado del pago
/// con Mercado Pago (esperando confirmación, aprobado, pendiente, rechazado).
class PaymentStatusSheetContent extends ConsumerWidget {
  const PaymentStatusSheetContent({required this.onGoToOrders, super.key});

  final VoidCallback onGoToOrders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final AsyncValue<CheckoutViewState> asyncState = ref.watch(
      checkoutControllerProvider,
    );
    final CheckoutViewState? state = asyncState.value;

    final PaymentProcessStatus status =
        state?.paymentStatus ?? PaymentProcessStatus.awaitingExternalPayment;
    final int serverTotalCents = state?.quote.totalCents ?? 0;

    final (
      IconData icon,
      Color statusColor,
      String title,
      String subtitle,
    ) = switch (status) {
      PaymentProcessStatus.approved => (
        LucideIcons.circleCheck,
        AppColors.success,
        AppStrings.paymentApprovedTitle,
        AppStrings.paymentApprovedSubtitle,
      ),
      PaymentProcessStatus.pending => (
        LucideIcons.clock,
        AppColors.warning,
        AppStrings.paymentPendingTitle,
        AppStrings.paymentPendingSubtitle,
      ),
      PaymentProcessStatus.rejected => (
        LucideIcons.circleX,
        AppColors.danger,
        AppStrings.paymentRejectedTitle,
        state?.submissionError ?? AppStrings.paymentRejectedSubtitle,
      ),
      PaymentProcessStatus.userCancelled => (
        LucideIcons.alertCircle,
        AppColors.warning,
        AppStrings.paymentRejectedTitle,
        AppStrings.paymentUserCancelledSubtitle,
      ),
      PaymentProcessStatus.timeout => (
        LucideIcons.hourglass,
        AppColors.accentGlow,
        AppStrings.paymentTimeoutTitle,
        AppStrings.paymentTimeoutSubtitle,
      ),
      _ => (
        LucideIcons.shieldCheck,
        AppColors.accent,
        AppStrings.paymentProcessingTitle,
        AppStrings.paymentProcessingSubtitle,
      ),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Row(
                children: <Widget>[
                  Container(
                    width: AppSpacing.xl,
                    height: AppSpacing.xl,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: statusColor, size: AppSpacing.md),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headlineMd.copyWith(
                        color: palette.textPrimary,
                      ),
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
        const SizedBox(height: AppSpacing.md),
        Text(
          subtitle,
          style: AppTypography.bodyMd.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: palette.glassFill2,
            borderRadius: AppRadii.baseAll,
            border: Border.all(color: palette.rimMedium),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  AppStrings.checkoutServerVerifiedNote,
                  style: AppTypography.labelMd.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                MoneyFormatter.format(serverTotalCents),
                style: AppTypography.headlineMd.copyWith(
                  color: AppColors.accentGlow,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (status == PaymentProcessStatus.awaitingExternalPayment) ...<Widget>[
          GlassButton.primary(
            label: AppStrings.paymentSimulateApproveAction,
            leadingIcon: LucideIcons.check,
            expand: true,
            onPressed: () => ref
                .read(checkoutControllerProvider.notifier)
                .handlePaymentResult(PaymentProcessStatus.approved),
          ),
          const SizedBox(height: AppSpacing.sm),
          GlassButton.secondary(
            label: AppStrings.paymentSimulateRejectAction,
            leadingIcon: LucideIcons.circleX,
            expand: true,
            onPressed: () => ref
                .read(checkoutControllerProvider.notifier)
                .handlePaymentResult(PaymentProcessStatus.rejected),
          ),
        ] else if (status == PaymentProcessStatus.approved ||
            status == PaymentProcessStatus.pending ||
            status == PaymentProcessStatus.timeout) ...<Widget>[
          GlassButton.primary(
            label: AppStrings.paymentGoToOrdersAction,
            leadingIcon: LucideIcons.compass,
            expand: true,
            onPressed: () {
              Navigator.of(context).pop();
              onGoToOrders();
            },
          ),
        ] else if (status == PaymentProcessStatus.rejected ||
            status == PaymentProcessStatus.userCancelled) ...<Widget>[
          GlassButton.primary(
            label: AppStrings.paymentRetryMercadoPagoAction,
            leadingIcon: LucideIcons.refreshCw,
            expand: true,
            onPressed: () {
              Navigator.of(context).pop();
              unawaited(
                ref
                    .read(checkoutControllerProvider.notifier)
                    .retryExternalPayment(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          GlassButton.secondary(
            label: AppStrings.paymentChangeMethodAction,
            leadingIcon: LucideIcons.wallet,
            expand: true,
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(checkoutControllerProvider.notifier)
                  .selectPaymentMethod(CheckoutPaymentMethod.cash);
            },
          ),
        ],
      ],
    );
  }
}
