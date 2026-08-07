import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/url_launcher_helper.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/page_header_title.dart';

/// 13. About Us Screen — mission, vision, legal links, social media.
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            GradientHeader(
              child: PageHeaderTitle(
                title: 'aboutUs.title'.tr(),
                icon: Icons.info_rounded,
                accent: AppColors.secondary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: const Icon(Icons.map_rounded, color: Colors.white, size: 42),
                  ),
                  const SizedBox(height: 16),
                  const Text('AlbMap', style: AppTextStyles.h1),
                  const SizedBox(height: 8),
                  Text(
                    'aboutUs.tagline'.tr(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  _InfoCard(
                    title: 'aboutUs.missionTitle'.tr(),
                    body: 'aboutUs.missionBody'.tr(),
                  ),
                  const SizedBox(height: 14),
                  _InfoCard(
                    title: 'aboutUs.visionTitle'.tr(),
                    body: 'aboutUs.visionBody'.tr(),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        ListTile(
                          title: Text('aboutUs.privacyPolicy'.tr()),
                          trailing: const Icon(Icons.open_in_new, size: 18, color: AppColors.textSecondary),
                          onTap: () => launchUrlSafely(context, Uri.parse('https://albmap.app/privacy')),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: Text('aboutUs.terms'.tr()),
                          trailing: const Icon(Icons.open_in_new, size: 18, color: AppColors.textSecondary),
                          onTap: () => launchUrlSafely(context, Uri.parse('https://albmap.app/terms')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('aboutUs.followUs'.tr(), style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialButton(icon: Icons.facebook, onTap: () => launchUrlSafely(context, Uri.parse('https://facebook.com/albmap'))),
                      const SizedBox(width: 14),
                      _SocialButton(icon: Icons.camera_alt_outlined, onTap: () => launchUrlSafely(context, Uri.parse('https://instagram.com/albmap'))),
                      const SizedBox(width: 14),
                      _SocialButton(icon: Icons.alternate_email, onTap: () => launchUrlSafely(context, Uri.parse('https://twitter.com/albmap'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(body, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
      ),
    );
  }
}
