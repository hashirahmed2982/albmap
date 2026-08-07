plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // google-services is intentionally NOT applied here — see the
    // conditional `apply(plugin = ...)` near the bottom of this file.
    // Applying it unconditionally makes its
    // processDebugGoogleServices/processReleaseGoogleServices Gradle
    // tasks hard-fail the *entire build* ("File google-services.json is
    // missing") whenever that file isn't present. This project
    // deliberately ships without Firebase config (see README — Firebase
    // setup is a manual step left to whoever deploys it) and
    // main.dart wraps Firebase.initializeApp() to degrade gracefully at
    // runtime; the build itself needs to degrade the same way, or nobody
    // can even `flutter run` the app before doing Firebase setup.
}

android {
    namespace = "com.example.albmap"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.albmap"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation(platform("com.google.firebase:firebase-bom:34.16.0"))
    implementation("com.google.firebase:firebase-analytics")
}

flutter {
    source = "../.."
}

// See the comment on the `plugins` block above: only wire up
// google-services once its config file actually exists, so the build
// doesn't hard-fail before Firebase setup has been done.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}