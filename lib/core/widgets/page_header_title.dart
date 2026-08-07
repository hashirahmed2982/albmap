import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Standard title row for [GradientHeader] content — a solid circular
/// back button (not a bare icon floating directly on the soft gradient,
/// which reads as weak/undefined against it) plus, where [icon] is given,
/// a colored icon badge next to the title so each section has a bit of
/// visual identity instead of just plain black text sitting in empty
/// gradient space. Used by every pushed/tab screen except Discover Map
/// (no static title — its header is a functional search/filter toolbar)
/// and Settings/Profile (already have their own established header design).
class PageHeaderTitle extends StatelessWidget {
  const PageHeaderTitle({
    required this.title,
    super.key,
    this.subtitle,
    this.icon,
    this.accent = AppColors.primary,
    this.showBackButton = true,
    this.backIcon = Icons.arrow_back,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color accent;
  final bool showBackButton;

  /// Icon for the back button — defaults to a back arrow, but a screen
  /// that's a terminal/success step (e.g. "business submitted") rather
  /// than a mid-flow page should pass [Icons.close_rounded] instead,
  /// since "back" isn't semantically what dismissing it does.
  final IconData backIcon;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showBackButton) ...[
          _CircularIconButton(
            icon: backIcon,
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
        ],
        if (icon != null) ...[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppTextStyles.h1, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _CircularIconButton extends StatelessWidget {
  const _CircularIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
