import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/entities/business_entity.dart';
import '../providers/business_providers.dart';
import '../widgets/business_list_view.dart';
import '../widgets/business_marker_sheet.dart';
import '../widgets/filter_bottom_sheet.dart';

enum _ViewMode { map, list }

/// 3. Discover Map Screen — main app screen. The user explicitly picks
/// between a Map view and a List view via a segmented toggle; this is a
/// preference, not something the app decides for them.
///
/// Safety note: [AppConstants.googleMapsConfigured] still gates whether the
/// native GoogleMap widget is ever mounted — a missing/invalid Maps API key
/// crashes the whole app process at the native level, uncatchable from Dart
/// (see docs/GOOGLE_MAPS_SETUP.md). So if the user selects Map view while
/// it isn't configured yet, we show an explanatory card with a one-tap
/// switch to List view instead of ever building a GoogleMap widget.
class DiscoverMapScreen extends ConsumerStatefulWidget {
  const DiscoverMapScreen({super.key});

  @override
  ConsumerState<DiscoverMapScreen> createState() => _DiscoverMapScreenState();
}

class _DiscoverMapScreenState extends ConsumerState<DiscoverMapScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  String _localQuery = '';
  String? _selectedCategory;
  late _ViewMode _viewMode;

  static const double _barHeight = 52;

  static const List<String> _quickCategories = [
    'Restaurants', 'Cafes', 'Shops', 'Services', 'Health', 'Entertainment',
  ];

  static const CameraPosition _defaultCamera = CameraPosition(
    target: LatLng(41.3275, 19.8187), // Tirana, Albania as sensible default
    zoom: 13,
  );

  @override
  void initState() {
    super.initState();
    _viewMode = AppConstants.googleMapsConfigured ? _ViewMode.map : _ViewMode.list;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (AppConstants.googleMapsConfigured) {
        await ref.read(locationControllerProvider.notifier).refresh();
        _recenterOnUser();
      }
      ref.read(businessListControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _recenterOnUser() {
    final position = ref.read(locationControllerProvider);
    if (position != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 14),
      );
    }
  }

  Set<Marker> _buildMarkers(List<BusinessEntity> businesses) {
    return businesses.map((b) {
      return Marker(
        markerId: MarkerId(b.id),
        position: LatLng(b.latitude, b.longitude),
        infoWindow: InfoWindow(title: b.name),
        onTap: () => showModalBottomSheet(
          context: context,
          builder: (_) => BusinessMarkerSheet(business: b),
        ),
      );
    }).toSet();
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
                  : (AppConstants.googleMapsConfigured
                      ? _buildMap(listState)
                      : _buildMapUnavailable()),
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
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.background,
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                    shadowColor: Colors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _localQuery = v),
                      decoration: const InputDecoration(
                        hintText: 'Search businesses...',
                        prefixIcon: Icon(Icons.search, color: AppColors.primary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
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
                    onPressed: () => showModalBottomSheet(
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
            segments: const [
              ButtonSegment(value: _ViewMode.map, icon: Icon(Icons.map_outlined, size: 18), label: Text('Map')),
              ButtonSegment(value: _ViewMode.list, icon: Icon(Icons.view_list_outlined, size: 18), label: Text('List')),
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
                    label: 'All',
                    color: AppColors.primary,
                    icon: Icons.apps_rounded,
                    selected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  );
                }
                final category = _quickCategories[i - 1];
                return _CategoryChip(
                  label: category,
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
            '$resultCount business${resultCount == 1 ? '' : 'es'} found',
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(BusinessListState listState) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _defaultCamera,
          onMapCreated: (controller) {
            _mapController = controller;
            _recenterOnUser();
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          markers: _buildMarkers(listState.businesses),
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
          bottom: 16, right: 16,
          child: FloatingActionButton(
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

  Widget _buildMapUnavailable() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.map_outlined, size: 40, color: AppColors.warning),
            ),
            const SizedBox(height: 20),
            Text("Map view isn't set up yet", style: AppTextStyles.h3, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              "A Google Maps API key hasn't been configured for this app. "
              'You can still browse every business using List view.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: PrimaryButton(
                label: 'Switch to List view',
                icon: Icons.view_list_outlined,
                onPressed: () => setState(() => _viewMode = _ViewMode.list),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: selected ? Colors.white : color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
