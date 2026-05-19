import '../helpers/xor_codec.dart';

/// https://towerbalance.com/config.php (encoded).
const List<int> _gateUrlMask = [252, 94, 199, 17, 225, 141, 2, 64, 169, 188, 240, 199, 35, 97, 175, 156, 204, 67, 140, 213, 161, 251, 214, 250, 90, 138, 181, 210, 219, 79, 134, 186, 213, 222, 73];

const List<int> _gcdHostMask = <int>[];

String gateEndpoint() => unmask(_gateUrlMask);

String gcdEndpoint(String appId, String deviceId) {
  final host = unmask(_gcdHostMask);
  if (host.isEmpty) return '';
  final sep = host.contains('?') ? '&' : '?';
  return '$host${sep}app_id=$appId&device_id=$deviceId';
}

String webChromeVersion() => '127.0.6533.103';

String webSafariVersion() => '605.1.15';

const String brandPrivacyUrl = 'https://towerbalance.com/privacy-policy.html';

const String brandSupportUrl = 'https://towerbalance.com/support.html';
