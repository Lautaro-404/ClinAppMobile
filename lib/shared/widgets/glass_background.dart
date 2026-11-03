import 'package:flutter/material.dart';

import 'package:clinapp/core/theme/app_palette.dart';

/// Fondo atmosférico Nivel 0 con manchas de luz adaptativas (oscuro o claro).
///
/// Usa gradientes radiales dentro de un [RepaintBoundary] en lugar de
/// `BackdropFilter` para tener costo de GPU prácticamente nulo.
class GlassBackground extends StatelessWidget {
  const GlassBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        RepaintBoundary(
          child: CustomPaint(
            painter: _AtmosphericMeshPainter(
              canvasColor: palette.canvas,
              flareColor: palette.lightFlare,
              emberColor: palette.lightEmber,
              isDark: palette.isDark,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        child,
      ],
    );
  }
}

class _AtmosphericMeshPainter extends CustomPainter {
  const _AtmosphericMeshPainter({
    required this.canvasColor,
    required this.flareColor,
    required this.emberColor,
    required this.isDark,
  });

  final Color canvasColor;
  final Color flareColor;
  final Color emberColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect fullRect = Offset.zero & size;
    canvas.drawRect(fullRect, Paint()..color = canvasColor);

    if (isDark) {
      _drawOrb(
        canvas: canvas,
        center: Offset(size.width * 0.12, size.height * 0.08),
        radius: size.width * 0.65,
        color: flareColor,
      );
      _drawOrb(
        canvas: canvas,
        center: Offset(size.width * 0.92, size.height * 0.42),
        radius: size.width * 0.70,
        color: emberColor,
      );
      _drawOrb(
        canvas: canvas,
        center: Offset(size.width * 0.18, size.height * 0.82),
        radius: size.width * 0.60,
        color: flareColor,
      );
    } else {
      // Modo Claro: Orbes coral y cálidos sutiles que transcienden el fondo
      _drawOrb(
        canvas: canvas,
        center: Offset(size.width * -0.05, size.height * -0.05),
        radius: size.width * 0.75,
        color: const Color.fromRGBO(255, 217, 210, 0.70),
      );
      _drawOrb(
        canvas: canvas,
        center: Offset(size.width * 1.05, size.height * 0.28),
        radius: size.width * 0.80,
        color: const Color.fromRGBO(255, 228, 222, 0.75),
      );
      _drawOrb(
        canvas: canvas,
        center: Offset(size.width * -0.05, size.height * 0.60),
        radius: size.width * 0.70,
        color: flareColor,
      );
      _drawOrb(
        canvas: canvas,
        center: Offset(size.width * 0.95, size.height * 0.85),
        radius: size.width * 0.70,
        color: emberColor,
      );
    }
  }

  void _drawOrb({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final Rect orbRect = Rect.fromCircle(center: center, radius: radius);
    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[color, color.withValues(alpha: 0)],
      ).createShader(orbRect);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AtmosphericMeshPainter oldDelegate) {
    return oldDelegate.canvasColor != canvasColor ||
        oldDelegate.flareColor != flareColor ||
        oldDelegate.emberColor != emberColor ||
        oldDelegate.isDark != isDark;
  }
}
