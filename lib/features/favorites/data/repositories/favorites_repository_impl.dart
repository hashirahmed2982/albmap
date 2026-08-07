import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../map/domain/entities/business_entity.dart';
import '../../../map/data/models/business_model.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/data/models/event_model.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_local_datasource.dart';
import '../datasources/favorites_remote_datasource.dart';

/// Both businesses and events sync with the backend (see
/// favorites_remote_datasource.dart) so a favorite survives a
/// reinstall/device switch and the owner's Dashboard favorite_count
/// reflects reality — Hive remains an instant, offline-safe local
/// cache/mirror, not the source of truth anymore.
class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl({
    required FavoritesLocalDataSource localDataSource,
    required FavoritesRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  })  : _local = localDataSource,
        _remote = remoteDataSource,
        _networkInfo = networkInfo;

  final FavoritesLocalDataSource _local;
  final FavoritesRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  Future<Either<Failure, void>> toggleFavoriteBusiness(BusinessEntity business) async {
    try {
      final bool wasAlreadyFavorite = await _local.isBusinessFavorite(business.id);

      final BusinessModel model = BusinessModel(
        id: business.id, ownerId: business.ownerId, name: business.name,
        description: business.description, category: business.category,
        streetAddress: business.streetAddress, city: business.city,
        postalCode: business.postalCode, country: business.country,
        latitude: business.latitude, longitude: business.longitude,
        status: business.status, phone: business.phone, whatsappNumber: business.whatsappNumber,
        logoUrl: business.logoUrl, openingHours: business.openingHours, tags: business.tags,
        rating: business.rating,
      );
      await _local.toggleBusiness(model);

      // Best-effort remote sync — if this fails (offline, server error),
      // the local toggle above still succeeded, so the UI keeps working;
      // it just won't sync to the server until the next successful call.
      // A more thorough implementation would queue this for retry, but
      // that's a larger offline-sync feature beyond this fix's scope.
      if (!AppConstants.useMockData && await _networkInfo.isConnected) {
        try {
          if (wasAlreadyFavorite) {
            await _remote.removeFavorite(business.id);
          } else {
            await _remote.addFavorite(business.id);
          }
        } on ServerException {
          // Swallow — local state is already correct, remote sync is
          // best-effort and shouldn't surface as a user-facing error for
          // what is, from the user's perspective, a successful action.
        }
      }

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> toggleFavoriteEvent(EventEntity event) async {
    try {
      final bool wasAlreadyFavorite = await _local.isEventFavorite(event.id);

      final EventModel model = EventModel(
        id: event.id, businessId: event.businessId, businessName: event.businessName,
        name: event.name, description: event.description, category: event.category,
        startTime: event.startTime, endTime: event.endTime, imageUrl: event.imageUrl,
        latitude: event.latitude, longitude: event.longitude, address: event.address,
        interestCount: event.interestCount, isInterested: event.isInterested,
      );
      await _local.toggleEvent(model);

      // Best-effort remote sync, same reasoning as toggleFavoriteBusiness
      // above — local toggle already succeeded, so a sync failure here
      // shouldn't surface as a user-facing error.
      if (!AppConstants.useMockData && await _networkInfo.isConnected) {
        try {
          if (wasAlreadyFavorite) {
            await _remote.removeFavoriteEvent(event.id);
          } else {
            await _remote.addFavoriteEvent(event.id);
          }
        } on ServerException {
          // Swallow — see toggleFavoriteBusiness.
        }
      }

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<BusinessEntity>>> getFavoriteBusinesses() async {
    if (!AppConstants.useMockData && await _networkInfo.isConnected) {
      try {
        final remoteFavorites = await _remote.getFavoriteBusinesses();
        // Backend is the source of truth when reachable — refresh the
        // local cache to match it (covers the "logged in on a new device"
        // case, where local Hive has nothing but the server has history).
        for (final business in remoteFavorites) {
          if (!await _local.isBusinessFavorite(business.id)) {
            await _local.toggleBusiness(business);
          }
        }
        return Right(remoteFavorites);
      } on ServerException {
        // Fall through to local cache below.
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }

    try {
      return Right(await _local.getFavoriteBusinesses());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<EventEntity>>> getFavoriteEvents() async {
    if (!AppConstants.useMockData && await _networkInfo.isConnected) {
      try {
        final remoteFavorites = await _remote.getFavoriteEvents();
        // Same "backend is the source of truth when reachable" refresh
        // as getFavoriteBusinesses above.
        for (final event in remoteFavorites) {
          if (!await _local.isEventFavorite(event.id)) {
            await _local.toggleEvent(event);
          }
        }
        return Right(remoteFavorites);
      } on ServerException {
        // Fall through to local cache below.
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }

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

  @override
  Future<Either<Failure, bool>> isEventFavorite(String eventId) async {
    try {
      return Right(await _local.isEventFavorite(eventId));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
