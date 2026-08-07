import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/page_header_title.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../map/domain/entities/business_entity.dart';
import '../../../categories/domain/category_translations.dart';
import '../../../map/presentation/widgets/business_list_view.dart';
import '../providers/analytics_providers.dart';

Color statusColor(BusinessStatus status) {
  switch (status) {
    case BusinessStatus.approved:
      return AppColors.approved;
    case BusinessStatus.pending:
      return AppColors.pending;
    case BusinessStatus.rejected:
      return AppColors.rejected;
  }
}

IconData statusIcon(BusinessStatus status) {
  switch (status) {
    case BusinessStatus.approved:
      return Icons.check_circle_rounded;
    case BusinessStatus.pending:
      return Icons.hourglass_top_rounded;
    case BusinessStatus.rejected:
      return Icons.cancel_rounded;
  }
}

String statusLabel(BusinessStatus status) {
  switch (status) {
    case BusinessStatus.approved:
      return 'myBusinesses.approvedLabel'.tr();
    case BusinessStatus.pending:
      return 'myBusinesses.pendingLabel'.tr();
    case BusinessStatus.rejected:
      return 'myBusinesses.rejectedLabel'.tr();
  }
}

/// "My Businesses" — every business the current user owns, across all
/// approval statuses. Approved ones link through to their Dashboard;
/// pending/rejected ones show status only (no stats exist yet).
class MyBusinessesScreen extends ConsumerWidget {
  const MyBusinessesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authControllerProvider).user?.id;
    if (userId == null) return const SizedBox.shrink();

    final businessesAsync = ref.watch(myBusinessesProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addBusiness),
        icon: const Icon(Icons.add),
        label: Text('addBusiness.title'.tr()),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GradientHeader(
              child: PageHeaderTitle(
                title: 'myBusinesses.title'.tr(),
                subtitle: 'myBusinesses.subtitle'.tr(),
                icon: Icons.dashboard_rounded,
                accent: AppColors.primary,
                // Smaller badge on business-management screens — the
                // default 44px badge plus the back button was eating
                // enough width that this subtitle ellipsized even at a
                // normal phone width.
                iconBadgeSize: 32,
              ),
            ),
            Expanded(
              child: businessesAsync.when(
                loading: () => const LoadingIndicator(),
                error: (_, __) => ErrorStateWidget(
                  message: 'myBusinesses.failedToLoad'.tr(),
                  onRetry: () => ref.invalidate(myBusinessesProvider(userId)),
                ),
                data: (businesses) {
                  if (businesses.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.storefront_outlined, size: 56, color: AppColors.textSecondary),
                            const SizedBox(height: 16),
                            Text('myBusinesses.emptyTitle'.tr(), style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: 200,
                              child: PrimaryButton(
                                label: 'myBusinesses.addFirst'.tr(),
                                onPressed: () => context.push(AppRoutes.addBusiness),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async => ref.invalidate(myBusinessesProvider(userId)),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemCount: businesses.length,
                      itemBuilder: (context, i) => _MyBusinessCard(business: businesses[i]),
                    ),
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

class _MyBusinessCard extends StatelessWidget {
  const _MyBusinessCard({required this.business});
  final BusinessEntity business;

  @override
  Widget build(BuildContext context) {
    final Color accent = categoryColor(business.category);
    final Color status = statusColor(business.status);
    final bool canOpenDashboard = business.status == BusinessStatus.approved;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: canOpenDashboard
              ? () => context.push(AppRoutes.businessDashboardPath(business.id))
              : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                      child: Icon(categoryIcon(business.category), color: accent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(business.name, style: AppTextStyles.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(localizedCategoryName(context, business.category), style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    // Edit is always reachable regardless of status — a
                    // rejected submission needs to be fixable, not a dead
                    // end, and this is deliberately a separate tap target
                    // from the card's own onTap (which opens the Dashboard
                    // only when approved).
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                      onPressed: () => context.push(AppRoutes.editBusinessPath(business.id)),
                    ),
                    if (canOpenDashboard) const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: status.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon(business.status), size: 16, color: status),
                      const SizedBox(width: 6),
                      Text(statusLabel(business.status), style: AppTextStyles.bodySmall.copyWith(color: status, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                if (business.status == BusinessStatus.pending) ...[
                  const SizedBox(height: 8),
                  Text(
                    'myBusinesses.pendingExplainer'.tr(),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
                if (business.status == BusinessStatus.rejected) ...[
                  const SizedBox(height: 8),
                  Text(
                    'myBusinesses.rejectedExplainer'.tr(),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
