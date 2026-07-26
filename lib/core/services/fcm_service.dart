import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../di/service_locator.dart';
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
    } catch (err, stack) {
      // Anything here — missing platform config, permission denied,
      // network failure — degrades to "push notifications don't arrive,"
      // never to a crash.
      if (kDebugMode) debugPrint('FCM initialization failed (non-fatal): $err\n$stack');
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
