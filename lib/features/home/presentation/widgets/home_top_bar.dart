import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/shared/widgets/clin_brand_logo.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';

/// Barra superior de Inicio con logo de ClinApp, ciudad, alertas y perfil.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    required this.onNotificationsTap,
    required this.onProfileTap,
    super.key,
  });

  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const ClinBrandLogo(size: 42),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                AppStrings.cityName.toUpperCase(),
                style: AppTypography.labelSm.copyWith(color: AppColors.accent),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                AppStrings.appName,
                style: AppTypography.headlineMd,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        GlassButton.icon(
          icon: LucideIcons.bell,
          semanticLabel: AppStrings.homeNotificationsSemantics,
          onPressed: onNotificationsTap,
        ),
        const SizedBox(width: AppSpacing.xs),
        GlassButton.icon(
          icon: LucideIcons.user,
          semanticLabel: AppStrings.homeProfileSemantics,
          onPressed: onProfileTap,
        ),
      ],
    );
  }
}
