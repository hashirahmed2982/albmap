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
  Future<BusinessModel> submitBusiness(BusinessModel business, {bool confirmDuplicate});
  Future<BusinessModel> updateBusiness(String businessId, Map<String, dynamic> changes);
  Future<List<BusinessModel>> getMyBusinesses(String ownerId);
  Future<String> uploadLogo(String filePath);
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
          // The backend defaults to a 20-row page when this is omitted
          // (see business.service.js's DEFAULT_PAGE_SIZE) — fine for a
          // radius-limited local search, but with no radius filter (the
          // default — see BusinessFilter.radiusKm) discovery is meant to
          // show every business worldwide, so ask for its max page size
          // instead of silently truncating to the first 20 rows returned.
          'limit': 100,
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
  Future<BusinessModel> submitBusiness(BusinessModel business, {bool confirmDuplicate = false}) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/businesses',
        data: <String, dynamic>{
          ...business.toCreateJson(),
          if (confirmDuplicate) 'confirmDuplicate': true,
        },
      );
      return BusinessModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // A 409 with a `duplicate` field is a structured warning, not a
      // generic failure — surface it so the UI can offer "submit anyway"
      // with the specific conflicting business's details, rather than
      // just showing a plain error string.
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Failed to submit business',
        e.response?.statusCode,
        e.response?.data?['duplicate'] as Map<String, dynamic>?,
      );
    }
  }

  @override
  Future<BusinessModel> updateBusiness(String businessId, Map<String, dynamic> changes) async {
    try {
      final Response<dynamic> response = await _dio.patch<dynamic>(
        '/businesses/$businessId',
        data: changes,
      );
      return BusinessModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Failed to update business',
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

  @override
  Future<String> uploadLogo(String filePath) async {
    try {
      final formData = FormData.fromMap(<String, dynamic>{
        'logo': await MultipartFile.fromFile(filePath),
      });
      final Response<dynamic> response = await _dio.post<dynamic>('/businesses/logo', data: formData);
      return response.data['url'] as String;
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Failed to upload logo',
        e.response?.statusCode,
      );
    }
  }
}
