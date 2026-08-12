import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/event_entity.dart';

abstract class EventRepository {
  Future<Either<Failure, List<EventEntity>>> getEvents({
    String? category,
    String? businessId,
    DateTime? fromDate,
    DateTime? toDate,
  });

  Future<Either<Failure, EventEntity>> getEventDetails(String id);

  /// Every event owned by [ownerId], across every business they own,
  /// regardless of whether it's already finished — backs "My Events",
  /// same relationship to [getEvents] as BusinessRepository.getMyBusinesses
  /// has to getBusinesses.
  Future<Either<Failure, List<EventEntity>>> getMyEvents(String ownerId);

  Future<Either<Failure, void>> createEvent(EventEntity event);

  /// Owner-only edit — the backend rejects this once the event has already
  /// finished (see event.service.js's updateEvent), so a failure here can
  /// legitimately mean "too late to edit," not just a network/validation
  /// error; callers should show the server's message as-is.
  Future<Either<Failure, EventEntity>> updateEvent(
    String eventId, {
    String? name,
    String? description,
    String? category,
    DateTime? startTime,
    DateTime? endTime,
    String? imageUrl,
  });

  Future<Either<Failure, String>> uploadEventImage(String filePath);

  Future<Either<Failure, void>> addInterest(String eventId);
  Future<Either<Failure, void>> removeInterest(String eventId);
}
