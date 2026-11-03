import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/features/home/domain/home_models.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';
import 'package:clinapp/shared/widgets/status_badge.dart';

/// Banner promocional destacado con degradado rojo-naranja y cupón.
class PromoBanner extends StatelessWidget {
  const PromoBanner({required this.promo, required this.onCtaTap, super.key});

  final PromoBannerData promo;
  final VoidCallback onCtaTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    final List<Color> gradientColors = palette.isDark
        ? const <Color>[
            Color(0xFF8F1B01),
            Color(0xCCB83A22),
            AppColors.surfaceRest,
          ]
        : const <Color>[
            Color(0xFFE8523A),
            Color(0xFFFF6B4A),
            Color(0xFFFFA07A),
          ];

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.cardAll,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(color: palette.rimMedium),
        boxShadow: palette.cardShadows,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.cardAll,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.md,
              child: Icon(
                LucideIcons.truck,
                size: 84,
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg - 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  StatusBadge(
                    label: promo.badgeLabel.toUpperCase(),
                    tone: StatusBadgeTone.accent,
                    icon: LucideIcons.sparkles,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    promo.title,
                    style: AppTypography.headlineLg.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  RichText(
                    text: TextSpan(
                      style: AppTypography.bodySm.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                      children: <InlineSpan>[
                        TextSpan(text: promo.couponPrefix),
                        TextSpan(
                          text: promo.couponCode,
                          style: AppTypography.labelMd.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GlassButton.primary(
                    label: promo.ctaLabel,
                    trailingIcon: LucideIcons.arrowRight,
                    onPressed: onCtaTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
