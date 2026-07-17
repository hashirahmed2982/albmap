import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/business_model.dart';
import 'business_remote_datasource.dart';

/// In-memory fake business dataset centered around Tirana, Albania (matches
/// the default map camera position in discover_map_screen.dart). Swap out
/// via [AppConstants.useMockData] in service_locator.dart.
class BusinessMockDataSource implements BusinessRemoteDataSource {
  static final List<BusinessModel> _businesses = [
    const BusinessModel(
      id: 'biz-1', ownerId: 'business-user-001',
      name: 'Espresso Corner', description: 'Cozy specialty coffee shop with fresh pastries daily.',
      category: 'Cafes', address: 'Rruga Myslym Shyri, Tirana',
      latitude: 41.3260, longitude: 19.8172, status: BusinessStatus.approved,
      phone: '+355 69 111 2222', rating: 4.6,
      openingHours: {'Mon-Fri': '07:00-19:00', 'Sat-Sun': '08:00-18:00'},
      tags: ['coffee', 'wifi', 'breakfast'],
    ),
    const BusinessModel(
      id: 'biz-2', ownerId: 'business-user-002',
      name: 'Bella Napoli', description: 'Authentic wood-fired Neapolitan pizza.',
      category: 'Restaurants', address: 'Blloku, Tirana',
      latitude: 41.3230, longitude: 19.8190, status: BusinessStatus.approved,
      phone: '+355 69 222 3333', rating: 4.8,
      openingHours: {'Daily': '12:00-23:00'},
      tags: ['pizza', 'italian', 'family-friendly'],
    ),
    const BusinessModel(
      id: 'biz-3', ownerId: 'business-user-003',
      name: 'Urban Fitness Studio', description: 'Boutique gym offering HIIT, yoga, and personal training.',
      category: 'Health', address: 'Rruga e Kavajës, Tirana',
      latitude: 41.3298, longitude: 19.8100, status: BusinessStatus.approved,
      phone: '+355 69 333 4444', rating: 4.3,
      openingHours: {'Mon-Sat': '06:00-22:00'},
      tags: ['gym', 'yoga', 'personal-training'],
    ),
    const BusinessModel(
      id: 'biz-4', ownerId: 'business-user-004',
      name: 'Green Leaf Market', description: 'Organic grocery store with local produce.',
      category: 'Shops', address: 'Rruga Barrikadave, Tirana',
      latitude: 41.3315, longitude: 19.8220, status: BusinessStatus.approved,
      phone: '+355 69 444 5555', rating: 4.5,
      openingHours: {'Daily': '08:00-21:00'},
      tags: ['organic', 'grocery', 'local'],
    ),
    const BusinessModel(
      id: 'biz-5', ownerId: 'business-user-005',
      name: 'CineStar Multiplex', description: 'Modern cinema with 6 screens and IMAX.',
      category: 'Entertainment', address: 'TEG, Tirana',
      latitude: 41.3025, longitude: 19.8300, status: BusinessStatus.approved,
      phone: '+355 69 555 6666', rating: 4.2,
      openingHours: {'Daily': '10:00-00:00'},
      tags: ['cinema', 'imax', 'family'],
    ),
    const BusinessModel(
      id: 'biz-6', ownerId: 'business-user-001',
      name: 'AutoCare Plus', description: 'Full-service auto repair and maintenance.',
      category: 'Services', address: 'Rruga Dritan Hoxha, Tirana',
      latitude: 41.3180, longitude: 19.8050, status: BusinessStatus.approved,
      phone: '+355 69 666 7777', rating: 4.0,
      openingHours: {'Mon-Sat': '08:00-18:00'},
      tags: ['auto-repair', 'maintenance'],
    ),
    const BusinessModel(
      id: 'biz-7', ownerId: 'business-user-001',
      name: 'Sunset Rooftop Bar', description: 'New rooftop bar with a view over Tirana, awaiting review.',
      category: 'Restaurants', address: 'Skanderbeg Square, Tirana',
      latitude: 41.3287, longitude: 19.8172, status: BusinessStatus.pending,
      phone: '+355 69 777 8888',
      tags: ['bar', 'rooftop', 'new'],
    ),
  ];

