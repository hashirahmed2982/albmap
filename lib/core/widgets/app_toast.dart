import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// One place for every toast/snackbar the app shows.
///
/// Before this existed, each screen built its own bare
/// `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(...)))`
/// — no icon, no color coding, no floating behavior, and inconsistent
/// duration. A user couldn't tell an error from a confirmation at a
/// glance, and some screens forgot to clear a still-showing snackbar
/// before pushing a new one (so messages would queue up and appear
/// seconds late). Routing everything through here fixes both: consistent
/// look, and `hideCurrentSnackBar()` before every show so the newest
/// message is always the one the user sees immediately.
class AppToast {
  AppToast._();

  static void success(BuildContext context, String message) {
    _show(context, message: message, background: AppColors.success, icon: Icons.check_circle_outline);
  }

  static void error(BuildContext context, String message) {
    _show(context, message: message, background: AppColors.error, icon: Icons.error_outline);
  }

  static void info(BuildContext context, String message) {
    _show(context, message: message, background: AppColors.info, icon: Icons.info_outline);
  }

  static void warning(BuildContext context, String message) {
    _show(context, message: message, background: AppColors.warning, icon: Icons.warning_amber_outlined);
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color background,
    required IconData icon,
  }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    // Clear any still-visible snackbar first so messages never queue up
    // behind each other and show stale/delayed.
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: background,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
