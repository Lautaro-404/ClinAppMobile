import 'package:flutter/painting.dart';

/// Paleta de ClinApp (fuente: `DESIGN.md`).
abstract final class AppColors {
  // Lienzo y superficies.
  static const Color canvas = Color(0xFF07090E);
  static const Color surface = Color(0xFF111319);
  static const Color surfaceRest = Color(0xFF0F131C);

  // Acento.
  static const Color accent = Color(0xFFE8523A);
  static const Color accentGlow = Color(0xFFFF6B4A);

  // Texto.
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color.fromRGBO(255, 255, 255, 0.60);
  static const Color textTertiary = Color.fromRGBO(255, 255, 255, 0.35);
  static const Color onAccent = Color(0xFFFFFFFF);

  // Retroalimentación.
  static const Color success = Color(0xFF10B981);
  static const Color successBloom = Color.fromRGBO(16, 185, 129, 0.25);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Vidrio: rellenos translúcidos (blanco sobre el fondo).
  static const Color glassFill1 = Color.fromRGBO(255, 255, 255, 0.08);
  static const Color glassFill2 = Color.fromRGBO(255, 255, 255, 0.12);
  static const Color glassFill3 = Color.fromRGBO(255, 255, 255, 0.14);
  static const Color glassFillFloating = Color.fromRGBO(15, 19, 28, 0.72);

  // Bordes especulares.
  static const Color rimStrong = Color.fromRGBO(255, 255, 255, 0.35);
  static const Color rimMedium = Color.fromRGBO(255, 255, 255, 0.22);
  static const Color rimSoft = Color.fromRGBO(255, 255, 255, 0.10);
  static const Color rimFaint = Color.fromRGBO(255, 255, 255, 0.04);

  // Chips inactivos.
  static const Color chipFill = Color.fromRGBO(255, 255, 255, 0.07);
  static const Color chipBorder = Color.fromRGBO(255, 255, 255, 0.14);
  static const Color chipText = Color.fromRGBO(255, 255, 255, 0.70);

  // Manchas de luz del fondo.
  static const Color lightFlare = Color.fromRGBO(232, 82, 58, 0.30);
  static const Color lightEmber = Color.fromRGBO(255, 107, 74, 0.25);

  // Sombras.
  static const Color shadowDeep = Color.fromRGBO(0, 0, 0, 0.55);
  static const Color shadowCard = Color.fromRGBO(0, 0, 0, 0.37);
  static const Color shadowModal = Color.fromRGBO(0, 0, 0, 0.65);
  static const Color accentShadow = Color.fromRGBO(232, 82, 58, 0.40);
  static const Color accentModalGlow = Color.fromRGBO(232, 82, 58, 0.15);
}
