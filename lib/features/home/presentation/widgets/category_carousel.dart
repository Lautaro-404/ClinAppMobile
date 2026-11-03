import 'package:flutter/material.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/features/home/domain/home_models.dart';
import 'package:clinapp/shared/widgets/glass_chip.dart';

/// Carrusel horizontal de categorías con soporte para filtrar comercios.
class CategoryCarousel extends StatelessWidget {
  const CategoryCarousel({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelectCategory,
    super.key,
  });

  final List<CategoryItem> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                AppStrings.homeCategoriesTitle.toUpperCase(),
                style: AppTypography.labelMd.copyWith(
                  color: palette.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Semantics(
              button: true,
              label: AppStrings.actionSeeAll,
              child: InkWell(
                onTap: () => onSelectCategory(null),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xs,
                    horizontal: AppSpacing.xs,
                  ),
                  child: Text(
                    AppStrings.actionSeeAll,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              for (int i = 0; i < categories.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                GlassChip(
                  label: categories[i].name,
                  isSelected: selectedCategoryId == categories[i].id,
                  leading: Text(
                    categories[i].emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  onTap: () => onSelectCategory(categories[i].id),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
