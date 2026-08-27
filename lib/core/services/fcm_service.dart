import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../di/service_locator.dart';
import '../router/app_router.dart';
import '../utils/app_logger.dart';
import 'fcm_token_repository.dart';

/// Same SharedPreferences key SettingsController persists
/// "Enable notifications" under (see settings_providers.dart) — read
/// directly here rather than through Riverpod since FcmService is a
/// plain singleton with no `ref` of its own (same reasoning as the
/// GoRouter bridge below).
const String _kNotificationsEnabledPrefKey = 'notif_enabled';

/// Every device subscribes to this topic — matches the backend's
/// ALL_USERS_TOPIC constant (see albmap-backend/src/modules/notifications/fcm.js).
/// An approved business broadcast is sent to exactly this topic, which is
/// what makes it reach every registered device.
const String kAllUsersTopic = 'all_users';

/// One channel for every push notification this app shows locally while
/// foregrounded — a single general-purpose channel is fine here since
/// there's only ever one "kind" of push today (business offers/status),
/// not e.g. separate message/reminder/promo channels that would need
/// their own user-configurable importance levels.
const String _kAndroidChannelId = 'albmap_default';
const String _kAndroidChannelName = 'Notifications';
const String _kAndroidChannelDescription = 'Business offers and updates from AlbMap.';

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
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

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

      await _initLocalNotifications();

      // iOS only: FirebaseMessaging.instance.subscribeToTopic()/getToken()
      // throw [firebase_messaging/apns-token-not-set] if called before iOS
      // has actually handed APNs' device token to Firebase — which can
      // still be in flight for a moment right after requestPermission()
      // returns, especially on a fresh install. Android has no APNs
      // token at all, so this is skipped there entirely.
      if (Platform.isIOS) {
        await _waitForApnsToken(messaging);
      }

      // iOS shows a system banner for a foreground push automatically —
      // but only once told to; by default it stays silent while the app
      // is open (the same gap Android has, just solved differently). No
      // local-notification plugin needed on this platform for it: this
      // one call is the whole fix.
      if (Platform.isIOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // Every device gets broadcasts by default — this is what makes an
      // admin-approved notification actually reach everyone, matching the
      // backend sending to this exact topic name on approval — *unless*
      // the user had already turned "Enable notifications" off in
      // Settings on a previous run, in which case respect that from the
      // very first subscribe rather than briefly subscribing them anyway.
      final prefs = await SharedPreferences.getInstance();
      final bool notificationsEnabled = prefs.getBool(_kNotificationsEnabledPrefKey) ?? true;
      if (notificationsEnabled) {
        await messaging.subscribeToTopic(kAllUsersTopic);
      }

      await _registerCurrentToken();
      messaging.onTokenRefresh.listen((_) => _registerCurrentToken());

      // Foreground: previously this was a silent no-op — Android never
      // shows a system notification for a foreground FCM message on its
      // own (unlike background/terminated, where the OS renders it from
      // the payload directly), so a push sent while the app was open
      // simply vanished until the user happened to reopen the
      // Notifications screen later. iOS is handled above via
      // setForegroundNotificationPresentationOptions instead — showing a
      // local notification for it here too would double it up.
      FirebaseMessaging.onMessage.listen((message) {
        if (kDebugMode) debugPrint('FCM foreground message: ${message.notification?.title}');
        if (Platform.isAndroid) _showLocalNotification(message);
      });

      // Background: app was running but not foregrounded, user taps the
      // system notification banner. Previously unhandled entirely — the
      // tap just brought the app to whatever screen it already had open,
      // never the business/event the notification was actually about.
      FirebaseMessaging.onMessageOpenedApp.listen((message) => _handleNotificationTap(message.data));

      // Cold start: app was fully terminated and the tap is what launched
      // it. Same gap as above, plus this is the case that's easy to
      // forget entirely since onMessageOpenedApp alone never fires for it.
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage.data);
      }
    } catch (err, stack) {
      // Anything here — missing platform config, permission denied,
      // network failure — degrades to "push notifications don't arrive,"
      // never to a crash.
      if (kDebugMode) debugPrint('FCM initialization failed (non-fatal): $err\n$stack');
    }
  }

  /// Polls for the APNs token iOS hands Firebase after permission is
  /// granted, up to a few seconds. Any FCM call that touches the backend
  /// token registry (subscribeToTopic, getToken) throws
  /// [firebase_messaging/apns-token-not-set] if made before this exists —
  /// giving up silently after the timeout rather than looping forever
  /// keeps this consistent with the rest of this class's
  /// never-block-the-app-on-a-degraded-push-setup approach: if it's still
  /// not set after 5 seconds, something's actually wrong (missing push
  /// capability/entitlement, simulator, no network) and the outer
  /// try/catch in [initialize] will catch the resulting error same as
  /// today, just a few seconds later.
  Future<void> _waitForApnsToken(FirebaseMessaging messaging) async {
    for (var attempt = 0; attempt < 10; attempt++) {
      final token = await messaging.getAPNSToken();
      if (token != null) return;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Maps a tapped notification to the screen it's actually about.
  ///
  /// Confirmed against the real backend (albmap-backend/src/modules/
  /// notifications/notification.service.js) — the FCM `data` payload is
  /// NOT the same shape as the REST feed's NotificationModel fields (an
  /// earlier version of this guessed `relatedId`, which the backend
  /// never actually sends): `sendToTopic` is called with
  /// `data: { type: 'business_offer', businessId, notificationId }` for
  /// an approved public broadcast, and `data: { type: 'business_status',
  /// businessId }` for a personal approval/rejection notice. There is no
  /// event-related push today (only the two call sites above exist
  /// server-side), so `businessId` is the only id key ever actually
  /// present right now.
  ///
  /// Falls back to the Notifications screen for a type this doesn't
  /// recognize (or a missing businessId) rather than doing nothing,
  /// which is what every notification tap did before this existed.
  ///
  /// Takes the raw data map rather than a RemoteMessage so the same logic
  /// serves both real FCM taps (background/cold-start) and taps on the
  /// local notification [_showLocalNotification] shows for a foreground
  /// Android push — the latter never has a RemoteMessage to hand back,
  /// only whatever payload was attached when the notification was shown.
  void _handleNotificationTap(Map<String, dynamic> data) {
    final router = _router;
    if (router == null) {
      AppLogger.warning('Notification tapped before router was attached; dropping deep link.');
      return;
    }

    try {
      final String type = data['type'] as String? ?? 'general';
      final String? businessId = data['businessId'] as String?;

      switch (type) {
        case 'business_offer':
        case 'business_status':
          if (businessId != null && businessId.isNotEmpty) {
            router.push(AppRoutes.businessDetailsPath(businessId));
            return;
          }
      }
      router.push(AppRoutes.notifications);
    } catch (err, stack) {
      AppLogger.warning('Failed to handle notification tap', err, stack);
    }
  }

  /// Sets up the Android notification channel and the tap callback for
  /// locally-shown notifications. Safe to call even where the plugin
  /// can't fully initialize (e.g. no platform config yet) — same
  /// non-fatal-degradation approach as the rest of this class.
  Future<void> _initLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      // Required on iOS even though this plugin is only ever used to show
      // Android foreground notifications (see the onMessage listener
      // above) — flutter_local_notifications throws "iOS settings must be
      // set when targeting iOS platform" at initialize() if this is
      // omitted, regardless of whether iOS notifications actually go
      // through this plugin. Permission requests are all false here since
      // FirebaseMessaging.requestPermission() above already asked (and
      // asking twice would show a second, redundant system prompt).
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          final String? payload = response.payload;
          if (payload == null || payload.isEmpty) return;
          try {
            final decoded = jsonDecode(payload) as Map<String, dynamic>;
            _handleNotificationTap(decoded);
          } catch (err) {
            if (kDebugMode) debugPrint('Failed to decode local notification payload: $err');
          }
        },
      );

      if (Platform.isAndroid) {
        const channel = AndroidNotificationChannel(
          _kAndroidChannelId,
          _kAndroidChannelName,
          description: _kAndroidChannelDescription,
          importance: Importance.high,
        );
        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }
    } catch (err) {
      if (kDebugMode) debugPrint('Local notifications init failed (non-fatal): $err');
    }
  }

  /// Android-only (see the onMessage listener above) — builds and shows a
  /// real system notification for a foreground FCM message, with the same
  /// `data` payload attached so tapping it deep-links exactly like a
  /// background/cold-start tap would. `message.notification` is null for
  /// a data-only message (the backend always sends `notification: {...}`
  /// alongside `data`, per fcm.js's sendToTopic, but this guards against a
  /// future payload shape that doesn't).
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        _kAndroidChannelId,
        _kAndroidChannelName,
        channelDescription: _kAndroidChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      );
      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(android: androidDetails),
        payload: jsonEncode(message.data),
      );
    } catch (err) {
      if (kDebugMode) debugPrint('Failed to show local notification (non-fatal): $err');
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

  /// Called from SettingsController when the user flips "Enable
  /// notifications" — previously this toggle only wrote a SharedPreferences
  /// value nothing else ever read, so turning it off didn't actually stop
  /// anything. Un/subscribing this device from the broadcast topic here
  /// means an admin-sent broadcast genuinely stops/resumes reaching this
  /// device, live, without needing an app restart.
  Future<void> setBroadcastNotificationsEnabled(bool enabled) async {
    try {
      if (enabled) {
        await FirebaseMessaging.instance.subscribeToTopic(kAllUsersTopic);
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic(kAllUsersTopic);
      }
    } catch (err) {
      // Same non-fatal-degradation philosophy as initialize() — a failed
      // (un)subscribe (offline, missing platform config) shouldn't block
      // the Settings screen from saving the user's choice.
      if (kDebugMode) debugPrint('FCM topic (un)subscribe failed (non-fatal): $err');
    }
  }
}
