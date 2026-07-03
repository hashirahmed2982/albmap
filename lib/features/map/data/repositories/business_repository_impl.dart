import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/business_entity.dart';
import '../../domain/repositories/business_repository.dart';
import '../datasources/business_local_datasource.dart';
import '../datasources/business_remote_datasource.dart';
import '../models/business_model.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  BusinessRepositoryImpl({
    required BusinessRemoteDataSource remoteDataSource,
    required BusinessLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remote = remoteDataSource,
        _local = localDataSource,
        _networkInfo = networkInfo;

  final BusinessRemoteDataSource _remote;
  final BusinessLocalDataSource _local;
  final NetworkInfo _networkInfo;

  List<BusinessEntity> _withDistance(
    List<BusinessModel> businesses,
    double? userLat,
    double? userLng,
  ) {
    if (userLat == null || userLng == null) return businesses;
    return businesses.map((BusinessModel b) {
      final double distanceMeters = Geolocator.distanceBetween(
        userLat, userLng, b.latitude, b.longitude,
      );
      return b.copyWith(distanceKm: distanceMeters / 1000);
    }).toList();
  }

  @override
  Future<Either<Failure, List<BusinessEntity>>> getBusinesses({
    String? category,
    double? radiusKm,
    double? userLat,
    double? userLng,
    String sortBy = 'distance',
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final List<BusinessModel> businesses = await _remote.getBusinesses(
          category: category, radiusKm: radiusKm, userLat: userLat, userLng: userLng, sortBy: sortBy,
        );
        await _local.cacheBusinesses(businesses);
        return Right(_withDistance(businesses, userLat, userLng));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (_) {
        return const Left(UnknownFailure());
      }
    } else {
      try {
        final List<BusinessModel> cached = await _local.getCachedBusinesses();
        if (cached.isEmpty) return const Left(NetworkFailure());
        return Right(_withDistance(cached, userLat, userLng));
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, BusinessEntity>> getBusinessDetails(String id) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await _remote.getBusinessDetails(id));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, List<BusinessEntity>>> searchBusinesses(String query) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await _remote.searchBusinesses(query));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> submitBusiness(BusinessEntity business) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final BusinessModel model = BusinessModel(
        id: business.id, ownerId: business.ownerId, name: business.name,
        description: business.description, category: business.category,
        address: business.address, latitude: business.latitude, longitude: business.longitude,
        status: business.status, phone: business.phone, logoUrl: business.logoUrl,
        openingHours: business.openingHours, tags: business.tags,
      );
      await _remote.submitBusiness(model);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, List<BusinessEntity>>> getMyBusinesses(String ownerId) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await _remote.getMyBusinesses(ownerId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
