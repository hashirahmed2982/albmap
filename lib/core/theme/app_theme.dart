import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// "Bold Editorial" design system — see
/// AlbMap_Design_Spec_Bold_Editorial.md. Kept as `AppTheme.light` (the
/// name main.dart already wires up via `theme: AppTheme.light` +
/// `themeMode: ThemeMode.light`) even though the actual palette is now
/// dark — renaming it would mean touching main.dart's theme-mode wiring
/// for no functional benefit; "light"/"dark" here are just method labels,
/// not a claim about the resulting background color. `AppTheme.dark`
/// below is unchanged/still a stub, same as before this redesign.
class AppTheme {
  AppTheme._();

  // Sharp corners is *the* defining visual rule of this design system —
  // "No rounded corners on cards, buttons, or inputs (this is the key
  // visual difference vs. the old design)". Every shape below uses this
  // one constant rather than scattering `BorderRadius.zero` everywhere,
  // so the one exception the spec does call out (small circular controls
  // like the map's back/heart/share buttons) stays obviously
  // intentional at each of those call sites instead of looking like a
  // missed spot.
  static const BorderRadius _sharpCorners = BorderRadius.zero;
  static const double _borderWidth = 1.5;

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      // The palette is dark despite this method's "light" name (see class
      // doc) — Brightness.dark here (not .light) is what's actually
      // correct for it, since it drives Material3's own defaults for
      // every widget below that isn't explicitly themed (default splash/
      // highlight colors, disabled-state opacity assumptions, etc.).
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.textOnPrimary,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTextStyles.h3,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: _sharpCorners),
          textStyle: AppTextStyles.button,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.borderStrong, width: _borderWidth),
          shape: RoundedRectangleBorder(borderRadius: _sharpCorners),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.textPrimary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

        // Unlike the old theme (no visible border until focused/error),
        // Bold Editorial's inputs show their border in every state — the
        // mockups' email/password fields on Login are visibly outlined
        // at rest, not just filled.
        border: OutlineInputBorder(
          borderRadius: _sharpCorners,
          borderSide: const BorderSide(color: AppColors.border, width: _borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: _sharpCorners,
          borderSide: const BorderSide(color: AppColors.border, width: _borderWidth),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: _sharpCorners,
          borderSide: const BorderSide(color: AppColors.border, width: _borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _sharpCorners,
          borderSide: const BorderSide(color: AppColors.primary, width: _borderWidth),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: _sharpCorners,
          borderSide: const BorderSide(color: AppColors.error, width: _borderWidth),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: _sharpCorners,
          borderSide: const BorderSide(color: AppColors.error, width: _borderWidth),
        ),

        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.error)) {
            return AppTextStyles.bodySmall.copyWith(color: AppColors.error, fontWeight: FontWeight.w600);
          }
          if (states.contains(WidgetState.focused)) {
            return AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600);
          }
          return AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary);
        }),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.7)),
        helperStyle: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
        errorMaxLines: 2,
        counterStyle: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),

        iconColor: AppColors.textSecondary,
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return AppColors.primary;
          if (states.contains(WidgetState.error)) return AppColors.error;
          return AppColors.textSecondary;
        }),
        suffixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return AppColors.primary;
          if (states.contains(WidgetState.error)) return AppColors.error;
          return AppColors.textSecondary;
        }),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: _sharpCorners,
          side: const BorderSide(color: AppColors.border, width: _borderWidth),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        extendedTextStyle: AppTextStyles.button,
        shape: RoundedRectangleBorder(borderRadius: _sharpCorners),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: _borderWidth),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.h1,
        headlineMedium: AppTextStyles.h2,
        titleLarge: AppTextStyles.h3,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: _sharpCorners,
          side: BorderSide(color: AppColors.border, width: _borderWidth),
        ),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        modalElevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: _sharpCorners,
          side: const BorderSide(color: AppColors.border, width: _borderWidth),
        ),
        titleTextStyle: AppTextStyles.h3,
        contentTextStyle: AppTextStyles.bodyMedium,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.surfaceLight,
        labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        secondaryLabelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textOnPrimary, fontWeight: FontWeight.w600),
        side: const BorderSide(color: AppColors.border, width: _borderWidth),
        shape: RoundedRectangleBorder(borderRadius: _sharpCorners),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        showCheckmark: false,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          selectedBackgroundColor: AppColors.primary,
          selectedForegroundColor: AppColors.textOnPrimary,
          side: const BorderSide(color: AppColors.border, width: _borderWidth),
          textStyle: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: _sharpCorners),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTextStyles.bodyMedium,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.border,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: _sharpCorners),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        side: const BorderSide(color: AppColors.borderStrong, width: _borderWidth),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.textSecondary;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? AppColors.primary : AppColors.textPrimary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary.withValues(alpha: 0.4);
          return AppColors.border;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.textPrimary),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: _sharpCorners,
          border: Border.all(color: AppColors.border, width: _borderWidth),
        ),
        textStyle: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: _sharpCorners),
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: _sharpCorners,
          side: const BorderSide(color: AppColors.border, width: _borderWidth),
        ),
        elevation: 0,
        textStyle: AppTextStyles.bodyMedium,
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        secondary: AppColors.secondaryLight,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
