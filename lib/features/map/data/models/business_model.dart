import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/business_entity.dart';

class BusinessModel extends BusinessEntity {
  const BusinessModel({
    required super.id,
    required super.ownerId,
    required super.name,
    required super.description,
    required super.category,
    required super.streetAddress,
    required super.city,
    required super.postalCode,
    required super.latitude,
    required super.longitude,
    required super.status,
    super.country,
    super.phone,
    super.whatsappNumber,
    super.logoUrl,
    super.openingHours,
    super.tags,
    super.rating,
    super.distanceKm,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Other',
      streetAddress: json['streetAddress'] as String? ?? '',
      city: json['city'] as String? ?? '',
      postalCode: json['postalCode'] as String? ?? '',
      country: json['country'] as String? ?? 'Albania',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: BusinessStatus.values.firstWhere(
        (BusinessStatus s) => s.name == (json['status'] as String? ?? 'pending'),
        orElse: () => BusinessStatus.pending,
      ),
      phone: json['phone'] as String?,
      whatsappNumber: json['whatsappNumber'] as String?,
      logoUrl: json['logoUrl'] as String?,
      openingHours: (json['openingHours'] as Map<String, dynamic>?)
              ?.map((String k, dynamic v) => MapEntry(k, v as String)) ??
          const <String, String>{},
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const <String>[],
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id, 'ownerId': ownerId, 'name': name, 'description': description,
      'category': category, 'streetAddress': streetAddress, 'city': city,
      'postalCode': postalCode, 'country': country, 'latitude': latitude,
      'longitude': longitude, 'status': status.name, 'phone': phone,
      'whatsappNumber': whatsappNumber,
      'logoUrl': logoUrl, 'openingHours': openingHours, 'tags': tags, 'rating': rating,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'name': name, 'description': description, 'category': category,
      'streetAddress': streetAddress, 'city': city, 'postalCode': postalCode, 'country': country,
      'latitude': latitude, 'longitude': longitude,
      'phone': phone, 'whatsappNumber': whatsappNumber, 'logoUrl': logoUrl,
      'openingHours': openingHours, 'tags': tags,
    };
  }
}
