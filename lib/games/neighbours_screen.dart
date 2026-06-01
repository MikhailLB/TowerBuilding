import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound_desk.dart';
import '../main.dart';
import '../meta/game_catalog.dart';
import '../theme/asset_paths.dart';
import '../theme/palette.dart';
import '../widgets/game_shell.dart';
import '../widgets/plank_panel.dart';
import '../widgets/storybook_button.dart';
import '../widgets/tutorial_overlay.dart';

class _Face {
  const _Face(this.house, this.tint);
  final int house; // 1..6
  final Color tint;
}

/// "Neighbours" — a memory game. Flip pairs of shuttered windows to reveal the
/// houses behind them and find every matching neighbour in as few flips as
/// possible.
class NeighboursScreen extends StatefulWidget {
  const NeighboursScreen({super.key, this.initialLevel = 0});

  final int initialLevel;

  @override
  State<NeighboursScreen> createState() => _NeighboursScreenState();
}

class _NeighboursScreenState extends State<NeighboursScreen> {
  static const _cols = [3, 4, 4];
  static const _rows = [4, 4, 5];
  static const _tints = [Hue.ember, Hue.moss, Hue.gold, Hue.lavender];

  final _rng = math.Random();

  static const _tutorialSteps = [
    TutorialStep(
      icon: Icons.style_rounded,
      title: 'Flip the shutters',
      body: 'Tap any house card to reveal the building behind it.',
      iconColor: Hue.gold,
    ),
    TutorialStep(
      icon: Icons.search_rounded,
      title: 'Find the matching pair',
      body: 'Two cards showing the same house & colour are a match — '
          'they stay open. Mismatches flip back after a moment.',
      iconColor: Hue.moss,
    ),
    TutorialStep(
      icon: Icons.memory_rounded,
      title: 'Use your memory',
      body: 'Remember what you\'ve seen! Clear the board in as few flips as '
          'possible for top stars.',
      iconColor: Hue.ember,
    ),
  ];

  late int _level;
  late int _pairs;
  bool _showTutorial = false;
  late int _columns;
  late List<int> _faceOf; // card index -> face id
  late List<_Face> _faces; // face id -> face
  late List<bool> _matched;
  late List<bool> _up;
  int? _first;
  bool _busy = false;
  int _moves = 0;
  int _found = 0;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _level = widget.initialLevel;
    _start(_level);
    _showTutorial = !player.introSeenFor(GameId.memory.code);
  }

  void _start(int level) {
    _level = level;
    _columns = _cols[level];
    _pairs = (_cols[level] * _rows[level]) ~/ 2;

    // Build distinct (house, tint) faces.
    final combos = <_Face>[];
    for (final tint in _tints) {
      for (var h = 1; h <= Art.houseCount; h++) {
        combos.add(_Face(h, tint));
      }
    }
    combos.shuffle(_rng);
    _faces = combos.take(_pairs).toList();

    final deck = <int>[];
    for (var i = 0; i < _pairs; i++) {
      deck..add(i)..add(i);
    }
    deck.shuffle(_rng);
    _faceOf = deck;
    _matched = List<bool>.filled(deck.length, false);
    _up = List<bool>.filled(deck.length, false);
    _first = null;
    _busy = false;
    _moves = 0;
    _found = 0;
    _won = false;
    setState(() {});
  }

  void _tap(int i) {
    if (_busy || _won || _matched[i] || _up[i]) return;
    SoundDesk.it.cue(Cue.tap);
    SoundDesk.it.buzz();
    _up[i] = true;
    if (_first == null) {
      _first = i;
      setState(() {});
      return;
    }
    _moves++;
    final a = _first!;
    _first = null;
    if (_faceOf[a] == _faceOf[i]) {
      _matched[a] = true;
      _matched[i] = true;
      _found++;
      SoundDesk.it.cue(Cue.settle);
      if (_found == _pairs) _win();
      setState(() {});
    } else {
      _busy = true;
      setState(() {});
      Future.delayed(const Duration(milliseconds: 750), () {
        if (!mounted) return;
        setState(() {
          _up[a] = false;
          _up[i] = false;
          _busy = false;
        });
      });
    }
  }

  int get _stars {
    if (_moves <= (_pairs * 1.3).round()) return 3;
    if (_moves <= (_pairs * 1.9).round()) return 2;
    return 1;
  }

  Future<void> _win() async {
    _won = true;
    SoundDesk.it.buzz(strong: true);
    final newly = await player.recordGame(
      GameId.memory,
      _level,
      stars: _stars,
      score: _moves,
      higherBetter: false,
      coinReward: 20 + _level * 15,
    );
    if (mounted) showAchievementToast(context, newly);
  }

  @override
  Widget build(BuildContext context) {
    final best = player.best(GameId.memory, _level);
    return _maybeWithTutorial(GameScaffold(
      title: 'Neighbours',
      subtitle: best == null ? 'Find every matching pair' : 'Best: $best flips',
      trailing: [
        StatChip(icon: Icons.swipe_rounded, label: '$_moves', iconColor: Hue.ember),
        const SizedBox(width: 8),
        StatChip(icon: Icons.favorite_rounded, label: '$_found/$_pairs',
            iconColor: Hue.moss),
      ],
      body: Column(
        children: [
          LevelBar(
            game: GameId.memory,
            current: _level,
            labels: const ['Easy', 'Medium', 'Hard'],
            onSelect: _start,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: _columns,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    padding: const EdgeInsets.all(4),
                    children: [
                      for (var i = 0; i < _faceOf.length; i++) _card(i),
                    ],
                  ),
                ),
                if (_won)
                  Center(
                    child: SizedBox(
                      height: 260,
                      child: _winCard(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _maybeWithTutorial(Widget child) {
    if (!_showTutorial) return child;
    return Stack(children: [
      child,
      TutorialOverlay(
        steps: _tutorialSteps,
        onDone: () async {
          await player.markGameIntroSeen(GameId.memory.code);
          if (mounted) setState(() => _showTutorial = false);
        },
      ),
    ]);
  }

  Widget _card(int i) {
    final open = _up[i] || _matched[i];
    final face = _faces[_faceOf[i]];
    return GestureDetector(
      onTap: () => _tap(i),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: open
            ? Container(
                key: ValueKey('o$i'),
                decoration: BoxDecoration(
                  color: face.tint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _matched[i] ? Hue.moss : face.tint,
                    width: 3,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(Art.house(face.house), fit: BoxFit.cover),
              )
            : Container(
                key: ValueKey('c$i'),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Hue.timber, Hue.timberDeep],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Hue.timberDeep, width: 3),
                ),
                child: const Icon(Icons.window_rounded,
                    color: Hue.parchment, size: 26),
              ),
      ),
    );
  }

  Widget _winCard() {
    final next = _level + 1;
    final hasNext = next < _cols.length;
    return ResultOverlay(
      title: 'All matched!',
      stars: _stars,
      detail: '$_moves flips',
      actions: [
        if (hasNext)
          ResultAction('Harder board', Icons.arrow_forward_rounded, BtnTone.ember,
              () => _start(next)),
        ResultAction('Play again', Icons.refresh_rounded, BtnTone.plank,
            () => _start(_level)),
      ],
    );
  }
}
