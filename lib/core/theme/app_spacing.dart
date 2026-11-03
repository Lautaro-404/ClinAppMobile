import 'package:flutter/widgets.dart';

/// Espaciados (grilla de 8px) y medidas de layout (fuente: `DESIGN.md`).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Margen lateral estándar de pantalla.
  static const double screenMargin = 20;

  /// Margen lateral en pantallas ultra compactas.
  static const double screenMarginCompact = 16;

  /// Ancho por debajo del cual se usa [screenMarginCompact].
  static const double compactWidth = 360;

  /// Separación de la barra flotante respecto del borde inferior.
  static const double navBottomOffset = 24;

  /// Espacio reservado al final del scroll para no quedar bajo la barra.
  static const double scrollBottomReserve = 108;

  /// Área táctil mínima (accesibilidad).
  static const double minTapTarget = 48;

  /// Margen lateral según el ancho disponible.
  static double marginFor(double width) =>
      width < compactWidth ? screenMarginCompact : screenMargin;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenMargin,
  );
}
