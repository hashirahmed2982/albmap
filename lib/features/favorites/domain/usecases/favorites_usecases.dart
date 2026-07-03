import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../map/domain/entities/business_entity.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../repositories/favorites_repository.dart';

enum FavoriteType { business, event }

class ToggleFavoriteParams extends Equatable {
  const ToggleFavoriteParams({required this.type, this.business, this.event});
  final FavoriteType type;
  final BusinessEntity? business;
  final EventEntity? event;

  @override
  List<Object?> get props => [type, business, event];
}

class ToggleFavoriteUseCase implements UseCase<void, ToggleFavoriteParams> {
  ToggleFavoriteUseCase(this._repository);
  final FavoritesRepository _repository;

  @override
  Future<Either<Failure, void>> call(ToggleFavoriteParams params) {
    if (params.type == FavoriteType.business && params.business != null) {
      return _repository.toggleFavoriteBusiness(params.business!);
    }
    if (params.type == FavoriteType.event && params.event != null) {
      return _repository.toggleFavoriteEvent(params.event!);
    }
    throw ArgumentError('Invalid favorite toggle params');
  }
}

class FavoritesResult extends Equatable {
  const FavoritesResult({required this.businesses, required this.events});
  final List<BusinessEntity> businesses;
  final List<EventEntity> events;

  @override
  List<Object?> get props => [businesses, events];
}

class GetFavoritesUseCase implements UseCase<FavoritesResult, NoParams> {
  GetFavoritesUseCase(this._repository);
  final FavoritesRepository _repository;

  @override
  Future<Either<Failure, FavoritesResult>> call(NoParams params) async {
    final Either<Failure, List<BusinessEntity>> businessesResult =
        await _repository.getFavoriteBusinesses();
    final Either<Failure, List<EventEntity>> eventsResult =
        await _repository.getFavoriteEvents();

    return businessesResult.fold(
      (Failure f) => Left(f),
      (List<BusinessEntity> businesses) => eventsResult.fold(
        (Failure f) => Left(f),
        (List<EventEntity> events) =>
            Right(FavoritesResult(businesses: businesses, events: events)),
      ),
    );
  }
}
