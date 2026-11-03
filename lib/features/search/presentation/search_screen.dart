import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/router/app_routes.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/features/home/presentation/widgets/home_top_bar.dart';
import 'package:clinapp/features/search/domain/search_models.dart';
import 'package:clinapp/features/search/presentation/search_controller.dart';
import 'package:clinapp/features/search/presentation/widgets/recent_searches_section.dart';
import 'package:clinapp/features/search/presentation/widgets/search_filters_row.dart';
import 'package:clinapp/features/search/presentation/widgets/suggested_merchant_tile.dart';
import 'package:clinapp/shared/widgets/empty_state.dart';
import 'package:clinapp/shared/widgets/error_state.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';
import 'package:clinapp/shared/widgets/glass_text_field.dart';
import 'package:clinapp/shared/widgets/loading_skeleton.dart';

/// Pantalla Buscar completa con entrada debounced, búsquedas recientes,
/// filtros combinables y tarjetas de comercios con plato insignia.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _selectRecentTerm(String term) {
    _textController.value = TextEditingValue(
      text: term,
      selection: TextSelection.collapsed(offset: term.length),
    );
    ref.read(searchControllerProvider.notifier).applyQueryImmediately(term);
  }

  void _resetAll() {
    _textController.clear();
    ref.read(searchControllerProvider.notifier).resetAllFiltersAndQuery();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<SearchViewState> asyncState = ref.watch(
      searchControllerProvider,
    );
    final double horizontalMargin = AppSpacing.marginFor(
      MediaQuery.sizeOf(context).width,
    );

    return SafeArea(
      bottom: false,
      child: asyncState.when(
        loading: () => _SearchLoadingView(horizontalMargin: horizontalMargin),
        error: (Object error, StackTrace stackTrace) {
          final String message = error is AppException
              ? error.message
              : AppStrings.genericErrorMessage;
          return Center(
            child: Padding(
              padding: EdgeInsets.all(horizontalMargin),
              child: ErrorState(
                message: message,
                onRetry: () =>
                    ref.read(searchControllerProvider.notifier).refresh(),
              ),
            ),
          );
        },
        data: (SearchViewState viewState) => _SearchContentView(
          viewState: viewState,
          horizontalMargin: horizontalMargin,
          textController: _textController,
          onSelectRecentTerm: _selectRecentTerm,
          onResetAll: _resetAll,
        ),
      ),
    );
  }
}

class _SearchLoadingView extends StatelessWidget {
  const _SearchLoadingView({required this.horizontalMargin});

  final double horizontalMargin;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalMargin,
        AppSpacing.md,
        horizontalMargin,
        AppSpacing.scrollBottomReserve,
      ),
      children: const <Widget>[
        LoadingSkeleton(height: 48),
        SizedBox(height: AppSpacing.md),
        LoadingSkeleton(height: 48),
        SizedBox(height: AppSpacing.md),
        LoadingSkeleton(height: 42),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(height: 150),
        SizedBox(height: AppSpacing.md),
        LoadingSkeleton(height: 150),
      ],
    );
  }
}

class _SearchContentView extends ConsumerWidget {
  const _SearchContentView({
    required this.viewState,
    required this.horizontalMargin,
    required this.textController,
    required this.onSelectRecentTerm,
    required this.onResetAll,
  });

  final SearchViewState viewState;
  final double horizontalMargin;
  final TextEditingController textController;
  final ValueChanged<String> onSelectRecentTerm;
  final VoidCallback onResetAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final List<SearchMerchantItem> merchants = viewState.visibleMerchants;
    final bool hasQuery = viewState.query.trim().isNotEmpty;
    final String countLabel = merchants.length == 1
        ? AppStrings.searchAvailableSingular
        : '${merchants.length}${AppStrings.searchAvailableSuffix}';

    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalMargin,
        AppSpacing.md,
        horizontalMargin,
        AppSpacing.scrollBottomReserve,
      ),
      children: <Widget>[
        HomeTopBar(
          onNotificationsTap: () => context.go(AppRoutes.profile),
          onProfileTap: () => context.go(AppRoutes.profile),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(
              child: GlassTextField(
                key: const Key('search-query-field'),
                controller: textController,
                hintText: AppStrings.searchHint,
                leadingIcon: LucideIcons.search,
                textInputAction: TextInputAction.search,
                trailing: hasQuery
                    ? Semantics(
                        button: true,
                        label: AppStrings.actionClear,
                        child: IconButton(
                          onPressed: () {
                            textController.clear();
                            ref
                                .read(searchControllerProvider.notifier)
                                .applyQueryImmediately('');
                          },
                          icon: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: palette.textSecondary,
                          ),
                        ),
                      )
                    : null,
                onChanged: (String value) => ref
                    .read(searchControllerProvider.notifier)
                    .updateQueryDebounced(value),
                onSubmitted: (String value) => ref
                    .read(searchControllerProvider.notifier)
                    .applyQueryImmediately(value),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GlassButton.icon(
              icon: LucideIcons.slidersHorizontal,
              semanticLabel: AppStrings.searchAdvancedFiltersSemantics,
              onPressed: onResetAll,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        RecentSearchesSection(
          recentSearches: viewState.recentSearches,
          onSelectTerm: onSelectRecentTerm,
          onDeleteTerm: (String term) => ref
              .read(searchControllerProvider.notifier)
              .removeRecentSearch(term),
          onClearAll: () =>
              ref.read(searchControllerProvider.notifier).clearRecentSearches(),
        ),
        const SizedBox(height: AppSpacing.lg),
        SearchFiltersRow(
          activeFilters: viewState.activeFilters,
          onToggleFilter: (SearchFilter filter) =>
              ref.read(searchControllerProvider.notifier).toggleFilter(filter),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                hasQuery
                    ? AppStrings.searchResultsTitle
                    : AppStrings.searchSuggestedTitle,
                style: AppTypography.headlineMd.copyWith(
                  color: palette.textPrimary,
                ),
              ),
            ),
            Text(
              countLabel,
              style: AppTypography.labelSm.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (int i = 0; i < merchants.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          SuggestedMerchantTile(
            merchant: merchants[i],
            onTap: () => context.push(AppRoutes.checkout),
            onToggleFavorite: () => ref
                .read(searchControllerProvider.notifier)
                .toggleFavorite(merchants[i].id),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        EmptyState(
          title: AppStrings.catalogEmptyTitle,
          subtitle: AppStrings.catalogEmptySubtitle,
          actionLabel: AppStrings.catalogExploreMerchants,
          onAction: onResetAll,
        ),
      ],
    );
  }
}
