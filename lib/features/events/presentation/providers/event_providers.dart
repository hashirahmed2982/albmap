import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/usecases/event_usecases.dart';

class EventFilter {
  const EventFilter({this.category, this.businessId, this.fromDate, this.toDate, this.query = ''});
  final String? category;
  final String? businessId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String query;

  bool get hasDateFilter => fromDate != null || toDate != null;

  EventFilter copyWith({
    String? category,
    String? businessId,
    DateTime? fromDate,
    DateTime? toDate,
    String? query,
    bool clearFromDate = false,
    bool clearToDate = false,
  }) {
    return EventFilter(
      category: category ?? this.category,
      businessId: businessId ?? this.businessId,
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
      query: query ?? this.query,
    );
  }
}

final eventFilterProvider = StateProvider<EventFilter>((ref) => const EventFilter());

final eventsProvider = FutureProvider.autoDispose<List<EventEntity>>((ref) async {
  final filter = ref.watch(eventFilterProvider);
  final useCase = sl<GetEventsUseCase>();
  final result = await useCase(GetEventsParams(
    category: filter.category,
    businessId: filter.businessId,
    fromDate: filter.fromDate,
    toDate: filter.toDate,
  ));
  final events = result.fold((_) => <EventEntity>[], (list) => list);

  // Finished events are never useful in the general browse list — the
  // backend's from/to params only filter by startTime (so an ongoing
  // multi-hour event whose startTime is already in the past wouldn't be
  // excluded by them), so this checks endTime client-side instead, and
  // applies unconditionally regardless of any explicit date filter above.
  final now = DateTime.now();
  Iterable<EventEntity> visible = events.where((e) => e.endTime.isAfter(now));

  if (filter.query.trim().isNotEmpty) {
    final q = filter.query.trim().toLowerCase();
    visible = visible.where((e) => e.name.toLowerCase().contains(q));
  }
  return visible.toList();
});

class CreateEventController extends StateNotifier<AsyncValue<void>> {
  CreateEventController() : super(const AsyncValue.data(null));

  Future<bool> submit(EventEntity event) async {
    state = const AsyncValue.loading();
    final useCase = sl<CreateEventUseCase>();
    final result = await useCase(event);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }
}

final createEventControllerProvider =
    StateNotifierProvider.autoDispose<CreateEventController, AsyncValue<void>>(
  (ref) => CreateEventController(),
);

/// "I'm interested" / RSVP toggle. Same null-on-success/message-on-failure
/// contract as FavoriteToggleController — callers show a toast on a
/// non-null return and otherwise just refresh whatever list/detail
/// provider is showing this event, since the toggle itself doesn't carry
/// the updated interestCount/isInterested back (the backend recomputes
/// those from event_interests on the next read, not on the toggle call).
class EventInterestController extends StateNotifier<AsyncValue<void>> {
  EventInterestController() : super(const AsyncValue.data(null));

  Future<String?> toggle(EventEntity event) async {
    final useCase = sl<ToggleEventInterestUseCase>();
    final result = await useCase(
      ToggleEventInterestParams(eventId: event.id, isCurrentlyInterested: event.isInterested),
    );
    return result.fold((failure) => failure.message, (_) => null);
  }
}

final eventInterestControllerProvider =
    StateNotifierProvider.autoDispose<EventInterestController, AsyncValue<void>>(
  (ref) => EventInterestController(),
);
