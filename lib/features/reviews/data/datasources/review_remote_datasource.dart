import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/review_model.dart';

/// Backend endpoints (see the backend's review.routes.js, mounted at
/// /businesses/:id/reviews): one review per user per business — POST is
/// create-or-update (submitting again edits your existing review rather
/// than erroring), and DELETE removes the *caller's own* review, there's
/// no id in the delete path.
abstract class ReviewRemoteDataSource {
  Future<List<ReviewModel>> getBusinessReviews(String businessId);
  Future<ReviewModel> submitReview(String businessId, {required int rating, String? comment});
  Future<void> deleteReview(String businessId);
}

class ReviewRemoteDataSourceImpl implements ReviewRemoteDataSource {
  ReviewRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<ReviewModel>> getBusinessReviews(String businessId) async {
    try {
      final Response<dynamic> response =
          await _dio.get<dynamic>('/businesses/$businessId/reviews');
      return (response.data['data'] as List<dynamic>)
          .map((dynamic e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] as String? ?? 'Failed to load reviews');
    }
  }

  @override
  Future<ReviewModel> submitReview(String businessId, {required int rating, String? comment}) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/businesses/$businessId/reviews',
        data: <String, dynamic>{'rating': rating, if (comment != null) 'comment': comment},
      );
      return ReviewModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] as String? ?? 'Failed to submit review');
    }
  }

  @override
  Future<void> deleteReview(String businessId) async {
    try {
      await _dio.delete<dynamic>('/businesses/$businessId/reviews');
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] as String? ?? 'Failed to delete review');
    }
  }
}
