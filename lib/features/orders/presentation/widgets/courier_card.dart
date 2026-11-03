import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/features/orders/domain/orders_models.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';

/// Tarjeta flotante del repartidor sobre el mapa con acciones de llamada y chat.
class CourierCard extends StatelessWidget {
  const CourierCard({
    required this.courier,
    required this.onCallTap,
    required this.onChatTap,
    super.key,
  });

  final CourierInfo courier;
  final VoidCallback onCallTap;
  final VoidCallback onChatTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: palette.glassFillFloating,
        borderRadius: AppRadii.pillAll,
        border: Border.all(color: palette.rimMedium),
        boxShadow: palette.floatingShadows,
      ),
      child: Row(
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: <Color>[AppColors.accent, AppColors.accentGlow],
                  ),
                  border: Border.all(color: AppColors.rimStrong),
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.bike,
                    size: 20,
                    color: AppColors.onAccent,
                  ),
                ),
              ),
              if (courier.isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.surfaceRest, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  courier.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMd.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${courier.vehicle} · ${courier.plate}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSm.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          GlassButton.icon(
            icon: LucideIcons.phone,
            semanticLabel: AppStrings.ordersCallCourierSemantics,
            onPressed: onCallTap,
          ),
          const SizedBox(width: AppSpacing.xs),
          GlassButton.icon(
            icon: LucideIcons.messageSquare,
            semanticLabel: AppStrings.ordersChatCourierSemantics,
            onPressed: onChatTap,
          ),
        ],
      ),
    );
  }
}
