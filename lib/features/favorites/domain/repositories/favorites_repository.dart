import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../map/domain/entities/business_entity.dart';
import '../../../events/domain/entities/event_entity.dart';

abstract class FavoritesRepository {
  Future<Either<Failure, void>> toggleFavoriteBusiness(BusinessEntity business);
  Future<Either<Failure, void>> toggleFavoriteEvent(EventEntity event);
  Future<Either<Failure, List<BusinessEntity>>> getFavoriteBusinesses();
  Future<Either<Failure, List<EventEntity>>> getFavoriteEvents();
  Future<Either<Failure, bool>> isBusinessFavorite(String businessId);
}
