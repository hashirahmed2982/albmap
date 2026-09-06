import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../utils/app_logger.dart';

/// Handles the app being opened via an `albmap://` link — currently just
/// the "View my businesses" CTA in the business-approval email (see
/// albmap-backend's email.js), which used to always open the website's
/// /dashboard even when this app was installed. The website's own
/// /app/my-businesses page (see albmap-website) is what actually sends
/// this: it tries `albmap://open/my-businesses` first and only falls
/// back to an app-store install page if nothing handles it within a
/// couple seconds — see that page for the other half of this.
///
/// Mirrors FcmService's attachRouter bridge: a plain singleton with no
/// BuildContext/ref of its own, so goRouterProvider hands it the live
/// GoRouter the same way it does for FcmService.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  GoRouter? _router;
  bool _initialized = false;

  void attachRouter(GoRouter router) {
    _router = router;
  }

  /// Called from AlbMapApp.build(), right after attachRouter runs (both
  /// happen via goRouterProvider) — independent of auth state, unlike
  /// FcmService.initialize() (deferred until login, since it registers a
  /// push token): listening for an incoming link is harmless before
  /// that, and the router's own redirect logic already sends a
  /// signed-out tap through /login first, same as any other
  /// business-only route reached any other way. Idempotent so a widget
  /// rebuild (locale change, etc.) never re-registers the listener or
  /// re-fires getInitialLink()'s cached result a second time.
  ///
  /// Known gap: a cold start via this link, before the user is logged
  /// in, lands them on /login as normal but doesn't replay the pending
  /// "go to My Businesses" afterward — logging in takes them to Discover
  /// Map instead. Only the warm-app case (already running, or already
  /// logged in) is handled below; revisit if that gap turns out to
  /// matter in practice.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handle(initialUri);
    } catch (err) {
      if (kDebugMode) debugPrint('Deep link initial-link check failed (non-fatal): $err');
    }

    _subscription ??= _appLinks.uriLinkStream.listen(
      _handle,
      onError: (Object err) {
        if (kDebugMode) debugPrint('Deep link stream error (non-fatal): $err');
      },
    );
  }

  /// `albmap://open/my-businesses` is the only link this app understands
  /// today — anything else (an unrecognized host/path, a malformed URI)
  /// is ignored rather than routed anywhere, same "degrade, don't crash
  /// or surprise-navigate" philosophy as FcmService's notification-tap
  /// handling.
  void _handle(Uri uri) {
    if (uri.scheme != 'albmap') return;

    final router = _router;
    if (router == null) {
      AppLogger.warning('Deep link received before router was attached; dropping it: $uri');
      return;
    }

    try {
      if (uri.host == 'open' && uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'my-businesses') {
        router.push(AppRoutes.myBusinesses);
      }
    } catch (err, stack) {
      AppLogger.warning('Failed to handle deep link: $uri', err, stack);
    }
  }
}
