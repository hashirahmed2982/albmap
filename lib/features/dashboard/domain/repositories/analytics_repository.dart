import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/business_analytics_entity.dart';

abstract class AnalyticsRepository {
  Future<Either<Failure, BusinessAnalyticsEntity>> getBusinessAnalytics(String businessId);

  /// Fire-and-forget style event recording. Called from Business Details
  /// when a visitor views the profile, taps Directions, or taps Call.
  /// Real backend implementations should batch/debounce these rather than
  /// hitting the API on every single tap.
  Future<Either<Failure, void>> recordEvent(String businessId, AnalyticsEventType type);
}
