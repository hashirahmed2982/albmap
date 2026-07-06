import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase here before runApp if using FCM:
  // await Firebase.initializeApp();

  await initServiceLocator();

  runApp(const ProviderScope(child: AlbMapApp()));
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
        routerConfig: router,
      ),
    );
  }
}
