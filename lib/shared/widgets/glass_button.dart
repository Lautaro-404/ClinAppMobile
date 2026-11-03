import 'package:flutter/material.dart';

import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_shadows.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';

/// Botón tipo píldora con estilo Liquid Glass.
///
/// Provee tres variantes: [GlassButton.primary], [GlassButton.secondary] y
/// [GlassButton.icon]. Garantiza área táctil mínima de 48×48 dp y etiquetas
/// semánticas en español.
class GlassButton extends StatelessWidget {
  const GlassButton.primary({
    required String this.label,
    required this.onPressed,
    super.key,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = false,
    this.semanticLabel,
  }) : _variant = _GlassButtonVariant.primary,
       icon = null;

  const GlassButton.secondary({
    required String this.label,
    required this.onPressed,
    super.key,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = false,
    this.semanticLabel,
  }) : _variant = _GlassButtonVariant.secondary,
       icon = null;

  const GlassButton.icon({
    required IconData this.icon,
    required String this.semanticLabel,
    required this.onPressed,
    super.key,
    this.isLoading = false,
  }) : _variant = _GlassButtonVariant.icon,
       label = null,
       leadingIcon = null,
       trailingIcon = null,
       expand = false;

  final String? label;
  final IconData? icon;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expand;
  final String? semanticLabel;
  final _GlassButtonVariant _variant;

  bool get _isEnabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    if (_variant == _GlassButtonVariant.icon) {
      return _buildIconButton(palette);
    }
    return _buildPillButton(palette);
  }

  Widget _buildIconButton(AppPalette palette) {
    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: semanticLabel,
      child: Tooltip(
        message: semanticLabel ?? '',
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSpacing.minTapTarget,
            minHeight: AppSpacing.minTapTarget,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.glassFill2,
              shape: BoxShape.circle,
              border: Border.all(color: palette.rimMedium),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: _isEnabled ? onPressed : null,
                customBorder: const CircleBorder(),
                child: Center(
                  child: isLoading
                      ? SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: palette.textPrimary,
                          ),
                        )
                      : Icon(
                          icon,
                          size: 20,
                          color: _isEnabled
                              ? palette.textPrimary
                              : palette.textTertiary,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillButton(AppPalette palette) {
    final bool isPrimary = _variant == _GlassButtonVariant.primary;

    final BoxDecoration decoration = isPrimary
        ? BoxDecoration(
            gradient: _isEnabled
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[AppColors.accentGlow, AppColors.accent],
                  )
                : null,
            color: _isEnabled ? null : palette.glassFill1,
            borderRadius: AppRadii.pillAll,
            border: Border.all(
              color: _isEnabled ? palette.rimStrong : palette.rimSoft,
            ),
            boxShadow: _isEnabled ? AppShadows.accentButton : null,
          )
        : BoxDecoration(
            color: palette.glassFill2,
            borderRadius: AppRadii.pillAll,
            border: Border.all(color: palette.rimMedium),
          );

    final Color contentColor = isPrimary
        ? (_isEnabled ? AppColors.onAccent : palette.textTertiary)
        : (_isEnabled ? palette.textPrimary : palette.textTertiary);

    final Widget innerContent = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + AppSpacing.xs,
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (isLoading) ...<Widget>[
            SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: contentColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ] else if (leadingIcon != null) ...<Widget>[
            Icon(leadingIcon, size: 18, color: contentColor),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Text(
              label ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelLg.copyWith(color: contentColor),
            ),
          ),
          if (!isLoading && trailingIcon != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            Icon(trailingIcon, size: 18, color: contentColor),
          ],
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: semanticLabel ?? label,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: AppSpacing.minTapTarget,
          minWidth: expand ? double.infinity : AppSpacing.minTapTarget,
        ),
        child: DecoratedBox(
          decoration: decoration,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: _isEnabled ? onPressed : null,
              borderRadius: AppRadii.pillAll,
              child: innerContent,
            ),
          ),
        ),
      ),
    );
  }
}

enum _GlassButtonVariant { primary, secondary, icon }
