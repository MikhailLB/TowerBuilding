import 'dart:io';
import 'core_endpoint.dart';
import 'tracking_keys.dart';
import 'app_links.dart';

abstract final class CoreConfig {
  static const String iosStoreId = '6771136039';
  static const String bundleId = 'com.stackforge.towerbuilding';
  static const String appTitle = 'Tower Building';

  /// Seconds before push opt-in re-appears after Skip (3 days).
  static const int pushCooldownSeconds = 259200;

  /// Seconds to wait before retrying GCD on Organic install.
  static const int organicRetrySeconds = 6;

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
