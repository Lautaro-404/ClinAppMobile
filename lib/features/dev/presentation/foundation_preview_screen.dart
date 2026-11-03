import 'package:flutter/material.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/core/utils/money_formatter.dart';

/// Pantalla temporal para verificar tipografía, colores y formato de montos.
///
/// Se reemplaza por el catálogo de componentes en la Etapa 2.
class FoundationPreviewScreen extends StatelessWidget {
  const FoundationPreviewScreen({super.key});

  /// Monto de ejemplo en centavos ($14.600).
  static const int _samplePriceCents = 1460000;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenMargin),
          children: <Widget>[
            Text(
              AppStrings.foundationTitle,
              style: AppTypography.headlineLg.copyWith(
                color: palette.textPrimary,
              ),
            ),
            Text(
              AppStrings.foundationSubtitle,
              style: AppTypography.bodyMd.copyWith(
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppStrings.foundationDisplay,
              style: AppTypography.displayLg.copyWith(
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.foundationHeadline,
              style: AppTypography.headlineMd.copyWith(
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.foundationBody,
              style: AppTypography.bodyLg.copyWith(color: palette.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.foundationLabel,
              style: AppTypography.labelMd.copyWith(color: palette.textPrimary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppStrings.foundationPriceLabel,
              style: AppTypography.labelSm.copyWith(
                color: palette.textSecondary,
              ),
            ),
            Text(
              MoneyFormatter.format(_samplePriceCents),
              style: AppTypography.currencyDisplay.copyWith(
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                _Swatch(color: AppColors.accent),
                _Swatch(color: AppColors.accentGlow),
                _Swatch(color: AppColors.success),
                _Swatch(color: AppColors.warning),
                _Swatch(color: AppColors.danger),
                _Swatch(color: AppColors.surface),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadii.mdAll,
        border: Border.all(color: palette.rimMedium),
      ),
      child: const SizedBox.square(dimension: AppSpacing.minTapTarget),
    );
  }
}
