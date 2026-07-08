import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({required NotificationRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource;

  final NotificationRemoteDataSource _remote;

  @override
  Future<Either<Failure, void>> broadcastFromBusiness({
    required String businessId,
    required String title,
    required String body,
  }) async {
    try {
      await _remote.broadcastFromBusiness(businessId: businessId, title: title, body: body);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
