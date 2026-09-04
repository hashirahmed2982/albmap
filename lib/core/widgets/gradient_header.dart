import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Header wrapper used consistently across ~16 screens. Previously a soft
/// gradient + rounded-bottom banner; flattened for the Bold Editorial
/// redesign (see AlbMap_Design_Spec_Bold_Editorial.md) — "No rounded
/// corners on cards, buttons, or inputs (this is the key visual
/// difference vs. the old design)" applies here too, and the Events.png
/// mockup shows the header content sitting directly on the same flat
/// background as the rest of the screen, no distinct banner tint or
/// curve. Kept as its own widget (not just deleted in favor of the
/// content sitting straight in each screen's body) purely so every one
/// of those 16 call sites keeps working unchanged — it just no longer
/// visually differs from `AppColors.background` behind it.
///
/// The background still extends all the way to the physical top of the
/// screen (behind the status bar/notch) — only the *content* inside it is
/// padded clear of the status bar, via MediaQuery rather than SafeArea, so
/// it reaches the very top instead of stopping below the clock/battery
/// icons. Callers should wrap their Scaffold body in
/// `SafeArea(top: false, child: ...)` — not a full SafeArea — since this
/// widget already accounts for the status bar itself.
class GradientHeader extends StatelessWidget {
  const GradientHeader({required this.child, super.key, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final EdgeInsetsGeometry basePadding =
        padding ?? const EdgeInsets.fromLTRB(16, 16, 16, 16);

    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: basePadding.add(EdgeInsets.only(top: statusBarHeight)),
      child: child,
    );
  }
}
