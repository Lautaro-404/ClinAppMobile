import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/features/auth/domain/auth_models.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';

/// Tarjeta principal de identidad y perfil del usuario autenticado.
class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.session,
    this.onChangePhoto,
    this.onEditProfile,
  });

  final AuthUserSession? session;
  final VoidCallback? onChangePhoto;
  final VoidCallback? onEditProfile;

  @override
  Widget build(BuildContext context) {
    if (session == null) {
      return const SizedBox.shrink();
    }

    final AuthUserSession user = session!;
    final AppPalette palette = context.palette;

    return GlassCard(
      child: Row(
        children: <Widget>[
          // Avatar con inicial y botón de cámara con área táctil >= 48x48 dp
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: palette.glassFill2,
                    borderRadius: AppRadii.lgAll,
                    border: Border.all(color: palette.rimMedium),
                    boxShadow: palette.cardShadows,
                  ),
                  alignment: Alignment.center,
                  child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: AppRadii.lgAll,
                          child: Image.network(
                            user.avatarUrl!,
                            width: 76,
                            height: 76,
                            cacheWidth: 160,
                            cacheHeight: 160,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (
                                  BuildContext context,
                                  Object error,
                                  StackTrace? stackTrace,
                                ) => FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    user.initialLetter,
                                    style: AppTypography.displayLg.copyWith(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                          ),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            user.initialLetter,
                            style: AppTypography.displayLg.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                Positioned(
                  bottom: -6,
                  right: -6,
                  child: Semantics(
                    container: true,
                    button: true,
                    label: AppStrings.profileChangePhotoSemantics,
                    child: Tooltip(
                      message: AppStrings.profileChangePhotoSemantics,
                      excludeFromSemantics: true,
                      child: InkWell(
                        onTap: onChangePhoto,
                        borderRadius: AppRadii.pillAll,
                        child: SizedBox.square(
                          dimension: AppSpacing.minTapTarget,
                          child: Center(
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Color.fromRGBO(232, 82, 58, 0.40),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                LucideIcons.camera,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Nombre, correo y badge de verificación
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        user.fullName,
                        style: AppTypography.headlineMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onEditProfile != null)
                      IconButton(
                        icon: Icon(
                          LucideIcons.pencil,
                          size: 16,
                          color: palette.textSecondary,
                        ),
                        tooltip: 'Editar perfil',
                        onPressed: onEditProfile,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: AppTypography.bodySm.copyWith(
                    color: palette.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: palette.isDark
                        ? const Color.fromRGBO(255, 255, 255, 0.08)
                        : const Color(0xFFFFEDE9),
                    borderRadius: AppRadii.pillAll,
                    border: Border.all(
                      color: palette.isDark
                          ? palette.rimSoft
                          : const Color(0xFFFFD2C8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        LucideIcons.badgeCheck,
                        size: 14,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          AppStrings.profileVerifiedBadge,
                          style: AppTypography.labelSm.copyWith(
                            color: palette.isDark
                                ? Colors.white
                                : AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
