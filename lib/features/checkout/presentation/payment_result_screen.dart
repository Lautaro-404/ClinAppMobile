import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/router/app_routes.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/features/checkout/data/supabase_checkout_repository.dart';
import 'package:clinapp/features/checkout/domain/checkout_models.dart';
import 'package:clinapp/features/checkout/domain/checkout_repository.dart';
import 'package:clinapp/features/checkout/presentation/checkout_controller.dart';
import 'package:clinapp/features/orders/presentation/active_orders_count_provider.dart';
import 'package:clinapp/shared/widgets/glass_background.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';

/// Pantalla receptora de Deep Links (`/pago/resultado`) tras abonar en Mercado Pago.
class PaymentResultScreen extends ConsumerStatefulWidget {
  const PaymentResultScreen({this.orderId, this.statusHint, super.key});

  /// Identificador del pedido obtenido del query parameter (`pedido` o `external_reference`).
  final String? orderId;

  /// Indicador referencial devuelto en la URL por Mercado Pago (no autoritativo).
  final String? statusHint;

  @override
  ConsumerState<PaymentResultScreen> createState() =>
      _PaymentResultScreenState();
}

class _PaymentResultScreenState extends ConsumerState<PaymentResultScreen> {
  StreamSubscription<PaymentProcessStatus>? _subscription;
  Timer? _timeoutTimer;
  PaymentProcessStatus _currentStatus =
      PaymentProcessStatus.awaitingExternalPayment;

  @override
  void initState() {
    super.initState();
    _initPaymentWatcher();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _initPaymentWatcher() {
    final String id = (widget.orderId ?? '').trim();
    if (id.isEmpty) {
      _currentStatus = PaymentProcessStatus.rejected;
      return;
    }

    final CheckoutRepository repo = ref.read(checkoutRepositoryProvider);

    // Timeout defensivo de 2 minutos
    _timeoutTimer = Timer(const Duration(seconds: 120), () {
      if (mounted &&
          (_currentStatus == PaymentProcessStatus.awaitingExternalPayment ||
              _currentStatus == PaymentProcessStatus.pending)) {
        setState(() {
          _currentStatus = PaymentProcessStatus.timeout;
        });
      }
    });

    _subscription = repo.watchOrderPaymentStatus(id).listen((
      PaymentProcessStatus newStatus,
    ) {
      if (!mounted) return;
      setState(() {
        _currentStatus = newStatus;
      });

      // Notificar al controller si está activo en memoria
      ref
          .read(checkoutControllerProvider.notifier)
          .handlePaymentResult(newStatus);

      if (newStatus == PaymentProcessStatus.approved) {
        final int currentCount = ref.read(activeOrdersCountProvider);
        ref.read(activeOrdersCountProvider.notifier).setCount(currentCount + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final double horizontalMargin = AppSpacing.marginFor(
      MediaQuery.sizeOf(context).width,
    );

    final (
      IconData icon,
      Color color,
      String title,
      String subtitle,
    ) = switch (_currentStatus) {
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
        AppStrings.paymentRejectedSubtitle,
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
        AppStrings.paymentAwaitingReturn,
      ),
    };

    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: AppSpacing.minTapTarget,
                        height: AppSpacing.minTapTarget,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: AppSpacing.lg),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineLg.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMd.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                    if (widget.orderId != null &&
                        widget.orderId!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: palette.glassFill1,
                          borderRadius: AppRadii.baseAll,
                          border: Border.all(color: palette.rimMedium),
                        ),
                        child: Text(
                          'Pedido: #${widget.orderId!.substring(0, 8).toUpperCase()}',
                          textAlign: TextAlign.center,
                          style: AppTypography.labelSm.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    if (_currentStatus == PaymentProcessStatus.approved ||
                        _currentStatus == PaymentProcessStatus.pending ||
                        _currentStatus ==
                            PaymentProcessStatus.timeout) ...<Widget>[
                      GlassButton.primary(
                        label: AppStrings.paymentGoToOrdersAction,
                        leadingIcon: LucideIcons.compass,
                        expand: true,
                        onPressed: () {
                          if (GoRouter.maybeOf(context) != null) {
                            context.go(AppRoutes.orders);
                          }
                        },
                      ),
                    ] else ...<Widget>[
                      GlassButton.primary(
                        label: AppStrings.paymentRetryMercadoPagoAction,
                        leadingIcon: LucideIcons.refreshCw,
                        expand: true,
                        onPressed: () {
                          if (GoRouter.maybeOf(context) != null) {
                            context.go(AppRoutes.checkout);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      GlassButton.secondary(
                        label: AppStrings.paymentChangeMethodAction,
                        leadingIcon: LucideIcons.wallet,
                        expand: true,
                        onPressed: () {
                          if (GoRouter.maybeOf(context) != null) {
                            context.go(AppRoutes.checkout);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
