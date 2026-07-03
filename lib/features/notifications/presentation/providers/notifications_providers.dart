import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../domain/entities/notification_entity.dart';

/// Notifications are cached locally (received via FCM background handler,
/// appended to this box). This provider exposes them reactively to the UI.
class NotificationsController extends StateNotifier<List<NotificationEntity>> {
  NotificationsController() : super(const []) {
    _load();
  }

  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    _box ??= await Hive.openBox<String>('notifications_box');
    return _box!;
  }

  Future<void> _load() async {
    final box = await _getBox();
    final raw = box.get('items');
    if (raw == null) {
      state = const [];
      return;
    }
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    state = decoded.map((e) {
      final m = e as Map<String, dynamic>;
      return NotificationEntity(
        id: m['id'] as String,
        title: m['title'] as String,
        body: m['body'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
        isRead: m['isRead'] as bool? ?? false,
        type: m['type'] as String? ?? 'general',
        relatedId: m['relatedId'] as String?,
      );
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _persist() async {
    final box = await _getBox();
    final json = state.map((n) => {
          'id': n.id, 'title': n.title, 'body': n.body,
          'createdAt': n.createdAt.toIso8601String(),
          'isRead': n.isRead, 'type': n.type, 'relatedId': n.relatedId,
        }).toList();
    await box.put('items', jsonEncode(json));
  }

  Future<void> markAsRead(String id) async {
    state = [
      for (final n in state) if (n.id == id) n.copyWith(isRead: true) else n,
    ];
    await _persist();
  }

  /// Inserts a new notification at the top of the list. Used by:
  /// - FCM foreground/background message handlers (real push delivery)
  /// - The business owner's "Send Notification" broadcast (see
  ///   send_business_notification_usecase.dart) — in mock/offline mode
  ///   there's no real backend fan-out to every user's device, so this
  ///   just adds it to the *current* device's own list so the flow is
  ///   demonstrable end-to-end. A real implementation would have the
  ///   backend push this to all subscribed users via FCM topics instead.
  Future<void> addNotification(NotificationEntity notification) async {
    state = [notification, ...state];
    await _persist();
  }

  Future<void> markAllAsRead() async {
    state = [for (final n in state) n.copyWith(isRead: true)];
    await _persist();
  }

  Future<void> delete(String id) async {
    state = state.where((n) => n.id != id).toList();
    await _persist();
  }
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, List<NotificationEntity>>(
  (ref) => NotificationsController(),
);

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsControllerProvider).where((n) => !n.isRead).length;
});
