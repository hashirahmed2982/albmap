import Flutter
import UIKit
import FBSDKCoreKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Firebase itself does NOT need FirebaseApp.configure() here — the
    // firebase_core Flutter plugin calls that automatically (reading
    // ios/Runner/GoogleService-Info.plist) the moment main.dart's
    // Firebase.initializeApp() runs. This is Facebook's own required
    // AppDelegate wiring (see flutter_facebook_auth's iOS setup docs) —
    // without it, FacebookAuth.instance.login() hangs after the user
    // authenticates in Safari/the Facebook app, since nothing hands the
    // redirect back to the SDK.
    ApplicationDelegate.shared.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    // Facebook's SDK needs first look at the callback URL (its own
    // fb<APP_ID> scheme); super still gets called after so Flutter's own
    // URL-handling plugins (deep links, etc.) keep working unaffected.
    // Google Sign-In's current implementation doesn't need a matching
    // hook here — it completes via ASWebAuthenticationSession internally.
    let handled = ApplicationDelegate.shared.application(app, open: url, options: options)
    if handled { return true }
    return super.application(app, open: url, options: options)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    AppEvents.shared.activateApp()
    super.applicationDidBecomeActive(application)
  }
}
