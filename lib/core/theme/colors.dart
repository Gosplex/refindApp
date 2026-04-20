import 'package:flutter/material.dart';

/// Calm, human-centered color system for the bookmark reminder app.
/// Built around sage green, warm off-white, and deep charcoal.
/// Every color answers: "Does this feel calm, natural, and effortless?"
abstract final class AppColors {

  // ─────────────────────────────────────────────
  // 🌿  Primary — Sage Green
  // ─────────────────────────────────────────────

  /// CTA buttons, active nav, focus rings
  static const Color primary       = Color(0xFF6B9E7A);

  /// Reminder badges, soft highlights
  static const Color primaryLight  = Color(0xFFA8C3A0);

  /// Tag fills, subtle tinted backgrounds
  static const Color primaryMuted  = Color(0xFFD6E8D3);

  /// Text on primary-colored surfaces
  static const Color onPrimary     = Color(0xFFFFFFFF);


  // ─────────────────────────────────────────────
  // ☀️  Light Mode Backgrounds
  // ─────────────────────────────────────────────

  /// App scaffold — warm off-white, never pure white
  static const Color background        = Color(0xFFF5F2ED);

  /// Cards, sheets, inputs — slightly elevated
  static const Color surface           = Color(0xFFFEFCFA);

  /// Hover states, dividers, skeleton shimmer
  static const Color surfaceVariant    = Color(0xFFEAE7E1);


  // ─────────────────────────────────────────────
  // 🌙  Dark Mode Backgrounds
  // ─────────────────────────────────────────────

  /// App scaffold dark — deep charcoal, not pure black
  static const Color backgroundDark     = Color(0xFF1C1C1E);

  /// Cards dark — slightly lighter than background
  static const Color surfaceDark        = Color(0xFF2A2A2C);

  /// Dividers, borders dark
  static const Color surfaceVariantDark = Color(0xFF3A3A3C);


  // ─────────────────────────────────────────────
  // 📝  Text
  // ─────────────────────────────────────────────

  /// Headings, titles — dark gray, not pure black
  static const Color textPrimary   = Color(0xFF2D2D2D);

  /// Body text, descriptions
  static const Color textSecondary = Color(0xFF6B6B6B);

  /// Timestamps, hints, placeholders
  static const Color textTertiary  = Color(0xFF9E9E9E);

  /// Text on dark surfaces — soft white
  static const Color textPrimaryDark   = Color(0xFFF0EDEA);

  /// Secondary text on dark surfaces
  static const Color textSecondaryDark = Color(0xFFADADAD);


  // ─────────────────────────────────────────────
  // 🧱  Borders & Dividers
  // ─────────────────────────────────────────────

  static const Color border     = Color(0xFFE2DDD7);
  static const Color borderDark = Color(0xFF3F3F41);


  // ─────────────────────────────────────────────
  // ⚠️  Semantic States
  // ─────────────────────────────────────────────

  /// Saved confirmation, sync success
  static const Color success     = Color(0xFF6BAE8A);
  static const Color successMuted = Color(0xFFD4EDE0);

  /// Overdue reminder, broken link
  static const Color error        = Color(0xFFB85C5C);
  static const Color errorMuted   = Color(0xFFF2DEDE);

  /// Reminder due soon
  static const Color warning      = Color(0xFFBF8C55);
  static const Color warningMuted = Color(0xFFF5E9D4);


  // ─────────────────────────────────────────────
  // 🌫️  Shadows & Overlays
  // ─────────────────────────────────────────────

  /// Soft card shadow — never harsh
  static const Color shadow  = Color(0x0D2D2D2D); // 5% opacity

  /// Bottom sheet / dialog scrim
  static const Color overlay = Color(0x661C1C1E); // 40% opacity


  // ─────────────────────────────────────────────
  // 🛠️  Helpers
  // ─────────────────────────────────────────────

  /// Resolves light/dark background at runtime
  static Color backgroundOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? backgroundDark
          : background;

  /// Resolves light/dark surface at runtime
  static Color surfaceOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? surfaceDark
          : surface;

  /// Resolves primary text color at runtime
  static Color textOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textPrimaryDark
          : textPrimary;
}