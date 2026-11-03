import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/router/app_routes.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/features/auth/domain/auth_models.dart';
import 'package:clinapp/features/auth/presentation/auth_controller.dart';
import 'package:clinapp/features/settings/domain/settings_models.dart';
import 'package:clinapp/features/settings/presentation/profile_controller.dart';
import 'package:clinapp/features/settings/presentation/widgets/account_settings_group.dart';
import 'package:clinapp/features/settings/presentation/widgets/profile_detail_sheets.dart';
import 'package:clinapp/features/settings/presentation/widgets/profile_header_card.dart';
import 'package:clinapp/features/settings/presentation/widgets/profile_metrics_row.dart';
import 'package:clinapp/features/settings/presentation/widgets/role_management_group.dart';
import 'package:clinapp/shared/widgets/clin_brand_logo.dart';
import 'package:clinapp/shared/widgets/error_state.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';
import 'package:clinapp/shared/widgets/loading_skeleton.dart';

/// Pantalla Perfil y Configuración en General Alvear.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final double horizontalMargin = AppSpacing.marginFor(
      MediaQuery.sizeOf(context).width,
    );
    final AsyncValue<ProfileViewState> profileAsync = ref.watch(
      profileControllerProvider,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: profileAsync.when(
          loading: () => Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalMargin,
              vertical: AppSpacing.md,
            ),
            child: const Column(
              children: <Widget>[
                LoadingSkeleton(height: 56),
                SizedBox(height: AppSpacing.md),
                LoadingSkeleton(height: 120),
                SizedBox(height: AppSpacing.md),
                LoadingSkeleton(height: 80),
              ],
            ),
          ),
          error: (Object err, _) => Padding(
            padding: EdgeInsets.all(horizontalMargin),
            child: ErrorState(
              message: AppException.fromError(err).message,
              onRetry: () => ref.invalidate(profileControllerProvider),
            ),
          ),
          data: (ProfileViewState viewState) {
            final AuthUserSession? session = viewState.session;
            final ProfileDashboardData dashboard = viewState.dashboard;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalMargin,
                AppSpacing.sm,
                horizontalMargin,
                AppSpacing.scrollBottomReserve,
              ),
              children: <Widget>[
                // Barra superior de perfil
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          const ClinBrandLogo(size: 38),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  AppStrings.cityName.toUpperCase(),
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  AppStrings.profileTitle,
                                  style: AppTypography.headlineMd.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: palette.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  AppStrings.profileSubtitle,
                                  style: AppTypography.labelSm.copyWith(
                                    color: palette.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    GlassButton.icon(
                      icon: LucideIcons.bell,
                      semanticLabel: AppStrings.profileNotificationsTitle,
                      onPressed: () {
                        ProfileDetailSheets.showNotifications(
                          context,
                          notifications: dashboard.notifications,
                          onClear: () {
                            ref
                                .read(profileControllerProvider.notifier)
                                .clearNotifications();
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Vista sin sesión o con sesión
                if (session == null) ...<Widget>[
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          '¡Hola, vecino de Alvear!',
                          style: AppTypography.headlineMd.copyWith(
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          AppStrings.profileSubtitle,
                          style: AppTypography.bodySm.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        GlassButton.primary(
                          label: AppStrings.loginSubmitCta,
                          leadingIcon: LucideIcons.logIn,
                          expand: true,
                          onPressed: () => context.push(AppRoutes.login),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        GlassButton.secondary(
                          label: AppStrings.registerTitle,
                          expand: true,
                          onPressed: () => context.push(AppRoutes.register),
                        ),
                      ],
                    ),
                  ),
                ] else ...<Widget>[
                  // Tarjeta principal del usuario
                  ProfileHeaderCard(
                    session: session,
                    onChangePhoto: () async {
                      try {
                        final Uint8List mockBytes = Uint8List.fromList(<int>[
                          0xFF,
                          0xD8,
                          0xFF,
                          0xE0,
                        ]);
                        final String? url = await ref
                            .read(profileControllerProvider.notifier)
                            .uploadAvatar(
                              bytes: mockBytes,
                              fileName: 'avatar.jpg',
                              mimeType: 'image/jpeg',
                            );
                        if (context.mounted && url != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(AppStrings.profilePhotoUpdated),
                            ),
                          );
                        }
                      } on Object catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppException.fromError(error).message,
                              ),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        }
                      }
                    },
                    onEditProfile: () {
                      ProfileDetailSheets.showEditProfile(
                        context,
                        session: session,
                        onSave: (String name, String phone) async {
                          try {
                            await ref
                                .read(profileControllerProvider.notifier)
                                .updateProfile(fullName: name, phone: phone);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Perfil actualizado.'),
                                ),
                              );
                            }
                          } on Object catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppException.fromError(error).message,
                                  ),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Fila de métricas
                  ProfileMetricsRow(metrics: dashboard.metrics),
                  const SizedBox(height: AppSpacing.lg),

                  // Sección Gestión y administración
                  RoleManagementGroup(
                    role: session.role,
                    onOpenPanel: (String panelTitle) {
                      if (panelTitle == AppStrings.profileAdminPanelTitle) {
                        context.push(AppRoutes.adminPanel);
                      } else if (panelTitle ==
                          AppStrings.profileMerchantPanelTitle) {
                        context.push(AppRoutes.merchantPanel);
                      } else if (panelTitle ==
                          AppStrings.profileCourierPanelTitle) {
                        context.push(AppRoutes.courierPanel);
                      } else {
                        ProfileDetailSheets.showRolePanelInfo(
                          context,
                          panelTitle,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Sección Cuenta y General
                  AccountSettingsGroup(
                    onSelectOption: (AccountOption option) {
                      switch (option) {
                        case AccountOption.addresses:
                          ProfileDetailSheets.showAddresses(
                            context,
                            addresses: dashboard.addresses,
                            onAddAddress: (String addressLine) async {
                              try {
                                await ref
                                    .read(profileControllerProvider.notifier)
                                    .addAddress(addressLine: addressLine);
                              } on Object catch (error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppException.fromError(error).message,
                                      ),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                }
                              }
                            },
                            onSetDefault: (String id) async {
                              try {
                                await ref
                                    .read(profileControllerProvider.notifier)
                                    .setDefaultAddress(id);
                              } on Object catch (error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppException.fromError(error).message,
                                      ),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                }
                              }
                            },
                            onDeleteAddress: (String id) async {
                              try {
                                await ref
                                    .read(profileControllerProvider.notifier)
                                    .deleteAddress(id);
                              } on Object catch (error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppException.fromError(error).message,
                                      ),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        case AccountOption.paymentMethods:
                          ProfileDetailSheets.showPaymentMethods(context);
                        case AccountOption.favorites:
                          ProfileDetailSheets.showFavorites(
                            context,
                            favorites: dashboard.favorites,
                            onToggleFavorite: (String merchantId) async {
                              try {
                                await ref
                                    .read(profileControllerProvider.notifier)
                                    .toggleFavorite(merchantId);
                              } on Object catch (error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppException.fromError(error).message,
                                      ),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        case AccountOption.notifications:
                          ProfileDetailSheets.showNotifications(
                            context,
                            notifications: dashboard.notifications,
                            onClear: () async {
                              try {
                                await ref
                                    .read(profileControllerProvider.notifier)
                                    .clearNotifications();
                              } on Object catch (error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppException.fromError(error).message,
                                      ),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        case AccountOption.coupons:
                          ProfileDetailSheets.showCoupons(
                            context,
                            coupons: dashboard.coupons,
                          );
                        case AccountOption.help:
                          ProfileDetailSheets.showHelp(context);
                        case AccountOption.settings:
                          ProfileDetailSheets.showAppSettings(
                            context,
                            ref: ref,
                            currentRole: session.role,
                          );
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Botón Cerrar Sesión con semántica y mínimo 48dp
                  Semantics(
                    button: true,
                    label: AppStrings.profileSignOutCta,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: AppSpacing.minTapTarget,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(239, 68, 68, 0.15),
                          borderRadius: AppRadii.pillAll,
                          border: Border.all(
                            color: const Color.fromRGBO(239, 68, 68, 0.30),
                          ),
                        ),
                        child: InkWell(
                          onTap: () async {
                            await ref
                                .read(authControllerProvider.notifier)
                                .signOut();
                          },
                          borderRadius: AppRadii.pillAll,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const Icon(
                                  LucideIcons.logOut,
                                  size: 18,
                                  color: AppColors.danger,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Flexible(
                                  child: Text(
                                    AppStrings.profileSignOutCta,
                                    style: AppTypography.labelLg.copyWith(
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.md),
                // Pie de versión y localidad
                Center(
                  child: Text(
                    AppStrings.profileVersionFooter,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSm.copyWith(
                      color: palette.textTertiary,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
