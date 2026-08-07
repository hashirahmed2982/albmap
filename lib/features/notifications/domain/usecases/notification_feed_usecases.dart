import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/notification_repository.dart';

class GetNotificationFeedUseCase implements UseCase<NotificationFeed, NoParams> {
  GetNotificationFeedUseCase(this._repository);
  final NotificationRepository _repository;

  @override
  Future<Either<Failure, NotificationFeed>> call(NoParams params) {
    return _repository.getFeed();
  }
}

class MarkNotificationReadUseCase implements UseCase<void, String> {
  MarkNotificationReadUseCase(this._repository);
  final NotificationRepository _repository;

  @override
  Future<Either<Failure, void>> call(String notificationId) {
    return _repository.markAsRead(notificationId);
  }
}

class MarkAllNotificationsReadUseCase implements UseCase<void, NoParams> {
  MarkAllNotificationsReadUseCase(this._repository);
  final NotificationRepository _repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return _repository.markAllAsRead();
  }
}

class DeleteNotificationUseCase implements UseCase<void, String> {
  DeleteNotificationUseCase(this._repository);
  final NotificationRepository _repository;

  @override
  Future<Either<Failure, void>> call(String notificationId) {
    return _repository.deleteNotification(notificationId);
  }
}

class ClearAllNotificationsUseCase implements UseCase<void, NoParams> {
  ClearAllNotificationsUseCase(this._repository);
  final NotificationRepository _repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return _repository.deleteAllNotifications();
  }
}
