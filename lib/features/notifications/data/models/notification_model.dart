import '../../../events/data/models/event_model.dart' show parseServerDateTime;
import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.createdAt,
    super.isRead,
    super.type,
    super.relatedId,
    super.businessName,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: parseServerDateTime(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      type: json['type'] as String? ?? 'general',
      relatedId: json['relatedId'] as String?,
      businessName: json['businessName'] as String?,
    );
  }
}
