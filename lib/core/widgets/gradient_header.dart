import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Soft gradient + rounded-bottom header used consistently across screens
/// (Discover, Events, Favorites, Profile) so the app reads as one designed
/// product rather than a stack of default Material scaffolds.
class GradientHeader extends StatelessWidget {
  const GradientHeader({required this.child, super.key, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.background],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: padding ?? const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: child,
    );
  }
}
