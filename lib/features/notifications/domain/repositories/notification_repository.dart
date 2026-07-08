import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';

abstract class NotificationRepository {
  /// Broadcasts an offer/announcement from a business owner. Real delivery
  /// to other users' devices happens server-side via FCM (see the
  /// backend's notification.service.js) — this call just triggers it.
  Future<Either<Failure, void>> broadcastFromBusiness({
    required String businessId,
    required String title,
    required String body,
  });
}
