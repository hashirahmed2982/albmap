import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../map/domain/entities/business_entity.dart';
import '../../../map/data/models/business_model.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/data/models/event_model.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_local_datasource.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl({required FavoritesLocalDataSource localDataSource})
      : _local = localDataSource;

  final FavoritesLocalDataSource _local;

  @override
  Future<Either<Failure, void>> toggleFavoriteBusiness(BusinessEntity business) async {
    try {
      final BusinessModel model = BusinessModel(
        id: business.id, ownerId: business.ownerId, name: business.name,
        description: business.description, category: business.category,
        address: business.address, latitude: business.latitude, longitude: business.longitude,
        status: business.status, phone: business.phone, logoUrl: business.logoUrl,
        openingHours: business.openingHours, tags: business.tags, rating: business.rating,
      );
      await _local.toggleBusiness(model);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> toggleFavoriteEvent(EventEntity event) async {
    try {
      final EventModel model = EventModel(
        id: event.id, businessId: event.businessId, businessName: event.businessName,
        name: event.name, description: event.description, category: event.category,
        startTime: event.startTime, endTime: event.endTime, imageUrl: event.imageUrl,
      );
      await _local.toggleEvent(model);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<BusinessEntity>>> getFavoriteBusinesses() async {
    try {
      return Right(await _local.getFavoriteBusinesses());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<EventEntity>>> getFavoriteEvents() async {
    try {
      return Right(await _local.getFavoriteEvents());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> isBusinessFavorite(String businessId) async {
    try {
      return Right(await _local.isBusinessFavorite(businessId));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
