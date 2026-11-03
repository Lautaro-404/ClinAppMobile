import 'package:flutter/material.dart';

import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/shared/widgets/clin_brand_logo.dart';

/// Cabecera hero con la mascota/logo de ClinApp, halo brillante y badge de General Alvear.
class AuthHeroHeader extends StatelessWidget {
  const AuthHeroHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.badgeText = 'ALVEAR',
    this.highlightSubtitle,
  });

  final String title;
  final String subtitle;
  final String badgeText;
  final Widget? highlightSubtitle;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Logo oficial con halo y píldora de Alvear.
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: <Widget>[
            // Halo brillante de fondo.
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color.fromRGBO(232, 82, 58, 0.35),
                    blurRadius: 36,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
            // Tarjeta Liquid Glass con logo oficial CLIN!.
            Container(
              width: 84,
              height: 84,
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                borderRadius: AppRadii.lgAll,
                color: palette.glassFill2,
                border: Border.all(color: palette.rimMedium),
                boxShadow: palette.cardShadows,
              ),
              child: const ClinBrandLogo(
                size: 72,
                circular: false,
                borderRadius: AppRadii.baseAll,
              ),
            ),
            // Píldora inferior "ALVEAR" con punto verde.
            Positioned(
              bottom: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: palette.isDark
                      ? const Color(0xFF1D2025)
                      : Colors.white,
                  borderRadius: AppRadii.pillAll,
                  border: Border.all(
                    color: palette.isDark
                        ? palette.rimSoft
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      badgeText,
                      style: AppTypography.labelSm.copyWith(
                        color: palette.isDark
                            ? Colors.white
                            : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.headlineLg.copyWith(
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (highlightSubtitle != null)
          highlightSubtitle!
        else
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(color: palette.textSecondary),
          ),
      ],
    );
  }
}
