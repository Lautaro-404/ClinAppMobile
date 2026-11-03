import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:clinapp/core/services/url_launcher_service.dart';

import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/router/app_routes.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/core/utils/money_formatter.dart';
import 'package:clinapp/features/checkout/domain/checkout_models.dart';
import 'package:clinapp/features/checkout/presentation/checkout_controller.dart';
import 'package:clinapp/features/checkout/presentation/widgets/checkout_address_section.dart';
import 'package:clinapp/features/checkout/presentation/widgets/checkout_cart_section.dart';
import 'package:clinapp/features/checkout/presentation/widgets/checkout_coupon_section.dart';
import 'package:clinapp/features/checkout/presentation/widgets/checkout_pay_bar.dart';
import 'package:clinapp/features/checkout/presentation/widgets/checkout_payment_section.dart';
import 'package:clinapp/features/checkout/presentation/widgets/payment_status_sheet.dart';
import 'package:clinapp/features/checkout/presentation/widgets/price_breakdown_card.dart';
import 'package:clinapp/shared/widgets/empty_state.dart';
import 'package:clinapp/shared/widgets/error_state.dart';
import 'package:clinapp/shared/widgets/glass_background.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';
import 'package:clinapp/shared/widgets/glass_sheet.dart';
import 'package:clinapp/shared/widgets/loading_skeleton.dart';

