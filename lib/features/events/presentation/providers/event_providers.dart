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

  EventFilter copyWith({
    String? category,
    String? businessId,
    DateTime? fromDate,
    DateTime? toDate,
    String? query,
  }) {
    return EventFilter(
      category: category ?? this.category,
      businessId: businessId ?? this.businessId,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
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
  if (filter.query.trim().isEmpty) return events;
  final q = filter.query.toLowerCase();
  return events.where((e) => e.name.toLowerCase().contains(q)).toList();
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
