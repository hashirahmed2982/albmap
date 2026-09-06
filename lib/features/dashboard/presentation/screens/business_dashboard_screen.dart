import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/page_header_title.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../map/presentation/providers/business_providers.dart';
import '../../../map/presentation/widgets/business_list_view.dart';
import '../providers/analytics_providers.dart';
import '../widgets/send_notification_sheet.dart';

/// Per-business Dashboard — engagement stats + a way to broadcast an offer
/// notification to (in production) everyone following this business.
class BusinessDashboardScreen extends ConsumerWidget {
  const BusinessDashboardScreen({required this.businessId, super.key});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(businessDetailsProvider(businessId));
    final analyticsAsync = ref.watch(businessAnalyticsProvider(businessId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: businessAsync.when(
        loading: () => const LoadingIndicator(),
        error: (_, __) => ErrorStateWidget(message: 'business.failedToLoad'.tr()),
        data: (business) {
          if (business == null) return ErrorStateWidget(message: 'business.notFound'.tr());
          final Color accent = categoryColor(business.category);

          return SafeArea(
            top: false,
            child: Column(
              children: [
                GradientHeader(
                  child: PageHeaderTitle(
                    title: 'dashboard.title'.tr(),
                    subtitle: business.name,
                    icon: categoryIcon(business.category),
                    accent: accent,
                    // Subtitle here is the business's own (variable-length)
                    // name — a smaller badge leaves it real room instead
                    // of ellipsizing a name that isn't even especially long.
                    iconBadgeSize: 32,
                  ),
                ),
                Expanded(
                  child: analyticsAsync.when(
                    loading: () => const LoadingIndicator(),
                    error: (_, __) => ErrorStateWidget(
                      message: 'dashboard.failedToLoad'.tr(),
                      onRetry: () => ref.invalidate(businessAnalyticsProvider(businessId)),
                    ),
                    data: (analytics) {
                      if (analytics == null) return const SizedBox.shrink();
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                          // A fixed childAspectRatio (the old GridView.count
                          // below) forces every tile to the same height no
                          // matter how much room its content actually
                          // needs — on a narrower phone, a larger system
                          // font size, or a locale whose label text is
                          // longer, the icon+number+label column no longer
                          // fit and Flutter renders the classic yellow/
                          // black "overflowed by N pixels" stripe. Two
                          // IntrinsicHeight rows let each tile size to its
                          // own content instead, so it can never overflow.
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.visibility_outlined,
                                    label: 'dashboard.profileClicks'.tr(),
                                    value: analytics.profileClicks,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.language_outlined,
                                    label: 'dashboard.websiteClicks'.tr(),
                                    value: analytics.websiteClicks,
                                    color: accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.call_outlined,
                                    label: 'dashboard.callClicks'.tr(),
                                    value: analytics.callClicks,
                                    color: AppColors.info,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.favorite_outline,
                                    label: 'dashboard.favorites'.tr(),
                                    value: analytics.favoriteCount,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (analytics.last7DaysProfileClicks.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                border: Border.all(color: AppColors.border, width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('dashboard.last7Days'.tr(), style: AppTextStyles.h3),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 90,
                                    child: _MiniBarChart(values: analytics.last7DaysProfileClicks, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.08),
                              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4), width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.campaign_outlined, color: AppColors.secondary),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text('dashboard.sendOfferTitle'.tr(), style: AppTextStyles.h3, maxLines: 2, overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'dashboard.sendOfferDesc'.tr(),
                                  style: AppTextStyles.bodyMedium,
                                ),
                                const SizedBox(height: 14),
                                PrimaryButton(
                                  label: 'dashboard.sendNotification'.tr(),
                                  icon: Icons.send_outlined,
                                  onPressed: () => showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (_) => SendNotificationSheet(business: business),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            color: color.withValues(alpha: 0.16),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text('$value', style: AppTextStyles.h1.copyWith(fontSize: 24)),
          Text(label, style: AppTextStyles.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({required this.values, required this.color});
  final List<int> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final int maxVal = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 30);
    final days = ['days.mon'.tr(), 'days.tue'.tr(), 'days.wed'.tr(), 'days.thu'.tr(), 'days.fri'.tr(), 'days.sat'.tr(), 'days.sun'.tr()];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int i = 0; i < values.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${values[i]}', style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 46 * (values[i] / maxVal).clamp(0.05, 1.0),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(i < days.length ? days[i] : '', style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
