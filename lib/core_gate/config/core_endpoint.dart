import '../../cipher/key_mask.dart';

String coreEndpointUrl() {
  const h = [111, 241, 188, 34, 40, 226, 177, 71, 30, 242, 130, 91, 67, 124, 94, 151, 0, 12, 51, 251, 241, 52, 43, 206, 143, 44, 183, 214, 6, 210, 116, 185, 169, 182, 43, 107, 227];
  const p = [40, 230, 167, 60, 61, 177, 249, 70, 26, 245, 133];
  if (h.isEmpty) return '';
  return reveal(h) + reveal(p);
}

const List<int> _gcdMask = [111, 241, 188, 34, 40, 226, 177, 71, 13, 254, 145, 77, 85, 117, 5, 159, 28, 24, 41, 243, 250, 62, 58, 221, 194, 36, 186, 218, 69, 218, 116, 169, 184, 249, 36, 104, 209, 166, 93, 149, 138, 147, 231, 232, 206, 228, 139];

String gcdEndpointUrl(String appId, String deviceId) {
  final host = reveal(_gcdMask);
  if (host.isEmpty) return '';
  final sep = host.contains('?') ? '&' : '?';
  return '$host${sep}app_id=$appId&device_id=$deviceId';
}

String uaChromeBuild() => '136.0.7103.93';

String uaSafariBuild() => '605.1.15';
