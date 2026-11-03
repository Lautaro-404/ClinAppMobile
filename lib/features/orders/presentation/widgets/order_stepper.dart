import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/features/orders/domain/orders_models.dart';

/// Stepper horizontal de 5 pasos con barra de ETA multisensorial.
class OrderStepper extends StatelessWidget {
  const OrderStepper({
    required this.status,
    this.remainingMinutes = 18,
    this.isExpress = true,
    super.key,
  });

  final OrderStatus status;
  final int remainingMinutes;
  final bool isExpress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    if (status.isCancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.15),
          borderRadius: AppRadii.lgAll,
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.40)),
        ),
        child: Row(
          children: <Widget>[
            const Icon(LucideIcons.circleX, color: AppColors.danger, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                status == OrderStatus.rechazado
                    ? 'Pedido rechazado por el local'
                    : 'Pedido cancelado',
                style: AppTypography.bodySm.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final int activeIndex = status.stepperIndex;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 2,
                child: _StepCircle(
                  icon: LucideIcons.checkCheck,
                  label: AppStrings.ordersStepConfirmed,
                  state: _stepStateFor(0, activeIndex),
                ),
              ),
              Expanded(
                child: _StepConnector(
                  isCompleted: activeIndex > 0,
                  isTransition: activeIndex == 1,
                ),
              ),
              Expanded(
                flex: 2,
                child: _StepCircle(
                  icon: LucideIcons.utensils,
                  label: AppStrings.ordersStepPreparing,
                  state: _stepStateFor(1, activeIndex),
                ),
              ),
              Expanded(
                child: _StepConnector(
                  isCompleted: activeIndex > 1,
                  isTransition: activeIndex == 2,
                ),
              ),
              Expanded(
                flex: 2,
                child: _StepCircle(
                  icon: LucideIcons.packageCheck,
                  label: AppStrings.ordersStepReady,
                  state: _stepStateFor(2, activeIndex),
                ),
              ),
              Expanded(
                child: _StepConnector(
                  isCompleted: activeIndex > 2,
                  isTransition: activeIndex == 3,
                ),
              ),
              Expanded(
                flex: 2,
                child: _StepCircle(
                  icon: LucideIcons.bike,
                  label: AppStrings.ordersStepOnTheWay,
                  state: _stepStateFor(3, activeIndex),
                ),
              ),
              Expanded(
                child: _StepConnector(
                  isCompleted: activeIndex > 3,
                  isTransition: activeIndex == 4,
                ),
              ),
              Expanded(
                flex: 2,
                child: _StepCircle(
                  icon: LucideIcons.mapPin,
                  label: AppStrings.ordersStepDelivered,
                  state: _stepStateFor(4, activeIndex),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: palette.glassFill2,
            borderRadius: AppRadii.pillAll,
            border: Border.all(color: palette.rimMedium),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Row(
                  children: <Widget>[
                    const Icon(
                      LucideIcons.clock,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Expanded(
                      child: Text(
                        '${AppStrings.ordersRemainingPrefix}$remainingMinutes min',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySm.copyWith(
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isExpress) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  AppStrings.ordersExpressDelivery,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  _StepVisualState _stepStateFor(int index, int activeIndex) {
    if (index < activeIndex) {
      return _StepVisualState.completed;
    }
    if (index == activeIndex) {
      return _StepVisualState.active;
    }
    return _StepVisualState.pending;
  }
}

enum _StepVisualState { completed, active, pending }

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.icon,
    required this.label,
    required this.state,
  });

  final IconData icon;
  final String label;
  final _StepVisualState state;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    final BoxDecoration decoration = switch (state) {
      _StepVisualState.completed => BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      _StepVisualState.active => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.accentGlow, AppColors.accent],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.rimStrong, width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.50),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      _StepVisualState.pending => BoxDecoration(
        color: palette.glassFill2,
        shape: BoxShape.circle,
        border: Border.all(color: palette.rimMedium),
      ),
    };

    final Color iconColor = switch (state) {
      _StepVisualState.completed ||
      _StepVisualState.active => AppColors.onAccent,
      _StepVisualState.pending => palette.textTertiary,
    };

    final Color labelColor = switch (state) {
      _StepVisualState.completed => AppColors.success,
      _StepVisualState.active => AppColors.accent,
      _StepVisualState.pending => palette.textTertiary,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        DecoratedBox(
          decoration: decoration,
          child: SizedBox.square(
            dimension: 36,
            child: Center(child: Icon(icon, size: 18, color: iconColor)),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTypography.labelSm.copyWith(
            color: labelColor,
            fontSize: 10,
            fontWeight: state == _StepVisualState.active
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector({required this.isCompleted, required this.isTransition});

  final bool isCompleted;
  final bool isTransition;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    final Decoration decoration = isCompleted
        ? const BoxDecoration(
            color: AppColors.success,
            borderRadius: AppRadii.pillAll,
          )
        : isTransition
        ? const BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[AppColors.success, AppColors.accent],
            ),
            borderRadius: AppRadii.pillAll,
          )
        : BoxDecoration(
            color: palette.rimMedium,
            borderRadius: AppRadii.pillAll,
          );

    return Container(
      height: 4,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: decoration,
    );
  }
}
