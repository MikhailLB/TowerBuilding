import 'dart:typed_data';

// Seed: "twr.v2.and" — unique to TowerBuilding Android.
// Change this seed per project to ensure unique binary fingerprint.
// After changing, re-run tool/encode_keys.dart to re-encode all secrets.
const _seedBytes = <int>[116, 119, 114, 46, 118, 50, 46, 97, 110, 100];

Uint8List _deriveKey() {
  final seed = _seedBytes.fold<int>(0, (a, b) => (a * 31 + b) & 0xFFFFFFFF);
  final key = Uint8List(16);
  var v = seed;
  for (var i = 0; i < key.length; i++) {
    v = (v * 1103515245 + 12345) & 0x7FFFFFFF;
    key[i] = v & 0xFF;
  }
  return key;
}

final _xk = _deriveKey();

/// Decodes an XOR-encoded byte list back to a plain string.
String d(List<int> data) {
  final out = Uint8List(data.length);
  for (var i = 0; i < data.length; i++) {
    out[i] = data[i] ^ _xk[i % _xk.length];
  }
  return String.fromCharCodes(out);
}
