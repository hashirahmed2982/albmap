import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/business_entity.dart';

abstract class BusinessRepository {
  Future<Either<Failure, List<BusinessEntity>>> getBusinesses({
    String? category,
    double? radiusKm,
    double? userLat,
    double? userLng,
    String sortBy = 'distance',
  });

  Future<Either<Failure, BusinessEntity>> getBusinessDetails(String id);

  Future<Either<Failure, List<BusinessEntity>>> searchBusinesses(String query);

  Future<Either<Failure, void>> submitBusiness(BusinessEntity business);

  /// Returns every business owned by [ownerId] regardless of approval
  /// status (pending/approved/rejected) — unlike [getBusinesses], which
  /// only ever returns approved listings for public discovery. Used by
  /// "My Businesses" so an owner can see their pending/rejected submissions.
  Future<Either<Failure, List<BusinessEntity>>> getMyBusinesses(String ownerId);
}
