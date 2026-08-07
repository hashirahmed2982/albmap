import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';

class NotificationFeed extends Equatable {
  const NotificationFeed({required this.notifications, required this.unreadCount});
  final List<NotificationEntity> notifications;
  final int unreadCount;

  @override
  List<Object?> get props => [notifications, unreadCount];
}

abstract class NotificationRepository {
  /// Submits a broadcast for admin review — returns 'pending', not
  /// delivered. Nothing reaches any device until an admin approves it in
  /// the admin portal.
  Future<Either<Failure, String>> submitBroadcast({
    required String businessId,
    required String title,
    required String body,
  });

  /// Every approved notification visible to the current user.
  Future<Either<Failure, NotificationFeed>> getFeed();

  Future<Either<Failure, void>> markAsRead(String notificationId);
  Future<Either<Failure, void>> markAllAsRead();

  /// Hides this notification from the current user's feed only — it's a
  /// shared row (a broadcast is the same row every recipient sees), so
  /// this can never delete it for anyone else.
  Future<Either<Failure, void>> deleteNotification(String notificationId);

  /// "Clear all" — hides every notification currently in the feed.
  Future<Either<Failure, void>> deleteAllNotifications();
}
