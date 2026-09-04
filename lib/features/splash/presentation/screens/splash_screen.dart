import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// 1. Splash Screen — shows logo, waits for auth restore, then routes
/// via the go_router redirect logic (see app_router.dart).
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authControllerProvider, (previous, next) {
      if (!next.isLoading) {
        if (next.isAuthenticated) {
          context.go(AppRoutes.discoverMap);
        } else {
          context.go(AppRoutes.login);
        }
      }
    });

    // Flat black, no gradient/shadow — matches the Bold Editorial rule
    // used everywhere else in the app ("background of the whole app is
    // black, no highlight"). The app icon itself (a red pin with the
    // Albanian eagle) already reads as a distinct shape against black, so
    // it's placed directly with no rounded/shadowed container behind it.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/icon_master.png', width: 120, height: 120),
            const SizedBox(height: 20),
            Text('AlbMap', style: AppTextStyles.h1.copyWith(fontSize: 36)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'splash.tagline'.tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
