import 'package:flutter/material.dart';

/// Centralized color palette. Never hardcode hex colors in widgets —
/// reference these so theming stays consistent app-wide.
///
/// "Bold Editorial" design system (see design canvas
/// https://claude.ai/code/artifact/a56c6c72-f234-4e2c-bb0e-b03f4d3581b2 and
/// the accompanying AlbMap_Design_Spec_Bold_Editorial.md handed off by the
/// client) — a dark, high-contrast look with exactly two accents (red for
/// actions, gold for ratings only) rather than the previous light theme's
/// broader palette. Every existing token name below is kept (nothing
/// renamed) even where the new design collapses several old distinct
/// colors onto the same new value — this is what lets every screen in the
/// app pick up the new look automatically just by these values changing,
/// with zero call-site edits required across the ~30+ files that
/// reference AppColors.* directly.
class AppColors {
  AppColors._();

  // ---- Accent red (the spec's "Accent red" / "Accent red pressed") ----
  static const Color primary = Color(0xFFD73337);
  static const Color primaryLight = Color(0xFFF14D4C); // pressed/hover state
  static const Color primaryDark = Color(0xFFAA2226);

  // The old design's second accent (orange "secondary") has no equivalent
  // in Bold Editorial — the spec is explicit that red and gold are the
  // *only* two accents used anywhere. Anything still reading
  // AppColors.secondary gets the same red rather than a leftover clashing
  // orange; anywhere gold is what's actually wanted (ratings), use
  // AppColors.gold directly instead of secondary.
  static const Color secondary = Color(0xFFD73337);
  static const Color secondaryLight = Color(0xFFF14D4C);

  // ---- Backgrounds & surfaces ----
  static const Color background = Color(0xFF130807);
  static const Color surface = Color(0xFF1E1311);
  // The spec's "Surface (lighter)" — secondary surface, e.g. a filled
  // category chip on the map.
  static const Color surfaceLight = Color(0xFF231715);
  static const Color surfaceDark = Color(0xFF0D0504);
  static const Color backgroundDark = Color(0xFF0D0504);

  // Dedicated input fill — same as `surface` in this design (inputs are
  // just surface-colored boxes with a border, not a visually distinct
  // fill), kept as its own token since ~15 files already reference it by
  // this name.
  static const Color inputFill = Color(0xFF1E1311);

  // ---- Text ----
  static const Color textPrimary = Color(0xFFF5ECEA);
  static const Color textSecondary = Color(0xFF9B8B88); // spec's "Text dim"
  static const Color textOnPrimary = Color(0xFFF5ECEA);

  // ---- Status colors ----
  // The old palette had four distinct semantic hues (green/amber/red/
  // blue). Bold Editorial doesn't define its own success/warning/info —
  // rather than inventing off-spec colors, success and info reuse the
  // dim text tone (a muted, non-alarming neutral) and warning maps to
  // gold (reads as "attention" without adding a third accent); error
  // maps to the one accent red the spec actually defines.
  static const Color success = Color(0xFF9B8B88);
  static const Color warning = Color(0xFFDDB049);
  static const Color error = Color(0xFFD73337);
  static const Color info = Color(0xFF9B8B88);

  static const Color pending = Color(0xFFDDB049);
  static const Color approved = Color(0xFF9B8B88);
  static const Color rejected = Color(0xFFD73337);

  static const Color divider = Color(0xFF3C2F2D); // spec's "Border"
  static const Color border = Color(0xFF3C2F2D);
  static const Color borderStrong = Color(0xFF524441);

  // Ratings-only accent — do not use anywhere else per spec.
  static const Color gold = Color(0xFFDDB049);

  // Shimmer placeholders need to read as "loading" against the new dark
  // surfaces — the old light-gray pair was invisible-to-inverted against
  // a dark background.
  static const Color shimmerBase = Color(0xFF231715);
  static const Color shimmerHighlight = Color(0xFF3C2F2D);
}
