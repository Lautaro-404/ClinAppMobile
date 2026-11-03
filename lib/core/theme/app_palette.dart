import 'package:flutter/material.dart';

import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_shadows.dart';
import 'package:clinapp/core/theme/glass_tokens.dart';

/// Extensión de tema con tokens Liquid Glass adaptativos a Modo Oscuro y Claro.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.surfaceRest,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.glassFill1,
    required this.glassFill2,
    required this.glassFill3,
    required this.glassFillFloating,
    required this.rimStrong,
    required this.rimMedium,
    required this.rimSoft,
    required this.rimFaint,
    required this.chipFill,
    required this.chipBorder,
    required this.chipText,
    required this.lightFlare,
    required this.lightEmber,
    required this.level1,
    required this.level2,
    required this.level3,
    required this.cardShadows,
    required this.floatingShadows,
    required this.modalShadows,
  });

  final Brightness brightness;
  final Color canvas;
  final Color surface;
  final Color surfaceRest;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color glassFill1;
  final Color glassFill2;
  final Color glassFill3;
  final Color glassFillFloating;
  final Color rimStrong;
  final Color rimMedium;
  final Color rimSoft;
  final Color rimFaint;
  final Color chipFill;
  final Color chipBorder;
  final Color chipText;
  final Color lightFlare;
  final Color lightEmber;
  final GlassLevel level1;
  final GlassLevel level2;
  final GlassLevel level3;
  final List<BoxShadow> cardShadows;
  final List<BoxShadow> floatingShadows;
  final List<BoxShadow> modalShadows;

  bool get isDark => brightness == Brightness.dark;

  /// Obtiene la [AppPalette] del contexto actual con fallback a oscuro.
  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ?? dark;
  }

  /// Instancia para Modo Oscuro (Liquid Glass Dark).
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    canvas: AppColors.canvas,
    surface: AppColors.surface,
    surfaceRest: AppColors.surfaceRest,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    glassFill1: AppColors.glassFill1,
    glassFill2: AppColors.glassFill2,
    glassFill3: AppColors.glassFill3,
    glassFillFloating: AppColors.glassFillFloating,
    rimStrong: AppColors.rimStrong,
    rimMedium: AppColors.rimMedium,
    rimSoft: AppColors.rimSoft,
    rimFaint: AppColors.rimFaint,
    chipFill: AppColors.chipFill,
    chipBorder: AppColors.chipBorder,
    chipText: AppColors.chipText,
    lightFlare: AppColors.lightFlare,
    lightEmber: AppColors.lightEmber,
    level1: GlassTokens.darkLevel1,
    level2: GlassTokens.darkLevel2,
    level3: GlassTokens.darkLevel3,
    cardShadows: AppShadows.cardDark,
    floatingShadows: AppShadows.floatingDark,
    modalShadows: AppShadows.modalDark,
  );

  /// Instancia para Modo Claro (Liquid Glass Light).
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    canvas: Color(0xFFF8F9FA),
    surface: Color(0xFFF1F3F5),
    surfaceRest: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    textTertiary: Color(0xFF94A3B8),
    glassFill1: Color.fromRGBO(255, 255, 255, 0.78),
    glassFill2: Color.fromRGBO(255, 255, 255, 0.85),
    glassFill3: Color.fromRGBO(255, 255, 255, 0.94),
    glassFillFloating: Color.fromRGBO(255, 255, 255, 0.85),
    rimStrong: Color.fromRGBO(255, 255, 255, 0.95),
    rimMedium: Color.fromRGBO(226, 232, 240, 0.85),
    rimSoft: Color.fromRGBO(15, 23, 42, 0.06),
    rimFaint: Color.fromRGBO(255, 255, 255, 0.65),
    chipFill: Color.fromRGBO(255, 255, 255, 0.80),
    chipBorder: Color.fromRGBO(15, 23, 42, 0.06),
    chipText: Color(0xFF1E293B),
    lightFlare: Color.fromRGBO(232, 82, 58, 0.12),
    lightEmber: Color.fromRGBO(255, 122, 89, 0.10),
    level1: GlassTokens.lightLevel1,
    level2: GlassTokens.lightLevel2,
    level3: GlassTokens.lightLevel3,
    cardShadows: AppShadows.cardLight,
    floatingShadows: AppShadows.floatingLight,
    modalShadows: AppShadows.modalLight,
  );

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? canvas,
    Color? surface,
    Color? surfaceRest,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? glassFill1,
    Color? glassFill2,
    Color? glassFill3,
    Color? glassFillFloating,
    Color? rimStrong,
    Color? rimMedium,
    Color? rimSoft,
    Color? rimFaint,
    Color? chipFill,
    Color? chipBorder,
    Color? chipText,
    Color? lightFlare,
    Color? lightEmber,
    GlassLevel? level1,
    GlassLevel? level2,
    GlassLevel? level3,
    List<BoxShadow>? cardShadows,
    List<BoxShadow>? floatingShadows,
    List<BoxShadow>? modalShadows,
  }) {
    return AppPalette(
      brightness: brightness ?? this.brightness,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceRest: surfaceRest ?? this.surfaceRest,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      glassFill1: glassFill1 ?? this.glassFill1,
      glassFill2: glassFill2 ?? this.glassFill2,
      glassFill3: glassFill3 ?? this.glassFill3,
      glassFillFloating: glassFillFloating ?? this.glassFillFloating,
      rimStrong: rimStrong ?? this.rimStrong,
      rimMedium: rimMedium ?? this.rimMedium,
      rimSoft: rimSoft ?? this.rimSoft,
      rimFaint: rimFaint ?? this.rimFaint,
      chipFill: chipFill ?? this.chipFill,
      chipBorder: chipBorder ?? this.chipBorder,
      chipText: chipText ?? this.chipText,
      lightFlare: lightFlare ?? this.lightFlare,
      lightEmber: lightEmber ?? this.lightEmber,
      level1: level1 ?? this.level1,
      level2: level2 ?? this.level2,
      level3: level3 ?? this.level3,
      cardShadows: cardShadows ?? this.cardShadows,
      floatingShadows: floatingShadows ?? this.floatingShadows,
      modalShadows: modalShadows ?? this.modalShadows,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      canvas: Color.lerp(canvas, other.canvas, t) ?? canvas,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceRest: Color.lerp(surfaceRest, other.surfaceRest, t) ?? surfaceRest,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textTertiary:
          Color.lerp(textTertiary, other.textTertiary, t) ?? textTertiary,
      glassFill1: Color.lerp(glassFill1, other.glassFill1, t) ?? glassFill1,
      glassFill2: Color.lerp(glassFill2, other.glassFill2, t) ?? glassFill2,
      glassFill3: Color.lerp(glassFill3, other.glassFill3, t) ?? glassFill3,
      glassFillFloating:
          Color.lerp(glassFillFloating, other.glassFillFloating, t) ??
          glassFillFloating,
      rimStrong: Color.lerp(rimStrong, other.rimStrong, t) ?? rimStrong,
      rimMedium: Color.lerp(rimMedium, other.rimMedium, t) ?? rimMedium,
      rimSoft: Color.lerp(rimSoft, other.rimSoft, t) ?? rimSoft,
      rimFaint: Color.lerp(rimFaint, other.rimFaint, t) ?? rimFaint,
      chipFill: Color.lerp(chipFill, other.chipFill, t) ?? chipFill,
      chipBorder: Color.lerp(chipBorder, other.chipBorder, t) ?? chipBorder,
      chipText: Color.lerp(chipText, other.chipText, t) ?? chipText,
      lightFlare: Color.lerp(lightFlare, other.lightFlare, t) ?? lightFlare,
      lightEmber: Color.lerp(lightEmber, other.lightEmber, t) ?? lightEmber,
      level1: GlassLevel.lerp(level1, other.level1, t),
      level2: GlassLevel.lerp(level2, other.level2, t),
      level3: GlassLevel.lerp(level3, other.level3, t),
      cardShadows:
          BoxShadow.lerpList(cardShadows, other.cardShadows, t) ?? cardShadows,
      floatingShadows:
          BoxShadow.lerpList(floatingShadows, other.floatingShadows, t) ??
          floatingShadows,
      modalShadows:
          BoxShadow.lerpList(modalShadows, other.modalShadows, t) ??
          modalShadows,
    );
  }
}

/// Extensión de conveniencia sobre [BuildContext].
extension BuildContextPaletteExtension on BuildContext {
  AppPalette get palette => AppPalette.of(this);
}
