import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// ─────────────────────────────────────────────
/// 🎬  Reusable motion primitives
///
/// These are the building blocks for the app's "alive" feel:
///  • [FadeSlideIn]  — staggered entrance for lists & sections
///  • [PressableScale] — tactile press feedback for any tappable
/// ─────────────────────────────────────────────

/// Fades + slides its [child] up into place once, on first build.
///
/// Pass [index] inside a list so items cascade in one after another.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = AppMotion.slow,
    this.delayPerItem = const Duration(milliseconds: 55),
    this.maxStagger = 8,
    this.offset = 16,
    this.curve = AppMotion.standard,
  });

  final Widget child;
  final int index;
  final Duration duration;
  final Duration delayPerItem;

  /// Cap the stagger so long lists don't take forever to appear.
  final int maxStagger;
  final double offset;
  final Curve curve;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    final steps = widget.index.clamp(0, widget.maxStagger);
    final delay = widget.delayPerItem * steps;
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - curved.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Wraps [child] and shrinks it slightly while pressed, then springs back.
/// Gives any tappable element a physical, satisfying response.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
    this.duration = AppMotion.fast,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final Duration duration;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: AppMotion.emphasized,
        child: widget.child,
      ),
    );
  }
}
