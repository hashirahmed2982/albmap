import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/notification_model.dart';

class BroadcastSubmissionResult {
  const BroadcastSubmissionResult({required this.id, required this.status});
  final String id;
  final String status; // always 'pending' on submission — see backend notification.service.js
}

class NotificationFeedResult {
  const NotificationFeedResult({required this.notifications, required this.unreadCount});
  final List<NotificationModel> notifications;
  final int unreadCount;
}

abstract class NotificationRemoteDataSource {
  /// Submits a broadcast for admin review — no longer delivers
  /// immediately. Nothing is sent to anyone until an admin approves it in
  /// the admin portal (see backend's notification.service.js
  /// submitBroadcast()).
  Future<BroadcastSubmissionResult> submitBroadcast({
    required String businessId,
    required String title,
    required String body,
  });

  /// Every approved notification visible to the current user — global
  /// broadcasts plus that user's own personal notices (e.g. "your
  /// business was approved"). Replaces the old purely-local, device-only
  /// notification list.
  Future<NotificationFeedResult> getFeed();

  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<BroadcastSubmissionResult> submitBroadcast({
    required String businessId,
    required String title,
    required String body,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/businesses/$businessId/broadcast',
        data: <String, String>{'title': title, 'body': body},
      );
      final data = response.data as Map<String, dynamic>;
      return BroadcastSubmissionResult(id: data['id'] as String, status: data['status'] as String);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Failed to submit notification',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<NotificationFeedResult> getFeed() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>('/notifications');
      final data = response.data as Map<String, dynamic>;
      final notifications = (data['data'] as List<dynamic>)
          .map((dynamic e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return NotificationFeedResult(notifications: notifications, unreadCount: data['unreadCount'] as int);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Failed to load notifications',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _dio.post<dynamic>('/notifications/$notificationId/read');
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] as String? ?? 'Failed to mark as read');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _dio.post<dynamic>('/notifications/read-all');
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] as String? ?? 'Failed to mark all as read');
    }
  }
}
