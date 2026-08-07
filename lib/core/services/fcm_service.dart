import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../di/service_locator.dart';
import '../router/app_router.dart';
import '../utils/app_logger.dart';
import 'fcm_token_repository.dart';

/// Every device subscribes to this topic — matches the backend's
/// ALL_USERS_TOPIC constant (see albmap-backend/src/modules/notifications/fcm.js).
/// An approved business broadcast is sent to exactly this topic, which is
/// what makes it reach every registered device.
const String kAllUsersTopic = 'all_users';

/// Handles push notification setup: permission request, topic
/// subscription, device token registration with the backend, and
/// foreground/background message handling. Call [initialize] once, after
/// Firebase.initializeApp() and after the user is authenticated (the
/// token-registration call requires a valid access token).
///
/// Deliberately does NOT crash the app if anything here fails — a push
/// notification feature not working is a degraded experience, not a
/// reason to prevent someone from using the rest of the app. Every step
/// is wrapped so a permission denial, a missing platform config, or a
/// network hiccup just logs and moves on.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  bool _initialized = false;
  GoRouter? _router;

  /// Wired from goRouterProvider once the app's GoRouter is built — see
  /// the comment there. FcmService is a plain singleton (reachable from
  /// AuthController, which has no BuildContext of its own to navigate
  /// with), not a Riverpod object, so this is the bridge between the two.
  void attachRouter(GoRouter router) {
    _router = router;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (kDebugMode) {
        debugPrint('FCM permission status: ${settings.authorizationStatus}');
      }

      // Every device gets broadcasts — this is what makes an admin-approved
      // notification actually reach everyone, matching the backend sending
      // to this exact topic name on approval.
      await messaging.subscribeToTopic(kAllUsersTopic);

      await _registerCurrentToken();
      messaging.onTokenRefresh.listen((_) => _registerCurrentToken());

      // Foreground: the OS won't show a system notification banner on its
      // own while the app is open, so this just refreshes the in-app feed
      // — the new notification appears next time the user opens the
      // Notifications screen (or immediately, if they're already on it
      // and it's listening — see notifications_providers.dart).
      FirebaseMessaging.onMessage.listen((message) {
        if (kDebugMode) debugPrint('FCM foreground message: ${message.notification?.title}');
      });

      // Background: app was running but not foregrounded, user taps the
      // system notification banner. Previously unhandled entirely — the
      // tap just brought the app to whatever screen it already had open,
      // never the business/event the notification was actually about.
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Cold start: app was fully terminated and the tap is what launched
      // it. Same gap as above, plus this is the case that's easy to
      // forget entirely since onMessageOpenedApp alone never fires for it.
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (err, stack) {
      // Anything here — missing platform config, permission denied,
      // network failure — degrades to "push notifications don't arrive,"
      // never to a crash.
      if (kDebugMode) debugPrint('FCM initialization failed (non-fatal): $err\n$stack');
    }
  }

  /// Maps a tapped notification to the screen it's actually about.
  /// `type`/`relatedId` mirror NotificationModel.fromJson's field names
  /// (notification_model.dart) — the reasonable assumption, absent a
  /// documented push-payload contract, is that the backend sends the same
  /// shape in the FCM `data` map as it does in the REST feed. Falls back
  /// to the Notifications screen for a type this doesn't recognize (or a
  /// missing relatedId) rather than doing nothing, which is what every
  /// notification tap did before this existed.
  void _handleNotificationTap(RemoteMessage message) {
    final router = _router;
    if (router == null) {
      AppLogger.warning('Notification tapped before router was attached; dropping deep link.');
      return;
    }

    try {
      final String type = message.data['type'] as String? ?? 'general';
      final String? relatedId = message.data['relatedId'] as String?;

      switch (type) {
        case 'business_offer':
        case 'business_approved':
        case 'business_rejected':
          if (relatedId != null && relatedId.isNotEmpty) {
            router.push(AppRoutes.businessDetailsPath(relatedId));
            return;
          }
        case 'event_reminder':
          if (relatedId != null && relatedId.isNotEmpty) {
            router.push(AppRoutes.eventDetailsPath(relatedId));
            return;
          }
      }
      router.push(AppRoutes.notifications);
    } catch (err, stack) {
      AppLogger.warning('Failed to handle notification tap', err, stack);
    }
  }

  Future<void> _registerCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await sl<FcmTokenRepository>().registerToken(token);
    } catch (err) {
      if (kDebugMode) debugPrint('FCM token registration failed (non-fatal): $err');
    }
  }
}
