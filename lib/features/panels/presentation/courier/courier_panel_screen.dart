import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/features/panels/domain/panel_models.dart';
import 'package:clinapp/features/panels/presentation/controllers/courier_panel_controller.dart';
import 'package:clinapp/features/panels/presentation/courier/widgets/courier_delivery_card.dart';
import 'package:clinapp/features/panels/presentation/courier/widgets/courier_earnings_card.dart';
import 'package:clinapp/features/panels/presentation/courier/widgets/courier_header_bar.dart';
import 'package:clinapp/features/panels/presentation/courier/widgets/courier_shift_bar.dart';
import 'package:clinapp/shared/widgets/glass_background.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';
import 'package:clinapp/shared/widgets/glass_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Pantalla completa del Panel de Repartidor para General Alvear.
class CourierPanelScreen extends ConsumerWidget {
  const CourierPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final AsyncValue<CourierPanelViewState> asyncState = ref.watch(
      courierPanelControllerProvider,
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
                  'Error al cargar el panel: $err',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.accent),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (CourierPanelViewState viewState) {
              final CourierShiftState shift = viewState.shift;

              final List<CourierDeliveryItem> assignedList = shift.deliveries
                  .where(
                    (CourierDeliveryItem d) =>
                        d.status != CourierDeliveryStatus.delivered,
                  )
                  .toList();

              final List<CourierDeliveryItem> kitchenList = shift.deliveries
                  .where(
                    (CourierDeliveryItem d) =>
                        d.status == CourierDeliveryStatus.inKitchen,
                  )
                  .toList();

              final List<CourierDeliveryItem> historyList = shift.deliveries
                  .where(
                    (CourierDeliveryItem d) =>
                        d.status == CourierDeliveryStatus.delivered,
                  )
                  .toList();

              final List<CourierDeliveryItem> displayList =
                  switch (viewState.activeFilterIndex) {
                    0 => assignedList,
                    1 => kitchenList,
                    2 => const <CourierDeliveryItem>[],
                    3 => historyList,
                    _ => assignedList,
                  };

              return Column(
                children: <Widget>[
                  CourierHeaderBar(
                    isOnline: shift.isOnline,
                    assignedCount: assignedList.length,
                    kitchenCount: kitchenList.length,
                    availableCount: 0,
                    historyCount: shift.todayDeliveriesCount,
                    activeFilterIndex: viewState.activeFilterIndex,
                    onFilterChanged: (int idx) {
                      ref
                          .read(courierPanelControllerProvider.notifier)
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
                        CourierShiftBar(
                          isOnline: shift.isOnline,
                          assignedCount: assignedList.length,
                          isGpsActive: shift.isGpsActive,
                          onToggleShift: (bool online) {
                            ref
                                .read(courierPanelControllerProvider.notifier)
                                .toggleShift(online);
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (displayList.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xl,
                            ),
                            child: Center(
                              child: Text(
                                AppStrings.courierEmptyAssigned,
                                style: AppTypography.bodyMd.copyWith(
                                  color: palette.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        else
                          ...displayList.map(
                            (CourierDeliveryItem delivery) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: CourierDeliveryCard(
                                delivery: delivery,
                                onPickedUp: () async {
                                  await ref
                                      .read(
                                        courierPanelControllerProvider.notifier,
                                      )
                                      .markPickedUp(delivery.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          AppStrings
                                              .courierOrderPickedUpSuccess,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                onDelivered: () async {
                                  await ref
                                      .read(
                                        courierPanelControllerProvider.notifier,
                                      )
                                      .markDelivered(delivery.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          AppStrings
                                              .courierOrderDeliveredSuccess,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                onOpenMerchantInfo: () {
                                  _showMerchantModal(
                                    context,
                                    delivery.merchantName,
                                    delivery.merchantAddress,
                                    delivery.merchantPhone,
                                  );
                                },
                                onOpenMapRoute: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Iniciando GPS hacia ${delivery.customerAddress}',
                                      ),
                                    ),
                                  );
                                },
                                onContactCustomer: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Llamando a ${delivery.customerName} (${delivery.customerPhone})',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.xs),
                        CourierEarningsCard(
                          earningsCents: shift.todayEarningsCents,
                          deliveriesCount: shift.todayDeliveriesCount,
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

  static void _showMerchantModal(
    BuildContext context,
    String name,
    String address,
    String phone,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        final AppPalette palette = sheetContext.palette;
        return GlassSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                name,
                style: AppTypography.headlineMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  const Icon(
                    LucideIcons.mapPin,
                    size: 16,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      address,
                      style: AppTypography.bodySm.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: <Widget>[
                  const Icon(
                    LucideIcons.phone,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Tel: $phone',
                    style: AppTypography.bodySm.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              GlassButton.primary(
                label: 'Cerrar',
                expand: true,
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }
}
