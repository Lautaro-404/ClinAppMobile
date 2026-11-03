import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/router/app_routes.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/core/utils/money_formatter.dart';
import 'package:clinapp/features/home/presentation/widgets/home_top_bar.dart';
import 'package:clinapp/features/orders/domain/orders_models.dart';
import 'package:clinapp/features/orders/presentation/orders_controller.dart';
import 'package:clinapp/features/orders/presentation/widgets/active_order_tracking_card.dart';
import 'package:clinapp/features/orders/presentation/widgets/order_chat_sheet.dart';
import 'package:clinapp/features/orders/presentation/widgets/order_history_card.dart';
import 'package:clinapp/features/orders/presentation/widgets/order_receipt_sheet.dart';
import 'package:clinapp/features/orders/presentation/widgets/order_stepper.dart';
import 'package:clinapp/features/orders/presentation/widgets/order_support_banner.dart';
import 'package:clinapp/features/orders/presentation/widgets/orders_segmented_tabs.dart';
import 'package:clinapp/shared/widgets/empty_state.dart';
import 'package:clinapp/shared/widgets/error_state.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';
import 'package:clinapp/shared/widgets/glass_sheet.dart';
import 'package:clinapp/shared/widgets/loading_skeleton.dart';

/// Pantalla Pedidos completa con seguimiento en tiempo real, selector segmentado,
/// mapa interactivo, historial paginado y comprobantes.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key, this.initialOrderId});

  final String? initialOrderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<OrdersViewState> asyncState = ref.watch(
      ordersControllerProvider,
    );
    final double horizontalMargin = AppSpacing.marginFor(
      MediaQuery.sizeOf(context).width,
    );

    return SafeArea(
      bottom: false,
      child: asyncState.when(
        loading: () => _OrdersLoadingView(horizontalMargin: horizontalMargin),
        error: (Object error, StackTrace stackTrace) {
          final String message = error is AppException
              ? error.message
              : AppStrings.genericErrorMessage;
          return Center(
            child: Padding(
              padding: EdgeInsets.all(horizontalMargin),
              child: ErrorState(
                message: message,
                onRetry: () =>
                    ref.read(ordersControllerProvider.notifier).refresh(),
              ),
            ),
          );
        },
        data: (OrdersViewState viewState) => _OrdersContentView(
          viewState: viewState,
          horizontalMargin: horizontalMargin,
          initialOrderId: initialOrderId,
        ),
      ),
    );
  }
}

class _OrdersLoadingView extends StatelessWidget {
  const _OrdersLoadingView({required this.horizontalMargin});

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
        LoadingSkeleton(height: 52),
        SizedBox(height: AppSpacing.md),
        LoadingSkeleton(height: 48),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(height: 380),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(height: 140),
      ],
    );
  }
}

class _OrdersContentView extends ConsumerStatefulWidget {
  const _OrdersContentView({
    required this.viewState,
    required this.horizontalMargin,
    this.initialOrderId,
  });

  final OrdersViewState viewState;
  final double horizontalMargin;
  final String? initialOrderId;

  @override
  ConsumerState<_OrdersContentView> createState() => _OrdersContentViewState();
}

