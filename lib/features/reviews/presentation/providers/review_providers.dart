import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/usecases/review_usecases.dart';

final businessReviewsProvider =
    FutureProvider.autoDispose.family<List<ReviewEntity>, String>((ref, businessId) async {
  final useCase = sl<GetBusinessReviewsUseCase>();
  final result = await useCase(businessId);
  return result.fold((_) => <ReviewEntity>[], (list) => list);
});

class ReviewController extends StateNotifier<AsyncValue<void>> {
  ReviewController() : super(const AsyncValue.data(null));

  /// Returns null on success (matching AuthController's
  /// changePassword/deleteAccount contract), or an error message on
  /// failure for the caller to toast.
  Future<String?> submit({required String businessId, required int rating, String? comment}) async {
    state = const AsyncValue.loading();
    final useCase = sl<SubmitReviewUseCase>();
    final result = await useCase(
      SubmitReviewParams(businessId: businessId, rating: rating, comment: comment),
    );
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return failure.message;
      },
      (_) {
        state = const AsyncValue.data(null);
        return null;
      },
    );
  }

  Future<String?> delete(String businessId) async {
    state = const AsyncValue.loading();
    final useCase = sl<DeleteReviewUseCase>();
    final result = await useCase(businessId);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return failure.message;
      },
      (_) {
        state = const AsyncValue.data(null);
        return null;
      },
    );
  }
}

final reviewControllerProvider =
    StateNotifierProvider.autoDispose<ReviewController, AsyncValue<void>>(
  (ref) => ReviewController(),
);
