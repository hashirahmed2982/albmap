# Map setup — no API key needed

This doc used to describe wiring up `google_maps_flutter` with a Google Maps
API key. That's no longer how the Discover Map screen works, so the old
instructions here were actively wrong — this replaces them.

## What the app actually uses

`lib/features/map/presentation/screens/discover_map_screen.dart` renders its
map with [`flutter_map`](https://pub.dev/packages/flutter_map) (tiles from
OpenStreetMap by default), not `google_maps_flutter`. Check `pubspec.yaml` —
there is no `google_maps_flutter` dependency, and none of the `MAPS_CONFIGURED`
/ `googleMapsConfigured` crash-safety flag machinery described in earlier
versions of this doc exists in the code anymore. There's nothing to enable:
the map renders out of the box, no Google Cloud project, no API key, no
per-platform native wiring (`GMSServices.provideAPIKey`, manifest
`meta-data`, etc.).

Location itself (the blue "you are here" dot, and sorting results by
distance) still uses `geolocator`, which needs the usual runtime location
permission — already wired:

- **Android**: `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` in
  `android/app/src/main/AndroidManifest.xml`.
- **iOS**: `NSLocationWhenInUseUsageDescription` in `ios/Runner/Info.plist`.

No setup steps remain here — just `flutter run` and grant the location
permission when prompted.

## Firebase / Google Sign-In / Facebook Login setup

That's a separate, still-relevant topic — see
[`docs/FIREBASE_SOCIAL_LOGIN_SETUP.md`](./FIREBASE_SOCIAL_LOGIN_SETUP.md).
