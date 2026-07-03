import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

class BusinessEntity extends Equatable {
  const BusinessEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.phone,
    this.logoUrl,
    this.openingHours = const <String, String>{},
    this.tags = const <String>[],
    this.rating,
    this.distanceKm,
  });

  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String category;
  final String address;
  final double latitude;
  final double longitude;
  final BusinessStatus status;
  final String? phone;
  final String? logoUrl;
  final Map<String, String> openingHours;
  final List<String> tags;
  final double? rating;
  final double? distanceKm;

  BusinessEntity copyWith({double? distanceKm}) {
    return BusinessEntity(
      id: id,
      ownerId: ownerId,
      name: name,
      description: description,
      category: category,
      address: address,
      latitude: latitude,
      longitude: longitude,
      status: status,
      phone: phone,
      logoUrl: logoUrl,
      openingHours: openingHours,
      tags: tags,
      rating: rating,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id, ownerId, name, description, category, address, latitude, longitude,
        status, phone, logoUrl, openingHours, tags, rating, distanceKm,
      ];
}
