import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/fcm_service.dart';
// Cross-feature import, and business_providers.dart imports this file
// right back (to read locationEnabled inside LocationController.refresh)
// — a two-way cycle, but Dart resolves file-level import cycles fine
// (same pattern already used between fcm_service.dart and app_router.dart).
import '../../../map/presentation/providers/business_providers.dart';

/// Language is deliberately NOT stored here — easy_localization (see
/// main.dart) already persists the chosen Locale itself via its own
/// SharedPreferences key. Keeping a second, separate "locale" value in
/// this controller would risk the two falling out of sync (e.g. one gets
/// updated and the other doesn't); the Settings screen reads/writes the
/// language choice directly via `context.locale` / `context.setLocale()`
/// instead.
class SettingsState {
  const SettingsState({
    this.notificationsEnabled = true,
    this.notificationFrequency = NotificationFrequency.always,
    this.locationEnabled = true,
    this.themeMode = ThemeMode.system,
  });

  final bool notificationsEnabled;
  final NotificationFrequency notificationFrequency;
  final bool locationEnabled;
  final ThemeMode themeMode;

  SettingsState copyWith({
    bool? notificationsEnabled,
    NotificationFrequency? notificationFrequency,
    bool? locationEnabled,
    ThemeMode? themeMode,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationFrequency: notificationFrequency ?? this.notificationFrequency,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

/// Persists preferences to SharedPreferences so they survive app restarts.
class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this._ref) : super(const SettingsState()) {
    _load();
  }

  final Ref _ref;

  static const _kNotifEnabled = 'notif_enabled';
  static const _kNotifFreq = 'notif_freq';
  static const _kLocationEnabled = 'location_enabled';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      notificationsEnabled: prefs.getBool(_kNotifEnabled) ?? true,
      notificationFrequency: NotificationFrequency.values.firstWhere(
        (f) => f.name == (prefs.getString(_kNotifFreq) ?? 'always'),
        orElse: () => NotificationFrequency.always,
      ),
      locationEnabled: prefs.getBool(_kLocationEnabled) ?? true,
    );
  }

  /// Previously this only wrote a SharedPreferences value nothing else
  /// ever read — the switch looked functional but didn't actually stop
  /// notifications. Now it live (un)subscribes this device from the
  /// broadcast topic, so turning it off genuinely stops broadcast pushes
  /// from reaching this device (see FcmService.setBroadcastNotificationsEnabled).
  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifEnabled, enabled);
    await FcmService.instance.setBroadcastNotificationsEnabled(enabled);
  }

  Future<void> setNotificationFrequency(NotificationFrequency freq) async {
    state = state.copyWith(notificationFrequency: freq);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNotifFreq, freq.name);
  }

  /// Previously this only wrote a SharedPreferences value LocationController
  /// never read — turning it off didn't stop the app from requesting GPS
  /// fixes. Now LocationController.refresh() checks this state directly,
  /// and turning it off here immediately clears any position already in
  /// use and reloads the business list without it, rather than waiting
  /// for the next screen that happens to call refresh().
  Future<void> setLocationEnabled(bool enabled) async {
    state = state.copyWith(locationEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLocationEnabled, enabled);
    if (!enabled) {
      _ref.read(locationControllerProvider.notifier).clear();
      await _ref.read(businessListControllerProvider.notifier).load();
    }
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) => SettingsController(ref));
