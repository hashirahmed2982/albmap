class AppConstants {
  AppConstants._();

  /// When true, the DI container wires in-memory fake datasources instead
  /// of hitting the real backend — lets the app run fully offline with
  /// canned data. Toggle via --dart-define=USE_MOCK_DATA=false once a
  /// real API is available, or just flip the default below.
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: true,
  );

  // Map tile source — using flutter_map (OpenStreetMap-compatible), which
  // has no native SDK/API-key crash risk unlike Google Maps. Point this at
  // a tile provider of your choice; OSM's public server is fine for dev
  // but its usage policy disallows production traffic at scale — swap in
  // a MapTiler/Stadia Maps/self-hosted URL (with {z}/{x}/{y} placeholders)
  // before shipping.
  static const String mapTileUrlTemplate = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );
  static const String mapTileUserAgentPackageName = 'com.example.albmap';

  // API
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://api.albmap.com/v1',
  );
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

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
  static const List<String> supportedLocales = ['en', 'sq', 'it'];
}

enum UserRole { guest, business, admin }

enum BusinessStatus { pending, approved, rejected }

enum NotificationFrequency { always, daily, weekly }
