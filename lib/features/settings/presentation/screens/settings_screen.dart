import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../providers/settings_providers.dart';

/// 11. Settings Screen — language, notifications, location, privacy.
///
/// Language switching is app-wide and production-ready: it calls
/// easy_localization's `context.setLocale()`, which immediately rebuilds
/// every widget using `.tr()` throughout the app (not just this screen)
/// and persists the choice for the next launch — no app-specific
/// SharedPreferences plumbing needed for that part, easy_localization
/// already handles it.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _localeLabel(String code) {
    switch (code) {
      case 'sq':
        return 'settings.albanian'.tr();
      case 'de':
        return 'settings.german'.tr();
      default:
        return 'settings.english'.tr();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final currentLocaleCode = context.locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            GradientHeader(
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: 4),
                  Text('settings.title'.tr(), style: AppTextStyles.h1),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SettingsSection(
              title: 'settings.language'.tr(),
              children: [
                for (final localeCode in AppConstants.supportedLocales)
                  RadioListTile<String>(
                    value: localeCode,
                    groupValue: currentLocaleCode,
                    activeColor: AppColors.primary,
                    title: Text(_localeLabel(localeCode)),
                    onChanged: (code) {
                      if (code != null) context.setLocale(Locale(code));
                    },
                  ),
              ],
            ),
            _SettingsSection(
              title: 'settings.notifications'.tr(),
              children: [
                SwitchListTile(
                  activeColor: AppColors.primary,
                  title: Text('settings.enableNotifications'.tr()),
                  subtitle: Text('settings.enableNotificationsDesc'.tr()),
                  value: settings.notificationsEnabled,
                  onChanged: controller.setNotificationsEnabled,
                ),
              ],
            ),
            _SettingsSection(
              title: 'settings.location'.tr(),
              children: [
                SwitchListTile(
                  activeColor: AppColors.primary,
                  title: Text('settings.enableLocation'.tr()),
                  subtitle: Text('settings.enableLocationDesc'.tr()),
                  value: settings.locationEnabled,
                  onChanged: controller.setLocationEnabled,
                ),
              ],
            ),
            _SettingsSection(
              title: 'settings.about'.tr(),
              children: [
                ListTile(
                  title: Text('settings.appVersion'.tr()),
                  trailing: FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) =>
                        Text(snapshot.hasData ? snapshot.data!.version : '—', style: AppTextStyles.bodyMedium),
                  ),
                ),
                ListTile(
                  title: Text('settings.privacyPolicy'.tr()),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => launchUrl(Uri.parse('https://albmap.app/privacy')),
                ),
                ListTile(
                  title: Text('settings.helpSupport'.tr()),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => launchUrl(Uri.parse('https://albmap.app/support')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}
