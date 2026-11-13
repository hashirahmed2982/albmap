import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart';
// google_maps_flutter's own ClusterManager/Cluster types are Google's
// native marker-clustering API, unused here — hidden so they don't
// collide with google_maps_cluster_manager_2's own (unrelated) classes
// of the same name, which this file actually uses.
import 'package:google_maps_flutter/google_maps_flutter.dart' hide ClusterManager, Cluster;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/map_style.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../categories/domain/category_translations.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/business_open_status.dart';
import '../../domain/entities/business_entity.dart';
import '../providers/business_providers.dart';
import '../widgets/business_list_view.dart';
import '../widgets/filter_bottom_sheet.dart';

enum _ViewMode { map, list }

/// Wraps a [BusinessEntity] for google_maps_cluster_manager_2's
/// [ClusterItem] mixin — kept at the presentation layer rather than
/// mixing it into BusinessEntity itself, so the domain layer stays free
/// of a map-rendering-library dependency.
class _BusinessClusterItem with ClusterItem {
  _BusinessClusterItem(this.business);
  final BusinessEntity business;

  @override
  LatLng get location => LatLng(business.latitude, business.longitude);
}

/// 3. Discover Map Screen — main app screen. The user explicitly picks
/// between a Map view and a List view via a segmented toggle.
///
/// "Bold Editorial" redesign (see AlbMap_Design_Spec_Bold_Editorial.md +
/// DiscoverMap.png): a dark-styled Google Map (see map_style.dart's
/// kGoogleMapsDarkStyle — previously CARTO Dark Matter OpenStreetMap
/// tiles, migrated to Google Maps now that the client has billing/API
/// keys set up), a flat/bordered search bar and category chips instead
/// of elevated pills, the marker-business.png pin asset for every
/// business (replacing the old per-category colored pin widget), and a
/// persistent bottom preview card for whichever business is currently
/// selected — replacing the previous tap-to-open-modal-sheet interaction
/// (BusinessMarkerSheet), which the mockup doesn't show at all in favor
/// of this persistent card.
class DiscoverMapScreen extends ConsumerStatefulWidget {
  const DiscoverMapScreen({super.key});

  @override
  ConsumerState<DiscoverMapScreen> createState() => _DiscoverMapScreenState();
}

