import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/page_header_title.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../map/presentation/widgets/business_list_view.dart';

/// "My Events" — every event the current user has created, across every
/// business they own, past and upcoming alike (mirrors "My Businesses":
/// an owner's own view shows everything, not just what's currently
/// live/relevant to the public). A finished event stays visible as
/// history, just without the edit affordance — see _MyEventCard.
class MyEventsScreen extends ConsumerWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authControllerProvider).user?.id;
    if (userId == null) return const SizedBox.shrink();

    final eventsAsync = ref.watch(myEventsProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addEvent),
        icon: const Icon(Icons.add),
        label: Text('addEvent.title'.tr()),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GradientHeader(
              child: PageHeaderTitle(
                title: 'myEvents.title'.tr(),
                subtitle: 'myEvents.subtitle'.tr(),
                icon: Icons.event_rounded,
                accent: AppColors.secondary,
                iconBadgeSize: 32,
              ),
            ),
            Expanded(
              child: eventsAsync.when(
                loading: () => const LoadingIndicator(),
                error: (_, __) => ErrorStateWidget(
                  message: 'myEvents.failedToLoad'.tr(),
                  onRetry: () => ref.invalidate(myEventsProvider(userId)),
                ),
                data: (events) {
                  if (events.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_outlined, size: 56, color: AppColors.textSecondary),
                            const SizedBox(height: 16),
                            Text('myEvents.emptyTitle'.tr(), style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: 200,
                              child: PrimaryButton(
                                label: 'myEvents.addFirst'.tr(),
                                onPressed: () => context.push(AppRoutes.addEvent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  // Soonest-upcoming-first, with past events (already
                  // sorted newest-finished-first by the backend) trailing
                  // at the bottom — reading top-to-bottom goes "what's
                  // next" before "history," matching how My Businesses
                  // puts nothing time-ordered above status at all, but is
                  // the more useful default specifically for a time-bound
                  // list like this one.
                  final now = DateTime.now();
                  final upcoming = events.where((e) => e.endTime.isAfter(now)).toList()
                    ..sort((a, b) => a.startTime.compareTo(b.startTime));
                  final past = events.where((e) => !e.endTime.isAfter(now)).toList();
                  final ordered = [...upcoming, ...past];

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async => ref.invalidate(myEventsProvider(userId)),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemCount: ordered.length,
                      itemBuilder: (context, i) => _MyEventCard(event: ordered[i]),
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

class _MyEventCard extends StatelessWidget {
  const _MyEventCard({required this.event});
  final EventEntity event;

  @override
  Widget build(BuildContext context) {
    final Color accent = categoryColor(event.category);
    final bool isPast = !event.endTime.isAfter(DateTime.now());
    final bool isOngoing = !isPast && event.isOngoing;
    final dateFmt = DateFormat('MMM d, yyyy · HH:mm', context.locale.languageCode);

    final Color statusColor = isPast
        ? AppColors.textSecondary
        : isOngoing
            ? AppColors.approved
            : AppColors.primary;
    final String statusLabel = isPast
        ? 'myEvents.pastLabel'.tr()
        : isOngoing
            ? 'myEvents.ongoingLabel'.tr()
            : 'myEvents.upcomingLabel'.tr();

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
          onTap: () => context.push(AppRoutes.eventDetailsPath(event.id)),
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
                      child: Icon(categoryIcon(event.category), color: accent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.name, style: AppTextStyles.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(event.businessName, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    // Only reachable for an event that hasn't finished yet
                    // — matches the backend's own PATCH /events/:id guard
                    // (see event.service.js's updateEvent), which rejects
                    // an edit to an already-finished event regardless of
                    // whether this button was ever shown for it.
                    if (!isPast)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                        onPressed: () => context.push(AppRoutes.editEventPath(event.id)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        statusLabel,
                        style: AppTextStyles.bodySmall.copyWith(color: statusColor, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dateFmt.format(event.startTime),
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (isPast) ...[
                  const SizedBox(height: 8),
                  Text('myEvents.historyExplainer'.tr(), style: AppTextStyles.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
