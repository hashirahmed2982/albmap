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

class BroadcastNotificationUseCase implements UseCase<void, BroadcastNotificationParams> {
  BroadcastNotificationUseCase(this._repository);
  final NotificationRepository _repository;

  @override
  Future<Either<Failure, void>> call(BroadcastNotificationParams params) {
    return _repository.broadcastFromBusiness(
      businessId: params.businessId,
      title: params.title,
      body: params.body,
    );
  }
}
