import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/business_entity.dart';
import '../../domain/usecases/business_usecases.dart';

/// Current device location, refreshed on demand from the Discover Map screen.
class LocationController extends StateNotifier<Position?> {
  LocationController() : super(null);

  Future<void> refresh() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      state = await Geolocator.getCurrentPosition();
    } catch (_) {
      // keep previous state on failure
    }
  }
}

final locationControllerProvider =
    StateNotifierProvider<LocationController, Position?>((ref) => LocationController());

class BusinessFilter {
  const BusinessFilter({this.category, this.radiusKm = 10, this.sortBy = 'distance'});
  final String? category;
  final double radiusKm;
  final String sortBy;

  BusinessFilter copyWith({String? category, double? radiusKm, String? sortBy, bool clearCategory = false}) {
    return BusinessFilter(
      category: clearCategory ? null : (category ?? this.category),
      radiusKm: radiusKm ?? this.radiusKm,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

final businessFilterProvider = StateProvider<BusinessFilter>((ref) => const BusinessFilter());

class BusinessListState {
  const BusinessListState({this.businesses = const [], this.isLoading = false, this.errorMessage});
  final List<BusinessEntity> businesses;
  final bool isLoading;
  final String? errorMessage;

  BusinessListState copyWith({List<BusinessEntity>? businesses, bool? isLoading, String? errorMessage}) {
    return BusinessListState(
      businesses: businesses ?? this.businesses,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class BusinessListController extends StateNotifier<BusinessListState> {
  BusinessListController(this._ref)
      : _getBusinesses = sl<GetBusinessesUseCase>(),
        super(const BusinessListState()) {
    load();
  }

  final Ref _ref;
  final GetBusinessesUseCase _getBusinesses;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final filter = _ref.read(businessFilterProvider);
    final position = _ref.read(locationControllerProvider);

    final result = await _getBusinesses(GetBusinessesParams(
      category: filter.category,
      radiusKm: filter.radiusKm,
      userLat: position?.latitude,
      userLng: position?.longitude,
      sortBy: filter.sortBy,
    ));

    result.fold(
      (Failure failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (businesses) => state = BusinessListState(businesses: businesses, isLoading: false),
    );
  }
}

final businessListControllerProvider =
    StateNotifierProvider<BusinessListController, BusinessListState>((ref) {
  return BusinessListController(ref);
});

final businessSearchQueryProvider = StateProvider<String>((ref) => '');

final businessSearchResultsProvider = FutureProvider.autoDispose<List<BusinessEntity>>((ref) async {
  final query = ref.watch(businessSearchQueryProvider);
  if (query.trim().length < 2) return <BusinessEntity>[];
  final useCase = sl<SearchBusinessesUseCase>();
  final result = await useCase(query);
  return result.fold((_) => <BusinessEntity>[], (list) => list);
});

final businessDetailsProvider =
    FutureProvider.autoDispose.family<BusinessEntity?, String>((ref, id) async {
  final useCase = sl<GetBusinessDetailsUseCase>();
  final result = await useCase(id);
  return result.fold((_) => null, (business) => business);
});
