import 'package:shared_preferences/shared_preferences.dart';

/// Durable key/value persistence. Key names use a project-unique `hv_` prefix
/// so they don't collide with — or look copied from — any other build in the
/// portfolio.
class SaveStore {
  SaveStore._(this._prefs);

  static const _kCoins = 'hv_coins';
  static const _kLifetimeCoins = 'hv_lifetime_coins';
  static const _kIntroSeen = 'hv_intro_seen';
  static const _kGameStars = 'hv_game_stars';
  static const _kGameBest = 'hv_game_best';
  static const _kThemes = 'hv_themes_owned';
  static const _kThemeSel = 'hv_theme_selected';
  static const _kAch = 'hv_achievements';
  static const _kGameIntros = 'hv_game_intros';
  static const _kDailyDay = 'hv_daily_day';
  static const _kDailyStreak = 'hv_daily_streak';
  static const _kSound = 'hv_sound_on';
  static const _kMusic = 'hv_music_on';
  static const _kHaptics = 'hv_haptics_on';
  static const _kMusicLevel = 'hv_music_level';
  static const _kSfxLevel = 'hv_sfx_level';

  final SharedPreferences _prefs;

  static Future<SaveStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    final store = SaveStore._(prefs);
    await store._seed();
    return store;
  }

  Future<void> _seed() async {
    if (!_prefs.containsKey(_kSound)) await _prefs.setBool(_kSound, true);
    if (!_prefs.containsKey(_kMusic)) await _prefs.setBool(_kMusic, true);
    if (!_prefs.containsKey(_kHaptics)) await _prefs.setBool(_kHaptics, true);
    if (!_prefs.containsKey(_kMusicLevel)) {
      await _prefs.setDouble(_kMusicLevel, 0.55);
    }
    if (!_prefs.containsKey(_kSfxLevel)) {
      await _prefs.setDouble(_kSfxLevel, 0.85);
    }
    if (!_prefs.containsKey(_kThemes)) {
      await _prefs.setStringList(_kThemes, const ['auto', 'day']);
    }
    if (!_prefs.containsKey(_kThemeSel)) {
      await _prefs.setString(_kThemeSel, 'auto');
    }
  }

  int get coins => _prefs.getInt(_kCoins) ?? 0;
  int get lifetimeCoins => _prefs.getInt(_kLifetimeCoins) ?? 0;
  bool get introSeen => _prefs.getBool(_kIntroSeen) ?? false;
  bool get soundOn => _prefs.getBool(_kSound) ?? true;
  bool get musicOn => _prefs.getBool(_kMusic) ?? true;
  bool get hapticsOn => _prefs.getBool(_kHaptics) ?? true;
  double get musicLevel => _prefs.getDouble(_kMusicLevel) ?? 0.55;
  double get sfxLevel => _prefs.getDouble(_kSfxLevel) ?? 0.85;
  String get selectedTheme => _prefs.getString(_kThemeSel) ?? 'auto';
  int get dailyDay => _prefs.getInt(_kDailyDay) ?? -1;
  int get dailyStreak => _prefs.getInt(_kDailyStreak) ?? 0;

  List<String> get ownedThemes =>
      _prefs.getStringList(_kThemes) ?? const ['auto', 'day'];
  List<String> get achievements => _prefs.getStringList(_kAch) ?? const [];
  Set<String> get gameIntrosSeen =>
      (_prefs.getStringList(_kGameIntros) ?? const []).toSet();

  Map<String, int> _readIntMap(String key) {
    final raw = _prefs.getStringList(key) ?? const [];
    final map = <String, int>{};
    for (final entry in raw) {
      final i = entry.lastIndexOf('=');
      if (i <= 0) continue;
      final k = entry.substring(0, i);
      final v = int.tryParse(entry.substring(i + 1));
      if (v != null) map[k] = v;
    }
    return map;
  }

  Future<void> _writeIntMap(String key, Map<String, int> map) {
    final encoded = map.entries.map((e) => '${e.key}=${e.value}').toList();
    return _prefs.setStringList(key, encoded);
  }

  Map<String, int> get gameStars => _readIntMap(_kGameStars);
  Map<String, int> get gameBest => _readIntMap(_kGameBest);

  Future<void> setCoins(int value) => _prefs.setInt(_kCoins, value);
  Future<void> setLifetimeCoins(int value) =>
      _prefs.setInt(_kLifetimeCoins, value);
  Future<void> setIntroSeen(bool value) =>
      _prefs.setBool(_kIntroSeen, value);
  Future<void> setSound(bool value) => _prefs.setBool(_kSound, value);
  Future<void> setMusic(bool value) => _prefs.setBool(_kMusic, value);
  Future<void> setHaptics(bool value) => _prefs.setBool(_kHaptics, value);
  Future<void> setMusicLevel(double value) =>
      _prefs.setDouble(_kMusicLevel, value);
  Future<void> setSfxLevel(double value) =>
      _prefs.setDouble(_kSfxLevel, value);
  Future<void> setSelectedTheme(String id) =>
      _prefs.setString(_kThemeSel, id);
  Future<void> setDailyDay(int day) => _prefs.setInt(_kDailyDay, day);
  Future<void> setDailyStreak(int streak) =>
      _prefs.setInt(_kDailyStreak, streak);

  Future<void> writeGameStars(Map<String, int> map) =>
      _writeIntMap(_kGameStars, map);
  Future<void> writeGameBest(Map<String, int> map) =>
      _writeIntMap(_kGameBest, map);
  Future<void> writeOwnedThemes(List<String> ids) =>
      _prefs.setStringList(_kThemes, ids);
  Future<void> writeAchievements(List<String> ids) =>
      _prefs.setStringList(_kAch, ids);
  Future<void> writeGameIntros(Set<String> ids) =>
      _prefs.setStringList(_kGameIntros, ids.toList());
}
