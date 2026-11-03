import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/shared/widgets/glass_chip.dart';

/// Barra superior fija con estética Liquid Glass para el panel de repartidor.
class CourierHeaderBar extends StatelessWidget {
  const CourierHeaderBar({
    super.key,
    required this.isOnline,
    required this.assignedCount,
    required this.kitchenCount,
    required this.availableCount,
    required this.historyCount,
    required this.activeFilterIndex,
    required this.onFilterChanged,
    required this.onBack,
  });

  final bool isOnline;
  final int assignedCount;
  final int kitchenCount;
  final int availableCount;
  final int historyCount;
  final int activeFilterIndex;
  final ValueChanged<int> onFilterChanged;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: palette.glassFill1,
        border: Border(bottom: BorderSide(color: palette.rimSoft)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              // Botón atrás
              IconButton(
                icon: const Icon(LucideIcons.arrowLeft, size: 20),
                color: palette.textPrimary,
                tooltip: 'Volver',
                onPressed: onBack,
              ),
              const SizedBox(width: AppSpacing.xs),

              // Avatar / Badge de Clin!
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[AppColors.accent, AppColors.accentGlow],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadii.pillAll,
                  border: Border.all(color: palette.rimStrong, width: 1.5),
                ),
                child: const Center(
                  child: Icon(LucideIcons.bike, size: 20, color: Colors.white),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Título y subtítulo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            AppStrings.courierPanelTitle,
                            style: AppTypography.headlineMd.copyWith(
                              fontWeight: FontWeight.bold,
                              color: palette.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: const BoxDecoration(
                            color: Color.fromRGBO(232, 82, 58, 0.20),
                            borderRadius: AppRadii.pillAll,
                          ),
                          child: Text(
                            AppStrings.courierPanelBadge,
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      AppStrings.courierPanelSubtitle,
                      style: AppTypography.bodySm.copyWith(
                        color: palette.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Indicador de estado (En servicio / Pausado)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isOnline
                      ? const Color.fromRGBO(16, 185, 129, 0.16)
                      : palette.glassFill2,
                  borderRadius: AppRadii.pillAll,
                  border: Border.all(
                    color: isOnline ? AppColors.success : palette.rimSoft,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline
                            ? AppColors.success
                            : palette.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline
                          ? AppStrings.courierStatusInService
                          : AppStrings.courierStatusPaused,
                      style: AppTypography.labelSm.copyWith(
                        color: isOnline
                            ? AppColors.success
                            : palette.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Chips horizontales de filtro
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                GlassChip(
                  label: '${AppStrings.courierTabAssigned} ($assignedCount)',
                  isSelected: activeFilterIndex == 0,
                  onTap: () => onFilterChanged(0),
                ),
                const SizedBox(width: AppSpacing.xs),
                GlassChip(
                  label: '${AppStrings.courierTabPreparing} ($kitchenCount)',
                  isSelected: activeFilterIndex == 1,
                  onTap: () => onFilterChanged(1),
                ),
                const SizedBox(width: AppSpacing.xs),
                GlassChip(
                  label: '${AppStrings.courierTabAvailable} ($availableCount)',
                  isSelected: activeFilterIndex == 2,
                  onTap: () => onFilterChanged(2),
                ),
                const SizedBox(width: AppSpacing.xs),
                GlassChip(
                  label: '${AppStrings.courierTabHistory} ($historyCount)',
                  isSelected: activeFilterIndex == 3,
                  onTap: () => onFilterChanged(3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
