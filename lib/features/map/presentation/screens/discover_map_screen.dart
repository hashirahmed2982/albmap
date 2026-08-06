import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../categories/domain/category_translations.dart';
import '../../domain/entities/business_entity.dart';
import '../providers/business_providers.dart';
import '../widgets/business_list_view.dart';
import '../widgets/business_marker_sheet.dart';
import '../widgets/filter_bottom_sheet.dart';
import 'dart:ui' as ui;

enum _ViewMode { map, list }

/// 3. Discover Map Screen — main app screen. The user explicitly picks
/// between a Map view and a List view via a segmented toggle.
///
/// Uses flutter_map (OpenStreetMap-compatible, open source) instead of
/// Google Maps — it's a pure-Dart widget with no native SDK or API key, so
/// there's no equivalent of the "missing key crashes the whole app" failure
/// mode Google Maps has. Tile source is configured in AppConstants —
/// point it at MapTiler/Stadia/self-hosted tiles before shipping to
/// production (OSM's free public server disallows production-scale
/// traffic per its usage policy).
class DiscoverMapScreen extends ConsumerStatefulWidget {
  const DiscoverMapScreen({super.key});

  @override
  ConsumerState<DiscoverMapScreen> createState() => _DiscoverMapScreenState();
}

class _DiscoverMapScreenState extends ConsumerState<DiscoverMapScreen> with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  String _localQuery = '';
  String? _selectedCategory;
  _ViewMode _viewMode = _ViewMode.map;

  static const double _barHeight = 52;

  static const List<String> _quickCategories = [
    'Restaurants', 'Cafes', 'Shops', 'Services', 'Health', 'Entertainment',
  ];

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
      unawaited(ref.read(businessListControllerProvider.notifier).load());
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
      unawaited(ref.read(businessListControllerProvider.notifier).load());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _recenterOnUser() {
    final position = ref.read(locationControllerProvider);
    if (position != null) {
      _mapController.move(LatLng(position.latitude, position.longitude), 14);
    }
  }

  List<BusinessEntity> _filtered(List<BusinessEntity> all) {
    Iterable<BusinessEntity> result = all;
    if (_selectedCategory != null) {
      result = result.where((b) => b.category == _selectedCategory);
    }
    final q = _localQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((b) => b.name.toLowerCase().contains(q));
    }
    return result.toList();
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(businessListControllerProvider);
    final displayed = _filtered(listState.businesses);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(context, resultCount: displayed.length),
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

  Widget _buildHeader(BuildContext context, {required int resultCount}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.background],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12 + MediaQuery.of(context).padding.top, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: _barHeight,
                  child: Material(
                    elevation: 2,
                    color: AppColors.surface,
                    shadowColor: Colors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _localQuery = v),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                      cursorColor: AppColors.primary,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: 'discover.searchHint'.tr(),
                        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                        prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 24),
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.surface,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: _barHeight,
                width: _barHeight,
                child: Material(
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.surface,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.tune, color: AppColors.primary),
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
            style: SegmentedButton.styleFrom(
              backgroundColor: AppColors.surface,
              selectedBackgroundColor: AppColors.primary,
              selectedForegroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.divider),
              textStyle: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickCategories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return _CategoryChip(
                    label: 'common.all'.tr(),
                    color: AppColors.primary,
                    icon: Icons.apps_rounded,
                    selected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  );
                }
                final category = _quickCategories[i - 1];
                return _CategoryChip(
                  label: localizedCategoryName(context, category),
                  color: categoryColor(category),
                  icon: categoryIcon(category),
                  selected: _selectedCategory == category,
                  onTap: () => setState(() => _selectedCategory = category),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(
            resultCount == 1 ? 'discover.resultFound'.tr() : 'discover.resultsFound'.tr(args: ['$resultCount']),
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMap(List<BusinessEntity> businesses, BusinessListState listState) {
    final position = ref.watch(locationControllerProvider);

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
                    width: 42,
                    height: 42,
                    child: GestureDetector(
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        builder: (_) => BusinessMarkerSheet(business: business),
                      ),
                      child: _MapPin(color: categoryColor(business.category), icon: categoryIcon(business.category)),
                    ),
                  ),
              ],
            ),
            // Required attribution for OpenStreetMap-derived tiles — check
            // your specific tile provider's attribution requirements if you
            // switch away from the default OSM URL.
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
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
          bottom: 78, right: 16,
          child: FloatingActionButton(
            heroTag: 'refresh-businesses',
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            elevation: 3,
            onPressed: () => ref.read(businessListControllerProvider.notifier).load(),
            child: const Icon(Icons.refresh_rounded),
          ),
        ),
        Positioned(
          bottom: 16, right: 16,
          child: FloatingActionButton(
            heroTag: 'recenter-map',
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            elevation: 3,
            onPressed: () async {
              await ref.read(locationControllerProvider.notifier).refresh();
              _recenterOnUser();
            },
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}

/// Teardrop-style map pin, colored per business category — flutter_map has
/// no built-in marker icon system like Google Maps, markers are just
/// arbitrary widgets, so this is hand-rolled but fully theme-consistent.
class _MapPin extends StatelessWidget {
  const _MapPin({required this.color, required this.icon});
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        CustomPaint(size: const Size(10, 6), painter: _PinTailPainter(color: color)),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  const _PinTailPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final ui.Path path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter oldDelegate) => oldDelegate.color != color;
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : color),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(color: selected ? Colors.white : color, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
