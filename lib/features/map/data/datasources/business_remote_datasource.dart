import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/business_model.dart';

abstract class BusinessRemoteDataSource {
  Future<List<BusinessModel>> getBusinesses({
    String? category,
    double? radiusKm,
    double? userLat,
    double? userLng,
    String sortBy = 'distance',
  });

  Future<BusinessModel> getBusinessDetails(String id);
  Future<List<BusinessModel>> searchBusinesses(String query);
  Future<void> submitBusiness(BusinessModel business);
  Future<List<BusinessModel>> getMyBusinesses(String ownerId);
}

class BusinessRemoteDataSourceImpl implements BusinessRemoteDataSource {
  BusinessRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<BusinessModel>> getBusinesses({
    String? category,
    double? radiusKm,
    double? userLat,
    double? userLng,
    String sortBy = 'distance',
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/businesses',
        queryParameters: <String, dynamic>{
          if (category != null) 'category': category,
          if (radiusKm != null) 'radiusKm': radiusKm,
          if (userLat != null) 'lat': userLat,
          if (userLng != null) 'lng': userLng,
          'sortBy': sortBy,
          'status': 'approved',
        },
      );
      return (response.data['data'] as List<dynamic>)
          .map((dynamic e) => BusinessModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Failed to load businesses',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<BusinessModel> getBusinessDetails(String id) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>('/businesses/$id');
      return BusinessModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Failed to load business',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<BusinessModel>> searchBusinesses(String query) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/businesses/search',
        queryParameters: <String, dynamic>{'q': query},
      );
      return (response.data['data'] as List<dynamic>)
          .map((dynamic e) => BusinessModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] as String? ?? 'Search failed');
    }
  }

  @override
  Future<void> submitBusiness(BusinessModel business) async {
    try {
      await _dio.post<dynamic>('/businesses', data: business.toCreateJson());
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Failed to submit business',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<BusinessModel>> getMyBusinesses(String ownerId) async {
    try {
      // No status filter here — the owner needs to see pending/rejected
      // submissions too, unlike the public getBusinesses() endpoint.
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/businesses',
        queryParameters: <String, dynamic>{'ownerId': ownerId},
      );
      return (response.data['data'] as List<dynamic>)
          .map((dynamic e) => BusinessModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Failed to load your businesses',
        e.response?.statusCode,
      );
    }
  }
}
