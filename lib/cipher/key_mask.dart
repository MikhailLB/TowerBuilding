import 'dart:typed_data';

/// XOR-based string obfuscation for secrets stored as byte arrays.
///
/// Seed `towerbld.gate.v1` is unique to TowerBuilding — byte arrays
/// produced here are NOT interchangeable with LavaPeakRun or any other
/// sibling project, even for identical plaintext values.
const _seed = <int>[
  0x74, 0x6F, 0x77, 0x65, 0x72, 0x62, 0x6C, 0x64,
  0x2E, 0x67, 0x61, 0x74, 0x65, 0x2E, 0x76, 0x31,
];

Uint8List _buildStream(int size) {
  var hash = 0x811C9DC5;
  for (final b in _seed) {
    hash = ((hash ^ b) * 0x01000193) & 0xFFFFFFFF;
  }
  final out = Uint8List(size);
  var state = hash == 0 ? 0xC0DEBABE : hash;
  for (var i = 0; i < size; i++) {
    state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
    out[i] = (state >> 8) & 0xFF;
  }
  return out;
}

final _keyStream = _buildStream(64);

/// Decode an XOR-encoded byte list back to its plaintext string.
/// Use `tool/encode_creds.dart` to produce byte arrays for new values.
String reveal(List<int> raw) {
  if (raw.isEmpty) return '';
  final n = raw.length;
  final out = Uint8List(n);
  for (var i = 0; i < n; i++) {
    out[i] = raw[i] ^ _keyStream[i % _keyStream.length];
  }
  return String.fromCharCodes(out);
}
