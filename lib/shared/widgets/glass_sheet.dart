import 'package:flutter/material.dart';

import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/glass_tokens.dart';
import 'package:clinapp/shared/widgets/glass_surface.dart';

/// Panel inferior modal de Nivel 3 con esquinas superiores de 36px y blur 32.
class GlassSheet extends StatelessWidget {
  const GlassSheet({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Muestra un [GlassSheet] como modal bottom sheet.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => GlassSheet(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return GlassSurface(
      level: GlassTokens.level3,
      borderRadius: AppRadii.sheetTop,
      enableBlur: true,
      fillOverride: palette.glassFill3,
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: palette.isDark
                          ? AppColors.rimStrong
                          : const Color(0xFFCBD5E1),
                      borderRadius: AppRadii.pillAll,
                    ),
                  ),
                ),
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
