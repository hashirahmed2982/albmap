import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/usecases/event_usecases.dart';
import 'event_list_tile.dart';

final _eventDetailsProvider =
    FutureProvider.autoDispose.family<EventEntity?, String>((ref, id) async {
  final useCase = sl<GetEventsUseCase>();
  final result = await useCase(const GetEventsParams());
  return result.fold(
    (_) => null,
    (events) => events.where((e) => e.id == id).firstOrNull,
  );
});

/// Event details — shown from Events list, Business details, or Favorites.
class EventDetailsScreen extends ConsumerWidget {
  const EventDetailsScreen({required this.eventId, super.key});
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(_eventDetailsProvider(eventId));
    final authState = ref.watch(authControllerProvider);
    final bool canFavorite = authState.user?.isBusinessUser ?? false;
    final dateFmt = DateFormat('EEEE, MMM d, yyyy · HH:mm');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: eventAsync.when(
        loading: () => const LoadingIndicator(),
        error: (_, __) => const ErrorStateWidget(message: 'Failed to load event'),
        data: (event) {
          if (event == null) return const ErrorStateWidget(message: 'Event not found');

          final Color accent = eventCategoryColor(event.category);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 200,
                backgroundColor: accent,
                actions: [
                  if (canFavorite)
                    IconButton(
                      icon: const Icon(Icons.favorite_border, color: Colors.white),
                      onPressed: () =>
                          ref.read(favoriteToggleControllerProvider.notifier).toggleEvent(event),
                    ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () => Share.share('Join ${event.name} — hosted by ${event.businessName}'),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: event.imageUrl != null
                      ? Image.network(event.imageUrl!, fit: BoxFit.cover)
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [accent, accent.withValues(alpha: 0.7)],
                            ),
                          ),
                          child: Center(
                            child: Icon(eventCategoryIcon(event.category), size: 72, color: Colors.white.withValues(alpha: 0.85)),
                          ),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                        child: Text(event.category, style: AppTextStyles.bodySmall.copyWith(color: accent, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 10),
                      Text(event.name, style: AppTextStyles.h1),
                      const SizedBox(height: 6),
                      Text('Hosted by ${event.businessName}', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 18),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 18, color: accent),
                                const SizedBox(width: 10),
                                Expanded(child: Text(dateFmt.format(event.startTime), style: AppTextStyles.bodyMedium)),
                              ],
                            ),
                            if (event.address != null) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 18, color: accent),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(event.address!, style: AppTextStyles.bodyMedium)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text('About this event', style: AppTextStyles.h3),
                      const SizedBox(height: 8),
                      Text(event.description, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: accent),
                          icon: const Icon(Icons.calendar_month_outlined),
                          label: const Text('Add to calendar'),
                          onPressed: () => Add2Calendar.addEvent2Cal(Event(
                            title: event.name,
                            description: event.description,
                            location: event.address ?? '',
                            startDate: event.startTime,
                            endDate: event.endTime,
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
