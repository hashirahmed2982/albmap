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

  // API — defaults to the Android emulator's alias for the host machine's
  // localhost (10.0.2.2), matching the most common Flutter dev workflow
  // (albmap-backend running via `npm run dev` on your machine, app running
  // in an Android emulator). Override for other setups:
  //   iOS simulator / running backend on the same machine:
  //     --dart-define=BASE_URL=http://localhost:4000/v1
  //   Physical device (phone on the same Wi-Fi as your dev machine):
  //     --dart-define=BASE_URL=http://<your-machine-LAN-IP>:4000/v1
  //   Production:
  //     --dart-define=BASE_URL=https://your-deployed-api.com/v1
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:4000/v1',
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
  static const List<String> supportedLocales = ['en', 'sq', 'de'];
}

enum UserRole { guest, business, admin }

enum BusinessStatus { pending, approved, rejected }

enum NotificationFrequency { always, daily, weekly }
