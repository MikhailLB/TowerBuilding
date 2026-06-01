import '../../cipher/key_mask.dart';

String coreEndpointUrl() {
  const h = [10, 48, 10, 141, 2, 98, 191, 126, 62, 92, 60, 117, 9, 108, 89, 149, 27, 229, 241, 171, 50, 120, 59, 229, 98, 105, 1, 65, 185, 209, 30, 252, 198, 40, 105, 61, 253];
  const p = [23, 210, 187, 10, 170, 49, 59, 62, 30, 223, 191];
  if (h.isEmpty) return '';
  return unveil(h) + unveil(p);
}

const List<int> _gcdMask = [10, 48, 10, 141, 2, 98, 191, 126, 166, 90, 181, 99, 140, 252, 239, 213, 107, 239, 197, 235, 130, 216, 25, 33, 196, 107, 66, 89, 163, 211, 30, 253, 130, 251, 170, 59, 207, 174, 97, 36, 235, 44, 52, 53, 208, 131, 74];

String gcdEndpointUrl(String appId, String deviceId) {
  final host = unveil(_gcdMask);
  if (host.isEmpty) return '';
  final sep = host.contains('?') ? '&' : '?';
  return '$host${sep}app_id=$appId&device_id=$deviceId';
}
