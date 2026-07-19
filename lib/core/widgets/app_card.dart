import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_x.dart';
import 'motion.dart';

/// ─────────────────────────────────────────────
/// 🧱  AppCard
///
/// The single, canonical surface used across the app (post cards, pinned
/// cards, preview cards, list rows…). Handles border, radius, optional
/// soft shadow and — when [onTap] is set — a tactile press + ripple.
/// ─────────────────────────────────────────────
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadius.lg,
    this.color,
    this.border = true,
    this.elevated = false,
    this.haptics = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final bool border;

  /// When true, adds a soft drop shadow for a gently lifted feel.
  final bool elevated;
  final bool haptics;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final decoration = BoxDecoration(
      color: color ?? c.surface,
      borderRadius: BorderRadius.circular(radius),
      border: border ? Border.all(color: c.border, width: 0.8) : null,
      boxShadow: elevated
          ? [
              BoxShadow(
                color: c.shadow,
                blurRadius: 24,
                spreadRadius: -6,
                offset: const Offset(0, 10),
              ),
            ]
          : null,
    );

    final content = Padding(padding: padding, child: child);

    if (onTap == null && onLongPress == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }

    return PressableScale(
      onTap: onTap == null
          ? null
          : () {
              if (haptics) HapticFeedback.selectionClick();
              onTap!();
            },
      onLongPress: onLongPress,
      child: DecoratedBox(
        decoration: decoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: content,
        ),
      ),
    );
  }
}
