import 'package:flutter/material.dart';

/// One complete set of colours for a single appearance (dark or light).
///
/// The app ships two palettes. [AppPalette.current] is switched in `App`
/// before the widget tree builds, and every `AppColors.xxx` getter reads from
/// it, so a colour written as `AppColors.fg` follows the selected mode.
class AppPalette {
  final bool isDark;

  // ── Semantic tokens (use these in new code) ─────────────────────────────────
  final Color page; // scaffold / page background
  final Color tabPage; // background of the main tab pages (Home, Treatments, …)
  final Color header; // flow header + app bars
  final Color card; // cards, sheets, inputs sitting on [page]
  final Color cardSelected; // selected card / chip fill
  final Color fg; // primary text + icons on [page]
  final Color fgMuted; // secondary text
  final Color fgFaint; // hints, disabled
  final Color btnFill; // primary button fill
  final Color btnText; // text/icon on [btnFill]
  final Color glassFill; // translucent fill for pills / icon buttons
  final Color glassBorder;
  final Color navBg;
  final Color navActive;
  final Color navInactive;
  final Color shadow;
  final Color success;
  final Color danger;

  // ── Legacy "cream" names (older pages) ─────────────────────────────────────
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color secondary;
  final Color gold;
  final Color goldLight;
  final Color goldDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color cardOverlay;

  // ── Legacy "dark olive" names (flow design) ────────────────────────────────
  final Color darkOlive;
  final Color navBarDark;
  final Color darkOliveLight;
  final Color cream;
  final Color textOnDark;
  final Color textOnDarkMuted;

  const AppPalette({
    required this.isDark,
    required this.page,
    required this.tabPage,
    required this.header,
    required this.card,
    required this.cardSelected,
    required this.fg,
    required this.fgMuted,
    required this.fgFaint,
    required this.btnFill,
    required this.btnText,
    required this.glassFill,
    required this.glassBorder,
    required this.navBg,
    required this.navActive,
    required this.navInactive,
    required this.shadow,
    required this.success,
    required this.danger,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondary,
    required this.gold,
    required this.goldLight,
    required this.goldDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.cardOverlay,
    required this.darkOlive,
    required this.navBarDark,
    required this.darkOliveLight,
    required this.cream,
    required this.textOnDark,
    required this.textOnDarkMuted,
  });

  /// Default appearance: the dark-olive "luxury spa" look.
  static AppPalette get dark => AppPalette(
    isDark: true,
    page: Color(0xFF434930),
    tabPage: Color(0xFF4E523B),
    header: Color(0xFF313129),
    card: Color(0xFF4E523B),
    cardSelected: Color(0xFF5B6240),
    fg: Color(0xFFFFFFFF),
    fgMuted: Color(0xB3FAF7F2),
    fgFaint: Color(0x8CFFFFFF),
    btnFill: Color(0xFFFFFFFF),
    btnText: Color(0xFF4E523B),
    glassFill: Color(0x1AFFFFFF),
    glassBorder: Color(0x26FFFFFF),
    navBg: Color(0xFF313129),
    navActive: Color(0xFFFFFFFF),
    navInactive: Color(0xFFB2B2B2),
    shadow: Color(0x33000000),
    success: Color(0xFF74D38E),
    danger: Color(0xFFFF7B6E),
    // legacy cream names, remapped for dark
    background: Color(0xFF434930),
    surface: Color(0xFF4E523B),
    surfaceVariant: Color(0xFF5A5F45),
    primary: Color(0xFFF5F0E8),
    primaryLight: Color(0xFF5B6240),
    primaryDark: Color(0xFFE0E4D4),
    secondary: Color(0xFF313129),
    gold: Color(0xFFC9A96E),
    goldLight: Color(0xFF4F4A35),
    goldDark: Color(0xFFE0C48A),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xB3FAF7F2),
    textMuted: Color(0x8CFFFFFF),
    border: Color(0x1FFFFFFF),
    cardOverlay: Color(0xCC313129),
    // legacy dark-olive names (original values)
    darkOlive: Color(0xFF434930),
    navBarDark: Color(0xFF313129),
    darkOliveLight: Color(0xFF4E523B),
    cream: Color(0xFFFAF7F2),
    textOnDark: Color(0xFFF5F0E8),
    textOnDarkMuted: Color(0xB3FAF7F2),
  );

  /// Light appearance: warm cream pages, white cards, olive accents.
  static AppPalette get light => AppPalette(
    isDark: false,
    page: Color(0xFFFAF7F2),
    tabPage: Color(0xFFFAF7F2),
    header: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    cardSelected: Color(0xFFE6EAD8),
    fg: Color(0xFF2C2C2A),
    fgMuted: Color(0xFF6B6B68),
    fgFaint: Color(0xFF9A9A96),
    btnFill: Color(0xFF4E523B),
    btnText: Color(0xFFFFFFFF),
    glassFill: Color(0x144E523B),
    glassBorder: Color(0x294E523B),
    navBg: Color(0xFFFFFFFF),
    navActive: Color(0xFF4E523B),
    navInactive: Color(0xFF9A9A96),
    shadow: Color(0x1A000000),
    success: Color(0xFF2E9E57),
    danger: Color(0xFFD64545),
    // legacy cream names (original values)
    background: Color(0xFFFAF7F2),
    surface: Color(0xFFF5F0E8),
    surfaceVariant: Color(0xFFEDE6D8),
    primary: Color(0xFF4E523B),
    primaryLight: Color(0xFFE0E4D4),
    primaryDark: Color(0xFF3A3D2C),
    secondary: Color(0xFF313129),
    gold: Color(0xFFC9A96E),
    goldLight: Color(0xFFF2E4CC),
    goldDark: Color(0xFFA07840),
    textPrimary: Color(0xFF2C2C2A),
    textSecondary: Color(0xFF6B6B68),
    textMuted: Color(0xFF9A9A96),
    border: Color(0xFFEBE4D9),
    cardOverlay: Color(0xCC313129),
    // legacy dark-olive names, remapped for light
    darkOlive: Color(0xFFFAF7F2),
    navBarDark: Color(0xFFFFFFFF),
    darkOliveLight: Color(0xFF4E523B),
    cream: Color(0xFF4E523B),
    textOnDark: Color(0xFF2C2C2A),
    textOnDarkMuted: Color(0xB32C2C2A),
  );

  /// Set by `App` (from the saved theme mode) before the tree builds.
  static AppPalette current = dark;

  static AppPalette of(Brightness b) => b == Brightness.dark ? dark : light;
}

