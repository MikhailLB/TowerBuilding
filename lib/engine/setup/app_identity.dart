import 'dart:io';

import '../helpers/xor_codec.dart';
import 'endpoint_registry.dart';

// AppsFlyer Android dev key (xahZQyEYQNa9BWXVbKVnHG — encoded).
const List<int> _afKeyAndroid = [236, 75, 219, 59, 195, 206, 104, 54, 140, 157, 230, 155, 19, 84, 150, 166, 207, 102, 185, 222, 199, 223];

const List<int> _afKeyIos = <int>[];

// Firebase project number 319805137758 (encoded).
const List<int> _fbProjAndroid = [167, 27, 138, 89, 162, 130, 28, 92, 234, 228, 178, 154];

const List<int> _fbProjIos = <int>[];

abstract final class AppIdentity {
  /// Android applicationId — MUST match `android/app/build.gradle.kts` and
  /// `android/app/src/main/AndroidManifest.xml`.
  static const String packageName = 'com.stackforge.towerbuilding';

  static const String storeIdentifier = 'com.stackforge.towerbuilding';

  static const String displayTitle = 'Tower Building';

  static const String iosAppId = '0000000000';

  static const int notifyCooldownSeconds = 60 * 60 * 24 * 3;

  static const int organicRefetchSeconds = 6;

  static String get devKey => Platform.isIOS
      ? unmask(_afKeyIos)
      : unmask(_afKeyAndroid);

  static String get fbProjectId => Platform.isIOS
      ? unmask(_fbProjIos)
      : unmask(_fbProjAndroid);

  static String get configUrl => gateEndpoint();
  static String get chromeBuild => webChromeVersion();
  static String get safariBuild => webSafariVersion();
  static String get privacyUrl => brandPrivacyUrl;
  static String get supportUrl => brandSupportUrl;

  static bool get gateEnabled => configUrl.isNotEmpty || devKey.isNotEmpty;
}
