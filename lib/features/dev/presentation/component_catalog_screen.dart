import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/shared/widgets/empty_state.dart';
import 'package:clinapp/shared/widgets/error_state.dart';
import 'package:clinapp/shared/widgets/glass_background.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';
import 'package:clinapp/shared/widgets/glass_chip.dart';
import 'package:clinapp/shared/widgets/glass_quality.dart';
import 'package:clinapp/shared/widgets/glass_sheet.dart';
import 'package:clinapp/shared/widgets/glass_text_field.dart';
import 'package:clinapp/shared/widgets/loading_skeleton.dart';
import 'package:clinapp/shared/widgets/price_text.dart';
import 'package:clinapp/shared/widgets/rating_pill.dart';
import 'package:clinapp/shared/widgets/section_header.dart';
import 'package:clinapp/shared/widgets/status_badge.dart';

/// Catálogo interactivo de componentes Liquid Glass (Etapa 2).
class ComponentCatalogScreen extends ConsumerStatefulWidget {
  const ComponentCatalogScreen({super.key});

  @override
  ConsumerState<ComponentCatalogScreen> createState() =>
      _ComponentCatalogScreenState();
}

class _ComponentCatalogScreenState
    extends ConsumerState<ComponentCatalogScreen> {
  int _selectedChipIndex = 0;

  static const int _sampleTotalCents = 1460000;
  static const int _sampleDeliveryCents = 85000;

  @override
  Widget build(BuildContext context) {
    final GlassQuality quality = ref.watch(glassQualityProvider);
    final AppPalette palette = context.palette;
    final double horizontalMargin = AppSpacing.marginFor(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalMargin,
              AppSpacing.md,
              horizontalMargin,
              AppSpacing.scrollBottomReserve,
            ),
            children: <Widget>[
              _HeaderSection(quality: quality),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: AppStrings.catalogButtonsSection),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  GlassButton.primary(
                    label: AppStrings.catalogPrimaryCta,
                    trailingIcon: LucideIcons.arrowRight,
                    onPressed: () {},
                  ),
                  GlassButton.secondary(
                    label: AppStrings.catalogSecondaryCta,
                    leadingIcon: LucideIcons.receipt,
                    onPressed: () {},
                  ),
                  GlassButton.icon(
                    icon: LucideIcons.heart,
                    semanticLabel: AppStrings.catalogFavoriteSemantics,
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              GlassButton.secondary(
                label: AppStrings.catalogOpenSheet,
                leadingIcon: LucideIcons.layers,
                expand: true,
                onPressed: () => _openDemoSheet(context),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: AppStrings.catalogInputsSection),
              const SizedBox(height: AppSpacing.sm),
              const GlassTextField(
                hintText: AppStrings.catalogSearchHint,
                leadingIcon: LucideIcons.search,
              ),
              const SizedBox(height: AppSpacing.sm),
              const GlassTextField(
                hintText: AppStrings.catalogPasswordHint,
                leadingIcon: LucideIcons.lock,
                obscureText: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(
                title: AppStrings.catalogChipsSection,
                actionLabel: AppStrings.actionSeeAll,
                onActionTap: () {},
              ),
              const SizedBox(height: AppSpacing.xs),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    GlassChip(
                      label: AppStrings.catalogChipPizzas,
                      isSelected: _selectedChipIndex == 0,
                      leading: Icon(
                        LucideIcons.pizza,
                        size: 16,
                        color: palette.textPrimary,
                      ),
                      onTap: () => setState(() => _selectedChipIndex = 0),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GlassChip(
                      label: AppStrings.catalogChipBurgers,
                      isSelected: _selectedChipIndex == 1,
                      onTap: () => setState(() => _selectedChipIndex = 1),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GlassChip(
                      label: AppStrings.catalogChipEmpanadas,
                      isSelected: _selectedChipIndex == 2,
                      onDeleted: () {},
                      onTap: () => setState(() => _selectedChipIndex = 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: AppStrings.catalogCardsSection),
              const SizedBox(height: AppSpacing.sm),
              const _SampleMerchantCard(
                totalCents: _sampleTotalCents,
                deliveryCents: _sampleDeliveryCents,
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: AppStrings.catalogStatesSection),
              const SizedBox(height: AppSpacing.sm),
              const LoadingSkeleton(height: 68),
              const SizedBox(height: AppSpacing.md),
              EmptyState(
                title: AppStrings.catalogEmptyTitle,
                subtitle: AppStrings.catalogEmptySubtitle,
                actionLabel: AppStrings.catalogExploreMerchants,
                onAction: () {},
              ),
              const SizedBox(height: AppSpacing.md),
              ErrorState(onRetry: () {}),
            ],
          ),
        ),
      ),
    );
  }

  void _openDemoSheet(BuildContext context) {
    final AppPalette palette = context.palette;
    GlassSheet.show<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppStrings.catalogSheetTitle,
            style: AppTypography.headlineMd.copyWith(
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.catalogSheetBody,
            style: AppTypography.bodyMd.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          GlassButton.primary(
            label: AppStrings.actionClose,
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _HeaderSection extends ConsumerWidget {
  const _HeaderSection({required this.quality});

  final GlassQuality quality;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;

    // Única tarjeta en la pantalla con enableBlur: true (máx. 3 por pantalla).
    return GlassCard(
      enableBlur: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppStrings.cityName.toUpperCase(),
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                    Text(
                      AppStrings.catalogTitle,
                      style: AppTypography.headlineLg.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const StatusBadge(label: AppStrings.catalogStatusOnline),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.catalogSubtitle,
            style: AppTypography.bodySm.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  AppStrings.catalogQualityLabel,
                  style: AppTypography.labelMd.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
              ),
              GlassChip(
                label: quality.usesBlur
                    ? AppStrings.catalogQualityHigh
                    : AppStrings.catalogQualityLow,
                isSelected: quality.usesBlur,
                onTap: () => ref.read(glassQualityProvider.notifier).toggle(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SampleMerchantCard extends StatelessWidget {
  const _SampleMerchantCard({
    required this.totalCents,
    required this.deliveryCents,
  });

  final int totalCents;
  final int deliveryCents;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              StatusBadge(
                label: AppStrings.catalogMerchantTag,
                tone: StatusBadgeTone.accent,
                showDot: false,
              ),
              StatusBadge(
                label: AppStrings.catalogStatusDelivered,
                icon: LucideIcons.circleCheck,
              ),
              StatusBadge(
                label: AppStrings.catalogStatusPreparing,
                tone: StatusBadgeTone.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  AppStrings.catalogMerchantName,
                  style: AppTypography.headlineMd.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const RatingPill(rating: 4.9, reviewCount: 184),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              const Icon(LucideIcons.clock, size: 15, color: AppColors.success),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      AppStrings.catalogMerchantMeta,
                      style: AppTypography.bodySm.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                    PriceText(
                      cents: deliveryCents,
                      style: AppTypography.bodySm,
                      color: palette.textSecondary,
                    ),
                  ],
                ),
              ),
              PriceText(cents: totalCents),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.glassFill2,
              borderRadius: AppRadii.baseAll,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                AppStrings.foundationPriceLabel,
                style: AppTypography.labelSm.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
