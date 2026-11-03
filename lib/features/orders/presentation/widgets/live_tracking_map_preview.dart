import 'package:flutter/material.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/features/orders/domain/orders_models.dart';
import 'package:clinapp/features/orders/presentation/widgets/courier_card.dart';

/// Vista previa integrada del mapa de seguimiento con trazado urbano y tarjeta del repartidor.
class LiveTrackingMapPreview extends StatelessWidget {
  const LiveTrackingMapPreview({
    required this.deliveryAddress,
    required this.courier,
    required this.onCallCourier,
    required this.onChatCourier,
    super.key,
  });

  final String deliveryAddress;
  final CourierInfo? courier;
  final VoidCallback onCallCourier;
  final VoidCallback onChatCourier;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: palette.canvas,
        borderRadius: AppRadii.cardAll,
        border: Border.all(color: palette.rimMedium),
        boxShadow: palette.cardShadows,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(
              painter: _GeneralAlvearMapPainter(isDark: palette.isDark),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    palette.canvas.withValues(alpha: 0.20),
                    Colors.transparent,
                    palette.canvas.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: palette.glassFillFloating,
                borderRadius: AppRadii.pillAll,
                border: Border.all(color: palette.rimMedium),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${AppStrings.ordersToPrefix}$deliveryAddress',
                    style: AppTypography.labelSm.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (courier != null)
            Positioned(
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: CourierCard(
                courier: courier!,
                onCallTap: onCallCourier,
                onChatTap: onChatCourier,
              ),
            ),
        ],
      ),
    );
  }
}

class _GeneralAlvearMapPainter extends CustomPainter {
  const _GeneralAlvearMapPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = isDark ? const Color(0xFF0D1117) : const Color(0xFFE2E8F0);
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final Paint blockPaint = Paint()
      ..color = isDark ? const Color(0xFF141923) : const Color(0xFFF1F5F9);
    const double blockW = 54;
    const double blockH = 38;
    const double roadGap = 12;

    for (double x = 8; x < size.width; x += blockW + roadGap) {
      for (double y = 8; y < size.height; y += blockH + roadGap) {
        final RRect block = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, blockW, blockH),
          const Radius.circular(6),
        );
        canvas.drawRRect(block, blockPaint);
      }
    }

    // Ruta de entrega.
    final Path routePath = Path();
    routePath.moveTo(size.width * 0.15, size.height * 0.70);
    routePath.lineTo(size.width * 0.45, size.height * 0.70);
    routePath.lineTo(size.width * 0.45, size.height * 0.28);
    routePath.lineTo(size.width * 0.82, size.height * 0.28);

    final Paint routeGlow = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(routePath, routeGlow);

    final Paint routeLine = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(routePath, routeLine);

    // Marcador de destino (Av. San Martín 450).
    final Paint destPaint = Paint()..color = AppColors.success;
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.28),
      6,
      destPaint,
    );

    // Marcador pulsante del repartidor (en camino).
    final Paint courierGlow = Paint()
      ..color = AppColors.accentGlow.withValues(alpha: 0.40);
    canvas.drawCircle(
      Offset(size.width * 0.45, size.height * 0.50),
      14,
      courierGlow,
    );
    final Paint courierDot = Paint()..color = AppColors.onAccent;
    canvas.drawCircle(
      Offset(size.width * 0.45, size.height * 0.50),
      5,
      courierDot,
    );
  }

  @override
  bool shouldRepaint(covariant _GeneralAlvearMapPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
