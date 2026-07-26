import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/notification_feed_usecases.dart';

class NotificationsState {
  const NotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<NotificationEntity> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? errorMessage;

  NotificationsState copyWith({
    List<NotificationEntity>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Server-backed notification feed — replaces the old purely-local
/// (device-only, never synced) Hive-based list. Every approved broadcast
/// and personal notice visible to the current user lives here now,
/// fetched from GET /notifications (see notification.service.js's
/// getFeedForUser on the backend).
class NotificationsController extends StateNotifier<NotificationsState> {
  NotificationsController()
      : _getFeedUseCase = sl<GetNotificationFeedUseCase>(),
        _markReadUseCase = sl<MarkNotificationReadUseCase>(),
        _markAllReadUseCase = sl<MarkAllNotificationsReadUseCase>(),
        super(const NotificationsState()) {
    load();
  }

  final GetNotificationFeedUseCase _getFeedUseCase;
  final MarkNotificationReadUseCase _markReadUseCase;
  final MarkAllNotificationsReadUseCase _markAllReadUseCase;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getFeedUseCase(const NoParams());
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (feed) => state = NotificationsState(
        notifications: feed.notifications,
        unreadCount: feed.unreadCount,
        isLoading: false,
      ),
    );
  }

  Future<void> markAsRead(String id) async {
    // Optimistic update — the UI reflects "read" immediately rather than
    // waiting on the round-trip; load() will correct it on the next
    // refresh if the call actually failed.
    final wasUnread = state.notifications.any((n) => n.id == id && !n.isRead);
    state = state.copyWith(
      notifications: [
        for (final n in state.notifications) if (n.id == id) n.copyWith(isRead: true) else n,
      ],
      unreadCount: wasUnread ? (state.unreadCount - 1).clamp(0, 1 << 31) : state.unreadCount,
    );
    await _markReadUseCase(id);
  }

  Future<void> markAllAsRead() async {
    state = state.copyWith(
      notifications: [for (final n in state.notifications) n.copyWith(isRead: true)],
      unreadCount: 0,
    );
    await _markAllReadUseCase(const NoParams());
  }
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, NotificationsState>(
  (ref) => NotificationsController(),
);

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsControllerProvider).unreadCount;
});
