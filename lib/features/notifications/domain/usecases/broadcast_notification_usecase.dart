import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/notification_repository.dart';

class BroadcastNotificationParams extends Equatable {
  const BroadcastNotificationParams({
    required this.businessId,
    required this.title,
    required this.body,
  });

  final String businessId;
  final String title;
  final String body;

  @override
  List<Object?> get props => [businessId, title, body];
}

/// Returns the resulting status ('pending') rather than void — the caller
/// needs to know this wasn't delivered yet, just submitted for review.
class BroadcastNotificationUseCase implements UseCase<String, BroadcastNotificationParams> {
  BroadcastNotificationUseCase(this._repository);
  final NotificationRepository _repository;

  @override
  Future<Either<Failure, String>> call(BroadcastNotificationParams params) {
    return _repository.submitBroadcast(
      businessId: params.businessId,
      title: params.title,
      body: params.body,
    );
  }
}
