import FirebaseMessaging
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register plugins eagerly so Firebase Messaging installs its
    // UNUserNotificationCenterDelegate swizzle before any push tap arrives.
    // Previously FlutterImplicitEngineDelegate deferred this, causing the
    // swizzle to arrive too late and notification callbacks to be dropped.
    GeneratedPluginRegistrant.register(with: self)

    // Explicit APNs registration on every launch — refreshes the FCM→APNs
    // token mapping even when permission was granted in a prior install.
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
