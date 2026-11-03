import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/router/app_routes.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/features/home/domain/home_models.dart';
import 'package:clinapp/features/home/presentation/home_controller.dart';
import 'package:clinapp/features/home/presentation/widgets/category_carousel.dart';
import 'package:clinapp/features/home/presentation/widgets/greeting_header.dart';
import 'package:clinapp/features/home/presentation/widgets/home_top_bar.dart';
import 'package:clinapp/features/home/presentation/widgets/last_order_card.dart';
import 'package:clinapp/features/home/presentation/widgets/merchant_card.dart';
import 'package:clinapp/features/home/presentation/widgets/promo_banner.dart';
import 'package:clinapp/shared/widgets/empty_state.dart';
import 'package:clinapp/shared/widgets/error_state.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';
import 'package:clinapp/shared/widgets/glass_text_field.dart';
import 'package:clinapp/shared/widgets/loading_skeleton.dart';
import 'package:clinapp/shared/widgets/section_header.dart';

/// Pantalla Inicio completa con estado reactivo, categorías, promo,
/// último pedido y comercios cercanos.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<HomeViewState> asyncState = ref.watch(
      homeControllerProvider,
    );
    final double horizontalMargin = AppSpacing.marginFor(
      MediaQuery.sizeOf(context).width,
    );

    return SafeArea(
      bottom: false,
      child: asyncState.when(
        loading: () => _HomeLoadingView(horizontalMargin: horizontalMargin),
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
                    ref.read(homeControllerProvider.notifier).refresh(),
              ),
            ),
          );
        },
        data: (HomeViewState viewState) => _HomeContentView(
          viewState: viewState,
          horizontalMargin: horizontalMargin,
        ),
      ),
    );
  }
}

class _HomeLoadingView extends StatelessWidget {
  const _HomeLoadingView({required this.horizontalMargin});

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
        LoadingSkeleton(height: 54),
        SizedBox(height: AppSpacing.md),
        LoadingSkeleton(height: 48),
        SizedBox(height: AppSpacing.md),
        LoadingSkeleton(height: 48),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(height: 160),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(height: 220),
      ],
    );
  }
}

class _HomeContentView extends ConsumerWidget {
  const _HomeContentView({
    required this.viewState,
    required this.horizontalMargin,
  });

  final HomeViewState viewState;
  final double horizontalMargin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HomeFeedData feed = viewState.feed;
    final List<MerchantSummary> merchants = viewState.visibleMerchants;

    return RefreshIndicator(
      onRefresh: () => ref.read(homeControllerProvider.notifier).refresh(),
      child: ListView(
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
          GreetingHeader(
            userName: feed.userName,
            address: feed.deliveryAddress,
            isOnline: feed.isOnline,
            onAddressTap: () => context.go(AppRoutes.profile),
          ),
          const SizedBox(height: AppSpacing.md),
          GlassTextField(
            hintText: AppStrings.catalogSearchHint,
            leadingIcon: LucideIcons.search,
            onSubmitted: (_) => context.go(AppRoutes.search),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                GlassButton.icon(
                  icon: LucideIcons.slidersHorizontal,
                  semanticLabel: AppStrings.homeFiltersSemantics,
                  onPressed: () => context.go(AppRoutes.search),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CategoryCarousel(
            categories: feed.categories,
            selectedCategoryId: viewState.selectedCategoryId,
            onSelectCategory: (String? id) =>
                ref.read(homeControllerProvider.notifier).selectCategory(id),
          ),
          const SizedBox(height: AppSpacing.lg),
          PromoBanner(
            promo: feed.promoBanner,
            onCtaTap: () => context.push(AppRoutes.checkout),
          ),
          if (feed.lastOrder != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            LastOrderCard(
              lastOrder: feed.lastOrder!,
              onReceiptTap: () => context.go(AppRoutes.orders),
              onRepeatTap: () async {
                final bool ok = await ref
                    .read(homeControllerProvider.notifier)
                    .repeatLastOrder(feed.lastOrder!);
                if (context.mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.ordersReorderSuccess),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  unawaited(context.push(AppRoutes.checkout));
                }
              },
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: AppStrings.homeNearbyTitle,
            subtitle: AppStrings.homeSubtitle,
            trailing: GlassButton.icon(
              icon: LucideIcons.map,
              semanticLabel: AppStrings.homeViewMapSemantics,
              onPressed: () => context.go(AppRoutes.orders),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (merchants.isEmpty)
            EmptyState(
              title: AppStrings.homeEmptyCategoryTitle,
              subtitle: AppStrings.homeEmptyCategorySubtitle,
              actionLabel: AppStrings.homeResetCategoryFilter,
              onAction: () => ref
                  .read(homeControllerProvider.notifier)
                  .selectCategory(null),
            )
          else
            for (int i = 0; i < merchants.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              MerchantCard(
                merchant: merchants[i],
                onTap: () => context.push(AppRoutes.checkout),
                onToggleFavorite: () => ref
                    .read(homeControllerProvider.notifier)
                    .toggleFavorite(merchants[i].id),
              ),
            ],
          if (kDebugMode) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            GlassButton.secondary(
              label: AppStrings.homeOpenCatalog,
              leadingIcon: LucideIcons.layers,
              expand: true,
              onPressed: () => context.push(AppRoutes.devCatalog),
            ),
          ],
        ],
      ),
    );
  }
}
