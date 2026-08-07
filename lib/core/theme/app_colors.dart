import 'package:flutter/material.dart';

/// Centralized color palette. Never hardcode hex colors in widgets —
/// reference these so theming/dark-mode stays consistent app-wide.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFE31320); // brand red
  // Real tint/shade of `primary`, not copies of it — these back the
  // header gradients (primaryDark -> primary) and dark-mode surfaces, so
  // they need actual luminance separation from primary to read as a
  // gradient/depth cue instead of a flat block of identical color.
  static const Color primaryLight = Color(0xFFEB5A63);
  static const Color primaryDark = Color(0xFFAA0E18);

  static const Color secondary = Color(0xFFFF8A3D); // warm accent
  static const Color secondaryLight = Color(0xFFFFB07A);

  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1B1F1E);
  static const Color backgroundDark = Color(0xFF121514);

  // Dedicated input fill — deliberately distinct from both `surface`
  // (white cards) and `background` (page background), so a text field
  // never visually disappears into whatever it's sitting on. Previously
  // fields used `surface` as their fill, which is literally invisible
  // against a white card (the most common place a form appears) — you'd
  // only see the field's outline, nothing else.
  static const Color inputFill = Color(0xFFF1F3F5);

  static const Color textPrimary = Color(0xFF1A1D1C);
  static const Color textSecondary = Color(0xFF6B7370);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFE8A83C);
  static const Color error = Color(0xFFD64545);
  static const Color info = Color(0xFF3B82C4);

  static const Color pending = Color(0xFFE8A83C);
  static const Color approved = Color(0xFF2E9E5B);
  static const Color rejected = Color(0xFFD64545);

  static const Color divider = Color(0xFFE3E6E4);
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
}
