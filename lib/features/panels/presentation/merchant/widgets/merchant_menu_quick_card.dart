import 'package:flutter/material.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/core/utils/money_formatter.dart';
import 'package:clinapp/features/panels/domain/panel_models.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';

/// Tarjeta Liquid Glass para pausar o activar stock de un plato del comercio.
class MerchantMenuQuickCard extends StatelessWidget {
  const MerchantMenuQuickCard({
    super.key,
    required this.item,
    required this.onToggleStock,
  });

  final MerchantMenuItem item;
  final ValueChanged<bool> onToggleStock;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        item.name,
                        style: AppTypography.headlineMd.copyWith(
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: item.isAvailable
                            ? const Color.fromRGBO(16, 185, 129, 0.15)
                            : palette.glassFill2,
                        borderRadius: AppRadii.pillAll,
                        border: Border.all(
                          color: item.isAvailable
                              ? AppColors.success.withValues(alpha: 0.3)
                              : palette.rimSoft,
                        ),
                      ),
                      child: Text(
                        item.isAvailable
                            ? AppStrings.merchantStockAvailable
                            : AppStrings.merchantStockPaused,
                        style: AppTypography.labelSm.copyWith(
                          color: item.isAvailable
                              ? AppColors.success
                              : palette.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: AppTypography.bodySm.copyWith(
                    color: palette.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  MoneyFormatter.format(item.priceCents),
                  style: AppTypography.labelLg.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch.adaptive(
            value: item.isAvailable,
            activeThumbColor: AppColors.accent,
            onChanged: onToggleStock,
          ),
        ],
      ),
    );
  }
}
