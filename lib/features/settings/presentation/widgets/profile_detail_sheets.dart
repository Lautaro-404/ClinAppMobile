import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/config/env.dart';
import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/core/theme/theme_mode_provider.dart';
import 'package:clinapp/core/utils/money_formatter.dart';
import 'package:clinapp/features/auth/domain/auth_models.dart';
import 'package:clinapp/features/auth/presentation/auth_controller.dart';
import 'package:clinapp/features/home/domain/home_models.dart';
import 'package:clinapp/features/settings/domain/settings_models.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';
import 'package:clinapp/shared/widgets/glass_quality.dart';
import 'package:clinapp/shared/widgets/glass_sheet.dart';
import 'package:clinapp/shared/widgets/glass_text_field.dart';

/// Hojas modales Liquid Glass para las opciones de cuenta y configuración.
abstract final class ProfileDetailSheets {
  /// Hoja modal para gestionar direcciones de entrega.
  static void showAddresses(
    BuildContext context, {
    required List<SavedAddressItem> addresses,
    required ValueChanged<String> onAddAddress,
    ValueChanged<String>? onSetDefault,
    ValueChanged<String>? onDeleteAddress,
  }) {
    final TextEditingController newAddrController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final AppPalette palette = sheetContext.palette;

        return GlassSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                AppStrings.profileAddressesTitle,
                style: AppTypography.headlineMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (addresses.isEmpty)
                Text(
                  AppStrings.profileNoAddresses,
                  style: AppTypography.bodyMd.copyWith(
                    color: palette.textSecondary,
                  ),
                )
              else
                ...addresses.map(
                  (SavedAddressItem addr) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: palette.glassFill1,
                        borderRadius: AppRadii.baseAll,
                        border: Border.all(
                          color: addr.isDefault
                              ? AppColors.accent
                              : palette.rimSoft,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            LucideIcons.mapPin,
                            size: 18,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: InkWell(
                              onTap: onSetDefault != null
                                  ? () => onSetDefault(addr.id)
                                  : null,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    addr.addressLine,
                                    style: AppTypography.labelMd.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${addr.title} • ${addr.city}',
                                    style: AppTypography.bodySm.copyWith(
                                      color: palette.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (addr.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: const BoxDecoration(
                                color: Color.fromRGBO(232, 82, 58, 0.20),
                                borderRadius: AppRadii.pillAll,
                              ),
                              child: Text(
                                'Principal',
                                style: AppTypography.labelSm.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else if (onDeleteAddress != null)
                            IconButton(
                              icon: Icon(
                                LucideIcons.trash2,
                                size: 16,
                                color: palette.textTertiary,
                              ),
                              tooltip: 'Eliminar dirección',
                              onPressed: () {
                                onDeleteAddress(addr.id);
                                Navigator.of(sheetContext).pop();
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              GlassTextField(
                controller: newAddrController,
                hintText: 'Ej: Paso de los Andes 120',
                leadingIcon: LucideIcons.plus,
              ),
              const SizedBox(height: AppSpacing.md),
              GlassButton.primary(
                label: AppStrings.profileNewAddressAction,
                expand: true,
                onPressed: () {
                  final String text = newAddrController.text.trim();
                  if (text.isNotEmpty) {
                    onAddAddress(text);
                    Navigator.of(sheetContext).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Hoja modal para listar y gestionar comercios favoritos del usuario.
  static void showFavorites(
    BuildContext context, {
    required List<MerchantSummary> favorites,
    required ValueChanged<String> onToggleFavorite,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final AppPalette palette = sheetContext.palette;

        return GlassSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                AppStrings.profileFavoritesTitle,
                style: AppTypography.headlineMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (favorites.isEmpty)
                Text(
                  AppStrings.profileNoFavorites,
                  style: AppTypography.bodyMd.copyWith(
                    color: palette.textSecondary,
                  ),
                )
              else
                ...favorites.map(
                  (MerchantSummary merchant) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: palette.glassFill1,
                        borderRadius: AppRadii.baseAll,
                        border: Border.all(color: palette.rimSoft),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            LucideIcons.store,
                            size: 20,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  merchant.name,
                                  style: AppTypography.labelMd.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: palette.textPrimary,
                                  ),
                                ),
                                Text(
                                  merchant.tagLabel,
                                  style: AppTypography.bodySm.copyWith(
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              LucideIcons.heart,
                              size: 18,
                              color: AppColors.danger,
                            ),
                            tooltip: 'Quitar de favoritos',
                            onPressed: () {
                              onToggleFavorite(merchant.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Hoja modal para editar datos personales del perfil (nombre y teléfono).
  static void showEditProfile(
    BuildContext context, {
    required AuthUserSession session,
    required Future<void> Function(String name, String phone) onSave,
  }) {
    final TextEditingController nameController = TextEditingController(
      text: session.fullName,
    );
    final TextEditingController phoneController = TextEditingController(
      text: session.phone,
    );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final AppPalette palette = sheetContext.palette;

        return GlassSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Editar datos personales',
                style: AppTypography.headlineMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GlassTextField(
                controller: nameController,
                hintText: 'Nombre completo',
                leadingIcon: LucideIcons.user,
              ),
              const SizedBox(height: AppSpacing.sm),
              GlassTextField(
                controller: phoneController,
                hintText: 'Teléfono',
                leadingIcon: LucideIcons.phone,
              ),
              const SizedBox(height: AppSpacing.md),
              GlassButton.primary(
                label: 'Guardar cambios',
                expand: true,
                onPressed: () async {
                  final String name = nameController.text.trim();
                  final String phone = phoneController.text.trim();
                  if (name.isNotEmpty) {
                    await onSave(name, phone);
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Hoja modal para métodos de pago.
  static void showPaymentMethods(BuildContext context) {
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
                AppStrings.profilePaymentMethodsTitle,
                style: AppTypography.headlineMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _infoTile(
                palette: palette,
                icon: LucideIcons.wallet,
                iconColor: AppColors.accent,
                title: 'Mercado Pago',
                subtitle: 'Saldo disponible y dinero en cuenta.',
              ),
              const SizedBox(height: AppSpacing.sm),
              _infoTile(
                palette: palette,
                icon: LucideIcons.banknote,
                iconColor: AppColors.success,
                title: 'Efectivo contra entrega',
                subtitle: 'Abonás en mano al recibir el pedido en tu puerta.',
              ),
            ],
          ),
        );
      },
    );
  }

  /// Hoja modal para notificaciones del usuario.
  static void showNotifications(
    BuildContext context, {
    required List<UserNotificationItem> notifications,
    required VoidCallback onClear,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final AppPalette palette = sheetContext.palette;

        return GlassSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                AppStrings.profileNotificationsTitle,
                style: AppTypography.headlineMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (notifications.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: Text(
                      AppStrings.profileNoNotifications,
                      style: AppTypography.bodyMd.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                ...notifications.map(
                  (UserNotificationItem n) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: palette.glassFill1,
                        borderRadius: AppRadii.baseAll,
                        border: Border.all(color: palette.rimSoft),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  n.title,
                                  style: AppTypography.labelMd.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                n.timeAgo,
                                style: AppTypography.labelSm.copyWith(
                                  color: palette.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            n.message,
                            style: AppTypography.bodySm.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              GlassButton.secondary(
                label: AppStrings.profileClearNotifications,
                expand: true,
                onPressed: () {
                  onClear();
                  Navigator.of(sheetContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Hoja modal para cupones disponibles.
  static void showCoupons(
    BuildContext context, {
    required List<AvailableCouponItem> coupons,
  }) {
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
                AppStrings.profileCouponsTitle,
                style: AppTypography.headlineMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...coupons.map(
                (AvailableCouponItem c) => Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: palette.glassFill1,
                    borderRadius: AppRadii.baseAll,
                    border: Border.all(color: AppColors.accent),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        LucideIcons.ticket,
                        size: 24,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              c.code,
                              style: AppTypography.headlineMd.copyWith(
                                color: AppColors.accentGlow,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              c.title,
                              style: AppTypography.bodySm.copyWith(
                                fontWeight: FontWeight.w600,
                                color: palette.textPrimary,
                              ),
                            ),
                            Text(
                              'Ahorro de ${MoneyFormatter.format(c.discountAmountCents)}',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Hoja modal de Ayuda y Soporte.
  static void showHelp(BuildContext context) {
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
                AppStrings.profileHelpTitle,
                style: AppTypography.headlineMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _infoTile(
                palette: palette,
                icon: LucideIcons.messageSquare,
                iconColor: AppColors.success,
                title: 'WhatsApp de Soporte Alvear',
                subtitle: 'Atención directa de 10:00 a 00:00 hs.',
              ),
              const SizedBox(height: AppSpacing.sm),
              InkWell(
                borderRadius: AppRadii.baseAll,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  showPrivacyPolicy(context);
                },
                child: _infoTile(
                  palette: palette,
                  icon: LucideIcons.fileText,
                  iconColor: AppColors.accent,
                  title: AppStrings.privacyPolicyTitle,
                  subtitle: AppStrings.privacyPolicySubtitle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Hoja modal con la Política de Privacidad y Uso de Datos en General Alvear.
  static void showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final AppPalette palette = sheetContext.palette;

        return GlassSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                AppStrings.privacyPolicyTitle,
                style: AppTypography.headlineMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.privacyPolicyBody,
                style: AppTypography.bodySm.copyWith(
                  color: palette.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              GlassButton.primary(
                label: AppStrings.actionClose,
                expand: true,
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Hoja modal para Ajustes, selección de tema visual y Rol de prueba (Demo).
  static void showAppSettings(
    BuildContext context, {
    required WidgetRef ref,
    required AppUserRole currentRole,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final AppPalette palette = sheetContext.palette;
        final GlassQuality quality = ref.watch(glassQualityProvider);
        final ThemeMode currentThemeMode = ref.watch(themeModeProvider);

        return GlassSheet(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  AppStrings.profileSettingsTitle,
                  style: AppTypography.headlineMd.copyWith(
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Selector de Modo de Tema (Sistema / Claro / Oscuro)
                Text(
                  AppStrings.profileThemeModeTitle,
                  style: AppTypography.labelLg.copyWith(
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _ModePillButton(
                        label: AppStrings.profileThemeModeSystem,
                        icon: LucideIcons.smartphone,
                        isSelected: currentThemeMode == ThemeMode.system,
                        palette: palette,
                        onPressed: () {
                          ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.system);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _ModePillButton(
                        label: AppStrings.profileThemeModeLight,
                        icon: LucideIcons.sun,
                        isSelected: currentThemeMode == ThemeMode.light,
                        palette: palette,
                        onPressed: () {
                          ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.light);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _ModePillButton(
                        label: AppStrings.profileThemeModeDark,
                        icon: LucideIcons.moon,
                        isSelected: currentThemeMode == ThemeMode.dark,
                        palette: palette,
                        onPressed: () {
                          ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.dark);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Selector de calidad de vidrio
                Text(
                  AppStrings.profileSettingsThemeTitle,
                  style: AppTypography.labelLg.copyWith(
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: quality == GlassQuality.high
                              ? palette.glassFill2
                              : Colors.transparent,
                          side: BorderSide(
                            color: quality == GlassQuality.high
                                ? AppColors.accent
                                : palette.rimSoft,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadii.pillAll,
                          ),
                        ),
                        onPressed: () {
                          ref
                              .read(glassQualityProvider.notifier)
                              .setQuality(GlassQuality.high);
                        },
                        child: Text(
                          AppStrings.catalogQualityHigh,
                          style: AppTypography.labelMd.copyWith(
                            color: quality == GlassQuality.high
                                ? AppColors.accent
                                : palette.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: quality == GlassQuality.low
                              ? palette.glassFill2
                              : Colors.transparent,
                          side: BorderSide(
                            color: quality == GlassQuality.low
                                ? AppColors.accent
                                : palette.rimSoft,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadii.pillAll,
                          ),
                        ),
                        onPressed: () {
                          ref
                              .read(glassQualityProvider.notifier)
                              .setQuality(GlassQuality.low);
                        },
                        child: Text(
                          AppStrings.catalogQualityLow,
                          style: AppTypography.labelMd.copyWith(
                            color: quality == GlassQuality.low
                                ? AppColors.accent
                                : palette.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (Env.enableDemoRoleSwitcher) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  // Selector de Rol de demostración (solo en dev)
                  Text(
                    AppStrings.profileSettingsRoleTitle,
                    style: AppTypography.labelLg.copyWith(
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ...AppUserRole.values.map(
                    (AppUserRole r) => Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _labelForRole(r),
                          style: AppTypography.labelMd.copyWith(
                            color: currentRole == r
                                ? AppColors.accent
                                : palette.textPrimary,
                            fontWeight: currentRole == r
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: currentRole == r
                            ? const Icon(
                                LucideIcons.check,
                                color: AppColors.accent,
                                size: 18,
                              )
                            : null,
                        onTap: () async {
                          await ref
                              .read(authControllerProvider.notifier)
                              .switchRole(r);
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${AppStrings.profileRoleSwitchedPrefix}${_labelForRole(r)}',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Text(
                  AppStrings.deleteAccountSectionTitle,
                  style: AppTypography.labelLg.copyWith(
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSpacing.minTapTarget),
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.pillAll,
                    ),
                  ),
                  icon: const Icon(
                    LucideIcons.trash2,
                    size: 18,
                    color: AppColors.danger,
                  ),
                  label: Text(
                    AppStrings.deleteAccountCta,
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    showDeleteAccountDialog(context, ref: ref);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Diálogo de confirmación de doble paso para eliminar permanentemente la cuenta.
  static void showDeleteAccountDialog(
    BuildContext context, {
    required WidgetRef ref,
  }) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final AppPalette palette = dialogContext.palette;
        return AlertDialog(
          backgroundColor: palette.surfaceRest,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.mdAll,
            side: BorderSide(color: palette.rimMedium),
          ),
          title: Text(
            AppStrings.deleteAccountConfirmTitle,
            style: AppTypography.headlineMd.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            AppStrings.deleteAccountConfirmBody,
            style: AppTypography.bodySm.copyWith(color: palette.textSecondary),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                AppStrings.deleteAccountCancel,
                style: AppTypography.labelMd.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await ref
                      .read(authControllerProvider.notifier)
                      .deleteAccount();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(AppStrings.deleteAccountSuccess),
                      ),
                    );
                  }
                } on Object catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppException.fromError(error).message),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                }
              },
              child: Text(
                AppStrings.deleteAccountConfirmAction,
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Hoja informativa para los paneles por rol.
  static void showRolePanelInfo(BuildContext context, String panelTitle) {
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
                panelTitle,
                style: AppTypography.headlineMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: palette.glassFill1,
                  borderRadius: AppRadii.baseAll,
                  border: Border.all(color: palette.rimSoft),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      LucideIcons.sparkles,
                      size: 24,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Acceso autorizado',
                            style: AppTypography.labelMd.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Estás operando en $panelTitle como usuario verificado de General Alvear.',
                            style: AppTypography.bodySm.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              GlassButton.primary(
                label: 'Aceptar',
                expand: true,
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _infoTile({
    required AppPalette palette,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.glassFill1,
        borderRadius: AppRadii.baseAll,
        border: Border.all(color: palette.rimSoft),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTypography.labelMd.copyWith(
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySm.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _labelForRole(AppUserRole r) {
    switch (r) {
      case AppUserRole.cliente:
        return AppStrings.profileRoleClient;
      case AppUserRole.local:
        return AppStrings.profileRoleMerchant;
      case AppUserRole.repartidor:
        return AppStrings.profileRoleCourier;
      case AppUserRole.admin:
        return AppStrings.profileRoleAdmin;
    }
  }
}

class _ModePillButton extends StatelessWidget {
  const _ModePillButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.palette,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final AppPalette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        backgroundColor: isSelected ? palette.glassFill2 : Colors.transparent,
        side: BorderSide(
          color: isSelected ? AppColors.accent : palette.rimSoft,
          width: isSelected ? 1.5 : 1,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.pillAll),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 15,
            color: isSelected ? AppColors.accent : palette.textSecondary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSm.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.accent : palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
