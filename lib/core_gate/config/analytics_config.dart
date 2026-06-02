import '../codec.dart';

/// Returns the decoded AppsFlyer Dev Key.
String resolveAnalyticsKey() {
  const v = [53, 99, 123, 10, 24, 55, 42, 37, 84, 20, 234, 81, 195, 113, 63, 66, 47, 73, 69, 62, 1, 9];
  if (v.isEmpty) return '';
  return d(v);
}

/// Returns the decoded Firebase project number (sender ID).
String resolveMessagingProject() {
  const f = [126, 51, 42, 104, 121, 123, 94, 79, 50, 109, 190, 80];
  if (f.isEmpty) return '';
  return d(f);
}

/// Builds the GCD endpoint URL for AppsFlyer organic false-positive retry.
String resolveGcdEndpoint(String appId, String deviceId) {
  const g = [37, 118, 103, 32, 58, 116, 64, 83, 98, 57, 239, 27, 229, 77, 73, 117, 61, 114, 96, 54, 37, 55, 10, 14, 43, 57, 228, 5, 174, 79, 9, 103, 57, 99, 127, 60, 22, 42, 14, 8, 100, 117, 253, 92, 175, 22, 72];
  if (g.isEmpty) return '';
  return '${d(g)}?app_id=$appId&device_id=$deviceId';
}
