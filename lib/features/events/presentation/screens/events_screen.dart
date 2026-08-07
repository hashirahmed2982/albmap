import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/page_header_title.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/event_providers.dart';
import '../widgets/event_date_filter_sheet.dart';
import 'event_list_tile.dart';

/// 5. Events Screen — browse & filter upcoming events.
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    final authState = ref.watch(authControllerProvider);
    final bool canCreate = authState.user?.isBusinessUser ?? false;
    final bool hasDateFilter = ref.watch(eventFilterProvider.select((f) => f.hasDateFilter));

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.addEvent),
              icon: const Icon(Icons.add),
              label: Text('events.addEvent'.tr()),
            )
          : null,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GradientHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageHeaderTitle(
                    title: 'events.title'.tr(),
                    subtitle: 'events.subtitle'.tr(),
                    icon: Icons.event_rounded,
                    accent: AppColors.secondary,
                    showBackButton: false,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: Material(
                            elevation: 2,
                            shadowColor: Colors.black.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (v) => ref.read(eventFilterProvider.notifier).update(
                                    (state) => state.copyWith(query: v),
                                  ),
                              decoration: InputDecoration(
                                hintText: 'events.searchHint'.tr(),
                                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 52,
                        width: 52,
                        child: Material(
                          elevation: 2,
                          shadowColor: Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          color: AppColors.surface,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
                                onPressed: () => showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => const EventDateFilterSheet(),
                                ),
                              ),
                              if (hasDateFilter)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: eventsAsync.when(
                loading: () => const LoadingIndicator(),
                error: (_, __) => ErrorStateWidget(
                  message: 'events.failedToLoad'.tr(),
                  onRetry: () => ref.invalidate(eventsProvider),
                ),
                data: (events) {
                  if (events.isEmpty) {
                    return EmptyStateWidget(
                      message: 'events.noEventsFound'.tr(), icon: Icons.event_busy_outlined,
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async => ref.invalidate(eventsProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      itemCount: events.length,
                      itemBuilder: (context, i) => EventListTile(event: events[i]),
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
