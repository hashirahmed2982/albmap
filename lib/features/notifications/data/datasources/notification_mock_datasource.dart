import 'notification_remote_datasource.dart';

/// Mock mode has no server to fan out a real push notification, so this
/// just succeeds immediately — the caller (SendBusinessNotificationController)
/// separately inserts the notification into the local NotificationsController
/// for UI feedback, which happens regardless of mock vs real mode.
class NotificationMockDataSource implements NotificationRemoteDataSource {
  @override
  Future<void> broadcastFromBusiness({
    required String businessId,
    required String title,
    required String body,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}
