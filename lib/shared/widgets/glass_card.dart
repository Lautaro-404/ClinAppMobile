import 'package:flutter/material.dart';

import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/glass_tokens.dart';
import 'package:clinapp/shared/widgets/glass_surface.dart';

/// Tarjeta reutilizable de vidrio (esquinas 28px por defecto).
///
/// Para mantener 60/120 fps en listas largas, [enableBlur] viene desactivado
/// por defecto y usa vidrio óptico translúcido sobre el fondo atmosférico.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderRadius = AppRadii.cardAll,
    this.level = GlassTokens.level1,
    this.enableBlur = false,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final GlassLevel level;
  final bool enableBlur;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Widget content = onTap != null
        ? Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: borderRadius,
              child: Padding(padding: padding, child: child),
            ),
          )
        : Padding(padding: padding, child: child);

    final Widget card = GlassSurface(
      level: level,
      borderRadius: borderRadius,
      enableBlur: enableBlur,
      child: content,
    );

    if (semanticLabel != null) {
      return Semantics(
        button: onTap != null,
        label: semanticLabel,
        child: card,
      );
    }
    return card;
  }
}
