import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(AppPalette.light);

  /// Default appearance: dark olive.
  static ThemeData get dark => _build(AppPalette.dark);

  static ThemeData _build(AppPalette p) {
    final isDark = p.isDark;
    // On the palette's `primary` fill: white on olive (light), olive on cream
    // (dark).
    final onPrimary = isDark ? p.darkOliveLight : Colors.white;
    final errorColor = isDark
        ? const Color(0xFFFFB4A8)
        : const Color(0xFFD32F2F);
    final colorScheme =
        (isDark ? ColorScheme.dark() : ColorScheme.light())
            .copyWith(
              primary: p.primary,
              primaryContainer: p.primaryLight,
              onPrimary: onPrimary,
              onPrimaryContainer: isDark ? p.textPrimary : p.primary,
              secondary: p.secondary,
              secondaryContainer: p.primaryLight,
              onSecondary: Colors.white,
              onSecondaryContainer: isDark ? p.textPrimary : p.primary,
              tertiary: p.gold,
              tertiaryContainer: p.goldLight,
              onTertiary: Colors.white,
              onTertiaryContainer: p.goldDark,
              surface: p.background,
              onSurface: p.textPrimary,
              onSurfaceVariant: p.textSecondary,
              outline: p.border,
              outlineVariant: p.border,
              error: errorColor,
              inverseSurface: isDark ? p.cream : p.secondary,
              onInverseSurface: isDark ? p.secondary : Colors.white,
              inversePrimary: p.primaryLight,
              surfaceContainer: p.surface,
              surfaceContainerHigh: p.surfaceVariant,
              surfaceContainerHighest: isDark
                  ? const Color(0xFF666B50)
                  : const Color(0xFFE5DDD0),
              surfaceContainerLow: p.background,
              surfaceContainerLowest: p.background,
              surfaceTint: Colors.transparent,
            );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.background,
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: p.textPrimary),
        titleTextStyle: AppTypography.headingSmall.copyWith(
          color: p.textPrimary,
        ),
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.primaryLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.black12,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall.copyWith(color: p.primary);
          }
          return AppTypography.labelSmall.copyWith(color: p.textMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: p.primary, size: 22);
          }
          return IconThemeData(color: p.textMuted, size: 22);
        }),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: onPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTypography.buttonLabel,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          side: BorderSide(color: p.primary),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTypography.buttonLabel,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor, width: 1.5),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: p.textMuted,
        ),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: p.textSecondary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: p.border,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: isDark ? p.cardSelected : p.primary,
        side: BorderSide(color: p.border),
        labelStyle: AppTypography.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: p.textPrimary,
        ),
        displayMedium: AppTypography.displayLarge.copyWith(
          color: p.textPrimary,
        ),
        displaySmall: AppTypography.headingLarge.copyWith(
          color: p.textPrimary,
        ),
        headlineLarge: AppTypography.headingLarge.copyWith(
          color: p.textPrimary,
        ),
        headlineMedium: AppTypography.headingMedium.copyWith(
          color: p.textPrimary,
        ),
        headlineSmall: AppTypography.headingSmall.copyWith(
          color: p.textPrimary,
        ),
        titleLarge: AppTypography.headingSmall.copyWith(
          color: p.textPrimary,
        ),
        titleMedium: AppTypography.labelLarge.copyWith(
          color: p.textPrimary,
        ),
        titleSmall: AppTypography.labelMedium.copyWith(
          color: p.textPrimary,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: p.textPrimary,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: p.textPrimary,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: p.textSecondary,
        ),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: p.textPrimary,
        ),
        labelMedium: AppTypography.labelMedium.copyWith(
          color: p.textSecondary,
        ),
        labelSmall: AppTypography.labelSmall.copyWith(
          color: p.textMuted,
        ),
      ),
    );
  }
}
