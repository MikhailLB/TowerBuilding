import 'package:flutter/material.dart';

import '../core/sound_desk.dart';
import '../main.dart';
import '../meta/game_catalog.dart';
import '../theme/palette.dart';
import '../theme/type_scale.dart';
import '../widgets/game_shell.dart';
import '../widgets/plank_panel.dart';
import '../widgets/storybook_button.dart';
import '../widgets/tutorial_overlay.dart';

/// "Skyline Movers" — a Tower of Hanoi recast as relocating a stack of houses
/// between three lamp-posts. A wider house may never sit on a narrower one.
/// Move the whole stack to the right-hand post in as few moves as possible.
class SkylineMoversScreen extends StatefulWidget {
  const SkylineMoversScreen({super.key, this.initialLevel = 0});

  final int initialLevel;

  @override
  State<SkylineMoversScreen> createState() => _SkylineMoversScreenState();
}

class _SkylineMoversScreenState extends State<SkylineMoversScreen> {
  static const _disksForLevel = [3, 4, 5, 6, 7];
  static const _palette = [
    Hue.ember,
    Hue.moss,
    Hue.gold,
    Hue.lavender,
    Hue.timber,
    Color(0xFF4FA3C7),
    Color(0xFFC2452F),
  ];

  static const _tutorialSteps = [
    TutorialStep(
      icon: Icons.view_column_rounded,
      title: 'Three posts, one goal',
      body: 'All houses start on the left post. '
          'Move the whole stack to the right post.',
      iconColor: Hue.ember,
    ),
    TutorialStep(
      icon: Icons.touch_app_rounded,
      title: 'Tap to pick & place',
      body: 'Tap a post to pick up its top house. Tap another post to drop it there. '
          'A wider house can NEVER sit on a narrower one.',
      iconColor: Hue.moss,
    ),
    TutorialStep(
      icon: Icons.emoji_events_rounded,
      title: 'The minimum is 2ⁿ − 1',
      body: '3 houses = 7 moves minimum. Fewer moves = more stars. '
          'Use all three posts freely.',
      iconColor: Hue.gold,
    ),
  ];

  late int _level;
  late int _disks;
  late List<List<int>> _posts;
  int? _selected;
  int _moves = 0;
  bool _won = false;
  bool _showTutorial = false;

  int get _minMoves => (1 << _disks) - 1;

  @override
  void initState() {
    super.initState();
    _level = widget.initialLevel;
    _start(_level);
    _showTutorial = !player.introSeenFor(GameId.skyline.code);
  }

  void _start(int level) {
    _level = level;
    _disks = _disksForLevel[level];
    _posts = [
      [for (var s = _disks; s >= 1; s--) s],
      <int>[],
      <int>[],
    ];
    _selected = null;
    _moves = 0;
    _won = false;
    setState(() {});
  }

  void _tapPost(int i) {
    if (_won) return;
    SoundDesk.it.cue(Cue.tap);
    if (_selected == null) {
      if (_posts[i].isEmpty) return;
      setState(() => _selected = i);
      return;
    }
    if (_selected == i) {
      setState(() => _selected = null);
      return;
    }
    final from = _posts[_selected!];
    final to = _posts[i];
    final moving = from.last;
    if (to.isEmpty || to.last > moving) {
      from.removeLast();
      to.add(moving);
      _moves++;
      SoundDesk.it.buzz();
      _selected = null;
      if (_posts[2].length == _disks) _win();
    } else {
      SoundDesk.it.cue(Cue.collapse);
      SoundDesk.it.buzz(strong: true);
      _selected = null;
    }
    setState(() {});
  }

  int get _stars {
    if (_moves <= _minMoves) return 3;
    if (_moves <= (_minMoves * 1.6).round()) return 2;
    return 1;
  }

  Future<void> _win() async {
    _won = true;
    SoundDesk.it.cue(Cue.settle);
    SoundDesk.it.buzz(strong: true);
    final newly = await player.recordGame(
      GameId.skyline,
      _level,
      stars: _stars,
      score: _moves,
      higherBetter: false,
      coinReward: 25 + _level * 15,
    );
    if (mounted) showAchievementToast(context, newly);
  }

  @override
  Widget build(BuildContext context) {
    final best = player.best(GameId.skyline, _level);
    return _maybeWithTutorial(GameScaffold(
      title: 'Skyline Movers',
      subtitle: best == null ? 'Best target: $_minMoves moves' : 'Best: $best moves',
      trailing: [
        StatChip(icon: Icons.swipe_rounded, label: '$_moves', iconColor: Hue.ember),
      ],
      body: Column(
        children: [
          LevelBar(
            game: GameId.skyline,
            current: _level,
            labels: const ['3', '4', '5', '6', '7'],
            onSelect: _start,
          ),
          const SizedBox(height: 8),
          Text('Move every house to the right post · best in $_minMoves',
              style: Lettering.body(size: 12.5, color: Hue.inkSoft),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Expanded(
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, c) => Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        Expanded(child: _post(i, c.maxWidth / 3, c.maxHeight)),
                    ],
                  ),
                ),
                if (_won) _winCard(),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _post(int i, double colW, double colH) {
    final selected = _selected == i;
    final stack = _posts[i];
    final diskH = ((colH - 40) / (_disks + 1)).clamp(16.0, 34.0);
    final maxDiskW = colW - 18;
    final minDiskW = maxDiskW * 0.34;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _tapPost(i),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        // Explicit height so the inner Stack is bounded — without this the
        // pole Container has zero intrinsic height and disks render below frame.
        height: colH,
        decoration: BoxDecoration(
          color: selected
              ? Hue.parchment.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Hue.gold : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          fit: StackFit.expand,
          children: [
            // The post / lamp-pole: full height minus top padding.
            Positioned(
              top: colH * 0.06,
              bottom: 8,
              width: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Hue.timberDeep,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Ground line.
            Positioned(
              bottom: 0,
              left: 6,
              right: 6,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Hue.timber,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Houses stacked from bottom upward.
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (var d = 0; d < stack.length; d++)
                    _disk(
                      stack[d],
                      diskH,
                      minDiskW,
                      maxDiskW,
                      lifted: selected && d == stack.length - 1,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _disk(int size, double h, double minW, double maxW, {bool lifted = false}) {
    final t = _disks == 1 ? 1.0 : (size - 1) / (_disks - 1);
    final w = minW + (maxW - minW) * t;
    final color = _palette[(size - 1) % _palette.length];
    return Container(
      width: w,
      height: h,
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.95), color],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: lifted ? Hue.gold : Hue.timberDeep,
          width: lifted ? 3 : 2,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x44000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Center(
        child: Container(
          width: w * 0.22,
          height: h * 0.45,
          decoration: BoxDecoration(
            color: Hue.parchment.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _winCard() {
    final next = _level + 1;
    final hasNext = next < _disksForLevel.length;
    return ResultOverlay(
      title: 'Relocated!',
      stars: _stars,
      detail: '$_moves moves · best possible $_minMoves',
      actions: [
        if (hasNext)
          ResultAction('Taller tower', Icons.arrow_upward_rounded, BtnTone.ember,
              () => _start(next)),
        ResultAction('Play again', Icons.refresh_rounded, BtnTone.plank,
            () => _start(_level)),
      ],
    );
  }

  Widget _maybeWithTutorial(Widget child) {
    if (!_showTutorial) return child;
    return Stack(children: [
      child,
      TutorialOverlay(
        steps: _tutorialSteps,
        onDone: () async {
          await player.markGameIntroSeen(GameId.skyline.code);
          if (mounted) setState(() => _showTutorial = false);
        },
      ),
    ]);
  }
}
