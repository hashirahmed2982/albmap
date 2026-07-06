import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Soft gradient + rounded-bottom header used consistently across screens.
/// The gradient background extends all the way to the physical top of the
/// screen (behind the status bar/notch) — only the *content* inside it is
/// padded clear of the status bar, via MediaQuery rather than SafeArea, so
/// the color reaches the very top instead of stopping below the clock/
/// battery icons. Callers should wrap their Scaffold body in
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.background],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: basePadding.add(EdgeInsets.only(top: statusBarHeight)),
      child: child,
    );
  }
}
