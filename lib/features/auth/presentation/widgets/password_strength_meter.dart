import 'package:flutter/material.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/features/auth/domain/auth_models.dart';

/// Barra indicadora de fortaleza de contraseña con 4 segmentos y etiqueta descriptiva.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.strength});

  final PasswordStrength strength;

  String _labelForStrength(PasswordStrength s) {
    switch (s) {
      case PasswordStrength.strong:
        return AppStrings.registerPasswordStrong;
      case PasswordStrength.good:
        return AppStrings.registerPasswordGood;
      case PasswordStrength.fair:
        return AppStrings.registerPasswordFair;
      case PasswordStrength.weak:
        return AppStrings.registerPasswordWeak;
      case PasswordStrength.empty:
        return '';
    }
  }

  Color _colorForStrength(PasswordStrength s) {
    switch (s) {
      case PasswordStrength.strong:
      case PasswordStrength.good:
        return AppColors.success;
      case PasswordStrength.fair:
        return AppColors.warning;
      case PasswordStrength.weak:
      case PasswordStrength.empty:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int activeSegments = strength.activeSegments;
    final Color activeColor = _colorForStrength(strength);
    final String label = _labelForStrength(strength);
    final AppPalette palette = context.palette;
    final Color inactiveColor = palette.isDark
        ? const Color(0xFF33353B)
        : palette.rimMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
              bottom: AppSpacing.xs,
              left: AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(
                  label,
                  style: AppTypography.labelSm.copyWith(
                    color: activeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: List<Widget>.generate(4, (int index) {
            final bool isActive = index < activeSegments;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? AppSpacing.xs : 0),
                decoration: BoxDecoration(
                  color: isActive ? activeColor : inactiveColor,
                  borderRadius: AppRadii.pillAll,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
