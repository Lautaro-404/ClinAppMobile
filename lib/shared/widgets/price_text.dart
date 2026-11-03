import 'package:flutter/material.dart';

import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/core/utils/money_formatter.dart';

/// Muestra un monto en centavos formateado en ARS con cifras tabulares.
class PriceText extends StatelessWidget {
  const PriceText({
    required this.cents,
    super.key,
    this.style,
    this.color = AppColors.accent,
  });

  final int cents;
  final TextStyle? style;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final TextStyle effectiveStyle = (style ?? AppTypography.currencyDisplay)
        .copyWith(color: color);
    return Text(MoneyFormatter.format(cents), style: effectiveStyle);
  }
}
