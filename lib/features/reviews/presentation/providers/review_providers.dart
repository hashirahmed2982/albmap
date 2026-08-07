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

// Deliberately NOT autoDispose (matches favoriteToggleControllerProvider) —
// every call site only ever does `ref.read(...).submit(...)`/`.delete(...)`,
// never `ref.watch`s this provider, so an autoDispose version had zero
// listeners keeping it alive and could get torn down mid-flight: the
// controller's `state = ...` after the awaited network call would throw
// "Tried to use ReviewController after `dispose` was called" once the
// review had actually already been created/deleted server-side — leaving
// the caller's `await submit(...)` never completing (so its loading
// spinner never cleared) even though the write had succeeded.
final reviewControllerProvider = StateNotifierProvider<ReviewController, AsyncValue<void>>(
  (ref) => ReviewController(),
);
