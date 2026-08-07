import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/review_entity.dart';

abstract class ReviewRepository {
  Future<Either<Failure, List<ReviewEntity>>> getBusinessReviews(String businessId);

  /// Create-or-update: submitting again edits the caller's existing
  /// review for this business (see the backend's review.service.js).
  Future<Either<Failure, ReviewEntity>> submitReview(
    String businessId, {
    required int rating,
    String? comment,
  });

  /// Deletes the *caller's own* review for this business.
  Future<Either<Failure, void>> deleteReview(String businessId);
}
