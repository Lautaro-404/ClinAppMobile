import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_shadows.dart';

/// Parámetros de un nivel de vidrio.
@immutable
class GlassLevel {
  const GlassLevel({
    required this.fill,
    required this.blurSigma,
    required this.rimStart,
    required this.rimEnd,
    required this.shadows,
  });

  final Color fill;

  /// Sigma del blur de fondo. Con calidad baja se ignora.
  final double blurSigma;

  /// Color del borde en la esquina superior izquierda.
  final Color rimStart;

  /// Color del borde en la esquina inferior derecha.
  final Color rimEnd;

  final List<BoxShadow> shadows;

  static GlassLevel lerp(GlassLevel a, GlassLevel b, double t) {
    return GlassLevel(
      fill: Color.lerp(a.fill, b.fill, t) ?? a.fill,
      blurSigma: a.blurSigma + (b.blurSigma - a.blurSigma) * t,
      rimStart: Color.lerp(a.rimStart, b.rimStart, t) ?? a.rimStart,
      rimEnd: Color.lerp(a.rimEnd, b.rimEnd, t) ?? a.rimEnd,
      shadows: BoxShadow.lerpList(a.shadows, b.shadows, t) ?? a.shadows,
    );
  }
}

/// Niveles de vidrio (fuente: `DESIGN.md`, sección Elevation & Depth).
abstract final class GlassTokens {
  /// Sigma máximo permitido en toda la app (rendimiento).
  static const double maxBlurSigma = 32;

  // --- MODO OSCURO ---
  static const GlassLevel darkLevel1 = GlassLevel(
    fill: AppColors.glassFill1,
    blurSigma: 20,
    rimStart: AppColors.rimMedium,
    rimEnd: AppColors.rimFaint,
    shadows: AppShadows.cardDark,
  );

  static const GlassLevel darkLevel2 = GlassLevel(
    fill: AppColors.glassFillFloating,
    blurSigma: 28,
    rimStart: AppColors.rimStrong,
    rimEnd: AppColors.rimSoft,
    shadows: AppShadows.floatingDark,
  );

  static const GlassLevel darkLevel3 = GlassLevel(
    fill: AppColors.glassFill3,
    blurSigma: 32,
    rimStart: AppColors.rimStrong,
    rimEnd: AppColors.rimSoft,
    shadows: AppShadows.modalDark,
  );

  // --- MODO CLARO (DESIGN.md Light) ---
  static const GlassLevel lightLevel1 = GlassLevel(
    fill: Color.fromRGBO(255, 255, 255, 0.78),
    blurSigma: 20,
    rimStart: Color.fromRGBO(255, 255, 255, 0.90),
    rimEnd: Color.fromRGBO(226, 232, 240, 0.85),
    shadows: AppShadows.cardLight,
  );

  static const GlassLevel lightLevel2 = GlassLevel(
    fill: Color.fromRGBO(255, 255, 255, 0.85),
    blurSigma: 24,
    rimStart: Color.fromRGBO(255, 255, 255, 0.95),
    rimEnd: Color.fromRGBO(226, 232, 240, 0.85),
    shadows: AppShadows.floatingLight,
  );

  static const GlassLevel lightLevel3 = GlassLevel(
    fill: Color.fromRGBO(255, 255, 255, 0.94),
    blurSigma: 32,
    rimStart: Color.fromRGBO(255, 255, 255, 1.0),
    rimEnd: Color.fromRGBO(226, 232, 240, 0.90),
    shadows: AppShadows.modalLight,
  );

  // Alias para retrocompatibilidad
  static const GlassLevel level1 = darkLevel1;
  static const GlassLevel level2 = darkLevel2;
  static const GlassLevel level3 = darkLevel3;

  /// Botón secundario de vidrio.
  static const double secondaryButtonBlur = 16;
}
