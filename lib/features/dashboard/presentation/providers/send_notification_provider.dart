import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/service_locator.dart';
import '../../../notifications/domain/entities/notification_entity.dart';
import '../../../notifications/domain/usecases/broadcast_notification_usecase.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';

/// Lets a business owner broadcast an offer/announcement notification tied
/// to one of their businesses.
///
/// Calls the real backend endpoint (POST /businesses/:id/broadcast — see
/// albmap-backend/src/modules/notifications) via BroadcastNotificationUseCase,
/// which triggers real FCM delivery server-side once a Firebase service
/// account is configured there. Regardless of mock/real mode, this also
/// inserts the notification into the *current* device's own local list so
/// the compose → send → appears-in-Alerts flow gives the sender immediate
/// feedback — the app has no GET /notifications sync endpoint yet, so this
/// is the sender's only way to see their own sent notification reflected
/// in the Alerts tab.
class SendBusinessNotificationController extends StateNotifier<AsyncValue<void>> {
  SendBusinessNotificationController(this._ref)
      : _broadcastUseCase = sl<BroadcastNotificationUseCase>(),
        super(const AsyncValue.data(null));

  final Ref _ref;
  final BroadcastNotificationUseCase _broadcastUseCase;

  Future<bool> send({
    required String businessId,
    required String businessName,
    required String title,
    required String message,
  }) async {
    state = const AsyncValue.loading();

    final result = await _broadcastUseCase(
      BroadcastNotificationParams(businessId: businessId, title: title, body: message),
    );

    if (result.isLeft()) {
      final failureMessage = result.fold((failure) => failure.message, (_) => '');
      state = AsyncValue.error(failureMessage, StackTrace.current);
      return false;
    }

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
  }
}

final sendBusinessNotificationControllerProvider = StateNotifierProvider.autoDispose<
    SendBusinessNotificationController, AsyncValue<void>>((ref) {
  return SendBusinessNotificationController(ref);
});
