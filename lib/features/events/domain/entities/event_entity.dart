import 'package:equatable/equatable.dart';

class EventEntity extends Equatable {
  const EventEntity({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.name,
    required this.description,
    required this.category,
    required this.startTime,
    required this.endTime,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.address,
    this.interestCount = 0,
    this.isInterested = false,
  });

  final String id;
  final String businessId;
  final String businessName;
  final String name;
  final String description;
  final String category;
  final DateTime startTime;
  final DateTime endTime;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String? address;

  /// How many users have marked "I'm interested" / RSVP'd — only
  /// meaningful when this came from an endpoint that joins
  /// event_interests (GET /events, GET /events/:id); other sources (event
  /// creation echo, local favorites cache) default this to 0.
  final int interestCount;

  /// Whether the *current* signed-in user has marked interest — false for
  /// a guest/anonymous caller, same caveat as [interestCount] above.
  final bool isInterested;

  bool get isUpcoming => startTime.isAfter(DateTime.now());
  bool get isOngoing =>
      DateTime.now().isAfter(startTime) && DateTime.now().isBefore(endTime);

  @override
  List<Object?> get props => <Object?>[
        id, businessId, businessName, name, description, category,
        startTime, endTime, imageUrl, latitude, longitude, address,
        interestCount, isInterested,
      ];
}
