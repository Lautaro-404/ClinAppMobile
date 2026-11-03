import 'package:flutter/painting.dart';

/// Estilos de texto de ClinApp (fuente: `DESIGN.md`). Fuente: Inter.
///
/// Los estilos no fijan un color por defecto para que hereden automáticamente
/// el color del [ThemeData.textTheme] según si el tema activo es claro u oscuro.
abstract final class AppTypography {
  static const String fontFamily = 'Inter';

  static TextStyle _style({
    required double size,
    required double height,
    required int weight,
    required double letterSpacingEm,
    bool tabular = false,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      height: height / size,
      fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      fontVariations: <FontVariation>[FontVariation.weight(weight.toDouble())],
      letterSpacing: letterSpacingEm * size,
      fontFeatures: tabular
          ? const <FontFeature>[FontFeature.tabularFigures()]
          : null,
      color: color,
    );
  }

  static final TextStyle displayLg = _style(
    size: 34,
    height: 40,
    weight: 700,
    letterSpacingEm: -0.02,
  );
  static final TextStyle headlineLg = _style(
    size: 26,
    height: 32,
    weight: 700,
    letterSpacingEm: -0.015,
  );
  static final TextStyle headlineMd = _style(
    size: 20,
    height: 26,
    weight: 600,
    letterSpacingEm: -0.01,
  );
  static final TextStyle bodyLg = _style(
    size: 17,
    height: 24,
    weight: 400,
    letterSpacingEm: -0.005,
  );
  static final TextStyle bodyMd = _style(
    size: 15,
    height: 21,
    weight: 400,
    letterSpacingEm: 0,
  );
  static final TextStyle bodySm = _style(
    size: 13,
    height: 18,
    weight: 400,
    letterSpacingEm: 0.005,
  );
  static final TextStyle labelLg = _style(
    size: 15,
    height: 20,
    weight: 600,
    letterSpacingEm: 0.01,
  );
  static final TextStyle labelMd = _style(
    size: 13,
    height: 16,
    weight: 600,
    letterSpacingEm: 0.02,
  );
  static final TextStyle labelSm = _style(
    size: 11,
    height: 14,
    weight: 500,
    letterSpacingEm: 0.03,
  );

  /// Montos: cifras tabulares para alinear verticalmente.
  static final TextStyle currencyDisplay = _style(
    size: 22,
    height: 28,
    weight: 700,
    letterSpacingEm: -0.02,
    tabular: true,
  );
}
