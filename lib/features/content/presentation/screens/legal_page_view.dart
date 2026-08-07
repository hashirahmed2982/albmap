import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/page_header_title.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/entities/site_content_entity.dart';
import '../providers/content_providers.dart';

/// Shared rendering for Privacy Policy and Terms & Conditions — both are
/// "a title plus an ordered list of heading/body sections" from
/// siteContentProvider, admin-edited from the admin portal's Content
/// page. [title]/[icon] are the screen's static chrome (shown even while
/// content is loading/failed to load), not the fetched page's own
/// `title` field — that field exists for the website's <h1> to use;
/// duplicating it here as a second on-screen heading would be redundant
/// with the header this screen already has.
///
/// Section bodies render as plain text with line breaks preserved (no
/// Markdown/HTML) — matches how the admin portal's editor describes them
/// and how the website renders the same data.
class LegalPageView extends ConsumerWidget {
  const LegalPageView({
    super.key,
    required this.title,
    required this.icon,
    required this.selector,
  });

  final String title;
  final IconData icon;
  final LegalPageEntity? Function(SiteContentEntity content) selector;

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
              child: PageHeaderTitle(title: title, icon: icon, accent: AppColors.secondary),
            ),
            Expanded(
              child: contentAsync.when(
                loading: () => const LoadingIndicator(),
                error: (_, __) => ErrorStateWidget(
                  message: 'common.somethingWrong'.tr(),
                  onRetry: () => ref.invalidate(siteContentProvider),
                ),
                data: (content) {
                  final LegalPageEntity? page = content != null ? selector(content) : null;
                  if (page == null) {
                    return ErrorStateWidget(
                      message: 'common.somethingWrong'.tr(),
                      onRetry: () => ref.invalidate(siteContentProvider),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: page.sections.length,
                    itemBuilder: (context, i) {
                      final section = page.sections[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(section.heading, style: AppTextStyles.h3),
                            const SizedBox(height: 8),
                            Text(section.body, style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      );
                    },
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
