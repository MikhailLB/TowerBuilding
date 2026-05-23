// ignore_for_file: avoid_print
import 'dart:typed_data';

/// ════════════════════════════════════════════════════════════
/// TowerBuilding — credential encoder
/// ════════════════════════════════════════════════════════════
///
/// USAGE:
///   dart run tool/encode_creds.dart
///
/// ⚠️  Always run with `dart run`, NEVER PowerShell foreach loops.
/// PowerShell overflows 32-bit integers → wrong byte values.
/// Symptom: FormatException in HTTP headers.
///
/// The _seed MUST match _seed in lib/cipher/key_mask.dart exactly.
/// ════════════════════════════════════════════════════════════

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

final _stream = _buildStream(64);

List<int> encode(String s) {
  final out = <int>[];
  for (var i = 0; i < s.length; i++) {
    out.add(s.codeUnitAt(i) ^ _stream[i % _stream.length]);
  }
  return out;
}

String fmt(List<int> v) => '[${v.join(', ')}]';

void main() {
  // ════════════════════════════════════════════════════════
  // ⚠️  FILL IN YOUR ACTUAL VALUES BELOW
  // ════════════════════════════════════════════════════════

  // lib/core_gate/config/core_endpoint.dart
  const configHost = 'https://TODO_YOUR_DOMAIN.com';   // TODO
  const configPath = '/config.php';                     // TODO

  // AppsFlyer GCD endpoint (change only if AF changes their URL)
  const gcdHost = 'https://gcdsdk.appsflyer.com/install_data/v4.0/';

  // lib/core_gate/config/tracking_keys.dart
  const appsflyerKey = 'TODO_APPSFLYER_DEV_KEY';        // TODO
  const firebaseProj = 'TODO_FIREBASE_PROJECT_NUMBER';  // TODO (numeric)

  // lib/core_gate/config/app_links.dart
  const privacyUrl = 'https://TODO_YOUR_DOMAIN.com/privacy-policy.html'; // TODO
  const supportUrl = 'https://TODO_YOUR_DOMAIN.com/support.html';        // TODO

  // ════════════════════════════════════════════════════════

  print('// ── core_endpoint.dart ──────────────────────────');
  print('const h = ${fmt(encode(configHost))};  // host');
  print('const p = ${fmt(encode(configPath))};  // path');
  print('');
  print('// ── core_endpoint.dart — GCD host ──────────────');
  print('const _gcdMask = ${fmt(encode(gcdHost))};');
  print('');
  print('// ── tracking_keys.dart — AppsFlyer key ──────────');
  print('const v = ${fmt(encode(appsflyerKey))};');
  print('');
  print('// ── tracking_keys.dart — Firebase project number ');
  print('const v = ${fmt(encode(firebaseProj))};');
  print('');
  print('// ── app_links.dart — privacy URL ─────────────────');
  print('const _privacyMask = ${fmt(encode(privacyUrl))};');
  print('');
  print('// ── app_links.dart — support URL ─────────────────');
  print('const _supportMask = ${fmt(encode(supportUrl))};');
  print('');
  print('// ── VERIFICATION ─────────────────────────────────');
  print('// configUrl  : $configHost$configPath');
  print('// afKey      : $appsflyerKey');
  print('// firebaseNum: $firebaseProj');
}
