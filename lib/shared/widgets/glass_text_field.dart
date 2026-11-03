import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';

/// Campo de texto tipo píldora (48dp de alto mínimo) con foco luminoso `#E8523A`.
class GlassTextField extends StatefulWidget {
  const GlassTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.leadingIcon,
    this.trailing,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? leadingIcon;
  final Widget? trailing;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final bool enabled;

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  late bool _obscured = widget.obscureText;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus != _isFocused) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    final Widget field = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: const BoxConstraints(minHeight: AppSpacing.minTapTarget),
      decoration: BoxDecoration(
        color: palette.glassFill1,
        borderRadius: AppRadii.pillAll,
        border: Border.all(
          color: _isFocused ? AppColors.accent : palette.rimMedium,
        ),
        boxShadow: _isFocused
            ? const <BoxShadow>[
                BoxShadow(
                  color: Color.fromRGBO(232, 82, 58, 0.30),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: <Widget>[
          if (widget.leadingIcon != null) ...<Widget>[
            Icon(
              widget.leadingIcon,
              size: 20,
              color: _isFocused ? AppColors.accent : palette.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: _obscured,
              enabled: widget.enabled,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onChanged: widget.onChanged,
              onFieldSubmitted: widget.onSubmitted,
              validator: widget.validator,
              style: AppTypography.bodyMd.copyWith(color: palette.textPrimary),
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.hintText,
                hintStyle: AppTypography.bodyMd.copyWith(
                  color: palette.textTertiary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm + AppSpacing.xs,
                ),
              ),
            ),
          ),
          if (widget.obscureText)
            Semantics(
              button: true,
              label: _obscured
                  ? AppStrings.showPassword
                  : AppStrings.hidePassword,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _obscured = !_obscured;
                  });
                },
                icon: Icon(
                  _obscured ? LucideIcons.eye : LucideIcons.eyeOff,
                  size: 18,
                  color: palette.textSecondary,
                ),
              ),
            )
          else if (widget.trailing != null)
            widget.trailing!,
        ],
      ),
    );

    if (widget.labelText == null) {
      return field;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.xs,
          ),
          child: Text(
            widget.labelText!,
            style: AppTypography.labelMd.copyWith(color: palette.textSecondary),
          ),
        ),
        field,
      ],
    );
  }
}
