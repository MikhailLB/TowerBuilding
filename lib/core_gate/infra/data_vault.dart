import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/gate_models.dart';

/// Persistence layer for the gate flow. All values live in
/// SharedPreferences; URL strings are stored scrambled (rotating-XOR pad +
/// base64) rather than as plaintext, removing the need for a secure-storage
/// plugin while keeping the destination out of a casual prefs dump.
///
/// Async accessors resolve the prefs instance lazily so a fresh [DataVault]
/// created inside the push background isolate (which never calls [init])
/// still works.
class DataVault {
  static const _kMode         = 'hvb.lane';
  static const _kPushCooldown = 'hvb.ping.hold';
  static const _kPushConsent  = 'hvb.ping.ok';
  static const _kSavedUrl     = 'hvb.dest';
  static const _kUrlTtl       = 'hvb.dest.exp';
  static const _kOneShotUrl   = 'hvb.ping.shot';

  // Pad for the lightweight value scramble (independent of the secret cipher).
  static const List<int> _pad = [
    0x5B, 0xA2, 0x37, 0xC9, 0x14, 0x6E, 0xD0, 0x8F,
    0x21, 0xF4, 0x4D, 0x9A, 0x63, 0xBE, 0x07, 0x52,
  ];

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> _resolve() async =>
      _prefs ??= await SharedPreferences.getInstance();

  SharedPreferences get _sync => _prefs!;

  String _scramble(String value) {
    final src = utf8.encode(value);
    final out = Uint8List(src.length);
    for (var i = 0; i < src.length; i++) {
      final k = _pad[i % _pad.length];
      final x = src[i] ^ k;
      final r = k & 7;
      out[i] = r == 0 ? x : ((x << r) | (x >> (8 - r))) & 0xFF;
    }
    return base64.encode(out);
  }

  String? _unscramble(String? enc) {
    if (enc == null || enc.isEmpty) return null;
    try {
      final raw = base64.decode(enc);
      final out = Uint8List(raw.length);
      for (var i = 0; i < raw.length; i++) {
        final k = _pad[i % _pad.length];
        final r = k & 7;
        final x = r == 0 ? raw[i] : ((raw[i] >> r) | (raw[i] << (8 - r))) & 0xFF;
        out[i] = x ^ k;
      }
      return utf8.decode(out, allowMalformed: true);
    } catch (_) {
      return null;
    }
  }

  LaunchMode readMode() => LaunchMode.fromKey(_sync.getString(_kMode));

  Future<void> writeMode(LaunchMode m) async =>
      _sync.setString(_kMode, m.toKey());

  Future<String?> readSavedUrl() async {
    final p = await _resolve();
    return _unscramble(p.getString(_kSavedUrl));
  }

  Future<void> writeSavedUrl(String url) async {
    try {
      final p = await _resolve();
      await p.setString(_kSavedUrl, _scramble(url));
    } catch (_) {}
  }

  Future<void> writeSavedTtl(int epochSeconds) async =>
      _sync.setInt(_kUrlTtl, epochSeconds);

  bool isSavedUrlExpired() {
    final ttl = _sync.getInt(_kUrlTtl);
    if (ttl == null) return true;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= ttl;
  }

  bool readPushConsent() => _sync.getBool(_kPushConsent) ?? false;

  Future<void> writePushConsent(bool ok) async =>
      _sync.setBool(_kPushConsent, ok);

  int? readPushCooldown() => _sync.getInt(_kPushCooldown);

  Future<void> writePushCooldown(int epochSeconds) async =>
      _sync.setInt(_kPushCooldown, epochSeconds);

  bool needsPushPrompt() {
    if (readPushConsent()) return false;
    final until = readPushCooldown();
    if (until == null) return true;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= until;
  }

  Future<void> stashOneShotUrl(String url) async {
    if (url.isEmpty) return;
    try {
      final p = await _resolve();
      await p.setString(_kOneShotUrl, _scramble(url));
    } catch (_) {}
  }

  Future<String?> consumeOneShotUrl() async {
    try {
      final p = await _resolve();
      final raw = p.getString(_kOneShotUrl);
      if (raw == null) return null;
      await p.remove(_kOneShotUrl);
      return _unscramble(raw);
    } catch (_) {
      return null;
    }
  }
}
