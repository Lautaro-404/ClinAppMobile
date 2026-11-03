import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_shadows.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';

/// Chip selector tipo píldora para categorías, filtros y búsquedas recientes.
///
/// Mantiene un contenedor táctil mínimo de 48dp de alto para accesibilidad.
class GlassChip extends StatelessWidget {
  const GlassChip({
    required this.label,
    super.key,
    this.isSelected = false,
    this.onTap,
    this.leading,
    this.onDeleted,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? leading;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    final BoxDecoration decoration = isSelected
        ? BoxDecoration(
            color: AppColors.accent,
            borderRadius: AppRadii.pillAll,
            border: Border.all(color: palette.rimStrong),
            boxShadow: AppShadows.accentButton,
          )
        : BoxDecoration(
            color: palette.chipFill,
            borderRadius: AppRadii.pillAll,
            border: Border.all(color: palette.chipBorder),
          );

    final TextStyle textStyle = isSelected
        ? AppTypography.labelLg.copyWith(color: AppColors.onAccent)
        : AppTypography.labelMd.copyWith(color: palette.chipText);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTapTarget),
        child: Center(
          widthFactor: 1,
          child: DecoratedBox(
            decoration: decoration,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: AppRadii.pillAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (leading != null) ...<Widget>[
                        leading!,
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle,
                        ),
                      ),
                      if (onDeleted != null) ...<Widget>[
                        const SizedBox(width: AppSpacing.xs),
                        Semantics(
                          button: true,
                          label: '${AppStrings.actionClear} $label',
                          child: InkResponse(
                            key: Key('delete-chip-$label'),
                            onTap: onDeleted,
                            radius: 18,
                            child: Icon(
                              LucideIcons.x,
                              size: 14,
                              color: isSelected
                                  ? AppColors.onAccent
                                  : palette.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
