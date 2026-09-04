import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/url_launcher_helper.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/page_header_title.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../content/domain/entities/site_content_entity.dart';
import '../../../content/presentation/providers/content_providers.dart';

IconData _iconFor(String platform) {
  // Material-icon approximations — this app has no brand-icon package
  // (font_awesome_flutter etc.) installed, so these are the closest
  // built-in stand-ins rather than the platforms' actual logos.
  switch (platform) {
    case 'facebook':
      return Icons.facebook;
    case 'instagram':
      return Icons.camera_alt_outlined;
    case 'twitter':
      return Icons.alternate_email;
    case 'tiktok':
      return Icons.music_note_outlined;
    case 'youtube':
      return Icons.play_circle_outline;
    case 'linkedin':
      return Icons.business_center_outlined;
    default:
      return Icons.link;
  }
}

/// 13. About Us Screen — mission, vision, legal links, social media.
///
/// All of it — tagline, mission/vision copy, social links, and even
/// which social icons show at all — is admin-editable content fetched
/// from GET /content (see siteContentProvider), not hardcoded strings.
/// An admin changes it from the admin portal's Content page; this screen
/// just renders whatever comes back, same as the website's /about page.
class AboutUsScreen extends ConsumerWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(siteContentProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GradientHeader(
              child: PageHeaderTitle(
                title: 'aboutUs.title'.tr(),
                icon: Icons.info_rounded,
                accent: AppColors.secondary,
              ),
            ),
            Expanded(
              child: contentAsync.when(
                loading: () => const LoadingIndicator(),
                error: (_, __) => ErrorStateWidget(
                  message: 'common.somethingWrong'.tr(),
                  onRetry: () => ref.invalidate(siteContentProvider),
                ),
                data: (content) {
                  final AboutContentEntity? about = content?.aboutUs;
                  if (about == null) {
                    return ErrorStateWidget(
                      message: 'common.somethingWrong'.tr(),
                      onRetry: () => ref.invalidate(siteContentProvider),
                    );
                  }
                  final SocialLinksEntity social = content?.socialLinks ?? const SocialLinksEntity();
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Center(
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
                            Text('AlbMap', style: AppTextStyles.h1),
                            const SizedBox(height: 8),
                            Text(
                              about.tagline,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      _InfoCard(title: about.missionTitle, body: about.missionBody),
                      const SizedBox(height: 14),
                      _InfoCard(title: about.visionTitle, body: about.visionBody),
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
                              trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
                              onTap: () => context.push(AppRoutes.privacyPolicy),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              title: Text('aboutUs.terms'.tr()),
                              trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
                              onTap: () => context.push(AppRoutes.termsConditions),
                            ),
                          ],
                        ),
                      ),
                      if (social.hasAny) ...[
                        const SizedBox(height: 28),
                        Text('aboutUs.followUs'.tr(), textAlign: TextAlign.center, style: AppTextStyles.h3),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 14,
                          runSpacing: 10,
                          children: [
                            for (final entry in <String, String?>{
                              'facebook': social.facebook,
                              'instagram': social.instagram,
                              'twitter': social.twitter,
                              'tiktok': social.tiktok,
                              'youtube': social.youtube,
                              'linkedin': social.linkedin,
                            }.entries)
                              if (entry.value != null)
                                _SocialButton(
                                  icon: _iconFor(entry.key),
                                  onTap: () => launchUrlSafely(context, Uri.parse(entry.value!)),
                                ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  );
                },
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
