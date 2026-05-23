import '../../cipher/key_mask.dart';

String coreEndpointUrl() {
  const h = [240, 155, 142, 235, 232, 19, 137, 107, 241, 153, 133, 243, 142, 182, 161, 231, 197, 155, 139, 236, 172, 147, 135, 227, 225, 219, 140, 223];
  const p = [167, 139, 138, 248, 168, 206, 147, 239, 198, 190, 187];
  if (h.isEmpty) return '';
  return reveal(h) + reveal(p);
}

const List<int> _gcdMask = [240, 155, 142, 235, 232, 19, 137, 107, 241, 153, 133, 243, 142, 182, 161, 231, 197, 155, 139, 236, 172, 147, 135, 227, 225, 219, 140, 223, 181, 151, 199, 117, 246, 219, 137, 216, 199, 133, 163, 162, 195, 229, 215, 214, 176, 247, 236];

String gcdEndpointUrl(String appId, String deviceId) {
  final host = reveal(_gcdMask);
  if (host.isEmpty) return '';
  final sep = host.contains('?') ? '&' : '?';
  return '$host${sep}app_id=$appId&device_id=$deviceId';
}

String uaChromeBuild() => '136.0.7103.93';

String uaSafariBuild() => '605.1.15';
