import 'package:flutter/material.dart';

import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';

/// Bloque de carga (skeleton) con pulso suave, sin `BackdropFilter`.
class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 80,
    this.borderRadius = AppRadii.cardAll,
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (disableAnimations) {
      return _buildBox(palette, 0.10);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double alpha = 0.06 + (_controller.value * 0.08);
        return _buildBox(palette, alpha);
      },
    );
  }

  Widget _buildBox(AppPalette palette, double alpha) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.textPrimary.withValues(alpha: alpha),
        borderRadius: widget.borderRadius,
        border: Border.all(color: palette.rimSoft),
      ),
      child: SizedBox(width: widget.width, height: widget.height),
    );
  }
}
