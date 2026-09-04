import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Bold Editorial design system's type scale — see
/// AlbMap_Design_Spec_Bold_Editorial.md: "Display / headlines: Instrument
/// Serif ... Business names, screen titles" and "Body / UI: Work Sans ...
/// All body text, labels, buttons." Only [h1] uses the serif — it's what
/// backs every screen's title via PageHeaderTitle plus the business name
/// on Business Details, matching the spec's two named "headline" use
/// cases. h2/h3 and everything smaller stay Work Sans, same as the spec's
/// body/UI category.
///
/// These used to be `static const TextStyle` — google_fonts' functions
/// aren't const (they resolve/cache the font at call time), so every
/// style here is now a getter instead. The one call site in the app that
/// did `const Text(..., style: AppTextStyles.h1)` needed its `const`
/// dropped accordingly (see about_us_screen.dart).
class AppTextStyles {
  AppTextStyles._();

  // Still referenced directly by AppTheme's top-level `fontFamily:` (the
  // Material fallback used before a specific TextStyle is resolved) and
  // by a couple of screens building a raw TextStyle — pointed at Work
  // Sans (the body/UI face); screens that need the display face use
  // [displayFontFamily] or [h1] directly instead.
  static String get fontFamily => GoogleFonts.workSans().fontFamily!;
  static String get displayFontFamily => GoogleFonts.instrumentSerif().fontFamily!;

  static TextStyle get h1 => GoogleFonts.instrumentSerif(
        fontSize: 30,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.15,
      );

  static TextStyle get h2 => GoogleFonts.workSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  static TextStyle get h3 => GoogleFonts.workSans(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.workSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.workSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.workSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get button => GoogleFonts.workSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnPrimary,
      );

  static TextStyle get caption => GoogleFonts.workSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );
}
