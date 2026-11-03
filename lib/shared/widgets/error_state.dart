import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';

/// Estado de error amigable en español rioplatense con botón de reintento.
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.onRetry,
    super.key,
    this.title = AppStrings.genericErrorTitle,
    this.message = AppStrings.genericErrorMessage,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.35),
              ),
            ),
            child: const SizedBox.square(
              dimension: AppSpacing.minTapTarget,
              child: Icon(
                LucideIcons.triangleAlert,
                color: AppColors.danger,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.headlineMd.copyWith(
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          GlassButton.primary(
            label: AppStrings.actionRetry,
            leadingIcon: LucideIcons.refreshCw,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
