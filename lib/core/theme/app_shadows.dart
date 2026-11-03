import 'package:flutter/painting.dart';

import 'package:clinapp/core/theme/app_colors.dart';

/// Sombras de ClinApp adaptadas a Modo Oscuro y Modo Claro.
abstract final class AppShadows {
  // --- MODO OSCURO ---
  static const List<BoxShadow> cardDark = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowCard,
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> floatingDark = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowDeep,
      blurRadius: 40,
      offset: Offset(0, 16),
    ),
  ];

  static const List<BoxShadow> modalDark = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowModal,
      blurRadius: 48,
      offset: Offset(0, 20),
    ),
    BoxShadow(color: AppColors.accentModalGlow, blurRadius: 24),
  ];

  // --- MODO CLARO (Daylight Drop Shadows según DESIGN.md) ---
  static const List<BoxShadow> cardLight = <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(17, 24, 39, 0.06),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Color.fromRGBO(17, 24, 39, 0.04),
      blurRadius: 6,
      offset: Offset(0, 2),
      spreadRadius: -1,
    ),
  ];

  static const List<BoxShadow> floatingLight = <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(17, 24, 39, 0.10),
      blurRadius: 32,
      offset: Offset(0, 12),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Color.fromRGBO(17, 24, 39, 0.05),
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> modalLight = <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(17, 24, 39, 0.14),
      blurRadius: 48,
      offset: Offset(0, 24),
      spreadRadius: -12,
    ),
    BoxShadow(color: Color.fromRGBO(232, 82, 58, 0.08), blurRadius: 20),
  ];

  /// Botón primario (común a ambos modos).
  static const List<BoxShadow> accentButton = <BoxShadow>[
    BoxShadow(
      color: AppColors.accentShadow,
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  // Alias para retrocompatibilidad
  static const List<BoxShadow> card = cardDark;
  static const List<BoxShadow> floating = floatingDark;
  static const List<BoxShadow> modal = modalDark;
}
