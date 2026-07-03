import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../map/domain/entities/business_entity.dart';
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
      return 'Approved';
    case BusinessStatus.pending:
      return 'Pending review';
    case BusinessStatus.rejected:
      return 'Rejected';
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
        label: const Text('Add Business'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            GradientHeader(
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Businesses', style: AppTextStyles.h1),
                        const Text('Manage your listings and view their status', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: businessesAsync.when(
                loading: () => const LoadingIndicator(),
                error: (_, __) => ErrorStateWidget(
                  message: 'Failed to load your businesses',
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
                            const Text("You haven't listed any businesses yet", style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: 200,
                              child: PrimaryButton(
                                label: 'Add your first business',
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
                          Text(business.category, style: AppTextStyles.bodySmall),
                        ],
                      ),
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
                  const Text(
                    'An admin will review this listing shortly. You\'ll be notified once it\'s approved.',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
                if (business.status == BusinessStatus.rejected) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'This submission was rejected. Edit and resubmit, or contact support for details.',
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
