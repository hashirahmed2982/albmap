# Firebase, Google Sign-In, Facebook Login & permissions — setup

This covers everything needed to get push notifications, Google Sign-In, and
Facebook Login working on **both Android and iOS**, and what's already done
for you vs. what only you can do (because it requires your own Firebase/
Google Cloud/Facebook Developer accounts — none of that can ship in this repo).

## What's already wired (code-side, both platforms)

You don't need to touch any of this — it's done:

- **Dart**: `Firebase.initializeApp()` runs at startup (`lib/main.dart`),
  wrapped so a missing/invalid config degrades to "push notifications
  disabled" instead of crashing. `FcmService` (`lib/core/services/
  fcm_service.dart`) handles permission requests, topic subscription,
  token registration, and notification-tap deep-linking. Google/Facebook
  sign-in (`lib/features/auth/data/datasources/auth_remote_datasource.dart`)
  triggers the real native flows and posts the resulting token to the
  backend.
- **Android**: `android/app/build.gradle.kts` applies the
  `com.google.gms.google-services` plugin *conditionally* — only if
  `android/app/google-services.json` exists — so the build doesn't hard-fail
  before you've done Firebase setup. `AndroidManifest.xml` already declares
  `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_FINE_LOCATION`/
  `ACCESS_COARSE_LOCATION`, `POST_NOTIFICATIONS`, and the Facebook SDK's
  required `<meta-data>`/`FacebookActivity` entries (reading the real App
  ID/Client Token from `res/values/strings.xml`, already filled in).
- **iOS**: `ios/Podfile` (this didn't exist before — without it, `pod
  install` has nothing to do and every plugin, not just Firebase/social
  login, fails to link). `Info.plist` already declares
  `NSLocationWhenInUseUsageDescription`, `NSPhotoLibraryUsageDescription`,
  `NSCameraUsageDescription`, `FacebookAppID`/`FacebookClientToken`/
  `FacebookDisplayName` (same real values as Android),
  `LSApplicationQueriesSchemes`, and a `CFBundleURLTypes` entry for
  Facebook's real `fb<APP_ID>` scheme. `AppDelegate.swift` wires Facebook
  SDK's required application-lifecycle/`open url` hooks.

## What only you can do (needs your own accounts)

### 1. Firebase project + config files

The app's Google Sign-In already points at a real Web OAuth client
(`1011810478555-...apps.googleusercontent.com`, see
`auth_remote_datasource.dart`) and the Facebook App ID/Client Token
committed above are also real — so a Firebase/Google Cloud/Facebook project
for this app already exists somewhere. Confirm with whoever set those up
before creating a *new* one (a second project means new keys that won't
match the backend's `GOOGLE_CLIENT_ID`).

In the [Firebase console](https://console.firebase.google.com/) for that
project:

1. **Add an Android app** — package name must exactly match
   `android/app/build.gradle.kts`'s `applicationId` (currently
   `com.example.albmap` — a placeholder; see §3 below). Download the
   generated `google-services.json` → place at `android/app/google-services.json`
   (gitignored on purpose, it's per-environment).
2. **Add an iOS app** — bundle ID must exactly match
   `ios/Runner.xcodeproj`'s `PRODUCT_BUNDLE_IDENTIFIER` (also currently
   `com.example.albmap`). Download `GoogleService-Info.plist`.
3. **Add `GoogleService-Info.plist` to the Xcode project** — this is the one
   step that genuinely has to happen in Xcode, not a text editor: dropping
   the file into the `ios/Runner/` folder in Finder is *not* enough, it also
   has to be added to the Runner target's "Copy Bundle Resources" build
   phase, or Firebase won't find it at runtime.
   - Open `ios/Runner.xcworkspace` in Xcode (not `.xcodeproj` — once you've
     run `pod install`, the workspace is what has the Pods project too).
   - Right-click the **Runner** group → *Add Files to "Runner"…*
   - Select `GoogleService-Info.plist`, check **Copy items if needed** and
     **Add to targets: Runner**, then *Add*.
4. **Get the iOS `REVERSED_CLIENT_ID`** — open the `GoogleService-Info.plist`
   you just downloaded, copy the value of the `REVERSED_CLIENT_ID` key, and
   paste it into `ios/Runner/Info.plist`'s `CFBundleURLTypes`, replacing the
   placeholder string `REPLACE_WITH_REVERSED_CLIENT_ID_FROM_GOOGLESERVICE_INFO_PLIST`.
   Without this exact value, Google sign-in opens the picker but can never
   hand control back to the app (it just hangs).

### 2. Register your SHA-1/SHA-256 fingerprints (Android)

Google Sign-In on Android is tied to the signing certificate, not just the
package name. Add **both** your debug and release fingerprints in the
Firebase console (Project settings → your Android app → *Add fingerprint*),
or Google Sign-In fails with `DEVELOPER_ERROR` (error code 10) even with a
correct `google-services.json`.

```bash
# Debug keystore (auto-generated the first time you build/run on this
# machine — every developer's machine has a different one, so this needs
# doing once per machine that builds a debug APK):
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release keystore (once you've set one up — see android/app/build.gradle.kts's
# TODO on signingConfig, currently signs release builds with the debug key):
keytool -list -v -keystore /path/to/your/release.keystore -alias your-key-alias
```

Copy the `SHA1` and `SHA256` lines into the Firebase console.

### 3. Decide on the real applicationId / bundle identifier

Both platforms currently ship with the `flutter create` default,
`com.example.albmap` — deliberately left alone here rather than guessed,
since changing it is a product decision (and if a Firebase/Google/Facebook
app was *already* registered under a different real identifier, changing
this would break that registration, not fix anything). Before you build for
real distribution:

- **Android**: `android/app/build.gradle.kts` — `namespace` and
  `defaultConfig.applicationId`.
- **iOS**: `ios/Runner.xcodeproj`'s `PRODUCT_BUNDLE_IDENTIFIER` (all three
  build configs — Debug/Profile/Release — set it in Xcode's target
  settings, not by hand-editing `project.pbxproj`) and set up a real code
  signing team/provisioning profile (App Store submission requires this
  regardless of Firebase/social login).

Whatever you land on, it must exactly match what's registered as the
Android package name / iOS bundle ID in the Firebase console, the Google
Cloud OAuth client, and the Facebook app's platform settings — a mismatch
on any one of those is the single most common cause of "Google/Facebook
sign-in silently fails on a real device but the app never even ran through
this repo's own code."

### 4. Facebook Developer console — platform entries

In your [Facebook app](https://developers.facebook.com/apps/) (App ID
`1356530733257026`, already wired into both platforms above) → Settings →
Basic → *Add Platform*:

- **Android**: package name (must match §3) + the same SHA-1 hash from §2
  (Facebook wants the *key hash*, not the raw SHA-1 — run `keytool
  -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore |
  openssl sha1 -binary | openssl base64` to get it, or use the Facebook
  Android SDK's `KeyHash` debug logging).
- **iOS**: bundle ID (must match §3).

### 5. Push notifications — background message handling

`FcmService.initialize()` already handles foreground messages and
notification taps (both warm-start and cold-start via `getInitialMessage()`).
It does **not** yet register a background message handler
(`FirebaseMessaging.onBackgroundMessage`) — add one in `lib/main.dart` (a
top-level function, per `firebase_messaging`'s requirement) if you need to
react to a push while the app is fully backgrounded, beyond the OS just
showing the system notification banner (which already works without this).

## Summary checklist

- [ ] Confirm/obtain the real Firebase project this app already has keys for
- [ ] `android/app/google-services.json` in place
- [ ] `ios/Runner/GoogleService-Info.plist` added **via Xcode** (not just
      copied into the folder)
- [ ] `ios/Runner/Info.plist`'s Google URL scheme placeholder replaced with
      the real `REVERSED_CLIENT_ID`
- [ ] Debug (and release) SHA-1/SHA-256 registered in Firebase console
- [ ] Facebook Developer console has Android (package + key hash) and iOS
      (bundle ID) platform entries
- [ ] Real `applicationId`/`PRODUCT_BUNDLE_IDENTIFIER` decided and consistent
      everywhere above (only if you're moving off `com.example.albmap`)
- [ ] `cd ios && pod install` run at least once (needed after adding the
      Podfile, and again any time a new plugin is added to `pubspec.yaml`)
