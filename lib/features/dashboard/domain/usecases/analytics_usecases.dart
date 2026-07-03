import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/business_analytics_entity.dart';
import '../repositories/analytics_repository.dart';

class GetBusinessAnalyticsUseCase implements UseCase<BusinessAnalyticsEntity, String> {
  GetBusinessAnalyticsUseCase(this._repository);
  final AnalyticsRepository _repository;

  @override
  Future<Either<Failure, BusinessAnalyticsEntity>> call(String businessId) {
    return _repository.getBusinessAnalytics(businessId);
  }
}

class RecordAnalyticsEventParams extends Equatable {
  const RecordAnalyticsEventParams({required this.businessId, required this.type});
  final String businessId;
  final AnalyticsEventType type;

  @override
  List<Object?> get props => [businessId, type];
}

class RecordAnalyticsEventUseCase implements UseCase<void, RecordAnalyticsEventParams> {
  RecordAnalyticsEventUseCase(this._repository);
  final AnalyticsRepository _repository;

  @override
  Future<Either<Failure, void>> call(RecordAnalyticsEventParams params) {
    return _repository.recordEvent(params.businessId, params.type);
  }
}
