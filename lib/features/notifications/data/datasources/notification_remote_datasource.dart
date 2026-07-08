import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';

abstract class NotificationRemoteDataSource {
  Future<void> broadcastFromBusiness({
    required String businessId,
    required String title,
    required String body,
  });
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<void> broadcastFromBusiness({
    required String businessId,
    required String title,
    required String body,
  }) async {
    try {
      // Matches the backend's POST /businesses/:id/broadcast exactly (see
      // albmap-backend/src/modules/notifications/notification.routes.js).
      await _dio.post<dynamic>(
        '/businesses/$businessId/broadcast',
        data: <String, String>{'title': title, 'body': body},
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Failed to send notification',
        e.response?.statusCode,
      );
    }
  }
}
