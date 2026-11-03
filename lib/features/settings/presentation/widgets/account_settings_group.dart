import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';

/// Opciones configurables en el grupo de cuenta.
enum AccountOption {
  addresses,
  paymentMethods,
  favorites,
  notifications,
  coupons,
  help,
  settings,
}

/// Grupo "CUENTA & GENERAL" con las 7 opciones del diseño de Stitch.
class AccountSettingsGroup extends StatelessWidget {
  const AccountSettingsGroup({super.key, required this.onSelectOption});

  final ValueChanged<AccountOption> onSelectOption;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

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
            AppStrings.profileAccountSection,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _AccountTile(
                icon: LucideIcons.mapPin,
                iconColor: AppColors.accent,
                title: AppStrings.profileAddressesTitle,
                subtitle: AppStrings.profileAddressesSubtitle,
                palette: palette,
                onTap: () => onSelectOption(AccountOption.addresses),
              ),
              _TileDivider(color: palette.rimSoft),
              _AccountTile(
                icon: LucideIcons.creditCard,
                iconColor: AppColors.success,
                title: AppStrings.profilePaymentMethodsTitle,
                subtitle: AppStrings.profilePaymentMethodsSubtitle,
                palette: palette,
                onTap: () => onSelectOption(AccountOption.paymentMethods),
              ),
              _TileDivider(color: palette.rimSoft),
              _AccountTile(
                icon: LucideIcons.heart,
                iconColor: AppColors.danger,
                title: AppStrings.profileFavoritesTitle,
                subtitle: AppStrings.profileFavoritesSubtitle,
                palette: palette,
                onTap: () => onSelectOption(AccountOption.favorites),
              ),
              _TileDivider(color: palette.rimSoft),
              _AccountTile(
                icon: LucideIcons.bell,
                iconColor: AppColors.accentGlow,
                title: AppStrings.profileNotificationsTitle,
                subtitle: AppStrings.profileNotificationsSubtitle,
                palette: palette,
                onTap: () => onSelectOption(AccountOption.notifications),
              ),
              _TileDivider(color: palette.rimSoft),
              _AccountTile(
                icon: LucideIcons.ticket,
                iconColor: AppColors.accent,
                title: AppStrings.profileCouponsTitle,
                subtitle: AppStrings.profileCouponsEmptySubtitle,
                palette: palette,
                onTap: () => onSelectOption(AccountOption.coupons),
              ),
              _TileDivider(color: palette.rimSoft),
              _AccountTile(
                icon: LucideIcons.helpCircle,
                iconColor: palette.textSecondary,
                title: AppStrings.profileHelpTitle,
                subtitle: AppStrings.profileHelpSubtitle,
                palette: palette,
                onTap: () => onSelectOption(AccountOption.help),
              ),
              _TileDivider(color: palette.rimSoft),
              _AccountTile(
                icon: LucideIcons.settings,
                iconColor: palette.textSecondary,
                title: AppStrings.profileSettingsTitle,
                subtitle: AppStrings.profileSettingsSubtitle,
                palette: palette,
                onTap: () => onSelectOption(AccountOption.settings),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
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
                color: palette.glassFill2,
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