class _OrdersContentViewState extends ConsumerState<_OrdersContentView> {
  bool _hasOpenedInitialOrder = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndOpenInitialOrder();
    });
  }

  @override
  void didUpdateWidget(covariant _OrdersContentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialOrderId != oldWidget.initialOrderId) {
      _checkAndOpenInitialOrder();
    }
  }

  void _checkAndOpenInitialOrder() {
    if (!mounted || _hasOpenedInitialOrder) return;
    final String? targetId = widget.initialOrderId;
    if (targetId == null || targetId.isEmpty) return;

    final OrderSummary? match =
        widget.viewState.activeOrders
            .where((OrderSummary o) => o.id == targetId)
            .firstOrNull ??
        widget.viewState.historyOrders
            .where((OrderSummary o) => o.id == targetId)
            .firstOrNull;

    if (match != null) {
      _hasOpenedInitialOrder = true;
      _showLiveTrackingSheet(context, match);
    }
  }

  void _showLiveTrackingSheet(BuildContext context, OrderSummary order) {
    final AppPalette palette = context.palette;
    GlassSheet.show<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                      AppStrings.ordersLiveSheetTitle,
                      style: AppTypography.headlineMd.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
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
          const SizedBox(height: AppSpacing.lg),
          OrderStepper(
            status: order.status,
            remainingMinutes: order.remainingMinutes ?? 18,
            isExpress: order.isExpress,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${AppStrings.ordersToPrefix}${order.deliveryAddress}',
            style: AppTypography.labelMd.copyWith(color: palette.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          GlassButton.primary(
            label: AppStrings.actionClose,
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showChatCourierSheet(BuildContext context, OrderSummary order) {
    OrderChatSheet.show(context, order);
  }

  void _showReceiptSheet(BuildContext context, OrderSummary order) {
    OrderReceiptSheet.show(context, order);
  }

  Future<void> _handleReorder(BuildContext context, OrderSummary order) async {
    try {
      final ReorderValidationResult result = await ref
          .read(ordersControllerProvider.notifier)
          .revalidateReorder(order);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.priceChanged
                  ? '${AppStrings.ordersReorderSuccess} Total estimado: ${MoneyFormatter.format(result.revalidatedSubtotalCents)}'
                  : AppStrings.ordersReorderSuccess,
            ),
            backgroundColor: AppColors.success,
          ),
        );
        unawaited(context.push(AppRoutes.checkout));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.genericErrorMessage),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final OrdersViewState viewState = widget.viewState;
    final double horizontalMargin = widget.horizontalMargin;
    final AppPalette palette = context.palette;
    final OrderSummary? activeOrder = viewState.primaryActiveOrder;
    final bool isHistoryTab = viewState.selectedTab == OrdersTab.history;

    return RefreshIndicator(
      onRefresh: () => ref.read(ordersControllerProvider.notifier).refresh(),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontalMargin,
          AppSpacing.md,
          horizontalMargin,
          AppSpacing.scrollBottomReserve,
        ),
        children: <Widget>[
          HomeTopBar(
            onNotificationsTap: () => context.go(AppRoutes.profile),
            onProfileTap: () => context.go(AppRoutes.profile),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.ordersTitle,
            style: AppTypography.headlineLg.copyWith(
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OrdersSegmentedTabs(
            selectedTab: viewState.selectedTab,
            activeCount: viewState.activeOrders.length,
            onTabChanged: (OrdersTab tab) =>
                ref.read(ordersControllerProvider.notifier).selectTab(tab),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!isHistoryTab) ...<Widget>[
            // Tab En curso:
            if (activeOrder != null) ...<Widget>[
              ActiveOrderTrackingCard(
                order: activeOrder,
                onLiveTrackingTap: () =>
                    _showLiveTrackingSheet(context, activeOrder),
                onContactCourierTap: () =>
                    _showChatCourierSheet(context, activeOrder),
                onCallCourierTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(AppStrings.ordersCallingCourier),
                      backgroundColor: palette.surfaceRest,
                    ),
                  );
                },
                onChatCourierTap: () =>
                    _showChatCourierSheet(context, activeOrder),
              ),
              const SizedBox(height: AppSpacing.lg),
            ] else ...<Widget>[
              EmptyState(
                title: AppStrings.ordersEmptyActiveTitle,
                subtitle: AppStrings.ordersEmptyActiveSubtitle,
                actionLabel: AppStrings.ordersEmptyActiveCta,
                onAction: () => context.go(AppRoutes.home),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            // Previsualización del historial bajo el pedido activo (como en Stitch).
            if (viewState.historyOrders.isNotEmpty) ...<Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      AppStrings.ordersHistorySectionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headlineMd.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  InkWell(
                    onTap: () => ref
                        .read(ordersControllerProvider.notifier)
                        .selectTab(OrdersTab.history),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xs,
                      ),
                      child: Text(
                        AppStrings.ordersHistorySeeAll,
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              for (
                int i = 0;
                i < viewState.historyOrders.take(2).length;
                i++
              ) ...<Widget>[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                OrderHistoryCard(
                  order: viewState.historyOrders[i],
                  onReorderTap: () =>
                      _handleReorder(context, viewState.historyOrders[i]),
                  onReceiptTap: () =>
                      _showReceiptSheet(context, viewState.historyOrders[i]),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          ] else ...<Widget>[
            // Tab Historial completo:
            Text(
              AppStrings.ordersHistorySectionTitle,
              style: AppTypography.headlineMd.copyWith(
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (viewState.historyOrders.isEmpty)
              EmptyState(
                title: AppStrings.ordersEmptyHistoryTitle,
                subtitle: AppStrings.ordersEmptyHistorySubtitle,
                actionLabel: AppStrings.ordersEmptyActiveCta,
                onAction: () => context.go(AppRoutes.home),
              )
            else ...<Widget>[
              for (
                int i = 0;
                i < viewState.historyOrders.length;
                i++
              ) ...<Widget>[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                OrderHistoryCard(
                  order: viewState.historyOrders[i],
                  onReorderTap: () =>
                      _handleReorder(context, viewState.historyOrders[i]),
                  onReceiptTap: () =>
                      _showReceiptSheet(context, viewState.historyOrders[i]),
                ),
              ],
              if (viewState.hasMoreHistory) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                GlassButton.secondary(
                  label: AppStrings.ordersLoadMore,
                  isLoading: viewState.isLoadingMoreHistory,
                  expand: true,
                  onPressed: () => ref
                      .read(ordersControllerProvider.notifier)
                      .loadMoreHistory(),
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
          OrderSupportBanner(
            onSupportTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Atención local en General Alvear todos los días de 11:00 a 01:00 hs.',
                  ),
                  backgroundColor: palette.surfaceRest,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
