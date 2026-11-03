import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/core/utils/date_formatter.dart';
import 'package:clinapp/features/home/domain/home_models.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';
import 'package:clinapp/shared/widgets/price_text.dart';

/// Tarjeta de acceso rápido "Tu último pedido" con acciones de recibo y repetición.
class LastOrderCard extends StatelessWidget {
  const LastOrderCard({
    required this.lastOrder,
    required this.onReceiptTap,
    required this.onRepeatTap,
    super.key,
  });

  final LastOrderSummary lastOrder;
  final VoidCallback onReceiptTap;
  final VoidCallback onRepeatTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final String formattedDate = DateFormatter.relativeDay(
      lastOrder.deliveredAt,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                AppStrings.homeLastOrderTitle,
                style: AppTypography.headlineMd.copyWith(
                  color: palette.textPrimary,
                ),
              ),
            ),
            Text(
              formattedDate,
              style: AppTypography.labelSm.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        GlassCard(
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: AppRadii.baseAll,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          AppColors.accent.withValues(
                            alpha: palette.isDark ? 0.35 : 0.20,
                          ),
                          palette.surfaceRest,
                        ],
                      ),
                      border: Border.all(color: palette.rimMedium),
                    ),
                    child: const SizedBox.square(
                      dimension: 60,
                      child: Icon(
                        LucideIcons.utensils,
                        size: 24,
                        color: AppColors.accentGlow,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md - 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                lastOrder.merchantName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelLg.copyWith(
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            PriceText(cents: lastOrder.totalCents),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lastOrder.itemsSummary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                        if (lastOrder.onTime) ...<Widget>[
                          const SizedBox(height: 4),
                          Row(
                            children: <Widget>[
                              const Icon(
                                LucideIcons.circleCheck,
                                size: 14,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  AppStrings.homeLastOrderDeliveredOnTime,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  Expanded(
                    child: GlassButton.secondary(
                      label: AppStrings.homeLastOrderReceipt,
                      leadingIcon: LucideIcons.receipt,
                      onPressed: onReceiptTap,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: GlassButton.primary(
                      label: AppStrings.homeLastOrderRepeat,
                      leadingIcon: LucideIcons.rotateCcw,
                      onPressed: onRepeatTap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
