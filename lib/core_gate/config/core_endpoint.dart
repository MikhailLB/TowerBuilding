import '../../cipher/key_mask.dart';

/// ════════════════════════════════════════════════════════════
/// ⚠️  TEMPLATE — encode your config URL
/// ════════════════════════════════════════════════════════════
///
/// HOW:
///   1. Fill values in tool/encode_creds.dart
///   2. Run: dart run tool/encode_creds.dart
///   3. Paste printed byte arrays below.
///
/// URL split: host  (e.g. https://yourdomain.com)
///          + path  (e.g. /config.php)

// TODO: replace with your encoded config host bytes
String coreEndpointUrl() {
  const h = <int>[];   // encoded host
  const p = <int>[];   // encoded path
  if (h.isEmpty) return '';
  return reveal(h) + reveal(p);
}

/// AppsFlyer GCD backup endpoint (encoded).
// TODO: replace with your encoded GCD host bytes
const List<int> _gcdMask = <int>[];

String gcdEndpointUrl(String appId, String deviceId) {
  final host = reveal(_gcdMask);
  if (host.isEmpty) return '';
  final sep = host.contains('?') ? '&' : '?';
  return '$host${sep}app_id=$appId&device_id=$deviceId';
}

/// Chrome version fragment for the Android User-Agent.
/// Keep this close to the current stable release.
String uaChromeBuild() => '136.0.7103.93';

/// Safari/WebKit version fragment for the iOS User-Agent.
String uaSafariBuild() => '605.1.15';