/// Pantalla de Checkout y Pagos fuera del shell principal (Etapa 7).
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();
  bool _controllersSeeded = false;

  @override
  void dispose() {
    _notesController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  void _syncControllersIfNeeded(CheckoutViewState viewState) {
    if (!_controllersSeeded) {
      _notesController.text = viewState.riderNotes;
      _couponController.text = viewState.couponInput;
      _controllersSeeded = true;
    }
  }

  Future<void> _handlePayPressed(CheckoutViewState viewState) async {
    final CheckoutSubmissionResult? submission = await ref
        .read(checkoutControllerProvider.notifier)
        .submitOrder();

    if (!mounted) {
      return;
    }

    final CheckoutViewState? latestState = ref
        .read(checkoutControllerProvider)
        .value;
    if (latestState == null) {
      return;
    }

    if (latestState.hasPendingDiscrepancy &&
        latestState.pendingDiscrepancyQuote != null) {
      await _openDiscrepancySheet(latestState);
      return;
    }

    if (submission == null) {
      if (latestState.submissionError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(latestState.submissionError!),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }

    if (!latestState.paymentMethod.usesExternalGateway) {
      final String msg =
          latestState.paymentMethod == CheckoutPaymentMethod.clinPay
          ? AppStrings.checkoutPaymentClinPayConfirmedMsg
          : AppStrings.paymentCashConfirmedMsg;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.success),
      );
      if (GoRouter.maybeOf(context) != null) {
        context.go(AppRoutes.orders);
      }
      return;
    }

    final String? checkoutUrl = submission.checkoutUrl;
    if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
      unawaited(ref.read(urlLauncherServiceProvider).openUrl(checkoutUrl));
    }

    if (!mounted) return;

    await GlassSheet.show<void>(
      context: context,
      child: PaymentStatusSheetContent(
        onGoToOrders: () {
          if (GoRouter.maybeOf(context) != null) {
            context.go(AppRoutes.orders);
          }
        },
      ),
    );
  }

  Future<void> _openDiscrepancySheet(CheckoutViewState state) async {
    final CheckoutQuote newQuote = state.pendingDiscrepancyQuote!;
    final int prevTotal = state.quote.totalCents;
    final int newTotal = newQuote.totalCents;
    final int difference = newTotal - prevTotal;

    await GlassSheet.show<void>(
      context: context,
      child: Builder(
        builder: (BuildContext sheetContext) {
          final AppPalette sheetPalette = sheetContext.palette;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    LucideIcons.alertCircle,
                    color: AppColors.warning,
                    size: AppSpacing.md,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      AppStrings.checkoutPriceDiscrepancyTitle,
                      style: AppTypography.headlineMd.copyWith(
                        color: sheetPalette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.checkoutPriceDiscrepancySubtitle,
                style: AppTypography.bodySm.copyWith(
                  color: sheetPalette.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: sheetPalette.glassFill1,
                  borderRadius: AppRadii.baseAll,
                  border: Border.all(color: sheetPalette.rimMedium),
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            AppStrings.checkoutPriceDiscrepancyPreviousTotal,
                            style: AppTypography.bodySm.copyWith(
                              color: sheetPalette.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          MoneyFormatter.format(prevTotal),
                          style: AppTypography.labelMd.copyWith(
                            color: sheetPalette.textSecondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            AppStrings.checkoutPriceDiscrepancyNewTotal,
                            style: AppTypography.labelMd.copyWith(
                              color: sheetPalette.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          MoneyFormatter.format(newTotal),
                          style: AppTypography.labelLg.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            AppStrings.checkoutPriceDiscrepancyDifference,
                            style: AppTypography.labelSm.copyWith(
                              color: sheetPalette.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${difference > 0 ? '+' : ''}${MoneyFormatter.format(difference)}',
                          style: AppTypography.labelSm.copyWith(
                            color: difference > 0
                                ? AppColors.warning
                                : AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              GlassButton.primary(
                label: AppStrings.checkoutPriceDiscrepancyAccept,
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  final CheckoutSubmissionResult? submission = await ref
                      .read(checkoutControllerProvider.notifier)
                      .acceptPriceDiscrepancy();
                  if (!mounted || submission == null) return;
                  if (!state.paymentMethod.usesExternalGateway) {
                    final String msg =
                        state.paymentMethod == CheckoutPaymentMethod.clinPay
                        ? AppStrings.checkoutPaymentClinPayConfirmedMsg
                        : AppStrings.paymentCashConfirmedMsg;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(msg),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    if (GoRouter.maybeOf(context) != null) {
                      context.go(AppRoutes.orders);
                    }
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              GlassButton.secondary(
                label: AppStrings.checkoutPriceDiscrepancyReview,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  ref
                      .read(checkoutControllerProvider.notifier)
                      .dismissPriceDiscrepancy();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _openAddressSelectorSheet(CheckoutViewState viewState) {
    unawaited(
      GlassSheet.show<void>(
        context: context,
        child: Builder(
          builder: (BuildContext sheetContext) {
            final AppPalette sheetPalette = sheetContext.palette;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        AppStrings.checkoutAddressSelectSheetTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headlineMd.copyWith(
                          color: sheetPalette.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GlassButton.icon(
                      icon: LucideIcons.x,
                      semanticLabel: AppStrings.actionClose,
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                for (final DeliveryAddressOption option
                    in viewState.addresses) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        borderRadius: AppRadii.baseAll,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          unawaited(
                            ref
                                .read(checkoutControllerProvider.notifier)
                                .selectAddress(option.id),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: option.id == viewState.selectedAddressId
                                ? sheetPalette.glassFill2
                                : sheetPalette.glassFill1,
                            borderRadius: AppRadii.baseAll,
                            border: Border.all(
                              color: option.id == viewState.selectedAddressId
                                  ? AppColors.accent
                                  : sheetPalette.rimMedium,
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                LucideIcons.mapPin,
                                color: option.id == viewState.selectedAddressId
                                    ? AppColors.accent
                                    : sheetPalette.textSecondary,
                                size: AppSpacing.md,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      option.addressLine,
                                      style: AppTypography.labelMd.copyWith(
                                        color: sheetPalette.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${option.city} · ${option.etaRangeText}',
                                      style: AppTypography.bodySm.copyWith(
                                        color: sheetPalette.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (option.id == viewState.selectedAddressId)
                                const Icon(
                                  LucideIcons.check,
                                  color: AppColors.accent,
                                  size: AppSpacing.md,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<CheckoutViewState> asyncState = ref.watch(
      checkoutControllerProvider,
    );
    final double horizontalMargin = AppSpacing.marginFor(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          bottom: false,
          child: asyncState.when(
            loading: () =>
                _CheckoutLoadingView(horizontalMargin: horizontalMargin),
            error: (Object error, StackTrace stackTrace) {
              final String message = error is AppException
                  ? error.message
                  : AppStrings.genericErrorMessage;
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(horizontalMargin),
                  child: ErrorState(
                    message: message,
                    onRetry: () => ref.invalidate(checkoutControllerProvider),
                  ),
                ),
              );
            },
            data: (CheckoutViewState viewState) {
              _syncControllersIfNeeded(viewState);
              return _buildContent(context, viewState, horizontalMargin);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    CheckoutViewState viewState,
    double horizontalMargin,
  ) {
    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalMargin,
                vertical: AppSpacing.sm,
              ),
              child: _CheckoutTopBar(
                onBackTap: () {
                  final GoRouter? router = GoRouter.maybeOf(context);
                  if (router != null && router.canPop()) {
                    context.pop();
                  } else if (router != null) {
                    context.go(AppRoutes.home);
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
              ),
            ),
            Expanded(
              child: viewState.items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(horizontalMargin),
                        child: EmptyState(
                          title: AppStrings.checkoutEmptyCartTitle,
                          subtitle: AppStrings.checkoutEmptyCartSubtitle,
                          actionLabel: AppStrings.checkoutEmptyCartCta,
                          onAction: () {
                            if (GoRouter.maybeOf(context) != null) {
                              context.go(AppRoutes.home);
                            }
                          },
                        ),
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalMargin,
                        AppSpacing.xs,
                        horizontalMargin,
                        AppSpacing.scrollBottomReserve + AppSpacing.lg,
                      ),
                      children: <Widget>[
                        const _CheckoutSubheader(),
                        const SizedBox(height: AppSpacing.md),
                        CheckoutCartSection(
                          merchantName: viewState.merchantName,
                          merchantTagline: viewState.merchantTagline,
                          items: viewState.items,
                          totalItemsCount: viewState.totalItemsCount,
                          onQuantityChange: (String productId, int delta) {
                            unawaited(
                              ref
                                  .read(checkoutControllerProvider.notifier)
                                  .updateItemQuantity(productId, delta),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CheckoutAddressSection(
                          address: viewState.selectedAddress,
                          notesController: _notesController,
                          onChangeAddressTap: () =>
                              _openAddressSelectorSheet(viewState),
                          onNotesChanged: (String value) => ref
                              .read(checkoutControllerProvider.notifier)
                              .updateRiderNotes(value),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CheckoutPaymentSection(
                          selectedMethod: viewState.paymentMethod,
                          clinpayBalanceCents: viewState.clinpayBalanceCents,
                          orderTotalCents: viewState.quote.totalCents,
                          onSelectMethod: (CheckoutPaymentMethod method) => ref
                              .read(checkoutControllerProvider.notifier)
                              .selectPaymentMethod(method),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CheckoutCouponSection(
                          controller: _couponController,
                          appliedCoupon: viewState.quote.appliedCoupon,
                          couponError: viewState.couponError,
                          isValidating: viewState.isValidatingCoupon,
                          onApplyTap: () {
                            unawaited(
                              ref
                                  .read(checkoutControllerProvider.notifier)
                                  .applyCoupon(_couponController.text),
                            );
                          },
                          onRemoveTap: () {
                            _couponController.clear();
                            unawaited(
                              ref
                                  .read(checkoutControllerProvider.notifier)
                                  .removeCoupon(),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        PriceBreakdownCard(quote: viewState.quote),
                      ],
                    ),
            ),
          ],
        ),
        if (viewState.items.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CheckoutPayBar(
              totalCents: viewState.quote.totalCents,
              isSubmitting: viewState.isSubmitting,
              onPayTap: () => unawaited(_handlePayPressed(viewState)),
            ),
          ),
      ],
    );
  }
}

class _CheckoutTopBar extends StatelessWidget {
  const _CheckoutTopBar({required this.onBackTap});

  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Row(
      children: <Widget>[
        GlassButton.icon(
          icon: LucideIcons.chevronLeft,
          semanticLabel: AppStrings.actionBack,
          onPressed: onBackTap,
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          width: AppSpacing.xl,
          height: AppSpacing.xl,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[AppColors.accentGlow, AppColors.accent],
            ),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            'C!',
            style: AppTypography.labelMd.copyWith(
              color: AppColors.onAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            AppStrings.checkoutHeaderTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headlineMd.copyWith(
              color: palette.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckoutSubheader extends StatelessWidget {
  const _CheckoutSubheader();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Row(
      children: <Widget>[
        Container(
          width: AppSpacing.xl + AppSpacing.sm,
          height: AppSpacing.xl + AppSpacing.sm,
          decoration: BoxDecoration(
            color: palette.glassFill2,
            shape: BoxShape.circle,
            border: Border.all(color: palette.rimMedium),
          ),
          child: const Icon(
            LucideIcons.shoppingBag,
            color: AppColors.accentGlow,
            size: AppSpacing.md,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                AppStrings.checkoutFinalStepLabel,
                style: AppTypography.labelSm.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              Text(
                AppStrings.checkoutTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headlineMd.copyWith(
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.successBloom,
            borderRadius: AppRadii.pillAll,
            border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                AppStrings.checkoutEncryptedBadge,
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckoutLoadingView extends StatelessWidget {
  const _CheckoutLoadingView({required this.horizontalMargin});

  final double horizontalMargin;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalMargin,
        AppSpacing.md,
        horizontalMargin,
        AppSpacing.scrollBottomReserve,
      ),
      children: const <Widget>[
        LoadingSkeleton(height: 56),
        SizedBox(height: AppSpacing.md),
        LoadingSkeleton(height: 220),
        SizedBox(height: AppSpacing.md),
        LoadingSkeleton(height: 150),
        SizedBox(height: AppSpacing.md),
        LoadingSkeleton(height: 180),
        SizedBox(height: AppSpacing.md),
        LoadingSkeleton(height: 140),
      ],
    );
  }
}
