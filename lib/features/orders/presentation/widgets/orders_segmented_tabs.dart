import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_shadows.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/features/orders/presentation/orders_controller.dart';

/// Selector segmentado tipo píldora de vidrio para cambiar entre En curso e Historial.
class OrdersSegmentedTabs extends StatelessWidget {
  const OrdersSegmentedTabs({
    required this.selectedTab,
    required this.activeCount,
    required this.onTabChanged,
    super.key,
  });

  final OrdersTab selectedTab;
  final int activeCount;
  final ValueChanged<OrdersTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final String activeLabel = activeCount > 0
        ? '${AppStrings.ordersActiveTab} ($activeCount)'
        : AppStrings.ordersActiveTab;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: palette.glassFill2,
        borderRadius: AppRadii.pillAll,
        border: Border.all(color: palette.rimMedium),
        boxShadow: palette.cardShadows,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _TabButton(
              label: activeLabel,
              icon: LucideIcons.bike,
              isSelected: selectedTab == OrdersTab.active,
              onTap: () => onTabChanged(OrdersTab.active),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _TabButton(
              label: AppStrings.ordersHistoryTab,
              icon: LucideIcons.history,
              isSelected: selectedTab == OrdersTab.history,
              onTap: () => onTabChanged(OrdersTab.history),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final Color textColor = isSelected
        ? AppColors.onAccent
        : palette.textSecondary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTapTarget),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[AppColors.accentGlow, AppColors.accent],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: AppRadii.pillAll,
            border: isSelected ? Border.all(color: AppColors.rimStrong) : null,
            boxShadow: isSelected ? AppShadows.accentButton : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadii.pillAll,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(icon, size: 18, color: textColor),
                      const SizedBox(width: AppSpacing.xs + 2),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelMd.copyWith(
                            color: textColor,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
