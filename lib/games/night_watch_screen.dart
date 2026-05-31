import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound_desk.dart';
import '../main.dart';
import '../meta/game_catalog.dart';
import '../theme/asset_paths.dart';
import '../theme/palette.dart';
import '../theme/type_scale.dart';
import '../widgets/game_shell.dart';
import '../widgets/plank_panel.dart';
import '../widgets/storybook_button.dart';
import '../widgets/tutorial_overlay.dart';

/// "Night Watch" — a Lights Out puzzle. Tapping a house toggles its own window
/// and those of its four neighbours. Light every window on the street. Boards
/// are scrambled from the solved state so they are always solvable.
class NightWatchScreen extends StatefulWidget {
  const NightWatchScreen({super.key, this.initialLevel = 0});

  final int initialLevel;

  @override
  State<NightWatchScreen> createState() => _NightWatchScreenState();
}

class _NightWatchScreenState extends State<NightWatchScreen> {
  static const _gridForLevel = [3, 4, 5];
  final _rng = math.Random();

  static const _tutorialSteps = [
    TutorialStep(
      icon: Icons.lightbulb_rounded,
      title: 'Light every window',
      body: 'The street is dark. Tap a house to toggle its window — '
          'and the windows of its four neighbours.',
      iconColor: Hue.gold,
    ),
    TutorialStep(
      icon: Icons.grid_on_rounded,
      title: 'Think in patterns',
      body: 'Tapping the same house twice undoes the change. '
          'Each tap flips up, down, left, right and the house itself.',
      iconColor: Hue.moss,
    ),
    TutorialStep(
      icon: Icons.emoji_events_rounded,
      title: 'Fewer taps, more stars',
      body: 'Try to light the whole street in as few taps as possible. '
          'Hit "New street" for a fresh puzzle any time.',
      iconColor: Hue.ember,
    ),
  ];

  late int _level;
  late int _n;
  late List<bool> _lit;
  bool _showTutorial = false;
  int _moves = 0;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _level = widget.initialLevel;
    _start(_level);
    _showTutorial = !player.introSeenFor(GameId.lights.code);
  }

  void _start(int level) {
    _level = level;
    _n = _gridForLevel[level];
    _lit = List<bool>.filled(_n * _n, true);
    _moves = 0;
    _won = false;
    _scramble();
    setState(() {});
  }

  void _toggle(int i) {
    void flip(int j) {
      if (j >= 0 && j < _lit.length) _lit[j] = !_lit[j];
    }

    final r = i ~/ _n, c = i % _n;
    flip(i);
    if (r > 0) flip(i - _n);
    if (r < _n - 1) flip(i + _n);
    if (c > 0) flip(i - 1);
    if (c < _n - 1) flip(i + 1);
  }

  void _scramble() {
    final taps = _n * _n;
    for (var k = 0; k < taps; k++) {
      _toggle(_rng.nextInt(_lit.length));
    }
    if (_lit.every((v) => v)) _scramble();
  }

  void _tap(int i) {
    if (_won) return;
    _toggle(i);
    _moves++;
    SoundDesk.it.cue(Cue.tap);
    SoundDesk.it.buzz();
    if (_lit.every((v) => v)) _win();
    setState(() {});
  }

  int get _stars {
    final par = _n * _n;
    if (_moves <= par) return 3;
    if (_moves <= (par * 1.6).round()) return 2;
    return 1;
  }

  Future<void> _win() async {
    _won = true;
    SoundDesk.it.cue(Cue.settle);
    SoundDesk.it.buzz(strong: true);
    final newly = await player.recordGame(
      GameId.lights,
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
    final best = player.best(GameId.lights, _level);
    final litCount = _lit.where((v) => v).length;
    return _maybeWithTutorial(GameScaffold(
      title: 'Night Watch',
      subtitle: best == null ? 'Light every window' : 'Best: $best taps',
      trailing: [
        StatChip(icon: Icons.touch_app_rounded, label: '$_moves', iconColor: Hue.ember),
        const SizedBox(width: 8),
        StatChip(icon: Icons.lightbulb_rounded, label: '$litCount/${_lit.length}',
            iconColor: Hue.gold),
      ],
      body: Column(
        children: [
          LevelBar(
            game: GameId.lights,
            current: _level,
            labels: const ['3×3', '4×4', '5×5'],
            onSelect: _start,
          ),
          const SizedBox(height: 8),
          Text('Tap a house to flip it and its neighbours',
              style: Lettering.body(size: 12.5, color: Hue.inkSoft),
              textAlign: TextAlign.center),
          const Spacer(),
          Center(
            child: Stack(
              children: [
                _board(),
                if (_won)
                  Positioned.fill(
                    child: Center(
                      child: SizedBox(height: 250, child: _winCard()),
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
          StorybookButton(
            label: 'New street',
            tone: BtnTone.plank,
            icon: Icons.refresh_rounded,
            width: double.infinity,
            onTap: () {
              SoundDesk.it.cue(Cue.tap);
              _start(_level);
            },
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
          await player.markGameIntroSeen(GameId.lights.code);
          if (mounted) setState(() => _showTutorial = false);
        },
      ),
    ]);
  }

  Widget _board() {
    final side = math.min(MediaQuery.of(context).size.width - 40, 360.0);
    final gap = 8.0;
    final cell = (side - gap * (_n + 1)) / _n;
    return Container(
      width: side,
      height: side,
      padding: EdgeInsets.all(gap),
      decoration: BoxDecoration(
        color: Hue.panelDeep,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Hue.timberDeep, width: 3),
      ),
      child: Stack(
        children: [
          for (var i = 0; i < _lit.length; i++)
            Positioned(
              left: (i % _n) * (cell + gap),
              top: (i ~/ _n) * (cell + gap),
              width: cell,
              height: cell,
              child: _house(i, cell),
            ),
        ],
      ),
    );
  }

  Widget _house(int i, double cell) {
    final lit = _lit[i];
    return GestureDetector(
      onTap: () => _tap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: lit ? Hue.gold : Hue.timberDeep,
            width: lit ? 2.5 : 1.5,
          ),
          boxShadow: lit
              ? [
                  BoxShadow(
                    color: Hue.gold.withValues(alpha: 0.6),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                ]
              : const [],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(Art.house((i % Art.houseCount) + 1), fit: BoxFit.cover),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              color: lit
                  ? Hue.gold.withValues(alpha: 0.0)
                  : const Color(0xCC0E1A3A),
            ),
            Align(
              alignment: Alignment.center,
              child: Icon(
                lit ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
                color: lit ? Hue.gold : Hue.parchment.withValues(alpha: 0.5),
                size: cell * 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _winCard() {
    final next = _level + 1;
    final hasNext = next < _gridForLevel.length;
    return ResultOverlay(
      title: 'Street lit!',
      stars: _stars,
      detail: '$_moves taps',
      actions: [
        if (hasNext)
          ResultAction('Bigger street', Icons.arrow_forward_rounded, BtnTone.ember,
              () => _start(next)),
        ResultAction('Play again', Icons.refresh_rounded, BtnTone.plank,
            () => _start(_level)),
      ],
    );
  }
}
