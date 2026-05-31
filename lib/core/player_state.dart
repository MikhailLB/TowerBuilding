import 'package:flutter/foundation.dart';

import '../meta/achievements.dart';
import '../meta/game_catalog.dart';
import '../theme/sky_theme.dart';
import 'save_store.dart';

/// Observable mirror of [SaveStore]. Screens listen to this for live updates to
/// coins, per-game progress, sky themes, achievements and daily rewards.
class PlayerState extends ChangeNotifier {
  PlayerState(this._store)
      : _coins = _store.coins,
        _lifetimeCoins = _store.lifetimeCoins,
        _introSeen = _store.introSeen,
        _gameStars = Map<String, int>.from(_store.gameStars),
        _gameBest = Map<String, int>.from(_store.gameBest),
        _ownedThemes = List<String>.from(_store.ownedThemes),
        _selectedTheme = _store.selectedTheme,
        _ach = _store.achievements.toSet(),
        _gameIntros = _store.gameIntrosSeen,
        _dailyDay = _store.dailyDay,
        _dailyStreak = _store.dailyStreak,
        _soundOn = _store.soundOn,
        _musicOn = _store.musicOn,
        _hapticsOn = _store.hapticsOn,
        _musicLevel = _store.musicLevel,
        _sfxLevel = _store.sfxLevel;

  final SaveStore _store;

  int _coins;
  int _lifetimeCoins;
  bool _introSeen;
  final Map<String, int> _gameStars;
  final Map<String, int> _gameBest;
  List<String> _ownedThemes;
  String _selectedTheme;
  final Set<String> _ach;
  final Set<String> _gameIntros;
  int _dailyDay;
  int _dailyStreak;
  bool _soundOn;
  bool _musicOn;
  bool _hapticsOn;
  double _musicLevel;
  double _sfxLevel;

