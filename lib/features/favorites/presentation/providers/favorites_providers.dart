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

/// Whether the given business/event is currently favorited — derived from
/// [favoritesProvider] (rather than a separate network call per item) so
/// Business/Event Details' favorite button can show its real state
/// (filled heart) instead of always rendering the outline icon regardless
/// of whether it was already favorited, which is what both screens did
/// before this existed. Recomputes automatically whenever
/// FavoriteToggleController invalidates favoritesProvider after a toggle.
final businessIsFavoriteProvider = Provider.autoDispose.family<bool, String>((ref, businessId) {
  final favoritesAsync = ref.watch(favoritesProvider);
  return favoritesAsync.maybeWhen(
    data: (result) => result.businesses.any((b) => b.id == businessId),
    orElse: () => false,
  );
});

final eventIsFavoriteProvider = Provider.autoDispose.family<bool, String>((ref, eventId) {
  final favoritesAsync = ref.watch(favoritesProvider);
  return favoritesAsync.maybeWhen(
    data: (result) => result.events.any((e) => e.id == eventId),
    orElse: () => false,
  );
});

class FavoriteToggleController extends StateNotifier<AsyncValue<void>> {
  FavoriteToggleController(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  // Both methods return the failure message (or null on success) instead
  // of void: the previous version discarded the Either entirely, so a
  // failed toggle (e.g. a Hive write error) left the star icon looking
  // like nothing happened, with no way for the caller to know it should
  // tell the user. Every call site now checks this and shows a toast.
  Future<String?> toggleBusiness(BusinessEntity business) async {
    final useCase = sl<ToggleFavoriteUseCase>();
    final result = await useCase(ToggleFavoriteParams(type: FavoriteType.business, business: business));
    _ref.invalidate(favoritesProvider);
    return result.fold((failure) => failure.message, (_) => null);
  }

  Future<String?> toggleEvent(EventEntity event) async {
    final useCase = sl<ToggleFavoriteUseCase>();
    final result = await useCase(ToggleFavoriteParams(type: FavoriteType.event, event: event));
    _ref.invalidate(favoritesProvider);
    return result.fold((failure) => failure.message, (_) => null);
  }
}

final favoriteToggleControllerProvider =
    StateNotifierProvider<FavoriteToggleController, AsyncValue<void>>(
  (ref) => FavoriteToggleController(ref),
);
