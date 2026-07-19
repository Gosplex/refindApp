import 'package:flutter/material.dart';
import 'colors.dart';

/// ─────────────────────────────────────────────
/// 🎨  Context extensions
///
/// Kills the repeated `final isDark = Theme.of(context)...` +
/// `final borderColor = isDark ? ... : ...` boilerplate that used to
/// live at the top of every build method.
///
/// Usage:
///   context.isDark
///   context.text.titleMedium
///   context.c.border
/// ─────────────────────────────────────────────
extension ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  TextTheme get text => Theme.of(this).textTheme;

  ThemeData get theme => Theme.of(this);

  /// Resolved, brightness-aware palette.
  AppPalette get c => AppPalette(isDark);
}

/// Brightness-aware resolver over [AppColors].
/// Ask for a role (`surface`, `border`, `textSecondary`, …) and get the
/// correct light/dark value without branching at the call site.
class AppPalette {
  const AppPalette(this.isDark);

  final bool isDark;

  // Backgrounds
  Color get background =>
      isDark ? AppColors.backgroundDark : AppColors.background;
  Color get surface => isDark ? AppColors.surfaceDark : AppColors.surface;
  Color get surfaceVariant =>
      isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;

  // Borders
  Color get border => isDark ? AppColors.borderDark : AppColors.border;

  // Text
  Color get textPrimary =>
      isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
  Color get textSecondary =>
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
  Color get textTertiary =>
      isDark ? AppColors.textSecondaryDark : AppColors.textTertiary;

  // Brand (constant across modes)
  Color get primary => AppColors.primary;
  Color get primaryLight => AppColors.primaryLight;
  Color get onPrimary => AppColors.onPrimary;

  /// Soft tinted brand surface that reads well in both modes.
  Color get primarySurface =>
      isDark ? const Color(0xFF2E3B31) : AppColors.primaryMuted;

  // Semantic
  Color get success => AppColors.success;
  Color get successSurface =>
      isDark ? const Color(0xFF26362C) : AppColors.successMuted;
  Color get error => AppColors.error;
  Color get errorSurface =>
      isDark ? const Color(0xFF3A2727) : AppColors.errorMuted;
  Color get warning => AppColors.warning;
  Color get warningSurface =>
      isDark ? const Color(0xFF3A3222) : AppColors.warningMuted;

  // Elevation
  Color get shadow => isDark ? const Color(0x33000000) : AppColors.shadow;
  Color get overlay => AppColors.overlay;
}
