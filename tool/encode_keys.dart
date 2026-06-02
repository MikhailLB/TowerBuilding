// ignore_for_file: avoid_print
import 'dart:typed_data';

// Seed for TowerBuilding Android: "twr.v2.and"
// Change this seed per project to ensure unique binary fingerprint.
const _seed = <int>[116, 119, 114, 46, 118, 50, 46, 97, 110, 100];

Uint8List _deriveKey() {
  final seed = _seed.fold<int>(0, (a, b) => (a * 31 + b) & 0xFFFFFFFF);
  final key = Uint8List(16);
  var v = seed;
  for (var i = 0; i < key.length; i++) {
    v = (v * 1103515245 + 12345) & 0x7FFFFFFF;
    key[i] = v & 0xFF;
  }
  return key;
}

List<int> encode(String s) {
  final key = _deriveKey();
  final out = <int>[];
  for (var i = 0; i < s.length; i++) {
    out.add(s.codeUnitAt(i) ^ key[i % key.length]);
  }
  return out;
}

String decode(List<int> data) {
  final key = _deriveKey();
  final out = Uint8List(data.length);
  for (var i = 0; i < data.length; i++) {
    out[i] = data[i] ^ key[i % key.length];
  }
  return String.fromCharCodes(out);
}

void main() {
  // TowerBuilding Android credentials
  const configHost  = 'https://towerbuillding.com';
  const configPath  = '/config.php';
  const afKey       = 'xahZQyEYQNa9BWXVbKVnHG';
  const firebaseNum = '319805137758';
  const gcdHost     = 'https://gcdsdk.appsflyer.com/install_data/v4.0/';

  final hBytes = encode(configHost);
  final pBytes = encode(configPath);
  final afBytes = encode(afKey);
  final fbBytes = encode(firebaseNum);
  final gcdBytes = encode(gcdHost);

  print('// ── endpoint_config.dart ────────────────────────');
  print('const h = $hBytes;');
  print('const p = $pBytes;');
  print('');
  print('// ── analytics_config.dart — AF key ──────────────');
  print('const v = $afBytes;');
  print('');
  print('// ── analytics_config.dart — Firebase number ─────');
  print('const f = $fbBytes;');
  print('');
  print('// ── analytics_config.dart — GCD host ────────────');
  print('const g = $gcdBytes;');
  print('');
  print('// ── verification (roundtrip) ─────────────────────');
  print('// configUrl : ${decode(hBytes)}${decode(pBytes)}');
  print('// afKey     : ${decode(afBytes)}');
  print('// firebase  : ${decode(fbBytes)}');
  print('// gcdHost   : ${decode(gcdBytes)}');
}
