import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/event_providers.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.addEvent),
              icon: const Icon(Icons.add),
              label: const Text('Add Event'),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            GradientHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Events', style: AppTextStyles.h1),
                  const SizedBox(height: 4),
                  const Text('Discover what\'s happening near you', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 14),
                  SizedBox(
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
                        decoration: const InputDecoration(
                          hintText: 'Search events...',
                          prefixIcon: Icon(Icons.search, color: AppColors.primary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: eventsAsync.when(
                loading: () => const LoadingIndicator(),
                error: (_, __) => ErrorStateWidget(
                  message: 'Failed to load events',
                  onRetry: () => ref.invalidate(eventsProvider),
                ),
                data: (events) {
                  if (events.isEmpty) {
                    return const EmptyStateWidget(
                      message: 'No upcoming events found', icon: Icons.event_busy_outlined,
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
