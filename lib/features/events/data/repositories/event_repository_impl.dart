import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_remote_datasource.dart';
import '../models/event_model.dart';

class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl({
    required EventRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  })  : _remote = remoteDataSource,
        _networkInfo = networkInfo;

  final EventRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  Future<Either<Failure, List<EventEntity>>> getEvents({
    String? category,
    String? businessId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await _remote.getEvents(
        category: category, businessId: businessId, fromDate: fromDate, toDate: toDate,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, EventEntity>> getEventDetails(String id) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await _remote.getEventDetails(id));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> createEvent(EventEntity event) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final EventModel model = EventModel(
        id: event.id, businessId: event.businessId, businessName: event.businessName,
        name: event.name, description: event.description, category: event.category,
        startTime: event.startTime, endTime: event.endTime, imageUrl: event.imageUrl,
      );
      await _remote.createEvent(model);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, String>> uploadEventImage(String filePath) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await _remote.uploadEventImage(filePath));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
