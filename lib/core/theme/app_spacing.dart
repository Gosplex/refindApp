import 'package:flutter/animation.dart';

/// ─────────────────────────────────────────────
/// 📏  Spacing scale
/// One source of truth for padding, gaps and margins.
/// Prefer these over magic numbers so rhythm stays consistent.
/// ─────────────────────────────────────────────
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// Standard horizontal screen inset.
  static const double screen = 16;
}

/// ─────────────────────────────────────────────
/// ⬛  Corner radius scale
/// ─────────────────────────────────────────────
abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double pill = 999;
}

/// ─────────────────────────────────────────────
/// 🎞️  Motion — durations & curves
/// Every animation in the app pulls from here so timing feels cohesive.
/// ─────────────────────────────────────────────
abstract final class AppMotion {
  static const Duration instant = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 480);
  static const Duration slower = Duration(milliseconds: 700);

  /// Calm, natural deceleration — the default for entrances.
  static const Curve standard = Curves.easeOutCubic;

  /// Snappy, expressive — good for presses and toggles.
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Gentle overshoot — playful reveals.
  static const Curve spring = Curves.easeOutBack;
}
