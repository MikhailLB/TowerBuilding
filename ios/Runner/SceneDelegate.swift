import Flutter
import UIKit
import UserNotifications

/// Scene-based apps deliver cold-start push taps through
/// `scene(_:willConnectTo:options:)` — NOT through the AppDelegate
/// launchOptions path that Firebase swizzle reads.
/// `getInitialMessage()` therefore returns nil for these taps.
///
/// We capture the URL here and store it in UserDefaults under
/// `flutter.tb_gate_cold_url`. The `flutter.` prefix is mandatory:
/// SharedPreferences on iOS namespaces every key with that prefix,
/// so NativeLinkBridge.consumeColdUrl() can read it without any
/// MethodChannel registration.
class SceneDelegate: FlutterSceneDelegate {
  static let coldUrlKey = "flutter.tb_gate_cold_url"

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    if let response = connectionOptions.notificationResponse,
       let url = SceneDelegate.extractUrl(
         from: response.notification.request.content.userInfo
       )
    {
      SceneDelegate.persist(url: url)
    }
  }

  override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    super.scene(scene, continue: userActivity)
  }

  /// Scans all keys the gray backend may use for the destination URL.
  /// Also logs the full userInfo in debug mode to help diagnose mismatches.
  static func extractUrl(from userInfo: [AnyHashable: Any]) -> String? {
    let keys = ["url", "link", "target", "deeplink", "deep_link"]

    #if DEBUG
    NSLog("[TB.NATIVE] userInfo keys: %@",
          userInfo.keys.map { "\($0)" }.joined(separator: ", "))
    for (k, v) in userInfo {
      NSLog("[TB.NATIVE] userInfo[\(k)] = \(v)")
    }
    #endif

    func scan(_ map: [AnyHashable: Any]) -> String? {
      for key in keys {
        if let raw = map[key] as? String,
           !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          return raw.trimmingCharacters(in: .whitespacesAndNewlines)
        }
      }
      return nil
    }

    // 1. Top-level keys (FCM flattens data payload into APNs userInfo)
    if let direct = scan(userInfo) { return direct }
    // 2. Nested "data" dict (some backends wrap payload)
    if let nested = userInfo["data"] as? [AnyHashable: Any] {
      if let url = scan(nested) { return url }
    }
    // 3. Nested "payload" dict
    if let nested = userInfo["payload"] as? [AnyHashable: Any] {
      if let url = scan(nested) { return url }
    }
    return nil
  }

  static func persist(url: String) {
    NSLog("[TB.NATIVE] cold-start url -> %@", url)
    let d = UserDefaults.standard
    d.set(url, forKey: coldUrlKey)
    d.synchronize()
  }
}
