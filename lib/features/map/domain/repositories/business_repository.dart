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

  /// Returns the created business (previously returned void) — the caller
  /// needs the assigned id/status back, and callers that hit a duplicate
  /// warning need to resubmit with confirmDuplicate: true to proceed.
  Future<Either<Failure, BusinessEntity>> submitBusiness(
    BusinessEntity business, {
    bool confirmDuplicate = false,
  });

  /// Owner-only edit of an existing business. Editing a sensitive field
  /// (name/category/address/coordinates) on an approved listing sends it
  /// back to 'pending' server-side — see business.service.js's
  /// SENSITIVE_FIELDS logic, mirrored client-side in EditBusinessScreen so
  /// the user is warned before submitting, not just after.
  Future<Either<Failure, BusinessEntity>> updateBusiness(
    String businessId, {
    String? name,
    String? description,
    String? category,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    Map<String, String>? openingHours,
  });

  /// Returns every business owned by [ownerId] regardless of approval
  /// status (pending/approved/rejected) — unlike [getBusinesses], which
  /// only ever returns approved listings for public discovery. Used by
  /// "My Businesses" so an owner can see their pending/rejected submissions.
  Future<Either<Failure, List<BusinessEntity>>> getMyBusinesses(String ownerId);

  /// Returns the hosted URL of the uploaded image — the caller then
  /// includes it as `logoUrl` in submitBusiness/updateBusiness.
  Future<Either<Failure, String>> uploadLogo(String filePath);
}
