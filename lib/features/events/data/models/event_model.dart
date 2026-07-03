import '../../domain/entities/event_entity.dart';

class EventModel extends EventEntity {
  const EventModel({
    required super.id,
    required super.businessId,
    required super.businessName,
    required super.name,
    required super.description,
    required super.category,
    required super.startTime,
    required super.endTime,
    super.imageUrl,
    super.latitude,
    super.longitude,
    super.address,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      businessName: json['businessName'] as String? ?? '',
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      imageUrl: json['imageUrl'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'businessId': businessId,
      'name': name,
      'description': description,
      'category': category,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }
}
