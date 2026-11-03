import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/features/search/domain/search_models.dart';
import 'package:clinapp/shared/widgets/glass_chip.dart';

/// Tira horizontal de filtros rápidos combinables en la pantalla Buscar.
class SearchFiltersRow extends StatelessWidget {
  const SearchFiltersRow({
    required this.activeFilters,
    required this.onToggleFilter,
    super.key,
  });

  final Set<SearchFilter> activeFilters;
  final ValueChanged<SearchFilter> onToggleFilter;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          GlassChip(
            label: AppStrings.searchFilterOpenNow,
            isSelected: activeFilters.contains(SearchFilter.openNow),
            leading: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: activeFilters.contains(SearchFilter.openNow)
                    ? AppColors.onAccent
                    : AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            onTap: () => onToggleFilter(SearchFilter.openNow),
          ),
          const SizedBox(width: AppSpacing.sm),
          GlassChip(
            label: AppStrings.searchFilterFreeDelivery,
            isSelected: activeFilters.contains(SearchFilter.freeDelivery),
            leading: const Text('🚀', style: TextStyle(fontSize: 13)),
            onTap: () => onToggleFilter(SearchFilter.freeDelivery),
          ),
          const SizedBox(width: AppSpacing.sm),
          GlassChip(
            label: AppStrings.searchFilterTopRated,
            isSelected: activeFilters.contains(SearchFilter.topRated),
            leading: Icon(
              LucideIcons.star,
              size: 14,
              color: activeFilters.contains(SearchFilter.topRated)
                  ? AppColors.onAccent
                  : AppColors.accent,
            ),
            onTap: () => onToggleFilter(SearchFilter.topRated),
          ),
          const SizedBox(width: AppSpacing.sm),
          GlassChip(
            label: AppStrings.searchFilterFastest,
            isSelected: activeFilters.contains(SearchFilter.fastest),
            leading: Icon(
              LucideIcons.clock,
              size: 14,
              color: activeFilters.contains(SearchFilter.fastest)
                  ? AppColors.onAccent
                  : AppColors.success,
            ),
            onTap: () => onToggleFilter(SearchFilter.fastest),
          ),
        ],
      ),
    );
  }
}
