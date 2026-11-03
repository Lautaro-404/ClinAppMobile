import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_radii.dart';

/// Logo oficial de marca CLIN! (mascota gorro de chef) con borde de cristal
/// y degradado de respaldo para entornos de prueba.
class ClinBrandLogo extends StatelessWidget {
  const ClinBrandLogo({
    super.key,
    this.size = 42,
    this.circular = true,
    this.borderRadius,
  });

  final double size;
  final bool circular;
  final BorderRadius? borderRadius;

  static const String assetPath = 'assets/images/clin_logo.png';

  @override
  Widget build(BuildContext context) {
    final BorderRadius resolvedRadius =
        borderRadius ??
        (circular ? BorderRadius.circular(size / 2) : AppRadii.baseAll);

    return Semantics(
      image: true,
      label: AppStrings.appName,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: circular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circular ? null : resolvedRadius,
          border: Border.all(color: AppColors.rimStrong, width: 1.5),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[AppColors.accentGlow, AppColors.accent],
          ),
        ),
        child: ClipRRect(
          borderRadius: resolvedRadius,
          child: Image.asset(
            assetPath,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (BuildContext context, Object error, StackTrace? st) {
              return Center(
                child: Icon(
                  LucideIcons.chefHat,
                  size: size * 0.52,
                  color: AppColors.onAccent,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
