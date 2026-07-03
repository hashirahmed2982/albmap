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

  /// Google Maps requires a valid API key configured natively in
  /// AndroidManifest.xml / AppDelegate.swift. Without one, the native
  /// GoogleMap view throws an uncatchable native exception that kills the
  /// whole app process (not a normal Dart exception — try/catch can't stop
  /// it). So Discover Map checks this flag *before* ever mounting the
  /// GoogleMap widget, falling back to a list view instead.
  ///
  /// Set to true only once you've completed docs/GOOGLE_MAPS_SETUP.md,
  /// either by flipping the default here or running with
  /// --dart-define=MAPS_CONFIGURED=true
  static const bool googleMapsConfigured = bool.fromEnvironment(
    'MAPS_CONFIGURED',
    defaultValue: false,
  );

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
