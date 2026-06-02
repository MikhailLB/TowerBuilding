import 'analytics_config.dart';
import 'endpoint_config.dart';
import 'link_config.dart';

class AppConfig {
  static const String bundleId = 'com.stackforge.towerbuilding';
  static const String storeId  = 'com.stackforge.towerbuilding';
  static const String appName  = 'TowerBuilding: Stack & Balance';
  static const String analyticsAppId = ''; // Android — not used

  static String get apiEndpoint      => resolveEndpoint();
  static String get analyticsKey     => resolveAnalyticsKey();
  static String get messagingProject => resolveMessagingProject();
  static String get privacyUrl       => kPrivacyPolicyUrl;
  static String get supportUrl       => kSupportUrl;

  /// Seconds before push prompt re-appears after Skip (3 days).
  static const int pushCooldownSeconds = 259200;

  /// Seconds to wait before GCD retry when AF returns Organic.
  static const int gcdRetrySeconds = 5;
}
