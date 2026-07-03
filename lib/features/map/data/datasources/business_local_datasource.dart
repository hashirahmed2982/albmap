import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../../core/error/exceptions.dart';
import '../models/business_model.dart';

abstract class BusinessLocalDataSource {
  Future<void> cacheBusinesses(List<BusinessModel> businesses);
  Future<List<BusinessModel>> getCachedBusinesses();
}

class BusinessLocalDataSourceImpl implements BusinessLocalDataSource {
  BusinessLocalDataSourceImpl(this._box);
  final Box<String> _box;
  static const String _key = 'cached_businesses';

  @override
  Future<void> cacheBusinesses(List<BusinessModel> businesses) async {
    try {
      final List<Map<String, dynamic>> json =
          businesses.map((BusinessModel b) => b.toJson()).toList();
      await _box.put(_key, jsonEncode(json));
    } catch (_) {
      throw CacheException('Failed to cache businesses');
    }
  }

  @override
  Future<List<BusinessModel>> getCachedBusinesses() async {
    final String? raw = _box.get(_key);
    if (raw == null) return <BusinessModel>[];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((dynamic e) => BusinessModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw CacheException('Failed to parse cached businesses');
    }
  }
}
