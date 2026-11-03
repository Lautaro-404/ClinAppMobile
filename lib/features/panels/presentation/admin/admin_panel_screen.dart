import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/core/utils/money_formatter.dart';
import 'package:clinapp/features/panels/domain/panel_models.dart';
import 'package:clinapp/features/panels/presentation/admin/widgets/admin_actor_card.dart';
import 'package:clinapp/features/panels/presentation/admin/widgets/admin_header_bar.dart';
import 'package:clinapp/features/panels/presentation/admin/widgets/admin_kpi_grid.dart';
import 'package:clinapp/features/panels/presentation/admin/widgets/admin_revenue_card.dart';
import 'package:clinapp/features/panels/presentation/controllers/admin_panel_controller.dart';
import 'package:clinapp/shared/widgets/glass_background.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';

/// Pantalla completa del Panel de Administrador para General Alvear.
class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final AsyncValue<AdminPanelViewState> asyncState = ref.watch(
      adminPanelControllerProvider,
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
                  'Error al cargar el panel admin: $err',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.accent),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (AdminPanelViewState viewState) {
              final AdminDashboardState dash = viewState.dashboard;

              return Column(
                children: <Widget>[
                  AdminHeaderBar(
                    merchantsCount: dash.merchants.length,
                    couriersCount: dash.couriers.length,
                    activeFilterIndex: viewState.activeFilterIndex,
                    onFilterChanged: (int idx) {
                      ref
                          .read(adminPanelControllerProvider.notifier)
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
                        if (viewState.activeFilterIndex == 0) ...<Widget>[
                          AdminKpiGrid(
                            activeOrders: dash.activeOrders,
                            activeCouriers: dash.activeCouriers,
                            openMerchants: dash.openMerchants,
                            avgDeliveryMinutes: dash.avgDeliveryMinutes,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AdminRevenueCard(
                            todayGmvCents: dash.todayGmvCents,
                            todayCommissionsCents: dash.todayCommissionsCents,
                          ),
                        ] else if (viewState.activeFilterIndex ==
                            1) ...<Widget>[
                          ...dash.merchants.map(
                            (AdminMerchantSummary m) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: AdminActorCard.merchant(
                                merchant: m,
                                onToggleActive: (bool open) {
                                  ref
                                      .read(
                                        adminPanelControllerProvider.notifier,
                                      )
                                      .toggleMerchant(m.id, open);
                                },
                              ),
                            ),
                          ),
                        ] else if (viewState.activeFilterIndex ==
                            2) ...<Widget>[
                          ...dash.couriers.map(
                            (AdminCourierSummary c) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: AdminActorCard.courier(courier: c),
                            ),
                          ),
                        ] else if (viewState.activeFilterIndex ==
                            3) ...<Widget>[
                          GlassCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  AppStrings.adminBaseDeliveryFee,
                                  style: AppTypography.headlineMd.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: palette.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Aplica a todos los pedidos dentro del radio urbano de General Alvear.',
                                  style: AppTypography.bodySm.copyWith(
                                    color: palette.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(
                                      MoneyFormatter.format(
                                        dash.baseDeliveryFeeCents,
                                      ),
                                      style: AppTypography.headlineLg.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    Row(
                                      children: <Widget>[
                                        IconButton(
                                          icon: const Icon(
                                            LucideIcons.minusCircle,
                                          ),
                                          color: palette.textPrimary,
                                          onPressed: () {
                                            if (dash.baseDeliveryFeeCents >
                                                50000) {
                                              ref
                                                  .read(
                                                    adminPanelControllerProvider
                                                        .notifier,
                                                  )
                                                  .updateDeliveryFee(
                                                    dash.baseDeliveryFeeCents -
                                                        10000,
                                                  );
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            LucideIcons.plusCircle,
                                          ),
                                          color: AppColors.accent,
                                          onPressed: () {
                                            ref
                                                .read(
                                                  adminPanelControllerProvider
                                                      .notifier,
                                                )
                                                .updateDeliveryFee(
                                                  dash.baseDeliveryFeeCents +
                                                      10000,
                                                );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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
