import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../providers/settings_providers.dart';

/// 11. Settings Screen — language, notifications, location, privacy.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            GradientHeader(
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: 4),
                  Text('Settings', style: AppTextStyles.h1),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SettingsSection(
              title: 'Language',
              children: [
                for (final locale in AppConstants.supportedLocales)
                  RadioListTile<String>(
                    value: locale,
                    groupValue: settings.locale,
                    activeColor: AppColors.primary,
                    title: Text(_localeName(locale)),
                    onChanged: (v) => controller.setLocale(v!),
                  ),
              ],
            ),
            _SettingsSection(
              title: 'Notifications',
              children: [
                SwitchListTile(
                  activeColor: AppColors.primary,
                  title: const Text('Enable notifications'),
                  value: settings.notificationsEnabled,
                  onChanged: controller.setNotificationsEnabled,
                ),
                if (settings.notificationsEnabled)
                  for (final freq in NotificationFrequency.values)
                    RadioListTile<NotificationFrequency>(
                      value: freq,
                      groupValue: settings.notificationFrequency,
                      activeColor: AppColors.primary,
                      title: Text(_freqLabel(freq)),
                      onChanged: (v) => controller.setNotificationFrequency(v!),
                    ),
              ],
            ),
            _SettingsSection(
              title: 'Location',
              children: [
                SwitchListTile(
                  activeColor: AppColors.primary,
                  title: const Text('Enable location services'),
                  subtitle: const Text('Used to show distance and nearby businesses'),
                  value: settings.locationEnabled,
                  onChanged: controller.setLocationEnabled,
                ),
              ],
            ),
            _SettingsSection(
              title: 'About',
              children: [
                ListTile(
                  title: const Text('App version'),
                  trailing: FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) =>
                        Text(snapshot.hasData ? snapshot.data!.version : '—', style: AppTextStyles.bodyMedium),
                  ),
                ),
                ListTile(title: const Text('Privacy Policy'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () {}),
                ListTile(title: const Text('Help / Support'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () {}),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _localeName(String code) {
    switch (code) {
      case 'sq':
        return 'Shqip (Albanian)';
      case 'it':
        return 'Italiano';
      default:
        return 'English';
    }
  }

  String _freqLabel(NotificationFrequency freq) {
    switch (freq) {
      case NotificationFrequency.always:
        return 'Always';
      case NotificationFrequency.daily:
        return 'Daily digest';
      case NotificationFrequency.weekly:
        return 'Weekly digest';
    }
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
