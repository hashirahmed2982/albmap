# Windows build troubleshooting

Common failures when running `flutter run` on Windows with this project,
and the fixes.

## 1. BUILD FAILED — "requires core library desugaring to be enabled"

**Cause:** `flutter_local_notifications` (and some other plugins) use Java 8+
APIs that need to be desugared for older Android API levels.

**Fix:** edit `android/app/build.gradle.kts`. Inside the `android { }` block,
update `compileOptions` and add the desugaring dependency:

```kotlin
android {
    namespace = "com.yourcompany.albmap"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"   // see issue #2 below

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true   // <-- add this line
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.yourcompany.albmap"
        minSdk = 21   // flutter_local_notifications + geolocator need 21+
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

If your `build.gradle.kts` doesn't have a `dependencies { }` block at the
bottom yet, add one at the top level (outside `android { }`) as shown above.

Then:
```powershell
flutter clean
flutter pub get
flutter run
```

## 2. Warning — "plugins depend on a different Android NDK version"

**Cause:** Flutter's default NDK version is older than what several plugins
(`add_2_calendar`, `connectivity_plus`, `firebase_core`, `geolocator_android`,
`google_maps_flutter_android`, etc.) now require.

**Fix:** already included in the snippet above —
```kotlin
ndkVersion = "27.0.12077973"
```
This is just a warning, not a build blocker, but fixing it avoids
inconsistent native crashes later (especially with Firebase and location
plugins). Use the exact version Flutter reports in your terminal output —
NDK versions are backward compatible, so always take the *highest* one
listed among your plugins.

## 3. PowerShell error — "running scripts is disabled on this system"

**Cause:** Flutter's tooling tries to run a `.ps1` script
(`update_engine_version.ps1`) to check the engine version, and Windows'
default PowerShell execution policy blocks all scripts.

**This is usually non-fatal** — Flutter falls back gracefully and the real
build error (if any) will be reported separately below it, same as in this
log. But if you want to silence it:

Open PowerShell **as Administrator** and run:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
This allows locally-created/signed scripts (like Flutter's) to run while
still blocking unsigned scripts downloaded from the internet — safe default,
not a global unlock.

## 4. Kotlin daemon crash — "this and base files have different roots"

**Symptom:** a long Kotlin/Gradle stack trace mentioning
`IllegalArgumentException: this and base files have different roots`,
usually pointing at a plugin's source file on one drive (e.g.
`C:\Users\...\Pub\Cache\...`) versus your project on another (e.g.
`D:\projects\...`).

**Cause:** a known Windows-specific Kotlin incremental-compiler bug when the
Flutter pub cache and your project folder live on **different drive
letters**. The compiler tries to compute a relative path between them and
fails, since relative paths can't cross drive roots on Windows.

**Fix options, in order of preference:**

**A. Move your project onto the same drive as your pub cache** (simplest —
if your pub cache is on `C:`, move/clone the project to `C:\projects\...`
instead of `D:\projects\...`).

**B. Or point the pub cache at the same drive as your project** instead —
set an environment variable (persists across sessions if set via System
Properties → Environment Variables, or per-session via PowerShell):
```powershell
setx PUB_CACHE "D:\pub-cache"
```
Then close and reopen your terminal, and run `flutter pub get` again to
repopulate the cache on `D:`.

**C. Or disable Kotlin incremental compilation** (least ideal — slower
builds, but works regardless of drive layout). Add to
`android/gradle.properties`:
```properties
kotlin.incremental=false
```

Try option A or B first; C is a fallback if you can't relocate either
folder.

## Recommended order of operations

1. Apply fix #1 (desugaring) and fix #2 (NDK version) together — same file edit.
2. Run `flutter clean && flutter pub get && flutter run`.
3. If the drive-letter Kotlin crash (#4) reappears, apply option A or B.
4. Fix #3 (PowerShell policy) is optional cleanup, not required for the build to succeed.
