import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/business_entity.dart';
import '../../domain/usecases/business_usecases.dart';

/// Current device location, refreshed on demand from the Discover Map screen.
class LocationController extends StateNotifier<Position?> {
  LocationController(this._ref) : super(null);
  final Ref _ref;

  Future<void> refresh() async {
    // Respect the "Enable location" switch in Settings — previously this
    // asked the OS for a fix unconditionally, so turning the switch off
    // did nothing (it just wrote a SharedPreferences value nobody read).
    if (!_ref.read(settingsControllerProvider).locationEnabled) {
      state = null;
      return;
    }

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
    } catch (err, stack) {
      // Keep previous state on failure — the map falls back to its
      // default center, so this is a graceful degradation, not a crash.
      // Still logged so a "map never centers on me" report is diagnosable.
      AppLogger.warning('Failed to fetch current position', err, stack);
    }
  }

  /// Called from SettingsController the moment "Enable location" is
  /// turned off, so anything already showing distance/"near me" data
  /// reflects the change immediately rather than waiting for the next
  /// screen that happens to call refresh().
  void clear() => state = null;
}

final locationControllerProvider =
    StateNotifierProvider<LocationController, Position?>((ref) => LocationController(ref));

class BusinessFilter {
  const BusinessFilter({this.category, this.radiusKm, this.sortBy = 'distance'});
  final String? category;

  /// Null means "no distance limit" — the default. Discovery should show
  /// every business worldwide until the user explicitly opts into a
  /// radius via the filter sheet, not silently restrict to a 10km bubble
  /// around wherever the device happens to be.
  final double? radiusKm;
  final String sortBy;

  BusinessFilter copyWith({
    String? category,
    double? radiusKm,
    String? sortBy,
    bool clearCategory = false,
    bool clearRadius = false,
  }) {
    return BusinessFilter(
      category: clearCategory ? null : (category ?? this.category),
      radiusKm: clearRadius ? null : (radiusKm ?? this.radiusKm),
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
