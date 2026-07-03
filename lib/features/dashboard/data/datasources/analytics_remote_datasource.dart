import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/business_analytics_entity.dart';

abstract class AnalyticsDataSource {
  Future<BusinessAnalyticsEntity> getBusinessAnalytics(String businessId);
  Future<void> recordEvent(String businessId, AnalyticsEventType type);
}

class AnalyticsRemoteDataSourceImpl implements AnalyticsDataSource {
  AnalyticsRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<BusinessAnalyticsEntity> getBusinessAnalytics(String businessId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>('/businesses/$businessId/analytics');
      final Map<String, dynamic> json = response.data as Map<String, dynamic>;
      return BusinessAnalyticsEntity(
        businessId: businessId,
        profileClicks: json['profileClicks'] as int? ?? 0,
        websiteClicks: json['websiteClicks'] as int? ?? 0,
        callClicks: json['callClicks'] as int? ?? 0,
        favoriteCount: json['favoriteCount'] as int? ?? 0,
        last7DaysProfileClicks:
            (json['last7DaysProfileClicks'] as List<dynamic>?)?.cast<int>() ?? const [],
      );
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] as String? ?? 'Failed to load analytics');
    }
  }

  @override
  Future<void> recordEvent(String businessId, AnalyticsEventType type) async {
    try {
      await _dio.post<dynamic>(
        '/businesses/$businessId/analytics/event',
        data: <String, String>{'type': type.name},
      );
    } on DioException {
      // Analytics recording is best-effort — never surface this failure to
      // the visitor viewing the business, it's not their problem.
    }
  }
}
