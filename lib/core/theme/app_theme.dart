import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTextStyles.h3,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTextStyles.button,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

        // No visible border in the default/enabled state — the fill alone
        // gives the field its shape and separates it from its background.
        // A border only appears once the field means something (focused
        // or in error), which reads as more refined than a border on
        // every field all the time and makes the focus/error states
        // actually mean something when they do appear.
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),

        // Label sits muted until the field is focused, then switches to
        // the brand color — a small but very "premium app" detail that a
        // static gray label on every state misses entirely.
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

        // Icons default to a muted tone and only pick up the brand color
        // while their field is actually focused — consistent, deliberate
        // color use instead of every icon being flatly primary-colored
        // regardless of field state.
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
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      // Without this, Material3's default FAB background is an
      // auto-derived tonal color from the seed palette — not our exact
      // brand red — so an "Add Event"/"Add Business" FAB rendered a
      // washed-out pastel color that visibly clashed with every other
      // (correctly brand-red) button on the same screen.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        extendedTextStyle: AppTextStyles.button,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.h1,
        headlineMedium: AppTextStyles.h2,
        titleLarge: AppTextStyles.h3,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
      ),

      // Everything below fills in surfaces that otherwise silently fall
      // back to stock Material styling — which is exactly what made the
      // app read as "default Flutter" in places even though the buttons/
      // inputs/nav bar above were already themed: a bottom sheet with
      // square corners and no drag handle, a dialog with sharp corners,
      // a plain grey ChoiceChip, a default-indicator TabBar. None of
      // these are exotic — they're just the widgets nothing had gotten
      // to yet.
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        modalElevation: 4,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: AppTextStyles.h3,
        contentTextStyle: AppTextStyles.bodyMedium,
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.inputFill,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.inputFill,
        labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        secondaryLabelStyle: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        showCheckmark: false,
      ),
      // Without this, SegmentedButton falls back to Material3's default
      // selected-segment colors (colorScheme.secondaryContainer/
      // onSecondaryContainer) — and since ColorScheme.light() below only
      // overrides primary/secondary/surface/error, not secondaryContainer,
      // that default is the stock Material baseline (an unrelated pale
      // purple), not derived from the brand palette. Every SegmentedButton
      // in the app (Discover Map's Map/List toggle, the filter sheet's
      // sort-by control, etc.) now shares this one brand-consistent style
      // instead of some being manually styled per-widget and others
      // silently falling back to the mismatched default.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          selectedBackgroundColor: AppColors.primary,
          selectedForegroundColor: Colors.white,
          side: const BorderSide(color: AppColors.divider),
          textStyle: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextStyles.bodyMedium,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.divider,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        side: const BorderSide(color: AppColors.textSecondary, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.textSecondary;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? AppColors.primary : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary.withValues(alpha: 0.4);
          return AppColors.divider;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.textPrimary),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: AppTextStyles.caption.copyWith(color: Colors.white),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 4,
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
