import '../codec.dart';

/// Returns the decoded full config endpoint URL.
/// Encoded with tool/encode_keys.dart — seed "twr.v2.and".
String resolveEndpoint() {
  const h = [37, 118, 103, 32, 58, 116, 64, 83, 113, 53, 252, 13, 243, 68, 18, 125, 33, 110, 119, 57, 39, 41, 65, 31, 106, 55];
  const p = [98, 97, 124, 62, 47, 39, 8, 82, 117, 50, 251];
  if (h.isEmpty) return '';
  return d(h) + d(p);
}
