import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = const ColorScheme.light(
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryLight,
      onPrimary: Colors.white,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.secondary,
      secondaryContainer: AppColors.primaryLight,
      onSecondary: Colors.white,
      onSecondaryContainer: AppColors.primary,
      tertiary: AppColors.gold,
      tertiaryContainer: AppColors.goldLight,
      onTertiary: Colors.white,
      onTertiaryContainer: AppColors.goldDark,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      error: Color(0xFFD32F2F),
      inverseSurface: AppColors.secondary,
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.primaryLight,
    ).copyWith(
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceVariant,
      surfaceContainerHighest: const Color(0xFFE5DDD0),
      surfaceContainerLow: AppColors.background,
      surfaceContainerLowest: AppColors.background,
      surfaceTint: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle:
            AppTypography.headingSmall.copyWith(color: AppColors.textPrimary),
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.black12,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall.copyWith(color: AppColors.primary);
          }
          return AppTypography.labelSmall.copyWith(color: AppColors.textMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 22);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 22);
        }),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
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
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTypography.buttonLabel,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
        ),
        hintStyle:
            AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        labelStyle:
            AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        labelStyle: AppTypography.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge
            .copyWith(color: AppColors.textPrimary),
        displayMedium: AppTypography.displayLarge
            .copyWith(color: AppColors.textPrimary),
        displaySmall: AppTypography.headingLarge
            .copyWith(color: AppColors.textPrimary),
        headlineLarge: AppTypography.headingLarge
            .copyWith(color: AppColors.textPrimary),
        headlineMedium: AppTypography.headingMedium
            .copyWith(color: AppColors.textPrimary),
        headlineSmall: AppTypography.headingSmall
            .copyWith(color: AppColors.textPrimary),
        titleLarge: AppTypography.headingSmall
            .copyWith(color: AppColors.textPrimary),
        titleMedium: AppTypography.labelLarge
            .copyWith(color: AppColors.textPrimary),
        titleSmall: AppTypography.labelMedium
            .copyWith(color: AppColors.textPrimary),
        bodyLarge:
            AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
        bodyMedium:
            AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        bodySmall: AppTypography.bodySmall
            .copyWith(color: AppColors.textSecondary),
        labelLarge: AppTypography.labelLarge
            .copyWith(color: AppColors.textPrimary),
        labelMedium: AppTypography.labelMedium
            .copyWith(color: AppColors.textSecondary),
        labelSmall:
            AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
      ),
    );
  }

  static ThemeData get dark => light;
}
