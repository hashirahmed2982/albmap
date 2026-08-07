import '../../../events/data/models/event_model.dart' show parseServerDateTime;
import '../../domain/entities/review_entity.dart';

class ReviewModel extends ReviewEntity {
  const ReviewModel({
    required super.id,
    required super.businessId,
    required super.userId,
    required super.rating,
    required super.createdAt,
    super.userName,
    super.comment,
    super.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String?,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      createdAt: parseServerDateTime(json['createdAt'] as String),
      updatedAt:
          json['updatedAt'] != null ? parseServerDateTime(json['updatedAt'] as String) : null,
    );
  }
}
