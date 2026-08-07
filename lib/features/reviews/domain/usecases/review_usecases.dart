import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/review_entity.dart';
import '../repositories/review_repository.dart';

class GetBusinessReviewsUseCase implements UseCase<List<ReviewEntity>, String> {
  GetBusinessReviewsUseCase(this._repository);
  final ReviewRepository _repository;

  @override
  Future<Either<Failure, List<ReviewEntity>>> call(String businessId) {
    return _repository.getBusinessReviews(businessId);
  }
}

class SubmitReviewParams extends Equatable {
  const SubmitReviewParams({required this.businessId, required this.rating, this.comment});
  final String businessId;
  final int rating;
  final String? comment;

  @override
  List<Object?> get props => [businessId, rating, comment];
}

class SubmitReviewUseCase implements UseCase<ReviewEntity, SubmitReviewParams> {
  SubmitReviewUseCase(this._repository);
  final ReviewRepository _repository;

  @override
  Future<Either<Failure, ReviewEntity>> call(SubmitReviewParams params) {
    return _repository.submitReview(params.businessId, rating: params.rating, comment: params.comment);
  }
}

class DeleteReviewUseCase implements UseCase<void, String> {
  DeleteReviewUseCase(this._repository);
  final ReviewRepository _repository;

  @override
  Future<Either<Failure, void>> call(String businessId) {
    return _repository.deleteReview(businessId);
  }
}
