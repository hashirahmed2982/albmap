import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../map/presentation/providers/business_providers.dart';

/// Full-screen "drop a pin" location picker for Add Business.
///
/// The map moves under a fixed center pin (the standard drop-pin UX
/// pattern) rather than placing a draggable marker — this avoids having to
/// hit-test taps against a marker widget, and makes it obvious exactly
/// which point will be used (always the exact center of the screen).
///
/// Returns the picked [LatLng] via Navigator.pop when the user confirms,
/// or null if they back out without picking anything.
class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({super.key, this.initialLocation});

  /// Pre-fills the picker at this location if provided (e.g. re-editing a
  /// previously picked location) — otherwise defaults to the user's current
  /// GPS location if available, falling back to Tirana.
  final LatLng? initialLocation;

  @override
  ConsumerState<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng _pickedLocation = const LatLng(41.3275, 19.8187); // Tirana default

  static const double _defaultZoom = 15;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _pickedLocation = widget.initialLocation!;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(locationControllerProvider.notifier).refresh();
        final position = ref.read(locationControllerProvider);
        if (position != null && mounted) {
          final userLocation = LatLng(position.latitude, position.longitude);
          setState(() => _pickedLocation = userLocation);
          _mapController.move(userLocation, _defaultZoom);
        }
      });
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No boxy AppBar here — a floating back button over the full-bleed
      // map instead, matching Discover Map's map-first look rather than
      // the flat default title bar this screen had before.
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pickedLocation,
              initialZoom: _defaultZoom,
              minZoom: 3,
              maxZoom: 18,
              // Fires continuously as the user drags — updates _pickedLocation
              // to whatever's currently under the fixed center pin.
              onPositionChanged: (camera, hasGesture) {
                setState(() => _pickedLocation = camera.center);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: AppConstants.mapTileUrlTemplate,
                userAgentPackageName: AppConstants.mapTileUserAgentPackageName,
                maxNativeZoom: 19,
              ),
              const RichAttributionWidget(
                attributions: [TextSourceAttribution('OpenStreetMap contributors')],
              ),
            ],
          ),

          // Fixed center pin — this is what "picks" the location, not a tap.
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40), // offsets for pin's visual tip
                child: Icon(Icons.location_on, size: 48, color: AppColors.primary),
              ),
            ),
          ),

          // Floating back button + title chip, in place of a boxy AppBar.
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  children: [
                    Material(
                      elevation: 2,
                      shadowColor: Colors.black.withValues(alpha: 0.15),
                      color: AppColors.surface,
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Text(
                          'locationPicker.title'.tr(),
                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Coordinates readout + confirm button
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.pin_drop_outlined, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'locationPicker.coordinates'.tr(args: [
                              _pickedLocation.latitude.toStringAsFixed(5),
                              _pickedLocation.longitude.toStringAsFixed(5),
                            ]),
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'locationPicker.instructions'.tr(),
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'locationPicker.confirm'.tr(),
                      onPressed: () => Navigator.of(context).pop(_pickedLocation),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Recenter-on-me FAB
          Positioned(
            right: 16,
            bottom: 190,
            child: FloatingActionButton(
              heroTag: 'recenter-location-picker',
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
              onPressed: () async {
                await ref.read(locationControllerProvider.notifier).refresh();
                final position = ref.read(locationControllerProvider);
                if (position != null) {
                  final userLocation = LatLng(position.latitude, position.longitude);
                  _mapController.move(userLocation, _defaultZoom);
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
