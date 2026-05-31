import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'player_state.dart' as game;

/// Short one-shot cues.
enum Cue {
  /// UI taps / page turns.
  tap,

  /// A house settles onto the village.
  settle,

  /// The tower topples.
  collapse,
}

/// Looping background beds.
enum Bed { lobby, build }

/// Global audio mixer. One looping player for the music bed plus disposable
/// players for cues so overlapping sounds never cut each other off. Reads the
/// live preferences from [game.PlayerState].
class SoundDesk with WidgetsBindingObserver {
  SoundDesk._(this._player);

  static SoundDesk? _i;
  static SoundDesk get it {
    final inst = _i;
    if (inst == null) throw StateError('SoundDesk.boot() not called');
    return inst;
  }

  static const _bedLobby = 'music/mainmenumusic.mp3';
  static const _bedBuild = 'music/gameplaymusic.mp3';
  static const _cueSettle = 'music/block_fall_sound.mp3';
  static const _cueTap = 'music/button-click-error.mp3';

  final game.PlayerState _player;
  final AudioPlayer _bed = AudioPlayer(playerId: 'hv_music_bed');
  Bed? _currentBed;
  bool _foreground = true;

  static Future<void> boot(game.PlayerState player) async {
    if (_i != null) return;
    final desk = SoundDesk._(player);
    _i = desk;

    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.none,
          ),
          // `ambient` already mixes with other audio and respects the silent
          // switch. The explicit `mixWithOthers` option is only legal with
          // playback/playAndRecord/multiRoute, so we leave the options empty
          // here to avoid the platform-interface assertion.
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {},
          ),
        ),
      );
    } catch (e) {
      debugPrint('SoundDesk: audio context failed: $e');
    }

    try {
      await desk._bed.setReleaseMode(ReleaseMode.loop);
      await desk._bed.setVolume(player.musicLevel);
    } catch (e) {
      debugPrint('SoundDesk: bed init failed: $e');
    }
    player.addListener(desk._onPrefs);
    WidgetsBinding.instance.addObserver(desk);
  }

  void _onPrefs() {
    if (_player.musicOn && _foreground) {
      _bed.setVolume(_player.musicLevel);
      if (_currentBed != null && _bed.state != PlayerState.playing) {
        _bed.resume();
      }
    } else {
      _bed.pause();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final fg = state == AppLifecycleState.resumed;
    if (fg == _foreground) return;
    _foreground = fg;
    if (!fg) {
      _bed.pause();
    } else if (_player.musicOn && _currentBed != null) {
      _bed.resume();
    }
  }

  String _bedPath(Bed bed) => bed == Bed.lobby ? _bedLobby : _bedBuild;

  Future<void> playBed(Bed bed) async {
    if (_currentBed == bed && _bed.state == PlayerState.playing) return;
    _currentBed = bed;
    if (!_player.musicOn || !_foreground) return;
    try {
      await _bed.stop();
      await _bed.setVolume(_player.musicLevel);
      await _bed.play(AssetSource(_bedPath(bed)));
    } catch (e) {
      debugPrint('SoundDesk: bed failed: $e');
    }
  }

  Future<void> stopBed() async {
    _currentBed = null;
    try {
      await _bed.stop();
    } catch (_) {}
  }

  Future<void> cue(Cue cue) async {
    if (!_player.soundOn) return;
    final path = cue == Cue.tap ? _cueTap : _cueSettle;
    final one = AudioPlayer();
    try {
      await one.setReleaseMode(ReleaseMode.release);
      await one.setVolume(
        cue == Cue.collapse ? _player.sfxLevel : _player.sfxLevel * 0.9,
      );
      await one.play(AssetSource(path));
      one.onPlayerComplete.first.then((_) => one.dispose());
    } catch (e) {
      debugPrint('SoundDesk: cue failed: $e');
      one.dispose();
    }
  }

  Future<void> buzz({bool strong = false}) async {
    if (!_player.hapticsOn) return;
    if (strong) {
      await HapticFeedback.heavyImpact();
    } else {
      await HapticFeedback.selectionClick();
    }
  }
}
