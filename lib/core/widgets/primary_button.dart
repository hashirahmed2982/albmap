import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.icon,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final Widget child = isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[Icon(icon, size: 20), const SizedBox(width: 8)],
              // Flexible + ellipsis: every button in the app uses this
              // shared widget, and a translated label (German in
              // particular tends to run noticeably longer than English)
              // could otherwise overflow a width-constrained button
              // (e.g. the "Add your first business" button, which is
              // wrapped in a fixed-width SizedBox) instead of just
              // truncating gracefully.
              Flexible(
                child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
              ),
            ],
          );

    if (outlined) {
      return OutlinedButton(onPressed: isLoading ? null : onPressed, child: child);
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
      ),
      child: child,
    );
  }
}
