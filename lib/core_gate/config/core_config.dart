import 'dart:io';
import 'core_endpoint.dart';
import 'tracking_keys.dart';
import 'app_links.dart';

/// ════════════════════════════════════════════════════════════
/// ⚠️  TEMPLATE — fill every TODO before building
/// ════════════════════════════════════════════════════════════
abstract final class CoreConfig {
  // ── iOS App Store numeric ID ──────────────────────────────
  // TODO: replace with your App Store app ID
  static const String iosStoreId = 'TODO_IOS_APP_STORE_ID';

  // ── Android/iOS bundle / package ID ──────────────────────
  static const String bundleId = 'com.mikhaillb.towerBalance';

  // ── Display name ─────────────────────────────────────────
  static const String appTitle = 'Tower Building';

  // ── Timing constants ─────────────────────────────────────
  /// Seconds before push opt-in re-appears after Skip (3 days).
  static const int pushCooldownSeconds = 259200;

  /// Seconds to wait before retrying GCD on Organic install.
  static const int organicRetrySeconds = 6;

  // ── Derived — do not edit ────────────────────────────────
  static String get configEndpoint  => coreEndpointUrl();
  static String get installKey      => trackingDevKey();
  static String get firebaseNumber  => messagingProjectId();
  static String get privacyUrl      => appPrivacyPageUrl;
  static String get supportUrl      => appSupportPageUrl;
  static String get platformStoreId =>
      Platform.isIOS ? 'id$iosStoreId' : bundleId;
  static String get analyticsAppId  =>
      Platform.isIOS ? iosStoreId : bundleId;
}
