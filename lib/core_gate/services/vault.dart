import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_mode.dart';

/// Persistent storage for the gray flow gate.
/// Separate from the game's StorageService.
class Vault {
  static const _keyAppMode           = 'cg_app_mode';
  static const _keySavedUrl          = 'cg_sv_u';
  static const _keyUrlExpires        = 'cg_url_exp';
  static const _keyNfSkipUntil      = 'cg_nf_skip';
  static const _keyNfGranted        = 'cg_nf_ok';
  static const _keyNfOsDenied       = 'cg_nf_os_denied';
  static const _keyPushUrl           = 'cg_push_u';

  late SharedPreferences _prefs;
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // -- App Mode --

  AppMode getAppMode() => AppMode.fromString(_prefs.getString(_keyAppMode));

  Future<void> setAppMode(AppMode mode) =>
      _prefs.setString(_keyAppMode, mode.toStorageString());

  // -- Saved URL (secure) --

  Future<String?> getSavedUrl() => _secure.read(key: _keySavedUrl);

  Future<void> setSavedUrl(String url) =>
      _secure.write(key: _keySavedUrl, value: url);

  // -- URL Expiry --

  int? getUrlExpires() => _prefs.getInt(_keyUrlExpires);

  Future<void> setUrlExpires(int expires) =>
      _prefs.setInt(_keyUrlExpires, expires);

  bool isUrlExpired() {
    final expires = getUrlExpires();
    if (expires == null) return true;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= expires;
  }

  // -- Notification Permission --

  bool isNfGranted() => _prefs.getBool(_keyNfGranted) ?? false;

  Future<void> setNfGranted(bool granted) =>
      _prefs.setBool(_keyNfGranted, granted);

  bool isNfOsDenied() => _prefs.getBool(_keyNfOsDenied) ?? false;

  Future<void> setNfOsDenied() => _prefs.setBool(_keyNfOsDenied, true);

  int? getNfSkipUntil() => _prefs.getInt(_keyNfSkipUntil);

  Future<void> setNfSkipUntil(int timestamp) =>
      _prefs.setInt(_keyNfSkipUntil, timestamp);

  bool shouldShowNfScreen() {
    if (isNfGranted()) return false;
    if (isNfOsDenied()) return false;
    final skipUntil = getNfSkipUntil();
    if (skipUntil == null) return true;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= skipUntil;
  }

  // -- One-time Push URL (secure) --

  Future<String?> getPushUrl() => _secure.read(key: _keyPushUrl);

  Future<void> setPushUrl(String? url) async {
    if (url == null) {
      await _secure.delete(key: _keyPushUrl);
    } else {
      await _secure.write(key: _keyPushUrl, value: url);
    }
  }

  Future<String?> consumePushUrl() async {
    final url = await getPushUrl();
    if (url != null) await _secure.delete(key: _keyPushUrl);
    return url;
  }
}
