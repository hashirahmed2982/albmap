import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../categories/domain/category_translations.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/business_entity.dart';
import '../providers/business_providers.dart';
import '../widgets/business_list_view.dart';
import '../widgets/filter_bottom_sheet.dart';

enum _ViewMode { map, list }

/// 3. Discover Map Screen — main app screen. The user explicitly picks
/// between a Map view and a List view via a segmented toggle.
///
/// "Bold Editorial" redesign (see AlbMap_Design_Spec_Bold_Editorial.md +
/// DiscoverMap.png): dark map tiles (see AppConstants.mapTileUrlTemplate
/// — CARTO Dark Matter, still OpenStreetMap-based, not Google Maps —
/// Google Maps is a separate planned migration once the client sets up
/// billing/API keys), a flat/bordered search bar and category chips
/// instead of elevated pills, the new marker-business.png pin asset for
/// every business (replacing the old per-category colored pin widget),
/// and a persistent bottom preview card for whichever business is
/// currently selected — replacing the previous tap-to-open-modal-sheet
/// interaction (BusinessMarkerSheet), which the mockup doesn't show at
/// all in favor of this persistent card.
class DiscoverMapScreen extends ConsumerStatefulWidget {
  const DiscoverMapScreen({super.key});

  @override
  ConsumerState<DiscoverMapScreen> createState() => _DiscoverMapScreenState();
}

class _DiscoverMapScreenState extends ConsumerState<DiscoverMapScreen> with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  String _localQuery = '';
  _ViewMode _viewMode = _ViewMode.map;
  Timer? _searchDebounce;

  // Which business's preview card is showing at the bottom of the map —
  // null means none picked yet (falls back to the nearest one, see
  // _selectedOrNearest below).
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(locationControllerProvider.notifier).refresh();
      _recenterOnUser();
      ref.read(businessListControllerProvider.notifier).load();
    });
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
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchDebounce?.cancel();
    _searchController.dispose();
    _mapController.dispose();
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
      _mapController.move(LatLng(position.latitude, position.longitude), 14);
    }
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

  /// The business the bottom preview card should show — whichever was
  /// last tapped, or (matching the mockup, which shows a business
  /// already selected on first load) the nearest one if nothing's been
  /// tapped yet.
  BusinessEntity? _selectedOrNearest(List<BusinessEntity> businesses) {
    if (businesses.isEmpty) return null;
    if (_selectedBusinessId != null) {
      for (final b in businesses) {
        if (b.id == _selectedBusinessId) return b;
      }
    }
    BusinessEntity nearest = businesses.first;
    for (final b in businesses.skip(1)) {
      if ((b.distanceKm ?? double.infinity) < (nearest.distanceKm ?? double.infinity)) {
        nearest = b;
      }
    }
    return nearest;
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(businessListControllerProvider);
    final String trimmedQuery = _localQuery.trim();
    // Single source of truth for "which category is selected" — shared
    // with FilterBottomSheet via businessFilterProvider (previously this
    // screen's quick-category chips tracked their own separate local
    // field, so picking a category here didn't show up when the filter
    // sheet was opened, and vice versa).
    final String? selectedCategory = ref.watch(businessFilterProvider).category;

    List<BusinessEntity> displayed;
    if (trimmedQuery.length >= _minSearchQueryLength) {
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
                  : _buildMap(displayed, listState),
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
          SegmentedButton<_ViewMode>(
            segments: [
              ButtonSegment(value: _ViewMode.map, icon: const Icon(Icons.map_outlined, size: 18), label: Text('discover.map'.tr())),
              ButtonSegment(value: _ViewMode.list, icon: const Icon(Icons.view_list_outlined, size: 18), label: Text('discover.list'.tr())),
            ],
            selected: {_viewMode},
            onSelectionChanged: (s) => setState(() => _viewMode = s.first),
            // No explicit style: the app-wide segmentedButtonTheme (see
            // app_theme.dart) already gives every SegmentedButton this
            // exact look — kept here before as a one-off override, now a
            // single source of truth so this and the filter sheet's
            // sort-by control can never drift apart.
          ),
          const SizedBox(height: 12),
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

  Widget _buildMap(List<BusinessEntity> businesses, BusinessListState listState) {
    final position = ref.watch(locationControllerProvider);
    final BusinessEntity? selected = _selectedOrNearest(businesses);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _defaultCenter,
            initialZoom: _defaultZoom,
            minZoom: 3,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: AppConstants.mapTileUrlTemplate,
              userAgentPackageName: AppConstants.mapTileUserAgentPackageName,
              maxNativeZoom: 19,
            ),
            MarkerLayer(
              markers: [
                if (position != null)
                  Marker(
                    point: LatLng(position.latitude, position.longitude),
                    width: 22,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.info,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                      ),
                    ),
                  ),
                for (final business in businesses)
                  Marker(
                    point: LatLng(business.latitude, business.longitude),
                    width: 40,
                    height: 40,
                    // Anchors the pin's visual tip (not its bounding box
                    // center) to the actual coordinate — marker-business
                    // .png is a teardrop shape with the point at the very
                    // bottom, same convention as the old hand-drawn pin.
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedBusinessId = business.id),
                      child: Image.asset('assets/markers/marker-business.png', width: 40, height: 40),
                    ),
                  ),
              ],
            ),
            // Required attribution — CARTO restyles OpenStreetMap's own
            // data into these dark tiles, so both need crediting, not
            // just one or the other.
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
                TextSourceAttribution('CARTO'),
              ],
            ),
          ],
        ),

        if (listState.isLoading)
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
          child: FloatingActionButton(
            heroTag: 'refresh-businesses',
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            onPressed: () => ref.read(businessListControllerProvider.notifier).load(),
            child: const Icon(Icons.refresh_rounded),
          ),
        ),
        Positioned(
          bottom: selected != null ? 96 : 16,
          right: selected != null ? 16 : 76,
          child: FloatingActionButton(
            heroTag: 'recenter-map',
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            onPressed: () async {
              await ref.read(locationControllerProvider.notifier).refresh();
              _recenterOnUser();
            },
            child: const Icon(Icons.my_location),
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
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          localizedCategoryName(context, business.category),
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (business.rating != null) ...[
                        Text(' · ', style: AppTextStyles.bodySmall),
                        const Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                        Text(business.rating!.toStringAsFixed(1), style: AppTextStyles.bodySmall),
                      ],
                      if (business.distanceKm != null) ...[
                        Text(' · ', style: AppTextStyles.bodySmall),
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
