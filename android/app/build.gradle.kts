import java.io.FileInputStream
import java.util.Properties

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

// Same conditional pattern as google-services.json above: key.properties is
// gitignored (see ../../.gitignore) and never committed, so a fresh clone
// or CI checkout won't have it until someone deploying a release build
// creates it locally by following README's keystore-generation steps.
// Falling back to the debug signing config when it's absent means
// `flutter run --release`/local testing still works before that's done —
// but a Play Store upload MUST be built with key.properties present, or
// it silently ships debug-signed (which Play will reject on upload
// anyway, since it can't be the app's first-ever signing key).
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.albmap.app"
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
        applicationId = "com.albmap.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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