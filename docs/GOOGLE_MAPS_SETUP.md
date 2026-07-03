# Google Maps integration setup

The Discover Map screen (`lib/features/map/presentation/screens/discover_map_screen.dart`)
uses `google_maps_flutter`, already declared in `pubspec.yaml`. It won't
render anything until you complete the steps below — this is a Google Cloud
credentials/platform-config task, not a code task, so it can't ship
pre-wired in the zip.

## Crash safety — read this first

A missing or invalid Maps API key doesn't just fail to render a map — it
crashes the **entire app process** at the native Android/iOS level
(`FATAL EXCEPTION`, `SIG 9` in Android logs). This is not a normal Dart
exception; it can't be caught with try/catch because it happens on a native
SDK thread outside Flutter's control.

To prevent this, the project never mounts the native `GoogleMap` widget
unless you explicitly say the key is configured:

```dart
// lib/core/constants/app_constants.dart
static const bool googleMapsConfigured = bool.fromEnvironment(
  'MAPS_CONFIGURED',
  defaultValue: false,   // <-- OFF by default, on purpose
);
```

**While this is `false`** (the default), Discover Map shows businesses as a
plain list instead — same data, same search/filter, zero crash risk. Once
you've completed the setup below, flip it on either by:
- Editing the default above to `true`, or
- Running with `--dart-define=MAPS_CONFIGURED=true` (matches the same
  pattern as `USE_MOCK_DATA` — see `docs/MOCK_DATA_SETUP.md`)

**Don't skip this step and just add the key** — if you add a valid key but
forget to flip `googleMapsConfigured` to `true`, you'll just keep seeing the
list fallback (safe, just not what you want). If you flip it to `true`
*without* a valid key configured natively, you're back to the crash — the
flag is a promise to the app that the native setup is done, not a
substitute for it.

## Step 1 — Get a Google Maps API key

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a project (or select an existing one)
3. Go to **APIs & Services → Library** and enable:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Places API** (optional — only needed if you later add address
     autocomplete to Add Business's address field)
4. Go to **APIs & Services → Credentials → Create Credentials → API Key**
5. You'll get one key. You *can* use the same key for both platforms, but
   Google strongly recommends creating **two separate keys**, each
   restricted to its own platform (Android app / iOS bundle ID) — this
   limits the blast radius if one key leaks. Under the key's settings:
   - Android key → **Application restrictions → Android apps** → add your
     package name + SHA-1 fingerprint (get it via
     `cd android && ./gradlew signingReport`)
   - iOS key → **Application restrictions → iOS apps** → add your bundle ID

Keep both keys somewhere safe — you'll paste them into platform config
files, never into Dart code (they'd end up in your git history and app
binary in plaintext either way, but at minimum don't compound the problem
by also hardcoding them in `lib/`).

## Step 2 — Generate the platform folders (if not done already)

```bash
cd albmap
flutter create --platforms=android,ios --org com.yourcompany .
flutter pub get
```

## Step 3 — Android setup

Edit `android/app/src/main/AndroidManifest.xml`. Inside the `<application>`
tag (as a sibling of `<activity>`), add:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_MAPS_API_KEY"/>
```

Also add the location permission near the top of the manifest, outside
`<application>`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

In `android/app/build.gradle`, confirm:

```groovy
defaultConfig {
    minSdkVersion 21   // google_maps_flutter requires 20+; geolocator needs 21+
    // ...
}
```

**Don't hardcode the key in source control.** Recommended pattern —
`android/local.properties` (already gitignored by default):

```properties
MAPS_API_KEY=YOUR_ANDROID_MAPS_API_KEY
```

Then in `android/app/build.gradle`, read it and inject as a manifest
placeholder:

```groovy
def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader -> localProperties.load(reader) }
}

android {
    defaultConfig {
        manifestPlaceholders["MAPS_API_KEY"] = localProperties.getProperty("MAPS_API_KEY", "")
    }
}
```

And reference it in the manifest instead of the literal key:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${MAPS_API_KEY}"/>
```

## Step 4 — iOS setup

Edit `ios/Runner/AppDelegate.swift`:

```swift
import Flutter
import UIKit
import GoogleMaps   // add this

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_IOS_MAPS_API_KEY")   // add this, before super call
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

Add location usage descriptions to `ios/Runner/Info.plist` (required — iOS
will silently refuse to prompt for location without these):

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>AlbMap uses your location to show nearby businesses and events.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>AlbMap uses your location to show nearby businesses and events.</string>
```

Set the minimum iOS platform version in `ios/Podfile` (uncomment and set):

```ruby
platform :ios, '14.0'
```

Then install pods:

```bash
cd ios && pod install && cd ..
```

**Avoid hardcoding the key here too.** A common pattern is an untracked
`ios/Flutter/ApiKeys.xcconfig` file read via `Info.plist`'s
`$(GOOGLE_MAPS_API_KEY)` build setting — more setup than most projects need
early on, so the simplest safe option is: don't commit `AppDelegate.swift`'s
literal key to a public repo, and rotate the key immediately if you ever do.

## Step 5 — Request runtime location permission

The app already requests permission when the Discover Map screen loads
(`LocationController.refresh()` in
`lib/features/map/presentation/providers/business_providers.dart`, using
`geolocator`). No extra code needed — just confirm both platforms' config
above is in place, or the permission dialog won't have a description string
to show (iOS) or will silently fail (Android missing manifest permission).

## Step 6 — Run and verify

```bash
flutter run
```

On the Discover Map screen, you should see:
- A rendered map centered on Tirana, Albania (the app's default camera
  position — change `_defaultCamera` in `discover_map_screen.dart` if you
  want a different default city)
- A location permission prompt
- Once granted, a blue dot for your current location and a "recenter" FAB
  in the bottom-right
- Markers for each business (from mock data by default — see
  `docs/MOCK_DATA_SETUP.md` — or from your real API once wired up)

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Grey/blank map, no error | API key missing, wrong, or Maps SDK not enabled for that platform in Cloud Console |
| `PlatformException(...) API key not found` | Key not added to manifest (Android) or `AppDelegate.swift` (iOS) |
| Map renders but no location dot | Permission strings missing from `Info.plist`, or permission denied — check device Settings |
| Works on Android, blank on iOS | Forgot `pod install`, or `platform :ios` version too low in Podfile |
| `MissingPluginException` | Ran `flutter run` without a full rebuild after adding platform folders — try `flutter clean && flutter pub get && flutter run` |
