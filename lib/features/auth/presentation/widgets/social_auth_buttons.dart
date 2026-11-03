import 'package:flutter/material.dart';

import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';

/// Divisor y botones sociales tipo píldora para Google y Apple.
class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({
    super.key,
    required this.dividerText,
    required this.onGooglePressed,
    required this.onApplePressed,
    this.isLoading = false,
  });

  final String dividerText;
  final VoidCallback onGooglePressed;
  final VoidCallback onApplePressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Divisor con etiqueta
        Row(
          children: <Widget>[
            Expanded(child: Divider(color: palette.rimMedium)),
            Flexible(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  dividerText.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSm.copyWith(
                    color: palette.textTertiary,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(child: Divider(color: palette.rimMedium)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Fila de botones Google y Apple
        Row(
          children: <Widget>[
            Expanded(
              child: _SocialPillButton(
                label: 'Google',
                icon: const _GoogleIcon(),
                onPressed: isLoading ? null : onGooglePressed,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _SocialPillButton(
                label: 'Apple',
                icon: _AppleIcon(color: palette.textPrimary),
                onPressed: isLoading ? null : onApplePressed,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialPillButton extends StatelessWidget {
  const _SocialPillButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.minTapTarget),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: palette.glassFill2,
          side: BorderSide(color: palette.rimMedium),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.pillAll),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            icon,
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMd.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFFEA4335),
            fontWeight: FontWeight.w900,
            fontSize: 12,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

class _AppleIcon extends StatelessWidget {
  const _AppleIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.apple, size: 20, color: color);
  }
}
