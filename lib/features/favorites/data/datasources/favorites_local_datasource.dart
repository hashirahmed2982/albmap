import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../../core/error/exceptions.dart';
import '../../../map/data/models/business_model.dart';
import '../../../events/data/models/event_model.dart';

abstract class FavoritesLocalDataSource {
  Future<void> toggleBusiness(BusinessModel business);
  Future<void> toggleEvent(EventModel event);
  Future<List<BusinessModel>> getFavoriteBusinesses();
  Future<List<EventModel>> getFavoriteEvents();
  Future<bool> isBusinessFavorite(String businessId);
  Future<bool> isEventFavorite(String eventId);
}

class FavoritesLocalDataSourceImpl implements FavoritesLocalDataSource {
  FavoritesLocalDataSourceImpl(this._box);
  final Box<String> _box;

  static const String _businessKey = 'favorite_businesses';
  static const String _eventKey = 'favorite_events';

  @override
  Future<void> toggleBusiness(BusinessModel business) async {
    try {
      final List<BusinessModel> current = await getFavoriteBusinesses();
      final bool exists = current.any((BusinessModel b) => b.id == business.id);
      final List<BusinessModel> updated = exists
          ? (current..removeWhere((BusinessModel b) => b.id == business.id))
          : (current..add(business));
      await _box.put(
        _businessKey,
        jsonEncode(updated.map((BusinessModel b) => b.toJson()).toList()),
      );
    } catch (_) {
      throw CacheException('Failed to update favorite business');
    }
  }

  @override
  Future<void> toggleEvent(EventModel event) async {
    try {
      final List<EventModel> current = await getFavoriteEvents();
      final bool exists = current.any((EventModel e) => e.id == event.id);
      final List<EventModel> updated = exists
          ? (current..removeWhere((EventModel e) => e.id == event.id))
          : (current..add(event));
      await _box.put(
        _eventKey,
        jsonEncode(updated.map((EventModel e) => e.toJson()).toList()),
      );
    } catch (_) {
      throw CacheException('Failed to update favorite event');
    }
  }

  @override
  Future<List<BusinessModel>> getFavoriteBusinesses() async {
    final String? raw = _box.get(_businessKey);
    if (raw == null) return <BusinessModel>[];
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((dynamic e) => BusinessModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<EventModel>> getFavoriteEvents() async {
    final String? raw = _box.get(_eventKey);
    if (raw == null) return <EventModel>[];
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((dynamic e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<bool> isBusinessFavorite(String businessId) async {
    final List<BusinessModel> favorites = await getFavoriteBusinesses();
    return favorites.any((BusinessModel b) => b.id == businessId);
  }

  @override
  Future<bool> isEventFavorite(String eventId) async {
    final List<EventModel> favorites = await getFavoriteEvents();
    return favorites.any((EventModel e) => e.id == eventId);
  }
}
