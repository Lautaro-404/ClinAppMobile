import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/core/utils/money_formatter.dart';
import 'package:clinapp/features/panels/domain/panel_models.dart';
import 'package:clinapp/features/panels/presentation/controllers/merchant_panel_controller.dart';
import 'package:clinapp/features/panels/presentation/merchant/widgets/merchant_header_bar.dart';
import 'package:clinapp/features/panels/presentation/merchant/widgets/merchant_menu_quick_card.dart';
import 'package:clinapp/features/panels/presentation/merchant/widgets/merchant_order_card.dart';
import 'package:clinapp/features/panels/presentation/merchant/widgets/merchant_status_bar.dart';
import 'package:clinapp/shared/widgets/glass_background.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';

/// Pantalla completa del Panel Mi Local (Comercio de General Alvear).
class MerchantPanelScreen extends ConsumerWidget {
  const MerchantPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final AsyncValue<MerchantPanelViewState> asyncState = ref.watch(
      merchantPanelControllerProvider,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          child: asyncState.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
            error: (Object err, StackTrace? stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Error al cargar el panel de local: $err',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.accent),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (MerchantPanelViewState viewState) {
              final MerchantDashboardState dash = viewState.dashboard;

              final List<MerchantOrderItem> incomingList = dash.orders
                  .where(
                    (MerchantOrderItem o) =>
                        o.status == MerchantOrderStatus.incoming,
                  )
                  .toList();

              final List<MerchantOrderItem> kitchenList = dash.orders
                  .where(
                    (MerchantOrderItem o) =>
                        o.status == MerchantOrderStatus.inKitchen,
                  )
                  .toList();

              final List<MerchantOrderItem> readyList = dash.orders
                  .where(
                    (MerchantOrderItem o) =>
                        o.status == MerchantOrderStatus.readyForPickup,
                  )
                  .toList();

              return Column(
                children: <Widget>[
                  MerchantHeaderBar(
                    isOpen: dash.isOpen,
                    incomingCount: incomingList.length,
                    kitchenCount: kitchenList.length,
                    readyCount: readyList.length,
                    menuCount: dash.menuItems.length,
                    activeFilterIndex: viewState.activeFilterIndex,
                    onFilterChanged: (int idx) {
                      ref
                          .read(merchantPanelControllerProvider.notifier)
                          .setFilterTab(idx);
                    },
                    onBack: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/perfil');
                      }
                    },
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: <Widget>[
                        MerchantStatusBar(
                          isOpen: dash.isOpen,
                          onToggleOpen: (bool open) {
                            ref
                                .read(merchantPanelControllerProvider.notifier)
                                .toggleOpen(open);
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Vista según la pestaña activa
                        if (viewState.activeFilterIndex == 3) ...<Widget>[
                          ...dash.menuItems.map(
                            (MerchantMenuItem item) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: MerchantMenuQuickCard(
                                item: item,
                                onToggleStock: (bool available) {
                                  ref
                                      .read(
                                        merchantPanelControllerProvider
                                            .notifier,
                                      )
                                      .toggleStock(item.id, available);
                                },
                              ),
                            ),
                          ),
                        ] else ...<Widget>[
                          () {
                            final List<MerchantOrderItem> currentList =
                                switch (viewState.activeFilterIndex) {
                                  0 => incomingList,
                                  1 => kitchenList,
                                  2 => readyList,
                                  _ => incomingList,
                                };

                            if (currentList.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.xl,
                                ),
                                child: Center(
                                  child: Text(
                                    AppStrings.merchantEmptyOrders,
                                    style: AppTypography.bodyMd.copyWith(
                                      color: palette.textSecondary,
                                    ),
                                  ),
                                ),
                              );
                            }

                            return Column(
                              children: currentList
                                  .map(
                                    (MerchantOrderItem order) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSpacing.md,
                                      ),
                                      child: MerchantOrderCard(
                                        order: order,
                                        onAcceptKitchen: () {
                                          ref
                                              .read(
                                                merchantPanelControllerProvider
                                                    .notifier,
                                              )
                                              .acceptOrder(order.id);
                                        },
                                        onMarkReady: () {
                                          ref
                                              .read(
                                                merchantPanelControllerProvider
                                                    .notifier,
                                              )
                                              .markReady(order.id);
                                        },
                                        onDispatch: () {
                                          ref
                                              .read(
                                                merchantPanelControllerProvider
                                                    .notifier,
                                              )
                                              .dispatchOrder(order.id);
                                        },
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          }(),
                        ],

                        const SizedBox(height: AppSpacing.sm),

                        // Resumen de caja del día
                        GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: <Color>[
                                      Color(0xFFE8523A),
                                      Color(0xFFC0392B),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: AppRadii.baseAll,
                                  border: Border.all(color: palette.rimStrong),
                                ),
                                child: const Icon(
                                  LucideIcons.banknote,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      AppStrings.merchantTodayRevenue,
                                      style: AppTypography.labelMd.copyWith(
                                        color: palette.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      MoneyFormatter.format(
                                        dash.todayRevenueCents,
                                      ),
                                      style: AppTypography.headlineMd.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(
                                    232,
                                    82,
                                    58,
                                    0.15,
                                  ),
                                  borderRadius: AppRadii.pillAll,
                                  border: Border.all(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  '${dash.todayCompletedOrders} despachados',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
