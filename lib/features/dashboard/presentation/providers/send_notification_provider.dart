import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../../notifications/domain/usecases/broadcast_notification_usecase.dart';

/// Lets a business owner submit an offer/announcement for admin review.
///
/// This no longer delivers immediately — the backend now holds every
/// broadcast as 'pending' until an admin approves it in the admin portal
/// (see albmap-backend/src/modules/notifications/notification.service.js
/// submitBroadcast()). Only once approved does it actually reach every
/// registered device via FCM and appear in anyone's Notifications screen
/// — including the sender's own, since there's no separate "my sent
/// notifications" list; it shows up in the same shared feed everyone else
/// sees, once approved.
class SendBusinessNotificationController extends StateNotifier<AsyncValue<void>> {
  SendBusinessNotificationController()
      : _broadcastUseCase = sl<BroadcastNotificationUseCase>(),
        super(const AsyncValue.data(null));

  final BroadcastNotificationUseCase _broadcastUseCase;

  /// Returns null on success (the submission was accepted, now pending
  /// review), or an error message on failure.
  Future<String?> send({
    required String businessId,
    required String businessName,
    required String title,
    required String message,
  }) async {
    state = const AsyncValue.loading();

    final result = await _broadcastUseCase(
      BroadcastNotificationParams(businessId: businessId, title: title, body: message),
    );

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return failure.message;
      },
      (_) {
        state = const AsyncValue.data(null);
        return null;
      },
    );
  }
}

final sendBusinessNotificationControllerProvider = StateNotifierProvider.autoDispose<
    SendBusinessNotificationController, AsyncValue<void>>((ref) {
  return SendBusinessNotificationController();
});
