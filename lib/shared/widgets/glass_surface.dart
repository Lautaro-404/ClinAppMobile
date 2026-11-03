import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/glass_tokens.dart';
import 'package:clinapp/shared/widgets/glass_quality.dart';

/// Superficie base Liquid Glass con borde especular de 1px y brillo superior.
///
/// Por rendimiento, [enableBlur] solo debe activarse en elementos flotantes o
/// modales (máximo 3 por pantalla). En tarjetas de listas usar `false`.
class GlassSurface extends ConsumerWidget {
  const GlassSurface({
    required this.child,
    super.key,
    this.level,
    this.borderRadius = AppRadii.cardAll,
    this.padding,
    this.enableBlur = false,
    this.fillOverride,
  });

  final Widget child;
  final GlassLevel? level;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool enableBlur;
  final Color? fillOverride;

  GlassLevel _resolveLevel(AppPalette palette) {
    final GlassLevel? target = level;
    if (target == null || target == GlassTokens.darkLevel1) {
      return palette.level1;
    }
    if (target == GlassTokens.darkLevel2) {
      return palette.level2;
    }
    if (target == GlassTokens.darkLevel3) {
      return palette.level3;
    }
    return target;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final GlassLevel effectiveLevel = _resolveLevel(palette);
    final GlassQuality quality = ref.watch(glassQualityProvider);
    final bool mediaDisableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bool shouldBlur =
        enableBlur && quality.usesBlur && !mediaDisableAnimations;
    final double sigma = effectiveLevel.blurSigma.clamp(
      0,
      GlassTokens.maxBlurSigma,
    );

    final Color effectiveFill =
        fillOverride ??
        (shouldBlur
            ? effectiveLevel.fill
            : Color.alphaBlend(effectiveLevel.fill, palette.surfaceRest));

    Widget surface = CustomPaint(
      foregroundPainter: _SpecularRimPainter(
        borderRadius: borderRadius,
        rimStart: effectiveLevel.rimStart,
        rimEnd: effectiveLevel.rimEnd,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: effectiveFill,
          borderRadius: borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[palette.rimFaint, effectiveFill],
          ),
        ),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );

    if (shouldBlur && sigma > 0) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: surface,
      );
    }

    Widget result = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: effectiveLevel.shadows,
      ),
      child: ClipRRect(borderRadius: borderRadius, child: surface),
    );

    if (shouldBlur && sigma > 0) {
      result = RepaintBoundary(child: result);
    }

    return result;
  }
}

class _SpecularRimPainter extends CustomPainter {
  const _SpecularRimPainter({
    required this.borderRadius,
    required this.rimStart,
    required this.rimEnd,
  });

  final BorderRadius borderRadius;
  final Color rimStart;
  final Color rimEnd;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect rrect = borderRadius.toRRect(rect).deflate(0.5);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[rimStart, rimEnd],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _SpecularRimPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.rimStart != rimStart ||
        oldDelegate.rimEnd != rimEnd;
  }
}