class _DiscoverMapScreenState extends ConsumerState<DiscoverMapScreen> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  BitmapDescriptor? _businessIcon;
  final TextEditingController _searchController = TextEditingController();
  String _localQuery = '';
  _ViewMode _viewMode = _ViewMode.map;
  Timer? _searchDebounce;

  // Groups nearby markers at lower zoom levels instead of rendering one
  // overlapping pin per business — essential once the viewport-bounds
  // fetch below can return hundreds of businesses in a dense area.
  late final ClusterManager<_BusinessClusterItem> _clusterManager;
  Set<Marker> _clusterMarkers = {};
  Timer? _boundsFetchDebounce;
  // Guards _syncClusterItems against re-clustering on every rebuild (view
  // mode toggles, a marker selection, etc.) when the actual business list
  // feeding the map hasn't changed at all.
  List<BusinessEntity> _lastClusterInput = const [];

  // Which business's preview card is showing at the bottom of the map —
  // null means no marker has been tapped yet, so no card shows at all
  // (see _selectedBusiness below).
  String? _selectedBusinessId;

  // Below this length, businessSearchResultsProvider itself short-circuits
  // to an empty list (see business_providers.dart) — no point round-
  // tripping to the backend for a 1-character query.
  static const int _minSearchQueryLength = 2;

  static const double _barHeight = 52;

  // Tirana, Albania as a sensible default center.
  static const LatLng _defaultCenter = LatLng(41.3275, 19.8187);
  static const double _defaultZoom = 13;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBusinessIcon();
    _clusterManager = ClusterManager<_BusinessClusterItem>(
      const <_BusinessClusterItem>[],
      (Set<Marker> markers) {
        if (mounted) setState(() => _clusterMarkers = markers);
      },
      markerBuilder: _buildClusterMarker,
      // The library's default `levels` list only has 9 entries, which
      // caps geohash-based clustering at geohash precision 9 — cells
      // roughly 5m×5m — no matter how far past that you zoom. Businesses
      // within ~5m of each other (neighboring shops in the same small
      // plaza, say) would stay merged into one cluster forever, even
      // zoomed in as far as the map's minMaxZoomPreference allows (18).
      // stopClusteringZoom is the library's own escape hatch: past this
      // zoom, every item renders as its own individual marker instead of
      // going through geohash bucketing at all, which is what actually
      // lets a tight group split apart on zoom-in.
      stopClusteringZoom: 17,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(locationControllerProvider.notifier).refresh();
      _recenterOnUser();
      ref.read(businessListControllerProvider.notifier).load();
    });
  }

  /// GoogleMap markers need an actual bitmap, not an arbitrary widget the
  /// way flutter_map's Marker.child used to accept — so the pin asset is
  /// decoded once here and reused for every business marker, rather than
  /// re-decoding it per marker per rebuild. Markers render with
  /// BitmapDescriptor.defaultMarker until this resolves (near-instant in
  /// practice), never blocked/crashed on it.
  ///
  /// Uses BitmapDescriptor.asset with explicit width/height, NOT the
  /// deprecated fromAssetImage(ImageConfiguration(size: ...)) this used to
  /// call — that `size` is silently ignored on every platform except web
  /// (see the platform interface source), so it never actually constrained
  /// anything here. What it rendered at instead was governed by which
  /// asset variant (1.0x/2.0x/3.0x) got picked, which — since no
  /// devicePixelRatio was ever set on that bare ImageConfiguration either
  /// — always fell back to the base 1.0x file regardless of the real
  /// device. Native marker rendering then sizes the bitmap relative to
  /// the device's actual screen density, so the same fixed 96px bitmap
  /// came out a different logical size on different-density devices —
  /// exactly the "bigger on some devices" being reported. `asset(...)`'s
  /// width/height are real, honored cross-platform constraints (per its
  /// own doc: MapBitmapScaling.auto "maintain[s] consistency across
  /// devices"), so this is now genuinely fixed at 40x40 everywhere.
  Future<void> _loadBusinessIcon() async {
    final icon = await BitmapDescriptor.asset(
      const ImageConfiguration(),
      'assets/markers/marker-business.png',
      width: 40,
      height: 40,
    );
    if (mounted) setState(() => _businessIcon = icon);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Business approval happens externally (an admin acting in the web
    // portal, not inside this app), so there's no in-app event to react
    // to — the app genuinely can't know a business got approved while it
    // wasn't running. Refreshing on resume covers the realistic version
    // of that: someone backgrounds the app while waiting, then reopens it
    // a bit later, without needing to fully quit and relaunch (which was
    // the previous "reinitialize app" workaround).
    if (state == AppLifecycleState.resumed) {
      ref.read(businessListControllerProvider.notifier).load();
      unawaited(_fetchMapBusinessesForCurrentBounds());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchDebounce?.cancel();
    _boundsFetchDebounce?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Instant local filtering (over whatever's already loaded) so typing
    // never feels laggy, while the real backend-wide search — see
    // businessSearchResultsProvider, previously defined but never called
    // from any screen — is debounced so we're not firing a network
    // request on every keystroke.
    setState(() => _localQuery = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      ref.read(businessSearchQueryProvider.notifier).state = value.trim();
    });
  }

  void _recenterOnUser() {
    final position = ref.read(locationControllerProvider);
    if (position != null) {
      // Null-safe: this can fire (via initState's postFrameCallback)
      // before GoogleMap's onMapCreated has resolved yet on a very slow
      // device — the refresh() awaited just before this call is a
      // permission prompt + GPS fix, virtually always slower than the
      // native map view attaching, but there's no reason to crash on the
      // rare case it isn't.
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 14),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    unawaited(_clusterManager.setMapId(controller.mapId));
    unawaited(_fetchMapBusinessesForCurrentBounds());
  }

  /// Re-clusters for the new zoom/position immediately (cheap, purely
  /// local), then — unless a text search is active, in which case the
  /// map shows those specific results rather than viewport-driven ones —
  /// debounces a real network fetch for whatever's now in view. A single
  /// pan/zoom gesture fires several idle-ish events in quick succession;
  /// only the last one, once motion actually settles, should trigger a
  /// fetch.
  void _onCameraIdle() {
    _clusterManager.updateMap();
    if (_localQuery.trim().length >= _minSearchQueryLength) return;
    _boundsFetchDebounce?.cancel();
    _boundsFetchDebounce = Timer(const Duration(milliseconds: 400), _fetchMapBusinessesForCurrentBounds);
  }

  Future<void> _fetchMapBusinessesForCurrentBounds() async {
    final controller = _mapController;
    if (controller == null) return;
    final LatLngBounds bounds = await controller.getVisibleRegion();
    if (!mounted) return;
    final String? category = ref.read(businessFilterProvider).category;
    await ref.read(mapBusinessesControllerProvider.notifier).loadForBounds(
          swLat: bounds.southwest.latitude,
          swLng: bounds.southwest.longitude,
          neLat: bounds.northeast.latitude,
          neLng: bounds.northeast.longitude,
          category: category,
        );
  }

  /// Feeds whichever business list the map should currently show into the
  /// cluster manager — guarded against redundant re-clustering when
  /// `mapDisplayed` is unchanged from the last call (e.g. a rebuild
  /// triggered by selecting a marker, not by the data itself changing).
  void _syncClusterItems(List<BusinessEntity> mapDisplayed) {
    if (listEquals(_lastClusterInput, mapDisplayed)) return;
    _lastClusterInput = mapDisplayed;
    _clusterManager.setItems(mapDisplayed.map(_BusinessClusterItem.new).toList());
  }

  Future<Marker> _buildClusterMarker(Cluster<_BusinessClusterItem> cluster) async {
    if (!cluster.isMultiple) {
      final BusinessEntity business = cluster.items.first.business;
      // Past stopClusteringZoom, every business becomes its own
      // single-item cluster regardless of how close together they are —
      // so two businesses at (or within a meter or two of) the exact same
      // coordinate never get grouped into a "2" badge here, they just end
      // up as two individual Markers stacked at the identical pixel
      // position. Normally harmless, but since zooming in further can
      // never spread them apart (there's no pixel distance between them
      // to begin with), whichever one ends up on top would otherwise
      // silently hide the other with no way to ever reach it.
      final List<BusinessEntity> overlapping = _businessesAtSameLocation(business);
      return Marker(
        markerId: MarkerId(business.id),
        position: cluster.location,
        icon: _businessIcon ?? BitmapDescriptor.defaultMarker,
        onTap: overlapping.length > 1
            ? () => _showOverlappingBusinessesSheet(overlapping)
            : () => setState(() => _selectedBusinessId = business.id),
      );
    }
    return Marker(
      markerId: MarkerId(cluster.getId()),
      position: cluster.location,
      icon: await _clusterBitmap(cluster.count),
      // No single business to select for a multi-item cluster — zooming
      // in is the standard way to let it split back apart into either
      // smaller clusters or individual markers. If the items underneath
      // genuinely can't separate (same/near-identical coordinates), this
      // keeps zooming until stopClusteringZoom is hit, at which point
      // they become individual overlapping markers and the check above
      // takes over.
      onTap: () => _mapController?.animateCamera(CameraUpdate.newLatLngZoom(cluster.location, 16)),
    );
  }

  // ~3m — comfortably smaller than marker-business.png's own footprint
  // even at the map's maximum zoom, so anything within this distance can
  // never usefully spread apart on screen no matter how far the user
  // zooms in (unlike stopClusteringZoom above, which only helps
  // businesses close together but not this close).
  static const double _overlapThresholdDegrees = 0.00003;

  List<BusinessEntity> _businessesAtSameLocation(BusinessEntity business) {
    return _lastClusterInput
        .where((b) =>
            (b.latitude - business.latitude).abs() < _overlapThresholdDegrees &&
            (b.longitude - business.longitude).abs() < _overlapThresholdDegrees)
        .toList();
  }

  /// Lets the user pick which of several co-located businesses they
  /// actually meant to tap, instead of one silently winning by whichever
  /// happened to render on top. Reuses BusinessCard as-is — tapping an
  /// entry navigates straight to its details page, same as the List view.
  void _showOverlappingBusinessesSheet(List<BusinessEntity> businesses) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'discover.multipleBusinessesHere'.tr(args: ['${businesses.length}']),
                style: AppTextStyles.h3,
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: businesses.length,
                itemBuilder: (_, i) => BusinessCard(business: businesses[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A simple red filled circle with the cluster's count, matching the
  /// app's accent color — drawn once per distinct count/zoom combination
  /// (ClusterManager calls this per cluster on every re-cluster, so
  /// there's no caching beyond what's cheap to just redraw each time).
  Future<BitmapDescriptor> _clusterBitmap(int count) async {
    const double size = 72;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, Paint()..color = AppColors.primary);
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final TextPainter painter = TextPainter(textDirection: ui.TextDirection.ltr)
      ..text = TextSpan(
        text: '$count',
        style: const TextStyle(fontSize: size / 2.6, color: Colors.white, fontWeight: FontWeight.w700),
      )
      ..layout();
    painter.paint(canvas, Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2));

    final ui.Image image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return BitmapDescriptor.defaultMarker;
    // Explicit width/height, same reasoning as _loadBusinessIcon's —
    // without them the rendered size follows the device's pixel ratio
    // inconsistently instead of a fixed logical size everywhere.
    return BitmapDescriptor.bytes(bytes.buffer.asUint8List(), width: 36, height: 36);
  }

  List<BusinessEntity> _byCategory(List<BusinessEntity> all, String? category) {
    if (category == null) return all;
    return all.where((b) => b.category == category).toList();
  }

  /// Local, instant name filter over whatever's already loaded for the
  /// current map radius — used as-is for short queries, and as a
  /// no-flicker placeholder while the real backend search (below) is
  /// still in flight for a longer query.
  List<BusinessEntity> _localFiltered(List<BusinessEntity> all, String? category) {
    final Iterable<BusinessEntity> byCategory = _byCategory(all, category);
    final q = _localQuery.trim().toLowerCase();
    if (q.isEmpty) return byCategory.toList();
    return byCategory.where((b) => b.name.toLowerCase().contains(q)).toList();
  }

  /// The business the bottom preview card should show — only ever one
  /// the user actually tapped a marker for. Returns null (no card at
  /// all) until then, rather than defaulting to showing the nearest
  /// business the moment the screen opens.
  BusinessEntity? _selectedBusiness(List<BusinessEntity> businesses) {
    if (_selectedBusinessId == null) return null;
    for (final b in businesses) {
      if (b.id == _selectedBusinessId) return b;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(businessListControllerProvider);
    final String trimmedQuery = _localQuery.trim();
    final bool isSearchActive = trimmedQuery.length >= _minSearchQueryLength;
    // Single source of truth for "which category is selected" — shared
    // with FilterBottomSheet via businessFilterProvider (previously this
    // screen's quick-category chips tracked their own separate local
    // field, so picking a category here didn't show up when the filter
    // sheet was opened, and vice versa).
    final String? selectedCategory = ref.watch(businessFilterProvider).category;

    // Re-fetches the map's viewport data the moment the category filter
    // changes — same bounds, different filter, so last viewport's data
    // is stale regardless of whether the camera has moved at all. Only
    // matters outside search mode, where the map shows search results
    // instead (see mapDisplayed below).
    ref.listen<BusinessFilter>(businessFilterProvider, (previous, next) {
      if (previous?.category != next.category && !isSearchActive) {
        unawaited(_fetchMapBusinessesForCurrentBounds());
      }
    });

    List<BusinessEntity> displayed;
    if (isSearchActive) {
      // A real query is active — search the *entire* backend catalog
      // (searchBusinesses has no radius limit, unlike the normal list
      // load), not just whatever happened to already be loaded for the
      // current map view. Category filter still applies client-side,
      // since the search endpoint only takes a text query.
      final searchAsync = ref.watch(businessSearchResultsProvider);
      displayed = searchAsync.when(
        data: (all) => _byCategory(all, selectedCategory),
        // Keep showing the last-known local-filtered list while a new
        // debounced search is loading, rather than flashing an empty
        // "no results" state on every keystroke.
        loading: () => _localFiltered(listState.businesses, selectedCategory),
        // Search failed (offline, server error) — fall back to filtering
        // what's already loaded rather than showing a dead end; this
        // mirrors the "never crash for a degraded feature" pattern used
        // for location/Firebase elsewhere in the app.
        error: (_, __) => _localFiltered(listState.businesses, selectedCategory),
      );
    } else {
      displayed = _localFiltered(listState.businesses, selectedCategory);
    }

    // The map's own marker source — search results when a query is
    // active (specific, already-fetched matches the map shouldn't
    // second-guess), otherwise whatever the viewport-bounds fetch
    // returned (see mapBusinessesControllerProvider), NOT the fixed-size
    // single page `listState`/`displayed` above was built from.
    final MapBusinessesState mapState = ref.watch(mapBusinessesControllerProvider);
    final List<BusinessEntity> mapDisplayed = isSearchActive ? displayed : mapState.businesses;
    // Only while the map is actually in the widget tree — toggling to
    // List view disposes the underlying GoogleMap platform view (it's
    // conditionally built below, not just hidden), and the cluster
    // manager's internal getVisibleRegion() call would throw against a
    // map id that no longer exists.
    if (_viewMode == _ViewMode.map) _syncClusterItems(mapDisplayed);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(context, selectedCategory: selectedCategory),
            Expanded(
              child: _viewMode == _ViewMode.list
                  ? BusinessListView(
                      businesses: displayed,
                      isLoading: listState.isLoading,
                      errorMessage: listState.errorMessage,
                      onRetry: () => ref.read(businessListControllerProvider.notifier).load(),
                      onRefresh: () async =>
                          ref.read(businessListControllerProvider.notifier).load(),
                    )
                  : _buildMap(mapDisplayed, listState, isLoadingMap: mapState.isLoading && !isSearchActive),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required String? selectedCategory}) {
    final List<String> quickCategories = ref.watch(categoryNamesProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12 + MediaQuery.of(context).padding.top, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: _barHeight,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    maxLength: 100,
                    style: AppTextStyles.bodyMedium,
                    cursorColor: AppColors.primary,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'discover.searchHint'.tr(),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                      prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 24),
                      // Suppresses the default "N/100" counter row — this
                      // field sits in a fixed-height pill (_barHeight),
                      // and the counter's extra height would overflow it.
                      counterText: '',
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: _barHeight,
                width: _barHeight,
                child: Material(
                  color: AppColors.primary,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.tune, color: Colors.white),
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const FilterBottomSheet(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // SegmentedButton<_ViewMode>(
          //   segments: [
          //     ButtonSegment(value: _ViewMode.map, icon: const Icon(Icons.map_outlined, size: 18), label: Text('discover.map'.tr())),
          //     ButtonSegment(value: _ViewMode.list, icon: const Icon(Icons.view_list_outlined, size: 18), label: Text('discover.list'.tr())),
          //   ],
          //   selected: {_viewMode},
          //   onSelectionChanged: (s) => setState(() => _viewMode = s.first),
          //   // No explicit style: the app-wide segmentedButtonTheme (see
          //   // app_theme.dart) already gives every SegmentedButton this
          //   // exact look — kept here before as a one-off override, now a
          //   // single source of truth so this and the filter sheet's
          //   // sort-by control can never drift apart.
          // ),
          // const SizedBox(height: 12),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: quickCategories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return _CategoryChip(
                    label: 'common.all'.tr(),
                    selected: selectedCategory == null,
                    onTap: () => ref.read(businessFilterProvider.notifier).update(
                          (f) => f.copyWith(clearCategory: true),
                        ),
                  );
                }
                final category = quickCategories[i - 1];
                return _CategoryChip(
                  label: localizedCategoryName(context, category),
                  selected: selectedCategory == category,
                  onTap: () => ref.read(businessFilterProvider.notifier).update(
                        (f) => f.copyWith(category: category),
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(List<BusinessEntity> businesses, BusinessListState listState, {required bool isLoadingMap}) {
    final BusinessEntity? selected = _selectedBusiness(businesses);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(target: _defaultCenter, zoom: _defaultZoom),
          minMaxZoomPreference: const MinMaxZoomPreference(3, 18),
          style: kGoogleMapsDarkStyle,
          // Google's own native blue dot — replaces the previous
          // hand-drawn colored dot (a custom BitmapDescriptor for that
          // would need a generated bitmap; this is the platform-native
          // equivalent and needs no extra asset). Only ever shown once
          // location permission is actually granted; never prompts for
          // it itself — that's still entirely locationControllerProvider's
          // job, unchanged, elsewhere in the app.
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: _onMapCreated,
          onCameraMove: _clusterManager.onCameraMove,
          onCameraIdle: _onCameraIdle,
          markers: _clusterMarkers,
        ),

        if (isLoadingMap || listState.isLoading)
          const Positioned(top: 16, left: 0, right: 0, child: LoadingIndicator()),

        if (listState.errorMessage != null && listState.businesses.isEmpty)
          Positioned.fill(
            child: Container(
              color: AppColors.background,
              child: ErrorStateWidget(
                message: listState.errorMessage!,
                onRetry: () => ref.read(businessListControllerProvider.notifier).load(),
              ),
            ),
          ),

        Positioned(
          bottom: selected != null ? 158 : 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: FloatingActionButton(
              heroTag: 'refresh-businesses',

              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              // Refreshes whatever's actually driving the markers on
              // screen right now — the viewport-bounds fetch while
              // browsing, or a fresh search while one's active — not the
              // unrelated fixed-page list data, which no longer feeds the
              // map's markers at all.
              onPressed: () {
                if (_localQuery.trim().length >= _minSearchQueryLength) {
                  ref.invalidate(businessSearchResultsProvider);
                } else {
                  _fetchMapBusinessesForCurrentBounds();
                }
              },
              child: const Icon(Icons.refresh_rounded),
            ),
          ),
        ),
        Positioned(
          bottom: selected != null ? 96 : 16,
          right: selected != null ? 16 : 76,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: FloatingActionButton(
              heroTag: 'recenter-map',
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              onPressed: () async {
                await ref.read(locationControllerProvider.notifier).refresh();
                _recenterOnUser();
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ),

        if (selected != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BusinessPreviewCard(business: selected),
          ),
      ],
    );
  }

}


/// Plain outlined pill (no icon, no per-category color) matching the
/// mockup's quick-filter chips — "Të gjitha"/"All" filled red when
/// selected, every other chip just an outlined dark pill with white
/// text regardless of category.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 1.5),
        ),
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// Persistent bottom card showing whichever business is currently
/// selected on the map — replaces the old tap-to-open modal
/// (BusinessMarkerSheet), which the DiscoverMap.png mockup doesn't use
/// at all in favor of this always-visible card sitting above the bottom
/// nav bar.
class _BusinessPreviewCard extends StatelessWidget {
  const _BusinessPreviewCard({required this.business});
  final BusinessEntity business;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.businessDetailsPath(business.id)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              color: AppColors.primary.withValues(alpha: 0.16),
              child: business.logoUrl != null
                  ? AppNetworkImage(
                      url: AppConstants.resolveMediaUrl(business.logoUrl)!,
                      width: 48,
                      height: 48,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.16),
                    )
                  : Icon(categoryIcon(business.category), color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(business.name, style: AppTextStyles.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  // Was missing entirely from this card — a business's
                  // open/closed status only became visible after tapping
                  // through to Business Details, not from the map itself
                  // where it matters most. Same OpenStatusBadge already
                  // used on the list view's cards and Business Details.
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        localizedCategoryName(context, business.category),
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      OpenStatusBadge(openingHours: business.openingHours, dense: true),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (business.rating != null) ...[
                        const Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                        Text(business.rating!.toStringAsFixed(1), style: AppTextStyles.bodySmall),
                      ],
                      if (business.rating != null && business.distanceKm != null)
                        Text(' · ', style: AppTextStyles.bodySmall),
                      if (business.distanceKm != null) ...[
                        Text(
                          'common.km_away'.tr(args: [business.distanceKm!.toStringAsFixed(1)]),
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
