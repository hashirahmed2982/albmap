class AppConstants {
  AppConstants._();

  /// When true, the DI container wires in-memory fake datasources instead
  /// of hitting the real backend — lets the app run fully offline with
  /// canned data. Now that a real backend exists (see the separate
  /// albmap-backend project) and baseUrl below points at it, this
  /// defaults to false. Flip back to true for offline UI work, or run
  /// with --dart-define=USE_MOCK_DATA=true.
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: false,
  );

  // Map tile source — using flutter_map (OpenStreetMap-compatible), which
  // has no native SDK/API-key crash risk unlike Google Maps. Point this at
  // a tile provider of your choice; OSM's public server is fine for dev
  // but its usage policy disallows production traffic at scale — swap in
  // a MapTiler/Stadia Maps/self-hosted URL (with {z}/{x}/{y} placeholders)
  // before shipping. Google Maps is planned as a follow-up migration once
  // billing/API keys are set up on the client's side — until then this
  // stays free/OSM-based.
  //
  // Dark Matter (CARTO) rather than plain OSM tiles — the Bold Editorial
  // redesign's Discover Map mockup shows a near-black map, which the
  // default bright OSM tiles can't produce; this is still a free,
  // OpenStreetMap-data-based tile set (CARTO restyles OSM data, doesn't
  // replace it), just with dark styling baked into the raster tiles
  // themselves. Requires attributing both OpenStreetMap and CARTO — see
  // the RichAttributionWidget on each map screen.
  static const String mapTileUrlTemplate = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
  );
  static const String mapTileUserAgentPackageName = 'com.albmap.app';

  // API — defaults to the real production backend over HTTPS. Plain HTTP
  // (the previous default, a bare IP) doesn't work in release builds at
  // all: iOS App Transport Security blocks every cleartext request by
  // default, and Android has blocked cleartext traffic by default since
  // API 28 — neither platform has (or should have) an exception carved
  // out for it, so every API call would silently fail on a real device.
  // Override for local development against a backend running on your own
  // machine:
  //   Android emulator (host loopback alias):
  //     --dart-define=BASE_URL=http://10.0.2.2:4000/v1
  //   iOS simulator / same machine:
  //     --dart-define=BASE_URL=http://localhost:4000/v1
  //   Physical device (phone on the same Wi-Fi as your dev machine):
  //     --dart-define=BASE_URL=http://<your-machine-LAN-IP>:4000/v1
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://api.albmap.app/v1',
  );
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// The backend returns uploaded-image paths as relative paths (e.g.
  /// "/uploads/xxx.png"), not absolute URLs — deliberately, so a stored
  /// image reference never goes stale if the backend's externally-
  /// reachable address changes later (a new ngrok tunnel each session, a
  /// server migration, etc). This resolves such a path against whatever
  /// [baseUrl] is *currently* configured, at display time, rather than
  /// baking in whatever address happened to be current at upload time.
  ///
  /// Handles three cases:
  /// - Already-absolute URL (starts with http/https) — used as-is. Covers
  ///   data saved before this change, which may still have a full URL
  ///   baked in from an old session.
  /// - Relative server path (starts with "/uploads/") — prefixed with
  ///   this build's current server origin.
  /// - Anything else (e.g. a raw local device file path from image_picker
  ///   in mock mode, before it's been uploaded) — returned unchanged;
  ///   callers displaying a possibly-local-file path should check
  ///   [isRemoteUrl] first and use Image.file for the non-remote case.
  static String? resolveMediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('/uploads/')) {
      // baseUrl includes the API's "/v1" suffix (e.g.
      // "http://10.0.2.2:4000/v1"), but uploaded files are served from
      // the server root, not under /v1 — so strip that suffix to get the
      // bare origin before appending the relative path.
      final origin = baseUrl.endsWith('/v1') ? baseUrl.substring(0, baseUrl.length - 3) : baseUrl;
      return '$origin$path';
    }
    return path;
  }

  /// True if [path] is something Image.network can load directly (either
  /// already absolute, or one of our own server-relative paths that
  /// [resolveMediaUrl] will turn into a full URL) — false for a raw local
  /// device file path, which needs Image.file instead.
  static bool isRemoteMediaPath(String? path) {
    if (path == null || path.isEmpty) return false;
    return path.startsWith('http://') || path.startsWith('https://') || path.startsWith('/uploads/');
  }

  // Hive boxes
  static const String userBox = 'user_box';
  static const String businessCacheBox = 'business_cache_box';
  static const String favoritesBox = 'favorites_box';
  static const String settingsBox = 'settings_box';

  // Secure storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  // Pagination
  static const int defaultPageSize = 20;

  // Map defaults
  static const double defaultZoom = 14.0;
  static const double defaultSearchRadiusKm = 10.0;

  // Misc
  static const String appName = 'AlbMap';
  static const List<String> supportedLocales = ['en', 'sq', 'de'];
}

enum UserRole { guest, business, admin }

enum BusinessStatus { pending, approved, rejected }
