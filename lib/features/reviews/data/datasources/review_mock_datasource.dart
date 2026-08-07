import '../models/review_model.dart';
import 'review_remote_datasource.dart';

/// In-memory fake reviews, tied to the fake business IDs in
/// business_mock_datasource.dart (biz-1, biz-2, ...) and the fake signed-in
/// user in auth_mock_datasource.dart (business-user-001), so "delete my
/// review" / "edit my review" behave correctly against the seeded data.
class ReviewMockDataSource implements ReviewRemoteDataSource {
  static const String _mockUserId = 'business-user-001';

  static final List<ReviewModel> _reviews = [
    ReviewModel(
      id: 'rev-1', businessId: 'biz-1', userId: 'user-demo-1', userName: 'Elira K.',
      rating: 5, comment: 'Best espresso in Tirana, hands down.',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    ReviewModel(
      id: 'rev-2', businessId: 'biz-1', userId: 'user-demo-2', userName: 'Marco P.',
      rating: 4, comment: 'Great atmosphere, a bit pricey.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ReviewModel(
      id: 'rev-3', businessId: 'biz-2', userId: 'user-demo-3', userName: 'Ana D.',
      rating: 5, comment: 'Authentic Napoli-style pizza, loved it!',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  Future<void> _fakeDelay() => Future<void>.delayed(const Duration(milliseconds: 400));

  @override
  Future<List<ReviewModel>> getBusinessReviews(String businessId) async {
    await _fakeDelay();
    return _reviews.where((r) => r.businessId == businessId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<ReviewModel> submitReview(String businessId, {required int rating, String? comment}) async {
    await _fakeDelay();
    final int existingIndex =
        _reviews.indexWhere((r) => r.businessId == businessId && r.userId == _mockUserId);
    final ReviewModel review = ReviewModel(
      id: existingIndex != -1 ? _reviews[existingIndex].id : 'rev-${DateTime.now().millisecondsSinceEpoch}',
      businessId: businessId,
      userId: _mockUserId,
      userName: 'Demo Business',
      rating: rating,
      comment: comment,
      createdAt: existingIndex != -1 ? _reviews[existingIndex].createdAt : DateTime.now(),
      updatedAt: existingIndex != -1 ? DateTime.now() : null,
    );
    if (existingIndex != -1) {
      _reviews[existingIndex] = review;
    } else {
      _reviews.add(review);
    }
    return review;
  }

  @override
  Future<void> deleteReview(String businessId) async {
    await _fakeDelay();
    _reviews.removeWhere((r) => r.businessId == businessId && r.userId == _mockUserId);
  }
}
