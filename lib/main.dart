import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Supported app languages — English, Albanian, German. Kept as one place
/// so Settings' language picker and MaterialApp.router's supportedLocales
/// always agree on exactly the same list.
const List<Locale> kSupportedLocales = [
  Locale('en'),
  Locale('sq'),
  Locale('de'),
];
const Locale kFallbackLocale = Locale('en');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Required before any DateFormat('...', localeCode) call for a non-'en'
  // locale — without this, formatting a date in Albanian/German throws a
  // LocaleDataException at runtime the first time a screen tries to show
  // a date (event times, notification timestamps, etc). Initializing all
  // three supported locales up front means switching languages never hits
  // this the first time a date-formatted screen opens after the switch.
  for (final locale in kSupportedLocales) {
    await initializeDateFormatting(locale.languageCode);
  }

  // Initialize Firebase here before runApp if using FCM:
  // await Firebase.initializeApp();

  await initServiceLocator();

  runApp(
    EasyLocalization(
      supportedLocales: kSupportedLocales,
      path: 'assets/translations',
      fallbackLocale: kFallbackLocale,
      startLocale: kFallbackLocale,
      child: const ProviderScope(child: AlbMapApp()),
    ),
  );
}

class AlbMapApp extends ConsumerWidget {
  const AlbMapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    // Pins dark (not light/white) status bar icons — our gradient headers
    // are light-tinted at the top, so dark clock/battery icons stay
    // readable against them. Forced explicitly rather than left to
    // platform default since we also force ThemeMode.light below.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: MaterialApp.router(
        title: 'AlbMap',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // Forced light mode: AppTheme.dark is not yet a fully fleshed-out
        // theme (missing input/button/dialog/bottom-sheet overrides), so
        // letting ThemeMode.system activate it produces black buttons,
        // black bottom sheets, and invisible text in dark-mode devices.
        // Re-enable ThemeMode.system once AppTheme.dark is completed.
        themeMode: ThemeMode.light,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        routerConfig: router,
      ),
    );
  }
}
