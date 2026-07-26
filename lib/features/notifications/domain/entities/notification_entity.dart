import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.type = 'general',
    this.relatedId,
    this.businessName,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String type; // business_offer, business_approved, business_rejected, event_reminder, general
  final String? relatedId;
  final String? businessName;

  NotificationEntity copyWith({bool? isRead}) {
    return NotificationEntity(
      id: id, title: title, body: body, createdAt: createdAt,
      isRead: isRead ?? this.isRead, type: type, relatedId: relatedId, businessName: businessName,
    );
  }

  @override
  List<Object?> get props => [id, title, body, createdAt, isRead, type, relatedId, businessName];
}
