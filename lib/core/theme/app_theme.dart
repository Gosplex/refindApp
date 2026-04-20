import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'text_styles.dart';

abstract final class AppTheme {

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme  => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = isDark
        ? const ColorScheme.dark(
      primary:          AppColors.primary,
      primaryContainer: AppColors.primaryMuted,
      secondary:        AppColors.primaryLight,
      surface:          AppColors.surfaceDark,
      error:            AppColors.error,
      onPrimary:        AppColors.onPrimary,
      onSurface:        AppColors.textPrimaryDark,
      onError:          AppColors.onPrimary,
    )
        : const ColorScheme.light(
      primary:          AppColors.primary,
      primaryContainer: AppColors.primaryMuted,
      secondary:        AppColors.primaryLight,
      surface:          AppColors.surface,
      error:            AppColors.error,
      onPrimary:        AppColors.onPrimary,
      onSurface:        AppColors.textPrimary,
      onError:          AppColors.onPrimary,
    );

    return ThemeData(
      useMaterial3:            true,
      brightness:              brightness,
      colorScheme:             colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      textTheme:               AppTextStyles.textTheme(isDark),

      appBarTheme: AppBarTheme(
        elevation:           0,
        scrolledUnderElevation: 0,
        centerTitle:         true,
        backgroundColor:     isDark ? AppColors.backgroundDark : AppColors.background,
        foregroundColor:     isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        systemOverlayStyle:  isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: isDark
              ? AppColors.surfaceVariantDark
              : AppColors.surfaceVariant,
          elevation:  0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize:   15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color:       isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation:   0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 0.8,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   isDark ? AppColors.surfaceDark : AppColors.surface,
        hintStyle:   TextStyle(
          color:    isDark ? AppColors.textSecondaryDark : AppColors.textTertiary,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 0.8,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 0.8,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 0.8,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:     isDark ? AppColors.surfaceDark : AppColors.surface,
        selectedItemColor:   AppColors.primary,
        unselectedItemColor: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondary,
        elevation:           0,
        type:                BottomNavigationBarType.fixed,
        selectedLabelStyle:  const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        unselectedLabelStyle:const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:      isDark ? AppColors.surfaceDark : AppColors.surface,
        indicatorColor:       AppColors.primaryMuted,
        iconTheme:            WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColors.primary, size: 22);
          }
          return IconThemeData(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary,
            );
          }
          return TextStyle(
            fontSize: 11, fontWeight: FontWeight.w400,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          );
        }),
        elevation: 0,
      ),

      dividerTheme: DividerThemeData(
        color:     isDark ? AppColors.borderDark : AppColors.border,
        thickness: 0.8,
        space:     0,
      ),

      chipTheme: ChipThemeData(
        backgroundColor:  isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
        selectedColor:    AppColors.primaryMuted,
        labelStyle: TextStyle(
          fontSize:   12,
          fontWeight: FontWeight.w400,
          color:      isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 0.8,
          ),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:   isDark ? AppColors.surfaceDark : AppColors.surface,
        modalBackgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        modalBarrierColor: AppColors.overlay,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 0,
        dragHandleColor: isDark ? AppColors.borderDark : AppColors.border,
        dragHandleSize: const Size(36, 4),
        showDragHandle:  true,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation:       0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceVariantDark : AppColors.textPrimary,
        contentTextStyle: TextStyle(
          color:      isDark ? AppColors.textPrimaryDark : AppColors.surface,
          fontSize:   13,
          fontWeight: FontWeight.w400,
        ),
        behavior:      SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? AppColors.onPrimary
            : isDark ? AppColors.textSecondaryDark : AppColors.textTertiary),
        trackColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? AppColors.primary
            : isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        titleTextStyle: TextStyle(
          fontSize:   15,
          fontWeight: FontWeight.w400,
          color:      isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontSize:   13,
          fontWeight: FontWeight.w400,
          color:      isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
      ),
    );
  }
}