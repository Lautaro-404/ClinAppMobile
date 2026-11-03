import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';
import 'package:clinapp/shared/widgets/status_badge.dart';

/// Saludo personalizado, badge "EN LÍNEA" y selector translúcido de dirección.
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    required this.userName,
    required this.address,
    required this.isOnline,
    required this.onAddressTap,
    super.key,
  });

  final String userName;
  final String address;
  final bool isOnline;
  final VoidCallback onAddressTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '${AppStrings.homeGreetingPrefix}$userName 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.displayLg.copyWith(
                  color: palette.textPrimary,
                ),
              ),
            ),
            if (isOnline) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              StatusBadge(label: AppStrings.catalogStatusOnline.toUpperCase()),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          borderRadius: AppRadii.pillAll,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          semanticLabel:
              '${AppStrings.homeChangeAddressSemantics}: '
              '${AppStrings.homeDeliverTo} $address',
          onTap: onAddressTap,
          child: Row(
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(
                  dimension: 30,
                  child: Icon(
                    LucideIcons.mapPin,
                    size: 16,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      AppStrings.homeDeliverTo,
                      style: AppTypography.labelSm.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                    Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLg.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronDown,
                size: 18,
                color: palette.textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
