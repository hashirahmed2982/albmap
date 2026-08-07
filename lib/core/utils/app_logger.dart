import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Single shared logger for the app.
///
/// Before this existed, error handling was a mix of `debugPrint` (silent
/// in release builds, unstructured) and bare `catch (_) {}` blocks that
/// swallowed failures with no trace at all — meaning a bug reported from
/// production had nothing to go on. Routing every caught exception through
/// here gives us one consistent, leveled, release-safe place to look, and
/// is the natural hook point for wiring in a crash-reporting SDK
/// (Crashlytics/Sentry) later without touching every call site again.
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 5,
      lineLength: 100,
      colors: !kReleaseMode,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    // Keep noisy debug/verbose logs out of release builds; warnings and
    // above still surface so real issues aren't lost.
    level: kReleaseMode ? Level.warning : Level.debug,
  );

  static void debug(String message) => _logger.d(message);

  static void info(String message) => _logger.i(message);

  static void warning(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
