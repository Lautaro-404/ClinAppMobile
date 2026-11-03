import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/features/auth/domain/auth_models.dart';

/// Grupo "GESTIÓN Y ADMINISTRACIÓN" que muestra los paneles correspondientes
/// según el rol del usuario (Admin, Local, Repartidor).
class RoleManagementGroup extends StatelessWidget {
  const RoleManagementGroup({
    super.key,
    required this.role,
    required this.onOpenPanel,
  });

  final AppUserRole role;
  final ValueChanged<String> onOpenPanel;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool showAdmin = role.canAccessAdminPanel;
    final bool showMerchant = role.canAccessMerchantPanel;
    final bool showCourier = role.canAccessCourierPanel;

    if (!showAdmin && !showMerchant && !showCourier) {
      return const SizedBox.shrink();
    }

    final List<Widget> items = <Widget>[];

    if (showAdmin) {
      items.add(
        _PanelTile(
          icon: LucideIcons.bookOpen,
          iconColor: AppColors.accent,
          iconBgColor: const Color.fromRGBO(232, 82, 58, 0.16),
          title: AppStrings.profileAdminPanelTitle,
          subtitle: AppStrings.profileAdminPanelSubtitle,
          palette: palette,
          onTap: () => onOpenPanel(AppStrings.profileAdminPanelTitle),
        ),
      );
    }

    if (showMerchant) {
      if (items.isNotEmpty) items.add(_TileDivider(color: palette.rimSoft));
      items.add(
        _PanelTile(
          icon: LucideIcons.store,
          iconColor: AppColors.accentGlow,
          iconBgColor: const Color.fromRGBO(255, 107, 74, 0.16),
          title: AppStrings.profileMerchantPanelTitle,
          subtitle: AppStrings.profileMerchantPanelSubtitle,
          palette: palette,
          onTap: () => onOpenPanel(AppStrings.profileMerchantPanelTitle),
        ),
      );
    }

    if (showCourier) {
      if (items.isNotEmpty) items.add(_TileDivider(color: palette.rimSoft));
      items.add(
        _PanelTile(
          icon: LucideIcons.bike,
          iconColor: AppColors.success,
          iconBgColor: const Color.fromRGBO(16, 185, 129, 0.16),
          title: AppStrings.profileCourierPanelTitle,
          subtitle: AppStrings.profileCourierPanelSubtitle,
          palette: palette,
          onTap: () => onOpenPanel(AppStrings.profileCourierPanelTitle),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.xs,
          ),
          child: Text(
            AppStrings.profileManagementSection,
            style: AppTypography.labelSm.copyWith(
              color: palette.textTertiary,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: palette.glassFill1,
            borderRadius: AppRadii.mdAll,
            border: Border.all(color: palette.rimSoft),
            boxShadow: palette.cardShadows,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(mainAxisSize: MainAxisSize.min, children: items),
        ),
      ],
    );
  }
}

class _PanelTile extends StatelessWidget {
  const _PanelTile({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: AppRadii.baseAll,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTypography.labelLg.copyWith(
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: AppTypography.bodySm.copyWith(
                      color: palette.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: palette.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: color,
      indent: AppSpacing.md,
      endIndent: AppSpacing.md,
    );
  }
}
