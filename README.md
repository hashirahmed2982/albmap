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
- **Map** → `docs/GOOGLE_MAPS_SETUP.md` (short read — no API key needed, the map uses `flutter_map`/OpenStreetMap)
- **Firebase / Google Sign-In / Facebook Login / permissions** → `docs/FIREBASE_SOCIAL_LOGIN_SETUP.md`

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
- Firebase project **config files** (`google-services.json` /
  `GoogleService-Info.plist`) — these are per-environment and gitignored on
  purpose; you add your own. Everything else (native manifest/Info.plist
  entries, Podfile, `AppDelegate.swift` wiring, Dart-side `Firebase.initializeApp()`)
  is already done — see `docs/FIREBASE_SOCIAL_LOGIN_SETUP.md`.
- Generated code (`*.g.dart`, `*.freezed.dart`) — none of the current models
  use `json_serializable`/`freezed` codegen (I hand-wrote `fromJson`/`toJson`
  for transparency and zero build-runner friction), but those packages are
  in `pubspec.yaml` if you want to migrate to it later.

---

## 3. Prerequisites

- Flutter 3.22+ (`flutter --version`)
- A physical device or emulator (Android or iOS) — no Google Play Services
  requirement, the map doesn't use Google Maps
- (Optional, for push notifications / Google Sign-In / Facebook Login) A
  Firebase project + Facebook app — see `docs/FIREBASE_SOCIAL_LOGIN_SETUP.md`

---

## 4. Setup steps

### Step 1 — Install dependencies
The `android/` and `ios/` native folders are committed in this repo (already
configured — permissions, Podfile, Facebook SDK wiring, etc.), so there's no
`flutter create` step needed. Just:

```bash
cd albmap
flutter pub get
```

On iOS, also install the native pods (needed once, and again any time a
plugin is added/changed in `pubspec.yaml`):
```bash
cd ios && pod install && cd ..
```

### Step 2 — (Optional) Firebase / Google Sign-In / Facebook Login
The map itself needs no setup (see Step 3). Push notifications and social
login do need your own Firebase/Google Cloud/Facebook accounts — that's a
config-files-and-console-registration task, not a code task, so it's split
out into its own doc: **`docs/FIREBASE_SOCIAL_LOGIN_SETUP.md`**. The app
runs fine without it; those features just stay inactive until you do it.

### Step 3 — Map
No API key or setup required — the Discover Map screen uses `flutter_map`
with OpenStreetMap tiles, not Google Maps. See `docs/GOOGLE_MAPS_SETUP.md`
if you want the details.

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

### Step 6 — Run
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
