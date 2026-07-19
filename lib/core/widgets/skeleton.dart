import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_x.dart';

/// ─────────────────────────────────────────────
/// ✨  Skeleton loading system
///
/// One shimmer to rule them all — replaces the three copy-pasted shimmer
/// implementations that used to live in home_screen and pinned_shimmer.
///
/// Wrap any tree of [SkeletonBox]es in a [Shimmer] to get a single,
/// synchronized light sweep:
///
///   Shimmer(child: Column(children: [SkeletonBox(...), SkeletonBox(...)]))
/// ─────────────────────────────────────────────

class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.slower,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.c.surfaceVariant;
    final highlight = Color.lerp(base, context.c.surface, 0.7)!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlideGradient(_controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.value);

  final double value;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Sweep from fully off-left (-1) to fully off-right (+1).
    final dx = bounds.width * (value * 2 - 1);
    return Matrix4.translationValues(dx, 0, 0);
  }
}

/// A single grey placeholder block. Only meaningful inside a [Shimmer].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.radius = AppRadius.sm,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.c.surfaceVariant,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
