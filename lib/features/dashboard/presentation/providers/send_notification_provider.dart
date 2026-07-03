import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../notifications/domain/entities/notification_entity.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';

/// Lets a business owner broadcast an offer/announcement notification tied
/// to one of their businesses.
///
/// IMPORTANT — mock/offline limitation: without a backend, there is no
/// mechanism to actually deliver this to *other* users' devices; push
/// fan-out requires a server that stores subscriptions and calls FCM. This
/// provider inserts the notification into the *current* device's own
/// notification list so the compose → send → appears-in-Alerts flow is
/// fully demonstrable, and is written as the single integration point a
/// real backend call would replace (see the TODO below).
class SendBusinessNotificationController extends StateNotifier<AsyncValue<void>> {
  SendBusinessNotificationController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<bool> send({
    required String businessId,
    required String businessName,
    required String title,
    required String message,
  }) async {
    state = const AsyncValue.loading();
    try {
      // TODO(backend): replace this local insert with a real API call, e.g.
      //   POST /businesses/{businessId}/broadcast { title, message }
      // which should fan out a push notification (FCM) to every user who
      // has favorited this business, or to all users for a general offer,
      // per whatever targeting rules the backend implements.
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final notification = NotificationEntity(
        id: const Uuid().v4(),
        title: title,
        body: message,
        createdAt: DateTime.now(),
        type: 'business_offer',
        relatedId: businessId,
      );
      await _ref.read(notificationsControllerProvider.notifier).addNotification(notification);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final sendBusinessNotificationControllerProvider = StateNotifierProvider.autoDispose<
    SendBusinessNotificationController, AsyncValue<void>>((ref) {
  return SendBusinessNotificationController(ref);
});
