/// Google's own "Night" styled-map preset (from the Maps Platform styling
/// wizard) — matches the Bold Editorial redesign's near-black map look,
/// same as the old CARTO Dark Matter tiles did before this migration.
///
/// Applied via `GoogleMap(style: kGoogleMapsDarkStyle, ...)`. Kept as a raw
/// JSON string (not a Dart object) since that's what GoogleMap.style
/// takes directly — no need to round-trip through jsonEncode.
///
/// The website (albmap-website's src/lib/map-style.ts) uses the exact
/// same style array — Google Maps' JSON styling format is shared across
/// the JS, Android, and iOS SDKs, so keeping both copies in sync keeps
/// the app and website's maps looking identical.
///
/// `road`/`road.local` labels were brightened from Google's original
/// "Night" preset values (#8a8a8a/#616161, each with no stroke override
/// of their own — just the global #212121 one, nearly the same shade as
/// the background itself) to #b8b8b8/#c9c9c9 with their own #1a1a1a
/// stroke. The originals sat at roughly 2.5-3:1 contrast against this
/// style's near-black background — under WCAG's 4.5:1 minimum for
/// legible text — so street names rendered but were nearly impossible to
/// actually read. The new values land around 8-10:1, matching how
/// legible administrative.country (#9e9e9e) and administrative.locality
/// (#bdbdbd) already were in this same style. road.local is brighter than
/// the generic road fill, not dimmer — those are the actual street names
/// most people are reading; arterials/highways are more often recognized
/// by shape/route number than by name.
const String kGoogleMapsDarkStyle = '''
[
  { "elementType": "geometry", "stylers": [{ "color": "#212121" }] },
  { "elementType": "labels.icon", "stylers": [{ "visibility": "off" }] },
  { "elementType": "labels.text.fill", "stylers": [{ "color": "#757575" }] },
  { "elementType": "labels.text.stroke", "stylers": [{ "color": "#212121" }] },
  { "featureType": "administrative", "elementType": "geometry", "stylers": [{ "color": "#757575" }] },
  { "featureType": "administrative.country", "elementType": "labels.text.fill", "stylers": [{ "color": "#9e9e9e" }] },
  { "featureType": "administrative.land_parcel", "stylers": [{ "visibility": "off" }] },
  { "featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{ "color": "#bdbdbd" }] },
  { "featureType": "poi", "elementType": "labels.text.fill", "stylers": [{ "color": "#757575" }] },
  { "featureType": "poi.park", "elementType": "geometry", "stylers": [{ "color": "#181818" }] },
  { "featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{ "color": "#616161" }] },
  { "featureType": "poi.park", "elementType": "labels.text.stroke", "stylers": [{ "color": "#1b1b1b" }] },
  { "featureType": "road", "elementType": "geometry.fill", "stylers": [{ "color": "#2c2c2c" }] },
  { "featureType": "road", "elementType": "labels.text.fill", "stylers": [{ "color": "#b8b8b8" }] },
  { "featureType": "road", "elementType": "labels.text.stroke", "stylers": [{ "color": "#1a1a1a" }] },
  { "featureType": "road.arterial", "elementType": "geometry", "stylers": [{ "color": "#373737" }] },
  { "featureType": "road.highway", "elementType": "geometry", "stylers": [{ "color": "#3c3c3c" }] },
  { "featureType": "road.highway.controlled_access", "elementType": "geometry", "stylers": [{ "color": "#4e4e4e" }] },
  { "featureType": "road.local", "elementType": "labels.text.fill", "stylers": [{ "color": "#c9c9c9" }] },
  { "featureType": "road.local", "elementType": "labels.text.stroke", "stylers": [{ "color": "#1a1a1a" }] },
  { "featureType": "transit", "elementType": "labels.text.fill", "stylers": [{ "color": "#757575" }] },
  { "featureType": "water", "elementType": "geometry", "stylers": [{ "color": "#000000" }] },
  { "featureType": "water", "elementType": "labels.text.fill", "stylers": [{ "color": "#3d3d3d" }] }
]
''';
