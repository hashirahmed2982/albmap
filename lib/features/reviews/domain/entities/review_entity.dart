import 'package:equatable/equatable.dart';

class ReviewEntity extends Equatable {
  const ReviewEntity({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.rating,
    required this.createdAt,
    this.userName,
    this.comment,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final String userId;
  final String? userName;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props =>
      <Object?>[id, businessId, userId, userName, rating, comment, createdAt, updatedAt];
}
