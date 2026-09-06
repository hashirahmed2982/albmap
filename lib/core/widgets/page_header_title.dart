import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Standard title row for [GradientHeader] content — a bordered circular
/// back button (not a bare icon floating directly on the flat black
/// header, which reads as weak/undefined against it) plus, where [icon]
/// is given, a sharp-square icon badge next to the title so each section
/// has a bit of visual identity instead of just plain text sitting in
/// empty header space. Used by every pushed/tab screen except Discover
/// Map (no static title — its header is a functional search/filter
/// toolbar) and Settings/Profile (already have their own established
/// header design).
class PageHeaderTitle extends StatelessWidget {
  const PageHeaderTitle({
    required this.title,
    super.key,
    this.subtitle,
    this.icon,
    this.accent = AppColors.primary,
    this.showBackButton = true,
    this.backIcon = Icons.arrow_back,
    this.iconBadgeSize = 44,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color accent;
  final bool showBackButton;

  /// Side length of the [icon] badge box (the glyph itself scales with
  /// it, at roughly half). Defaults to 44, but a screen whose subtitle is
  /// long/variable-length content rather than a short fixed string (e.g.
  /// a business's own name on My Businesses/Business Dashboard/Edit
  /// Business) should pass a smaller value — otherwise the badge + back
  /// button can eat enough width that the title/subtitle get pushed into
  /// an ellipsis even for a moderately long business name.
  final double iconBadgeSize;

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
            width: iconBadgeSize,
            height: iconBadgeSize,
            color: accent.withValues(alpha: 0.16),
            child: Icon(icon, color: accent, size: iconBadgeSize * 0.5),
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
    // Circular is the spec's one deliberate exception to "sharp corners
    // everywhere" (small controls like this back button) — but the
    // elevation/drop-shadow it used to have is not; a border gives it the
    // same depth cue as every other bordered surface in this design
    // instead of a one-off shadow.
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, size: 19, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
