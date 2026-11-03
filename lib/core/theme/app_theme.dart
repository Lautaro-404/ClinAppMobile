import 'package:flutter/material.dart';

import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_typography.dart';

/// Temas oscuro y claro de ClinApp.
abstract final class AppTheme {
  static ThemeData get dark {
    const ColorScheme scheme = ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.accentGlow,
      onSecondary: AppColors.onAccent,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
      onError: AppColors.onAccent,
      tertiary: AppColors.success,
    );

    final TextTheme textTheme =
        TextTheme(
          displayLarge: AppTypography.displayLg,
          headlineLarge: AppTypography.headlineLg,
          headlineMedium: AppTypography.headlineMd,
          titleMedium: AppTypography.labelLg,
          bodyLarge: AppTypography.bodyLg,
          bodyMedium: AppTypography.bodyMd,
          bodySmall: AppTypography.bodySm,
          labelLarge: AppTypography.labelLg,
          labelMedium: AppTypography.labelMd,
          labelSmall: AppTypography.labelSm,
        ).apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      canvasColor: AppColors.canvas,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      extensions: const <ThemeExtension<dynamic>>[AppPalette.dark],
    );
  }

  static ThemeData get light {
    const ColorScheme scheme = ColorScheme.light(
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.accentGlow,
      onSecondary: AppColors.onAccent,
      surface: Color(0xFFF8F9FA),
      onSurface: Color(0xFF0F172A),
      error: AppColors.danger,
      onError: AppColors.onAccent,
      tertiary: Color(0xFF059669),
    );

    final TextTheme textTheme =
        TextTheme(
          displayLarge: AppTypography.displayLg,
          headlineLarge: AppTypography.headlineLg,
          headlineMedium: AppTypography.headlineMd,
          titleMedium: AppTypography.labelLg,
          bodyLarge: AppTypography.bodyLg,
          bodyMedium: AppTypography.bodyMd,
          bodySmall: AppTypography.bodySm,
          labelLarge: AppTypography.labelLg,
          labelMedium: AppTypography.labelMd,
          labelSmall: AppTypography.labelSm,
        ).apply(
          bodyColor: const Color(0xFF0F172A),
          displayColor: const Color(0xFF0F172A),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      canvasColor: const Color(0xFFF8F9FA),
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      extensions: const <ThemeExtension<dynamic>>[AppPalette.light],
    );
  }
}