  Future<void> _fakeDelay() => Future<void>.delayed(const Duration(milliseconds: 400));

  @override
  Future<List<BusinessModel>> getBusinesses({
    String? category,
    double? radiusKm,
    double? userLat,
    double? userLng,
    String sortBy = 'distance',
  }) async {
    await _fakeDelay();
    Iterable<BusinessModel> results = _businesses.where((b) => b.status == BusinessStatus.approved);
    if (category != null) {
      results = results.where((b) => b.category == category);
    }
    return results.toList();
  }

  @override
  Future<BusinessModel> getBusinessDetails(String id) async {
    await _fakeDelay();
    return _businesses.firstWhere((b) => b.id == id, orElse: () => _businesses.first);
  }

  @override
  Future<List<BusinessModel>> searchBusinesses(String query) async {
    await _fakeDelay();
    final q = query.toLowerCase();
    return _businesses.where((b) => b.name.toLowerCase().contains(q)).toList();
  }

  @override
  Future<BusinessModel> submitBusiness(BusinessModel business, {bool confirmDuplicate = false}) async {
    await _fakeDelay();
    if (!confirmDuplicate) {
      final existingMatch = _businesses.where(
        (b) => b.name.toLowerCase() == business.name.toLowerCase() && b.status != BusinessStatus.rejected,
      );
      if (existingMatch.isNotEmpty) {
        throw ServerException(
          'A business named "${existingMatch.first.name}" already exists nearby. '
          'Submit again to confirm this is a different business.',
          409,
          <String, dynamic>{
            'id': existingMatch.first.id,
            'name': existingMatch.first.name,
            'address': existingMatch.first.address,
            'distanceMeters': 50,
          },
        );
      }
    }
    _businesses.add(business);
    return business;
  }

  @override
  Future<BusinessModel> updateBusiness(String businessId, Map<String, dynamic> changes) async {
    await _fakeDelay();
    final index = _businesses.indexWhere((b) => b.id == businessId);
    if (index == -1) {
      throw ServerException('Business not found', 404);
    }
    final existing = _businesses[index];
    final sensitiveFieldsChanged = (changes['name'] != null && changes['name'] != existing.name) ||
        (changes['category'] != null && changes['category'] != existing.category) ||
        (changes['address'] != null && changes['address'] != existing.address) ||
        (changes['latitude'] != null && changes['latitude'] != existing.latitude) ||
        (changes['longitude'] != null && changes['longitude'] != existing.longitude);

    final updated = BusinessModel(
      id: existing.id,
      ownerId: existing.ownerId,
      name: changes['name'] as String? ?? existing.name,
      description: changes['description'] as String? ?? existing.description,
      category: changes['category'] as String? ?? existing.category,
      address: changes['address'] as String? ?? existing.address,
      latitude: (changes['latitude'] as num?)?.toDouble() ?? existing.latitude,
      longitude: (changes['longitude'] as num?)?.toDouble() ?? existing.longitude,
      status: (existing.status == BusinessStatus.approved && sensitiveFieldsChanged)
          ? BusinessStatus.pending
          : existing.status,
      phone: changes['phone'] as String? ?? existing.phone,
      logoUrl: existing.logoUrl,
      openingHours: (changes['openingHours'] as Map?)?.cast<String, String>() ?? existing.openingHours,
      tags: existing.tags,
      rating: existing.rating,
    );
    _businesses[index] = updated;
    return updated;
  }

  @override
  Future<List<BusinessModel>> getMyBusinesses(String ownerId) async {
    await _fakeDelay();
    return _businesses.where((b) => b.ownerId == ownerId).toList();
  }

  @override
  Future<String> uploadLogo(String filePath) async {
    await _fakeDelay();
    // No real server to host it in mock mode — echo back the local file
    // path so the UI can still display the picked image immediately.
    return filePath;
  }
}
