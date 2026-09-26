import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  // ── Display — Cormorant Garamond ─────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.cormorantGaramond(
        fontSize: 42, fontWeight: FontWeight.w600, height: 1.1,
      );

  static TextStyle get displayLargeItalic => GoogleFonts.cormorantGaramond(
        fontSize: 42,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        height: 1.1,
      );

  static TextStyle get headingLarge => GoogleFonts.cormorantGaramond(
        fontSize: 26, fontWeight: FontWeight.w600, height: 1.2,
      );

  static TextStyle get headingMedium => GoogleFonts.cormorantGaramond(
        fontSize: 22, fontWeight: FontWeight.w600, height: 1.2,
      );

  static TextStyle get headingSmall => GoogleFonts.cormorantGaramond(
        fontSize: 18, fontWeight: FontWeight.w600, height: 1.3,
      );

  static TextStyle get priceDisplay => GoogleFonts.cormorantGaramond(
        fontSize: 32, fontWeight: FontWeight.w700, height: 1.1,
      );

  // ── Body & UI — DM Sans ──────────────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.dmSans(
        fontSize: 16, fontWeight: FontWeight.w400, height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w400, height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.dmSans(
        fontSize: 13, fontWeight: FontWeight.w400, height: 1.5,
      );

  static TextStyle get labelLarge => GoogleFonts.dmSans(
        fontSize: 13, fontWeight: FontWeight.w600, height: 1.4,
      );

  static TextStyle get labelMedium => GoogleFonts.dmSans(
        fontSize: 12, fontWeight: FontWeight.w500, height: 1.4,
      );

  static TextStyle get labelSmall => GoogleFonts.dmSans(
        fontSize: 11, fontWeight: FontWeight.w500, height: 1.4,
      );

  static TextStyle get overline => GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        height: 1.4,
      );

  static TextStyle get buttonLabel => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        height: 1.0,
      );
}
