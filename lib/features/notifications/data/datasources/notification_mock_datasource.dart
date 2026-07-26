import '../models/notification_model.dart';
import 'notification_remote_datasource.dart';

/// Mock mode has no admin portal to approve anything against, so this
/// simulates the whole pipeline locally: submitting a broadcast adds it
/// directly to the feed as already "approved" (skipping the review wait,
/// since there's no reviewer to wait on) and read-state is tracked
/// in-memory for the session.
class NotificationMockDataSource implements NotificationRemoteDataSource {
  static final List<NotificationModel> _feed = [
    NotificationModel(
      id: 'notif-1',
      title: 'Welcome to AlbMap!',
      body: 'Discover great local businesses and events near you.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      type: 'general',
    ),
    NotificationModel(
      id: 'notif-2',
      title: 'Your business was approved! 🎉',
      body: 'Espresso Corner is now live on AlbMap and visible to everyone.',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      type: 'business_approved',
      businessName: 'Espresso Corner',
    ),
  ];

  Future<void> _fakeDelay() => Future<void>.delayed(const Duration(milliseconds: 300));

  @override
  Future<BroadcastSubmissionResult> submitBroadcast({
    required String businessId,
    required String title,
    required String body,
  }) async {
    await _fakeDelay();
    final id = 'notif-${DateTime.now().microsecondsSinceEpoch}';
    _feed.insert(
      0,
      NotificationModel(
        id: id,
        title: title,
        body: body,
        createdAt: DateTime.now(),
        type: 'business_offer',
      ),
    );
    return BroadcastSubmissionResult(id: id, status: 'approved');
  }

  @override
  Future<NotificationFeedResult> getFeed() async {
    await _fakeDelay();
    return NotificationFeedResult(
      notifications: List.of(_feed),
      unreadCount: _feed.where((n) => !n.isRead).length,
    );
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _fakeDelay();
    final index = _feed.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final n = _feed[index];
      _feed[index] = NotificationModel(
        id: n.id, title: n.title, body: n.body, createdAt: n.createdAt,
        isRead: true, type: n.type, relatedId: n.relatedId, businessName: n.businessName,
      );
    }
  }

  @override
  Future<void> markAllAsRead() async {
    await _fakeDelay();
    for (var i = 0; i < _feed.length; i++) {
      final n = _feed[i];
      _feed[i] = NotificationModel(
        id: n.id, title: n.title, body: n.body, createdAt: n.createdAt,
        isRead: true, type: n.type, relatedId: n.relatedId, businessName: n.businessName,
      );
    }
  }
}
