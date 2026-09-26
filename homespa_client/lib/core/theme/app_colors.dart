import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Backgrounds ─────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFFAF7F2);
  static const Color surface = Color(0xFFF5F0E8);
  static const Color surfaceVariant = Color(0xFFEDE6D8);

  // ── Primary (olive dark) ─────────────────────────────────────────────────────
  static const Color primary = Color(0xFF4E523B);
  static const Color primaryLight = Color(0xFFE0E4D4);
  static const Color primaryDark = Color(0xFF3A3D2C);

  // ── Secondary (charcoal dark) ────────────────────────────────────────────────
  static const Color secondary = Color(0xFF313129);

  // ── Accent (gold) ────────────────────────────────────────────────────────────
  static const Color gold = Color(0xFFC9A96E);
  static const Color goldLight = Color(0xFFF2E4CC);
  static const Color goldDark = Color(0xFFA07840);

  // ── Text ─────────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF2C2C2A);
  static const Color textSecondary = Color(0xFF6B6B68);
  static const Color textMuted = Color(0xFF9A9A96);

  // ── Border ───────────────────────────────────────────────────────────────────
  static const Color border = Color(0xFFEBE4D9);

  // ── Overlay for image cards (keeps text readable) ─────────────────────────────
  static const Color cardOverlay = Color(0xCC313129);
}
