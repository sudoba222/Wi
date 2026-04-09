import 'package:flutter/material.dart';

class AppColors {
  // ── Core brand colours ────────────────────────────────────────────────────
  static const Color darkPurple  = Color(0xFF210B2C);
  static const Color wisteria    = Color(0xFFBC96E6);
  static const Color sunglow     = Color(0xFFFFD166);  // amber accent
  static const Color white       = Color(0xFFFFFFFF);
  static const Color splashPurple = Color(0xFF7603B8);

  // ── Light theme ───────────────────────────────────────────────────────────
  static const Color background  = Color(0xFFF6F2FF);  // soft lavender
  static const Color mutedText   = Color(0xFF9B89A9);

  // ── Dark theme surfaces ───────────────────────────────────────────────────
  static const Color darkBg      = Color(0xFF1A0A22);  // deep purple-black
  static const Color darkCard    = Color(0xFF2D1040);  // elevated card
  static const Color darkDrawer  = Color(0xFF1E0B2C);  // drawer background

  /// Returns the correct background colour for the current theme.
  static Color bgFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBg : background;

  /// Returns the correct card colour for the current theme.
  static Color cardFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCard : white;

  /// Returns the correct text colour for the current theme.
  static Color textFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? white : darkPurple;
}
