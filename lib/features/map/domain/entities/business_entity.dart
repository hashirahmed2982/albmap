import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

class BusinessEntity extends Equatable {
  const BusinessEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.category,
    required this.streetAddress,
    required this.city,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.country = 'Albania',
    this.phone,
    this.whatsappNumber,
    this.logoUrl,
    this.openingHours = const <String, String>{},
    this.tags = const <String>[],
    this.rating,
    this.ratingCount = 0,
    this.distanceKm,
  });

  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String category;
  final String streetAddress;
  final String city;
  final String postalCode;
  final String country;
  final double latitude;
  final double longitude;
  final BusinessStatus status;
  final String? phone;
  final String? whatsappNumber;
  final String? logoUrl;
  final Map<String, String> openingHours;
  final List<String> tags;
  final double? rating;
  final int ratingCount;
  final double? distanceKm;

  /// Single display-friendly line — "Street, Postal Code City, Country" —
  /// for anywhere the UI wants one line rather than four separate fields
  /// (map marker sheets, list cards, share text). The backend computes
  /// the same thing server-side as `formattedAddress`; this client-side
  /// version exists for mock-mode data, which never round-trips through
  /// the backend's formatter.
  String get formattedAddress {
    final parts = [streetAddress, '$postalCode $city'.trim(), country]
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  BusinessEntity copyWith({double? distanceKm}) {
    return BusinessEntity(
      id: id,
      ownerId: ownerId,
      name: name,
      description: description,
      category: category,
      streetAddress: streetAddress,
      city: city,
      postalCode: postalCode,
      country: country,
      latitude: latitude,
      longitude: longitude,
      status: status,
      phone: phone,
      whatsappNumber: whatsappNumber,
      logoUrl: logoUrl,
      openingHours: openingHours,
      tags: tags,
      rating: rating,
      ratingCount: ratingCount,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id, ownerId, name, description, category, streetAddress, city, postalCode, country,
        latitude, longitude, status, phone, whatsappNumber, logoUrl, openingHours, tags, rating,
        ratingCount, distanceKm,
      ];
}
