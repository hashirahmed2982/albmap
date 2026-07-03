import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../map/domain/entities/business_entity.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../domain/usecases/favorites_usecases.dart';

final favoritesProvider = FutureProvider.autoDispose<FavoritesResult>((ref) async {
  final useCase = sl<GetFavoritesUseCase>();
  final result = await useCase(const NoParams());
  return result.fold(
    (failure) => const FavoritesResult(businesses: [], events: []),
    (data) => data,
  );
});

class FavoriteToggleController extends StateNotifier<AsyncValue<void>> {
  FavoriteToggleController(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  Future<void> toggleBusiness(BusinessEntity business) async {
    final useCase = sl<ToggleFavoriteUseCase>();
    await useCase(ToggleFavoriteParams(type: FavoriteType.business, business: business));
    _ref.invalidate(favoritesProvider);
  }

  Future<void> toggleEvent(EventEntity event) async {
    final useCase = sl<ToggleFavoriteUseCase>();
    await useCase(ToggleFavoriteParams(type: FavoriteType.event, event: event));
    _ref.invalidate(favoritesProvider);
  }
}

final favoriteToggleControllerProvider =
    StateNotifierProvider<FavoriteToggleController, AsyncValue<void>>(
  (ref) => FavoriteToggleController(ref),
);
