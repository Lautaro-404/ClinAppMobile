import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/core/theme/glass_tokens.dart';
import 'package:clinapp/core/utils/money_formatter.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';
import 'package:clinapp/shared/widgets/glass_surface.dart';

/// Barra inferior flotante tipo píldora (Liquid Glass nivel 2) con el total
/// autoritativo del servidor y el botón primario de pago.
class CheckoutPayBar extends StatelessWidget {
  const CheckoutPayBar({
    required this.totalCents,
    required this.isSubmitting,
    required this.onPayTap,
    super.key,
  });

  final int totalCents;
  final bool isSubmitting;
  final VoidCallback? onPayTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final String formattedTotal = MoneyFormatter.format(totalCents);
    final String payButtonLabel = isSubmitting
        ? AppStrings.checkoutSubmittingLabel
        : '${AppStrings.checkoutPayButtonPrefix}$formattedTotal';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMarginCompact,
          AppSpacing.xs,
          AppSpacing.screenMarginCompact,
          AppSpacing.md,
        ),
        child: RepaintBoundary(
          child: GlassSurface(
            level: GlassTokens.level2,
            borderRadius: AppRadii.pillAll,
            enableBlur: true,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          AppStrings.checkoutFinalTotalLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSm.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                        Text(
                          formattedTotal,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headlineMd.copyWith(
                            color: palette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 3,
                    child: GlassButton.primary(
                      label: payButtonLabel,
                      leadingIcon: LucideIcons.lock,
                      isLoading: isSubmitting,
                      expand: true,
                      onPressed: isSubmitting ? null : onPayTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
