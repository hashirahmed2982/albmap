import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/business_analytics_entity.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/analytics_remote_datasource.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  AnalyticsRepositoryImpl({required AnalyticsDataSource dataSource}) : _dataSource = dataSource;
  final AnalyticsDataSource _dataSource;

  @override
  Future<Either<Failure, BusinessAnalyticsEntity>> getBusinessAnalytics(String businessId) async {
    try {
      return Right(await _dataSource.getBusinessAnalytics(businessId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> recordEvent(String businessId, AnalyticsEventType type) async {
    try {
      await _dataSource.recordEvent(businessId, type);
      return const Right(null);
    } catch (_) {
      // Best-effort — never block or alarm the visitor over analytics failing.
      return const Right(null);
    }
  }
}
