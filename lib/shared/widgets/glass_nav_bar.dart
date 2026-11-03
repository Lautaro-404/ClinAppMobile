import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_shadows.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/core/theme/glass_tokens.dart';
import 'package:clinapp/shared/widgets/glass_surface.dart';

/// Barra de navegación inferior flotante en forma de píldora (`DESIGN.md`).
///
/// Usa vidrio Nivel 2 con blur 24-28, envuelta en un [RepaintBoundary] y separada
/// a 20px de los bordes laterales y 24px sobre el indicador inferior del sistema.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    required this.currentIndex,
    required this.onTap,
    super.key,
    this.activeOrdersCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int activeOrdersCount;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final double horizontalMargin = AppSpacing.marginFor(
      MediaQuery.sizeOf(context).width,
    );

    final List<_NavItemData> items = <_NavItemData>[
      const _NavItemData(label: AppStrings.navHome, icon: LucideIcons.house),
      const _NavItemData(label: AppStrings.navSearch, icon: LucideIcons.search),
      _NavItemData(
        label: AppStrings.navOrders,
        icon: LucideIcons.receiptText,
        badgeCount: activeOrdersCount,
      ),
      const _NavItemData(label: AppStrings.navProfile, icon: LucideIcons.user),
    ];

    return SafeArea(
      top: false,
      minimum: EdgeInsets.only(
        left: horizontalMargin,
        right: horizontalMargin,
        bottom: AppSpacing.navBottomOffset,
      ),
      child: RepaintBoundary(
        child: GlassSurface(
          level: GlassTokens.level2,
          borderRadius: AppRadii.pillAll,
          enableBlur: true,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs + 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List<Widget>.generate(items.length, (int index) {
              return Expanded(
                child: _NavBarDestination(
                  data: items[index],
                  isSelected: index == currentIndex,
                  onTap: () => onTap(index),
                  inactiveColor: palette.textSecondary,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.label,
    required this.icon,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final int badgeCount;
}

class _NavBarDestination extends StatelessWidget {
  const _NavBarDestination({
    required this.data,
    required this.isSelected,
    required this.onTap,
    required this.inactiveColor,
  });

  final _NavItemData data;
  final bool isSelected;
  final VoidCallback onTap;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final Color fg = isSelected ? AppColors.onAccent : inactiveColor;
    final String semanticsLabel = data.badgeCount > 0
        ? '${data.label}, ${data.badgeCount} '
              '${AppStrings.navActiveOrdersBadgeSemantics}'
        : data.label;

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticsLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.minTapTarget,
          minWidth: AppSpacing.minTapTarget,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.transparent,
            borderRadius: AppRadii.pillAll,
            boxShadow: isSelected ? AppShadows.accentButton : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadii.pillAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        Icon(data.icon, size: 20, color: fg),
                        if (data.badgeCount > 0)
                          Positioned(
                            top: -5,
                            right: -9,
                            child: _BadgeBubble(
                              count: data.badgeCount,
                              inverted: isSelected,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSm.copyWith(
                        color: fg,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
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

class _BadgeBubble extends StatelessWidget {
  const _BadgeBubble({required this.count, required this.inverted});

  final int count;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final Color bg = inverted ? Colors.white : AppColors.accent;
    final Color fg = inverted ? AppColors.accent : AppColors.onAccent;

    return DecoratedBox(
      decoration: BoxDecoration(color: bg, borderRadius: AppRadii.pillAll),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Center(
            child: Text(
              '$count',
              style: AppTypography.labelSm.copyWith(
                fontSize: 10,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
