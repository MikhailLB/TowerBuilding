// ignore_for_file: avoid_print
import 'dart:typed_data';

/// ════════════════════════════════════════════════════════════
/// Credential encoder — produces obfuscated byte tables.
/// ════════════════════════════════════════════════════════════
///
/// USAGE:
///   dart run tool/encode_creds.dart
///
/// ⚠️  Always run with `dart run`, NEVER through PowerShell foreach loops
/// (PowerShell overflows 32-bit integers → corrupt byte values).
///
/// The cipher below MUST stay byte-identical to lib/cipher/key_mask.dart.
/// ════════════════════════════════════════════════════════════

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

int _rotl8(int v, int r) =>
    r == 0 ? v & 0xFF : ((v << r) | (v >> (8 - r))) & 0xFF;

List<int> conceal(String s) {
  final out = <int>[];
  for (var i = 0; i < s.length; i++) {
    final k = _stream[i % _stream.length];
    out.add(_rotl8((s.codeUnitAt(i) ^ k) & 0xFF, k & 7));
  }
  return out;
}

String fmt(List<int> v) => '[${v.join(', ')}]';

void main() {
  // lib/core_gate/config/core_endpoint.dart
  const configHost = 'https://towerbuildingstackbalance.com';
  const configPath = '/config.php';

  // AppsFlyer GCD endpoint (change only if AF changes their URL)
  const gcdHost = 'https://gcdsdk.appsflyer.com/install_data/v4.0/';

  // lib/core_gate/config/tracking_keys.dart
  const appsflyerKey = 'c8eg9BLQNxAmhFn7P6jkrR';
  const firebaseProj = '337036206535';

  // lib/core_gate/config/app_links.dart
  const privacyUrl = 'https://towerbuildingstackbalance.com/privacy-policy.html';
  const supportUrl = 'https://towerbuildingstackbalance.com/support.html';

  print('// ── core_endpoint.dart ──────────────────────────');
  print('const h = ${fmt(conceal(configHost))};  // host');
  print('const p = ${fmt(conceal(configPath))};  // path');
  print('const _gcdMask = ${fmt(conceal(gcdHost))};');
  print('');
  print('// ── tracking_keys.dart ──────────────────────────');
  print('const v = ${fmt(conceal(appsflyerKey))};  // dev key');
  print('const v = ${fmt(conceal(firebaseProj))};  // firebase project number');
  print('');
  print('// ── app_links.dart ──────────────────────────────');
  print('const _privacyMask = ${fmt(conceal(privacyUrl))};');
  print('const _supportMask = ${fmt(conceal(supportUrl))};');
  print('');
  print('// ── VERIFICATION ────────────────────────────────');
  print('// configUrl  : $configHost$configPath');
  print('// afKey      : $appsflyerKey');
  print('// firebaseNum: $firebaseProj');
}
