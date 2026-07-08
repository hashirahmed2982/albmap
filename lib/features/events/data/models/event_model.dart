import '../../domain/entities/event_entity.dart';

/// Backend (MySQL, dateStrings:true) returns "YYYY-MM-DD HH:MM:SS" with no
/// timezone marker. The server always stores/compares these in UTC (see
/// the backend's event.service.js toMysqlDatetime()), so a marker-less
/// string here means UTC — but Dart's DateTime.parse() treats a
/// marker-less string as LOCAL time, silently shifting every event's
/// displayed time by the device's UTC offset. This appends 'Z' explicitly
/// unless the string already carries a zone marker (covers plain ISO 8601
/// strings too, so this stays safe for any future data source), then
/// converts to the device's local time zone — every screen that formats
/// event times (EventListTile, EventDetailsScreen) expects a local
/// DateTime to display the correct wall-clock time to the user, not the
/// raw UTC value.
DateTime parseServerDateTime(String value) {
  final hasZoneMarker = value.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(value);
  final utcValue = DateTime.parse(hasZoneMarker ? value : '${value}Z');
  return utcValue.toLocal();
}

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
      startTime: parseServerDateTime(json['startTime'] as String),
      endTime: parseServerDateTime(json['endTime'] as String),
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
