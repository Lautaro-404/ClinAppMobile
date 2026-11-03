import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/shared/widgets/glass_chip.dart';

/// Barra superior fija para el panel de administración de General Alvear.
class AdminHeaderBar extends StatelessWidget {
  const AdminHeaderBar({
    super.key,
    required this.merchantsCount,
    required this.couriersCount,
    required this.activeFilterIndex,
    required this.onFilterChanged,
    required this.onBack,
  });

  final int merchantsCount;
  final int couriersCount;
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
              IconButton(
                icon: const Icon(LucideIcons.arrowLeft, size: 20),
                color: palette.textPrimary,
                tooltip: 'Volver',
                onPressed: onBack,
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadii.pillAll,
                  border: Border.all(color: palette.rimStrong, width: 1.5),
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.shieldCheck,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            AppStrings.adminPanelHeaderTitle,
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
                            color: Color.fromRGBO(99, 102, 241, 0.20),
                            borderRadius: AppRadii.pillAll,
                          ),
                          child: Text(
                            AppStrings.adminPanelBadge,
                            style: AppTypography.labelSm.copyWith(
                              color: const Color(0xFF818CF8),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      AppStrings.adminPanelSubtitle,
                      style: AppTypography.bodySm.copyWith(
                        color: palette.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(16, 185, 129, 0.16),
                  borderRadius: AppRadii.pillAll,
                  border: Border.all(color: AppColors.success),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Operativo',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.success,
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                GlassChip(
                  label: AppStrings.adminTabSummary,
                  isSelected: activeFilterIndex == 0,
                  onTap: () => onFilterChanged(0),
                ),
                const SizedBox(width: AppSpacing.xs),
                GlassChip(
                  label: '${AppStrings.adminTabMerchants} ($merchantsCount)',
                  isSelected: activeFilterIndex == 1,
                  onTap: () => onFilterChanged(1),
                ),
                const SizedBox(width: AppSpacing.xs),
                GlassChip(
                  label: '${AppStrings.adminTabCouriers} ($couriersCount)',
                  isSelected: activeFilterIndex == 2,
                  onTap: () => onFilterChanged(2),
                ),
                const SizedBox(width: AppSpacing.xs),
                GlassChip(
                  label: AppStrings.adminTabRates,
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
