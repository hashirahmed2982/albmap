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

  Future<Either<Failure, void>> createEvent(EventEntity event);

  Future<Either<Failure, String>> uploadEventImage(String filePath);

  Future<Either<Failure, void>> addInterest(String eventId);
  Future<Either<Failure, void>> removeInterest(String eventId);
}
