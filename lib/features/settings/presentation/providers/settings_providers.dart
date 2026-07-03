import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';

class SettingsState {
  const SettingsState({
    this.locale = 'en',
    this.notificationsEnabled = true,
    this.notificationFrequency = NotificationFrequency.always,
    this.locationEnabled = true,
    this.themeMode = ThemeMode.system,
  });

  final String locale;
  final bool notificationsEnabled;
  final NotificationFrequency notificationFrequency;
  final bool locationEnabled;
  final ThemeMode themeMode;

  SettingsState copyWith({
    String? locale,
    bool? notificationsEnabled,
    NotificationFrequency? notificationFrequency,
    bool? locationEnabled,
    ThemeMode? themeMode,
  }) {
    return SettingsState(
      locale: locale ?? this.locale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationFrequency: notificationFrequency ?? this.notificationFrequency,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

/// Persists preferences to SharedPreferences so they survive app restarts.
class SettingsController extends StateNotifier<SettingsState> {
  SettingsController() : super(const SettingsState()) {
    _load();
  }

  static const _kLocale = 'locale';
  static const _kNotifEnabled = 'notif_enabled';
  static const _kNotifFreq = 'notif_freq';
  static const _kLocationEnabled = 'location_enabled';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      locale: prefs.getString(_kLocale) ?? 'en',
      notificationsEnabled: prefs.getBool(_kNotifEnabled) ?? true,
      notificationFrequency: NotificationFrequency.values.firstWhere(
        (f) => f.name == (prefs.getString(_kNotifFreq) ?? 'always'),
        orElse: () => NotificationFrequency.always,
      ),
      locationEnabled: prefs.getBool(_kLocationEnabled) ?? true,
    );
  }

  Future<void> setLocale(String locale) async {
    state = state.copyWith(locale: locale);
    (await SharedPreferences.getInstance()).setString(_kLocale, locale);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    (await SharedPreferences.getInstance()).setBool(_kNotifEnabled, enabled);
  }

  Future<void> setNotificationFrequency(NotificationFrequency freq) async {
    state = state.copyWith(notificationFrequency: freq);
    (await SharedPreferences.getInstance()).setString(_kNotifFreq, freq.name);
  }

  Future<void> setLocationEnabled(bool enabled) async {
    state = state.copyWith(locationEnabled: enabled);
    (await SharedPreferences.getInstance()).setBool(_kLocationEnabled, enabled);
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) => SettingsController());
