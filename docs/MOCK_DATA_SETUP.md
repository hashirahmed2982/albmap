# Running AlbMap on mock data (no backend required)

This lets you build/run/demo the full app — map, search, business details,
events, add business/event forms — without a backend server. Favorites and
Notifications already work with zero backend (Hive-only), so this doc covers
Auth, Businesses, and Events, which normally hit the network.

## How it works

Every feature's data layer already follows the same shape:

```
Repository → RemoteDataSource (interface) → RemoteDataSourceImpl (Dio, real API)
```

Three mock datasources ship in this project, implementing the exact same
interfaces as the real ones:

- `lib/features/auth/data/datasources/auth_mock_datasource.dart`
- `lib/features/map/data/datasources/business_mock_datasource.dart`
- `lib/features/events/data/datasources/event_mock_datasource.dart`

`lib/core/di/service_locator.dart` picks between the real and mock version
at startup based on a single flag:

```dart
// lib/core/constants/app_constants.dart
static const bool useMockData = bool.fromEnvironment(
  'USE_MOCK_DATA',
  defaultValue: true,   // <-- mock data ON by default
);
```

No other code changes — repositories, use cases, providers, and screens
have no idea whether they're talking to Dio or an in-memory list.

## Step 1 — Just run it

Mock data is **on by default**, so:

```bash
flutter pub get
flutter run
```

You'll land on the login screen. Since `AuthMockDataSource` accepts any
non-empty email/password, type anything and log in — or tap **Continue as
Guest**.

## Step 2 — What you get out of the box

- **Login/Sign Up** — any email/password combination succeeds; sign-up also
  always succeeds. Logged-in mock user is a `UserRole.business` account, so
  you'll see the full tab set (Favorites, Profile, Add Business, Add Event).
- **Discover Map** — 6 sample businesses around Tirana, Albania (cafés,
  restaurants, a gym, a market, a cinema, an auto shop), each with category,
  rating, opening hours, and phone number. Search and category filters work
  against this in-memory list.
- **Events** — 4 sample events tied to those same businesses, with real
  future dates (relative to when you run the app), so "upcoming events"
  filtering and Business Details' related-events section both work.
- **Add Business / Add Event** — forms submit into the same in-memory list
  for the current app session (resets on hot restart — this is a fake
  in-memory store, not persisted storage).
- **Favorites, Notifications** — already fully local (Hive), unaffected by
  this flag.

## Step 3 — Customize the mock data

Just edit the static lists directly:

- Add/edit businesses → `_businesses` list in `business_mock_datasource.dart`
- Add/edit events → `_events` list in `event_mock_datasource.dart`
  (event `businessId` values must match a business `id` from the list above
  for the "related events" section on Business Details to show anything)
- Change the logged-in demo user → `_fakeUser` in `auth_mock_datasource.dart`

All fields map 1:1 to `BusinessEntity`/`EventEntity`/`UserEntity` — no JSON
parsing involved, just Dart object literals.

## Step 4 — Switch to a real backend later

Once your API is ready, either:

**Option A — flip the default**, in `app_constants.dart`:
```dart
defaultValue: false,
```

**Option B — leave the default alone and pass it at run time** (no code
change needed at all):
```bash
flutter run --dart-define=USE_MOCK_DATA=false --dart-define=BASE_URL=https://your-api.example.com/v1
```

This is the cleaner option for CI/CD — mock data for local dev builds, real
backend for staging/prod builds, controlled entirely by build flags.

## Notes / limitations of the mock layer

- **Not persisted.** Data submitted via Add Business/Add Event lives only
  for the current app process — hot restart or app kill resets it. If you
  want persistence without a backend, swap the mock datasources' in-memory
  `List` for reads/writes against a local Hive box instead (the
  `BusinessLocalDataSource`/cache pattern already in the map feature is a
  good template).
- **No approval workflow simulation.** All mock businesses are pre-seeded as
  `BusinessStatus.approved`. Newly submitted ones via `submitBusiness()` are
  added as-is (whatever status you pass in `AddBusinessScreen`, currently
  `BusinessStatus.pending`) but there's no mock admin flow to "approve" them
  — they just won't show up on the map until you manually change their
  status in code.
- **No error-path testing.** The mock datasources don't simulate network
  failures, timeouts, or validation errors from a server. If you need to
  test `ErrorStateWidget`/retry flows, temporarily throw a `ServerException`
  from one of the mock methods.
