# AlbMap — Flutter Frontend

Business & event discovery app for iOS and Android. Clean Architecture, Riverpod,
go_router, offline-first data layer.

This package contains **only the mobile frontend** (matches the "Flutter Mobile
Application" component of the technical spec). It expects a REST backend at
the URL configured in `lib/core/constants/app_constants.dart`. Until that backend
exists, the app will build and navigate, but network calls will fail — that's
expected and by design (see "Running against no backend" below).

---

## 0. Quick links

- **Run without a backend** → `docs/MOCK_DATA_SETUP.md` (mock data is ON by default — just `flutter run`)
- **Google Maps setup** → `docs/GOOGLE_MAPS_SETUP.md`

## 1. What's included

- **13 screens**, fully wired: Splash, Login/Sign Up, Discover Map, Business
  Details, Events, Event Details, Favorites, Notifications, Profile, Add
  Business, Add Event, Settings, Contact Us, About Us.
- **Clean Architecture** per feature: `data/` (models, datasources,
  repository impl) → `domain/` (entities, repository interface, use cases) →
  `presentation/` (Riverpod providers, screens, widgets).
- **State management**: Riverpod (`StateNotifierProvider` for mutable state,
  `FutureProvider` for one-shot fetches).
- **Navigation**: `go_router` with a `StatefulShellRoute` bottom-nav shell and
  auth-aware redirects (guest vs business-user route guards).
- **Networking**: Dio with an auth-header interceptor and silent 401 →
  token-refresh flow.
- **Offline support**: Hive-backed local cache for businesses (map screen
  falls back to last-cached list when offline) and favorites (fully local,
  no backend dependency).
- **DI**: GetIt service locator (`lib/core/di/service_locator.dart`), wired
  once at startup — Riverpod providers pull dependencies from it rather than
  redefining the graph in two places.
- **Error handling**: `dartz Either<Failure, T>` throughout the domain layer;
  data-layer exceptions never leak past repositories.

## 2. What's NOT included (by design)

- The backend API, MySQL schema, and admin/website Next.js apps — out of
  scope for this Flutter deliverable.
- Actual Poppins font files (pubspec's font block is commented out — see
  step 5).
- Firebase project config files (`google-services.json` /
  `GoogleService-Info.plist`) — you'll generate these yourself in step 6.
- Generated code (`*.g.dart`, `*.freezed.dart`) — none of the current models
  use `json_serializable`/`freezed` codegen (I hand-wrote `fromJson`/`toJson`
  for transparency and zero build-runner friction), but those packages are
  in `pubspec.yaml` if you want to migrate to it later.
- Google/Facebook social login SDK wiring — the buttons exist and call
  repository methods (`loginWithGoogle`/`loginWithFacebook`), but you must
  add `google_sign_in` / `flutter_facebook_auth` and get the OAuth token
  before hitting those endpoints.
- Image picker wiring for logo/poster uploads — the UI placeholders are
  there; hook up `image_picker` + your storage upload endpoint.

---

## 3. Prerequisites

- Flutter 3.22+ (`flutter --version`)
- A physical device or emulator with Google Play Services (for Google Maps)
- A Google Cloud project with **Maps SDK for Android** and **Maps SDK for
  iOS** enabled, plus an API key
- (Optional, for push notifications) A Firebase project

---

## 4. Setup steps

### Step 1 — Create the platform folders
This zip contains only `lib/`, `pubspec.yaml`, and config files — no
`android/` or `ios/` folders (those are binary/platform-generated and don't
belong in a hand-authored deliverable). Generate them:

```bash
cd albmap
flutter create --platforms=android,ios --org com.yourcompany .
```

This will NOT overwrite your existing `lib/` or `pubspec.yaml` — it only
fills in the missing platform folders.

### Step 2 — Install dependencies
```bash
flutter pub get
```

### Step 3 — Add your Google Maps API key

**Android** — edit `android/app/src/main/AndroidManifest.xml`, inside `<application>`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_MAPS_API_KEY"/>
```
Also set `minSdkVersion 21` or higher in `android/app/build.gradle`.

**iOS** — edit `ios/Runner/AppDelegate.swift`:
```swift
import GoogleMaps // add this import

// inside application(_:didFinishLaunchingWithOptions:), before return:
GMSServices.provideAPIKey("YOUR_IOS_MAPS_API_KEY")
```
Also add to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>AlbMap uses your location to show nearby businesses and events.</string>
```

### Step 4 — Point the app at your backend
Edit `lib/core/constants/app_constants.dart`:
```dart
static const String baseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'https://your-api.example.com/v1',
);
```
Or pass it at build time without editing code:
```bash
flutter run --dart-define=BASE_URL=https://your-api.example.com/v1
```

Expected REST contract (adjust datasource files under
`lib/features/*/data/datasources/` if your API differs):
- `POST /auth/login`, `/auth/signup`, `/auth/google`, `/auth/facebook` →
  `{ accessToken, refreshToken, user }`
- `POST /auth/refresh` → `{ accessToken }`
- `GET /auth/me`, `POST /auth/forgot-password`
- `GET /businesses?category&radiusKm&lat&lng&sortBy&status=approved` →
  `{ data: [...] }`
- `GET /businesses/:id`, `GET /businesses/search?q=`, `POST /businesses`
- `GET /events?category&businessId&from&to` → `{ data: [...] }`
- `GET /events/:id`, `POST /events`

### Step 5 — (Optional) Add real fonts
The app references a `Poppins` font family but ships without the `.ttf`
files (licensing). To enable it:
1. Download Poppins from [Google Fonts](https://fonts.google.com/specimen/Poppins)
2. Drop the 4 weights into `assets/fonts/`
3. Uncomment the `fonts:` block at the bottom of `pubspec.yaml`

Without this step the app still runs fine — Flutter silently falls back to
the platform default font.

### Step 6 — (Optional) Enable push notifications
1. Create a Firebase project, add Android + iOS apps
2. Download `google-services.json` → `android/app/`
3. Download `GoogleService-Info.plist` → `ios/Runner/`
4. In `lib/main.dart`, uncomment:
   ```dart
   await Firebase.initializeApp();
   ```
5. Follow the `firebase_messaging` setup for background handlers
   (`onBackgroundMessage`) — wire incoming payloads into
   `NotificationsController` (`lib/features/notifications/presentation/providers/notifications_providers.dart`).

### Step 7 — Run
```bash
flutter run
```

---

## 5. Running against no backend

The Discover Map, Events, and Business Details screens will show error/empty
states until a backend is live — this is intentional and matches Clean
Architecture's contract (repositories return `Failure`, UI renders
`ErrorStateWidget`). Favorites work fully offline since they're Hive-only.
To develop UI without a backend, either:
- Point `baseUrl` at a mock server (e.g. `json-server`, Mockoon), or
- Temporarily swap the `*RemoteDataSourceImpl` registrations in
  `lib/core/di/service_locator.dart` for fake in-memory implementations.

## 6. Project structure

```
lib/
  core/                    # Shared infrastructure, no feature imports it depends on
    constants/             # AppConstants, enums (UserRole, BusinessStatus, ...)
    di/                    # GetIt service_locator.dart — single wiring point
    error/                 # Failure (domain) + Exception (data) hierarchies
    network/               # DioClient (auth + refresh interceptor), NetworkInfo
    router/                # go_router config + route guards
    theme/                 # AppColors, AppTextStyles, AppTheme
    usecase/                # Base UseCase<Type, Params> abstraction
    widgets/                # PrimaryButton, Loading/Error/Empty states, MainShell
  features/
    <feature>/
      data/
        datasources/        # Remote (Dio) + local (Hive) sources
        models/              # extends domain entity, adds fromJson/toJson
        repositories/        # implements domain repository interface
      domain/
        entities/            # Pure Dart, no framework deps
        repositories/        # Abstract interface (data layer implements it)
        usecases/             # One class per use case, single `call()` method
      presentation/
        providers/            # Riverpod StateNotifier/FutureProvider
        screens/               # Full-page widgets, wired to go_router
        widgets/               # Feature-local reusable widgets
  main.dart                  # Bootstraps DI + Hive, runs ProviderScope
```

Thirteen features exist under `lib/features/`: `splash`, `auth`, `map`
(Discover Map + business domain/data shared by other features),
`business_details`, `events`, `favorites`, `notifications`, `profile`,
`add_business`, `add_event`, `settings`, `contact_us`, `about_us`.

## 7. Conventions / best practices applied

- **Dependency direction**: `presentation` → `domain` ← `data`. Domain never
  imports data or presentation. Enforced by folder discipline, not tooling —
  review PRs for violations.
- **Either<Failure, T>** everywhere in the domain layer — no throwing across
  layer boundaries, no `null` used to mean "error."
- **Immutable state objects** for Riverpod (`copyWith` pattern) —
  no direct field mutation.
- **`const` constructors** wherever possible (enforced by `analysis_options.yaml`).
- **Distance calculation** happens client-side in the repository
  (`Geolocator.distanceBetween`), not duplicated in widgets.
- **Offline fallback** lives in the repository, not the UI — screens don't
  know or care whether data came from cache or network.
- **Route guards** centralized in `go_router`'s `redirect`, not scattered
  `if (isGuest)` checks inside every screen's `build()`.