/// Mode-aware colours. Every member is a getter, so none of them can be used
/// in a `const` expression — write `Container(color: AppColors.card)`, not
/// `const Container(color: AppColors.card)`.
abstract final class AppColors {
  static bool get isDark => AppPalette.current.isDark;

  // ── Semantic tokens ─────────────────────────────────────────────────────────
  static Color get page => AppPalette.current.page;
  static Color get tabPage => AppPalette.current.tabPage;
  static Color get header => AppPalette.current.header;
  static Color get card => AppPalette.current.card;
  static Color get cardSelected => AppPalette.current.cardSelected;
  static Color get fg => AppPalette.current.fg;
  static Color get fgMuted => AppPalette.current.fgMuted;
  static Color get fgFaint => AppPalette.current.fgFaint;
  static Color get btnFill => AppPalette.current.btnFill;
  static Color get btnText => AppPalette.current.btnText;
  static Color get glassFill => AppPalette.current.glassFill;
  static Color get glassBorder => AppPalette.current.glassBorder;
  static Color get navBg => AppPalette.current.navBg;
  static Color get navActive => AppPalette.current.navActive;
  static Color get navInactive => AppPalette.current.navInactive;
  static Color get shadow => AppPalette.current.shadow;
  static Color get success => AppPalette.current.success;
  static Color get danger => AppPalette.current.danger;

  /// The foreground colour at [alpha] (0–1): hairlines, tinted fills, dividers.
  /// White in dark mode, charcoal in light mode.
  static Color tint(double alpha) => fg.withValues(alpha: alpha);

  // ── Legacy cream names ──────────────────────────────────────────────────────
  static Color get background => AppPalette.current.background;
  static Color get surface => AppPalette.current.surface;
  static Color get surfaceVariant => AppPalette.current.surfaceVariant;
  static Color get primary => AppPalette.current.primary;
  static Color get primaryLight => AppPalette.current.primaryLight;
  static Color get primaryDark => AppPalette.current.primaryDark;
  static Color get secondary => AppPalette.current.secondary;
  static Color get gold => AppPalette.current.gold;
  static Color get goldLight => AppPalette.current.goldLight;
  static Color get goldDark => AppPalette.current.goldDark;
  static Color get textPrimary => AppPalette.current.textPrimary;
  static Color get textSecondary => AppPalette.current.textSecondary;
  static Color get textMuted => AppPalette.current.textMuted;
  static Color get border => AppPalette.current.border;
  static Color get cardOverlay => AppPalette.current.cardOverlay;

  // ── Legacy dark-olive names ─────────────────────────────────────────────────
  static Color get darkOlive => AppPalette.current.darkOlive;
  static Color get navBarDark => AppPalette.current.navBarDark;
  static Color get darkOliveLight => AppPalette.current.darkOliveLight;
  static Color get cream => AppPalette.current.cream;
  static Color get textOnDark => AppPalette.current.textOnDark;
  static Color get textOnDarkMuted => AppPalette.current.textOnDarkMuted;
}