  // ── Currency ──────────────────────────────────────────────────────────
  int get coins => _coins;
  int get lifetimeCoins => _lifetimeCoins;

  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    _coins += amount;
    _lifetimeCoins += amount;
    await _store.setCoins(_coins);
    await _store.setLifetimeCoins(_lifetimeCoins);
    notifyListeners();
  }

  Future<bool> spendCoins(int amount) async {
    if (amount <= 0 || _coins < amount) return false;
    _coins -= amount;
    await _store.setCoins(_coins);
    notifyListeners();
    return true;
  }

  // ── Intro ─────────────────────────────────────────────────────────────
  bool get introSeen => _introSeen;
  Future<void> markIntroSeen() async {
    if (_introSeen) return;
    _introSeen = true;
    await _store.setIntroSeen(true);
    notifyListeners();
  }

  // ── Per-game progress ─────────────────────────────────────────────────
  String _key(GameId g, int level) => '${g.code}:$level';

  int stars(GameId g, int level) => _gameStars[_key(g, level)] ?? 0;
  int? best(GameId g, int level) => _gameBest[_key(g, level)];

  int starsForGame(GameId g) {
    var sum = 0;
    for (var l = 0; l < g.levelCount; l++) {
      sum += stars(g, l);
    }
    return sum;
  }

  int get totalStars =>
      _gameStars.values.fold(0, (sum, value) => sum + value);

  int clearedLevels(GameId g) {
    var n = 0;
    for (var l = 0; l < g.levelCount; l++) {
      if (stars(g, l) > 0) n++;
    }
    return n;
  }

  /// Level 0 is always open; later levels open once the previous one is cleared.
  bool levelUnlocked(GameId g, int level) =>
      level <= 0 || stars(g, level - 1) > 0;

  /// Records a finished round. [higherBetter] selects whether a larger or
  /// smaller [score] is the better record. Pays [coinReward] on first clear.
  Future<List<Achievement>> recordGame(
    GameId g,
    int level, {
    required int stars,
    required int score,
    required bool higherBetter,
    int coinReward = 0,
  }) async {
    final key = _key(g, level);
    final prevStars = _gameStars[key] ?? 0;
    final firstClear = prevStars == 0 && stars > 0;

    if (stars > prevStars) {
      _gameStars[key] = stars;
      await _store.writeGameStars(_gameStars);
    }
    final prevBest = _gameBest[key];
    final better = prevBest == null ||
        (higherBetter ? score > prevBest : score < prevBest);
    if (better) {
      _gameBest[key] = score;
      await _store.writeGameBest(_gameBest);
    }
    if (firstClear && coinReward > 0) {
      await addCoins(coinReward);
    }
    final newly = syncAchievements();
    notifyListeners();
    return newly;
  }

  // ── Per-game intro seen ───────────────────────────────────────────────────
  bool introSeenFor(String gameCode) => _gameIntros.contains(gameCode);
  Future<void> markGameIntroSeen(String gameCode) async {
    if (_gameIntros.contains(gameCode)) return;
    _gameIntros.add(gameCode);
    await _store.writeGameIntros(_gameIntros);
  }

  // ── Sky themes ────────────────────────────────────────────────────────
  List<String> get ownedThemes => List.unmodifiable(_ownedThemes);
  String get selectedTheme => _selectedTheme;
  bool ownsTheme(String id) => _ownedThemes.contains(id);

  Future<bool> unlockTheme(SkyTheme theme) async {
    if (_ownedThemes.contains(theme.id)) return true;
    if (!await spendCoins(theme.cost)) return false;
    _ownedThemes = [..._ownedThemes, theme.id];
    await _store.writeOwnedThemes(_ownedThemes);
    syncAchievements();
    notifyListeners();
    return true;
  }

  Future<void> selectTheme(String id) async {
    if (!_ownedThemes.contains(id)) return;
    _selectedTheme = id;
    await _store.setSelectedTheme(id);
    notifyListeners();
  }

  // ── Achievements ──────────────────────────────────────────────────────
  bool achieved(String id) => _ach.contains(id);
  int get achievementCount => _ach.length;

  /// Unlocks any achievements whose condition is now satisfied, granting their
  /// coin reward. Returns the freshly unlocked list (for a toast/popup).
  List<Achievement> syncAchievements() {
    final newly = <Achievement>[];
    var changed = true;
    var guard = 0;
    while (changed && guard++ < 5) {
      changed = false;
      for (final a in AchievementBook.all) {
        if (!_ach.contains(a.id) && a.earned(this)) {
          _ach.add(a.id);
          newly.add(a);
          _coins += a.reward;
          _lifetimeCoins += a.reward;
          changed = true;
        }
      }
    }
    if (newly.isNotEmpty) {
      _store.writeAchievements(_ach.toList());
      _store.setCoins(_coins);
      _store.setLifetimeCoins(_lifetimeCoins);
      notifyListeners();
    }
    return newly;
  }

  // ── Daily rewards ─────────────────────────────────────────────────────
  static int _todayIndex() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  int get dailyStreak => _dailyStreak;
  bool get dailyClaimable => _dailyDay != _todayIndex();

  /// The streak value that *will* apply after claiming today.
  int get pendingStreak {
    if (!dailyClaimable) return _dailyStreak;
    return _dailyDay == _todayIndex() - 1 ? _dailyStreak + 1 : 1;
  }

  int get pendingReward => DailyLadder.rewardFor(pendingStreak);

  /// Claims today's reward, returns the coins granted (0 if already claimed).
  Future<int> claimDaily() async {
    if (!dailyClaimable) return 0;
    final streak = pendingStreak;
    final reward = DailyLadder.rewardFor(streak);
    _dailyStreak = streak;
    _dailyDay = _todayIndex();
    await _store.setDailyStreak(_dailyStreak);
    await _store.setDailyDay(_dailyDay);
    await addCoins(reward);
    syncAchievements();
    return reward;
  }

  // ── Audio / haptics ───────────────────────────────────────────────────
  bool get soundOn => _soundOn;
  bool get musicOn => _musicOn;
  bool get hapticsOn => _hapticsOn;
  double get musicLevel => _musicLevel;
  double get sfxLevel => _sfxLevel;

  Future<void> setSound(bool value) async {
    _soundOn = value;
    await _store.setSound(value);
    notifyListeners();
  }

  Future<void> setMusic(bool value) async {
    _musicOn = value;
    await _store.setMusic(value);
    notifyListeners();
  }

  Future<void> setHaptics(bool value) async {
    _hapticsOn = value;
    await _store.setHaptics(value);
    notifyListeners();
  }

  Future<void> setMusicLevel(double value) async {
    _musicLevel = value.clamp(0.0, 1.0);
    await _store.setMusicLevel(_musicLevel);
    notifyListeners();
  }

  Future<void> setSfxLevel(double value) async {
    _sfxLevel = value.clamp(0.0, 1.0);
    await _store.setSfxLevel(_sfxLevel);
    notifyListeners();
  }
}
