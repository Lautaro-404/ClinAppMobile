import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/shared/widgets/glass_chip.dart';

/// Sección de búsquedas recientes con chips seleccionables y borrado.
class RecentSearchesSection extends StatelessWidget {
  const RecentSearchesSection({
    required this.recentSearches,
    required this.onSelectTerm,
    required this.onDeleteTerm,
    required this.onClearAll,
    super.key,
  });

  final List<String> recentSearches;
  final ValueChanged<String> onSelectTerm;
  final ValueChanged<String> onDeleteTerm;
  final VoidCallback onClearAll;

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
                AppStrings.searchRecentTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMd.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ),
            if (recentSearches.isNotEmpty)
              Semantics(
                button: true,
                label: AppStrings.searchClearAll,
                child: InkWell(
                  onTap: onClearAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      AppStrings.searchClearAll,
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
        if (recentSearches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Text(
              AppStrings.searchEmptyHistory,
              style: AppTypography.bodySm.copyWith(color: palette.textTertiary),
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              for (final String term in recentSearches)
                GlassChip(
                  label: term,
                  leading: Icon(
                    LucideIcons.history,
                    size: 14,
                    color: palette.textSecondary,
                  ),
                  onTap: () => onSelectTerm(term),
                  onDeleted: () => onDeleteTerm(term),
                ),
            ],
          ),
      ],
    );
  }
}
