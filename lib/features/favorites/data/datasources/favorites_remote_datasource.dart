import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../map/data/models/business_model.dart';

/// Backend favorites sync — fixes a real gap: favorites were previously
/// 100% local (Hive), meaning a reinstall or device switch silently lost
/// every favorite, and business_analytics.favorite_count on the owner's
/// Dashboard was permanently stuck at whatever the DB default was. Only
/// covers business favorites (not events) — the backend has no
/// event-favorites table yet; event favorites remain local-only for now.
abstract class FavoritesRemoteDataSource {
  Future<List<BusinessModel>> getFavoriteBusinesses();
  Future<void> addFavorite(String businessId);
  Future<void> removeFavorite(String businessId);
}

class FavoritesRemoteDataSourceImpl implements FavoritesRemoteDataSource {
  FavoritesRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<BusinessModel>> getFavoriteBusinesses() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>('/favorites');
      return (response.data['data'] as List<dynamic>)
          .map((dynamic e) => BusinessModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] as String? ?? 'Failed to load favorites');
    }
  }

  @override
  Future<void> addFavorite(String businessId) async {
    try {
      await _dio.post<dynamic>('/favorites', data: <String, String>{'businessId': businessId});
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] as String? ?? 'Failed to add favorite');
    }
  }

  @override
  Future<void> removeFavorite(String businessId) async {
    try {
      await _dio.delete<dynamic>('/favorites/$businessId');
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] as String? ?? 'Failed to remove favorite');
    }
  }
}
