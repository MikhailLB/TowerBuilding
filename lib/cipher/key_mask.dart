import 'dart:typed_data';

/// Byte-array obfuscation for embedded secrets.
///
/// Keystream is produced by a xorshift32 generator seeded through a
/// Jenkins-style additive mix of [_seed]; each output byte is recovered by
/// an XOR followed by a per-position bitwise rotation whose amount is taken
/// from the low bits of the keystream. The combination of rotation + XOR
/// (rather than a plain XOR) and the xorshift core make the byte tables
/// unique to this build. [_seed] is project-specific and must never be
/// shared with another build.
const String _seed = 'hvbrick::lane.k7';

int _mix() {
  var h = 0x2166AC5D;
  for (final c in _seed.codeUnits) {
    h = (h ^ c) & 0xFFFFFFFF;
    h = (h + (((h << 6) & 0xFFFFFFFF)) + (h >> 2)) & 0xFFFFFFFF;
  }
  return h == 0 ? 0x9E3779B9 : h;
}

Uint8List _buildStream(int n) {
  var s = _mix();
  final out = Uint8List(n);
  for (var i = 0; i < n; i++) {
    s ^= (s << 13) & 0xFFFFFFFF;
    s ^= s >> 17;
    s ^= (s << 5) & 0xFFFFFFFF;
    out[i] = (s >> 11) & 0xFF;
  }
  return out;
}

final Uint8List _stream = _buildStream(96);

int _rotr8(int v, int r) =>
    r == 0 ? v & 0xFF : ((v >> r) | (v << (8 - r))) & 0xFF;

/// Decode an obfuscated byte list back to its plaintext string.
/// Counterpart to `conceal` in `tool/encode_creds.dart`.
String unveil(List<int> raw) {
  if (raw.isEmpty) return '';
  final n = raw.length;
  final out = Uint8List(n);
  for (var i = 0; i < n; i++) {
    final k = _stream[i % _stream.length];
    out[i] = _rotr8(raw[i] & 0xFF, k & 7) ^ k;
  }
  return String.fromCharCodes(out);
}
