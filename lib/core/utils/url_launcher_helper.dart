import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_logger.dart';
import '../widgets/app_toast.dart';

/// Wraps [launchUrl] with the error handling every call site needs but
/// none of them had: `launchUrl` returns `false` (or throws) when there's
/// no app that can handle the link — no dialer, no WhatsApp, no browser —
/// and every call site in this app used to fire-and-forget it, so tapping
/// "Call" on a device with no phone capability just silently did nothing.
/// This awaits the result, logs failures, and surfaces a toast so the
/// user isn't left wondering whether the tap registered at all.
Future<void> launchUrlSafely(
  BuildContext context,
  Uri uri, {
  LaunchMode mode = LaunchMode.platformDefault,
}) async {
  bool launched = false;
  try {
    launched = await launchUrl(uri, mode: mode);
  } catch (err, stack) {
    AppLogger.warning('launchUrl failed for $uri', err, stack);
  }
  if (!launched && context.mounted) {
    AppToast.error(context, 'common.cannotOpenLink'.tr());
  }
}
