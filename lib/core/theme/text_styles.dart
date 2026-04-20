import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

abstract final class AppTextStyles {

  static TextStyle _f({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double letterSpacing = 0.0,
    double height = 1.4,
  }) =>
      GoogleFonts.josefinSans(
        fontSize:      fontSize,
        fontWeight:    fontWeight,
        color:         color,
        letterSpacing: letterSpacing,
        height:        height,
      );

  static TextTheme textTheme(bool isDark) {
    final primary   = isDark ? AppColors.textPrimaryDark   : AppColors.textPrimary;
    final secondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final tertiary  = isDark ? AppColors.textSecondaryDark : AppColors.textTertiary;

    return TextTheme(

      headlineLarge: _f(
        fontSize:      30,
        fontWeight:    FontWeight.w600,
        color:         primary,
        letterSpacing: -0.5,
        height:        1.2,
      ),

      headlineMedium: _f(
        fontSize:      26,
        fontWeight:    FontWeight.w600,
        color:         primary,
        letterSpacing: -0.3,
        height:        1.25,
      ),

      headlineSmall: _f(
        fontSize:      22,
        fontWeight:    FontWeight.w500,
        color:         primary,
        letterSpacing: -0.2,
        height:        1.3,
      ),

      titleLarge: _f(
        fontSize:      18,
        fontWeight:    FontWeight.w500,
        color:         primary,
        letterSpacing: 0.0,
        height:        1.35,
      ),

      titleMedium: _f(
        fontSize:      16,
        fontWeight:    FontWeight.w500,
        color:         primary,
        letterSpacing: 0.0,
        height:        1.4,
      ),

      titleSmall: _f(
        fontSize:      14,
        fontWeight:    FontWeight.w500,
        color:         primary,
        letterSpacing: 0.1,
        height:        1.4,
      ),

      bodyLarge: _f(
        fontSize:      15,
        fontWeight:    FontWeight.w400,
        color:         primary,
        height:        1.6,
      ),

      bodyMedium: _f(
        fontSize:      14,
        fontWeight:    FontWeight.w400,
        color:         secondary,
        height:        1.6,
      ),

      bodySmall: _f(
        fontSize:      12,
        fontWeight:    FontWeight.w400,
        color:         tertiary,
        height:        1.5,
      ),

      labelLarge: _f(
        fontSize:      14,
        fontWeight:    FontWeight.w500,
        color:         AppColors.onPrimary,
        letterSpacing: 0.1,
      ),

      labelMedium: _f(
        fontSize:      12,
        fontWeight:    FontWeight.w500,
        color:         secondary,
        letterSpacing: 0.2,
      ),

      labelSmall: _f(
        fontSize:      11,
        fontWeight:    FontWeight.w400,
        color:         tertiary,
        letterSpacing: 0.3,
        height:        1.4,
      ),
    );
  }
}