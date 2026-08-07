import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Consistent chrome for every `showModalBottomSheet` content in the app:
/// a drag handle (the visual cue that a sheet is swipe-dismissible, which
/// nothing had before) and bottom [SafeArea] padding so the sheet's last
/// interactive element never sits flush against the home indicator
/// (iOS) or gesture nav bar (Android) — a real, easy-to-miss gap since
/// `showModalBottomSheet` does not add that inset for you.
///
/// Usage: wrap a sheet's content column in this instead of a bare
/// `Padding`/`SafeArea`, e.g.:
/// ```dart
/// showModalBottomSheet<void>(
///   context: context,
///   isScrollControlled: true,
///   builder: (_) => AppBottomSheet(child: MyFormColumn()),
/// );
/// ```
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 20),
    this.showHandle = true,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: padding.left,
          right: padding.right,
          top: padding.top,
          bottom: padding.bottom + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHandle)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}
