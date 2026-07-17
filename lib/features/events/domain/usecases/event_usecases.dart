import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/event_entity.dart';
import '../repositories/event_repository.dart';

class GetEventsUseCase implements UseCase<List<EventEntity>, GetEventsParams> {
  GetEventsUseCase(this._repository);
  final EventRepository _repository;

  @override
  Future<Either<Failure, List<EventEntity>>> call(GetEventsParams params) {
    return _repository.getEvents(
      category: params.category, businessId: params.businessId,
      fromDate: params.fromDate, toDate: params.toDate,
    );
  }
}

class GetEventsParams extends Equatable {
  const GetEventsParams({this.category, this.businessId, this.fromDate, this.toDate});
  final String? category;
  final String? businessId;
  final DateTime? fromDate;
  final DateTime? toDate;

  @override
  List<Object?> get props => [category, businessId, fromDate, toDate];
}

class CreateEventUseCase implements UseCase<void, EventEntity> {
  CreateEventUseCase(this._repository);
  final EventRepository _repository;

  @override
  Future<Either<Failure, void>> call(EventEntity event) {
    return _repository.createEvent(event);
  }
}

class UploadEventImageUseCase implements UseCase<String, String> {
  UploadEventImageUseCase(this._repository);
  final EventRepository _repository;

  @override
  Future<Either<Failure, String>> call(String filePath) {
    return _repository.uploadEventImage(filePath);
  }
}
