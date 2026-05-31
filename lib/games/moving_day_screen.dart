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

/// "Moving Day" — a sliding-tile picture puzzle. A house facade is sliced into
/// an N×N grid with one empty plot; tap any tile in the empty plot's row or
/// column to slide that whole run. Rebuild the picture in as few moves as you
/// can. Entirely hand-rolled board logic.
class MovingDayScreen extends StatefulWidget {
  const MovingDayScreen({super.key, this.initialLevel = 0});

  final int initialLevel;

  @override
  State<MovingDayScreen> createState() => _MovingDayScreenState();
}

class _MovingDayScreenState extends State<MovingDayScreen> {
  static const _grid = [3, 4, 5];
  static const _picture = [2, 4, 6]; // house art id per level

  final _rng = math.Random();

  late int _level;
  late int _size;
  late List<int> _tiles;
  int _moves = 0;
  bool _solved = false;
  bool _showNumbers = true;
  bool _showTutorial = false;

  int get _blank => _size * _size - 1;
  String get _image => Art.house(_picture[_level]);

  static const _tutorialSteps = [
    TutorialStep(
      icon: Icons.grid_view_rounded,
      title: 'Slide the houses',
      body: 'Tap any house in the same row or column as the empty plot. '
          'That whole row or column slides toward the gap.',
      iconColor: Hue.moss,
    ),
    TutorialStep(
      icon: Icons.image_rounded,
      title: 'Rebuild the picture',
      body: 'Match the numbered tiles to their positions to reveal the full building. '
          'Fewer moves earns more stars.',
      iconColor: Hue.gold,
    ),
    TutorialStep(
      icon: Icons.emoji_events_rounded,
      title: 'Stars & coins',
      body: 'Solve in par moves for 3 stars. Clearing a grid the first time earns bonus coins.',
      iconColor: Hue.ember,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _level = widget.initialLevel;
    _start(_level);
    _showTutorial = !player.introSeenFor(GameId.movingDay.code);
  }

  void _start(int level) {
    _level = level;
    _size = _grid[level];
    _tiles = List<int>.generate(_size * _size, (i) => i);
    _moves = 0;
    _solved = false;
    _shuffle();
    setState(() {});
  }

  void _shuffle() {
    final steps = _size * _size * 20;
    var blank = _tiles.indexOf(_blank);
    for (var i = 0; i < steps; i++) {
      final r = blank ~/ _size, c = blank % _size;
      final opts = <int>[];
      if (r > 0) opts.add(blank - _size);
      if (r < _size - 1) opts.add(blank + _size);
      if (c > 0) opts.add(blank - 1);
      if (c < _size - 1) opts.add(blank + 1);
      final pick = opts[_rng.nextInt(opts.length)];
      _tiles[blank] = _tiles[pick];
      _tiles[pick] = _blank;
      blank = pick;
    }
    if (_isSolved()) _shuffle();
  }

  bool _isSolved() {
    // Win as soon as all picture tiles occupy their home position.
    // The blank tile position is intentionally ignored — requiring it to also
    // land on the last cell frustrates players whose picture is visibly complete.
    for (var i = 0; i < _tiles.length; i++) {
      final v = _tiles[i];
      if (v != _blank && v != i) return false;
    }
    return true;
  }

  void _tap(int tapped) {
    if (_solved) return;
    final blank = _tiles.indexOf(_blank);
    final br = blank ~/ _size, bc = blank % _size;
    final tr = tapped ~/ _size, tc = tapped % _size;
    if (tapped == blank || (br != tr && bc != tc)) return;

    if (br == tr) {
      final step = tc > bc ? 1 : -1;
      for (var c = bc; c != tc; c += step) {
        _tiles[br * _size + c] = _tiles[br * _size + c + step];
      }
      _tiles[br * _size + tc] = _blank;
    } else {
      final step = tr > br ? 1 : -1;
      for (var r = br; r != tr; r += step) {
        _tiles[r * _size + bc] = _tiles[(r + step) * _size + bc];
      }
      _tiles[tr * _size + bc] = _blank;
    }

    _moves++;
    SoundDesk.it.cue(Cue.tap);
    SoundDesk.it.buzz();
    if (_isSolved()) _win();
    setState(() {});
  }

  int get _stars {
    final par = (_size * _size * 1.4).round();
    if (_moves <= par) return 3;
    if (_moves <= par * 1.8) return 2;
    return 1;
  }

  Future<void> _win() async {
    _solved = true;
    SoundDesk.it.cue(Cue.settle);
    SoundDesk.it.buzz(strong: true);
    final newly = await player.recordGame(
      GameId.movingDay,
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
    final media = MediaQuery.of(context);
    final boardPx = math.min(media.size.width - 40, media.size.height * 0.5);
    final cell = boardPx / _size;
    final best = player.best(GameId.movingDay, _level);

    return _withTutorial(
      GameScaffold(
        title: 'Moving Day',
        subtitle: best == null ? 'Slide the houses into place' : 'Best: $best moves',
        trailing: [
        StatChip(icon: Icons.swipe_rounded, label: '$_moves', iconColor: Hue.ember),
        const SizedBox(width: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              border: Border.all(color: Hue.timberDeep, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(_image, fit: BoxFit.cover),
          ),
        ),
      ],
      body: Column(
        children: [
          LevelBar(
            game: GameId.movingDay,
            current: _level,
            labels: const ['3×3', '4×4', '5×5'],
            onSelect: _start,
          ),
          const Spacer(),
          _board(boardPx, cell),
          const Spacer(),
          _controls(),
        ],
      ),
    ));
  }

  Widget _withTutorial(Widget child) {
    if (!_showTutorial) return child;
    return Stack(
      children: [
        child,
        TutorialOverlay(
          steps: _tutorialSteps,
          onDone: () async {
            await player.markGameIntroSeen(GameId.movingDay.code);
            if (mounted) setState(() => _showTutorial = false);
          },
        ),
      ],
    );
  }

  Widget _board(double boardPx, double cell) {
    final tiles = <Widget>[];
    for (var pos = 0; pos < _tiles.length; pos++) {
      final value = _tiles[pos];
      if (value == _blank) continue;
      tiles.add(
        AnimatedPositioned(
          key: ValueKey(value),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          left: (pos % _size) * cell,
          top: (pos ~/ _size) * cell,
          width: cell,
          height: cell,
          child: GestureDetector(
            onTap: () => _tap(pos),
            child: _Tile(
              value: value,
              size: _size,
              cell: cell,
              boardPx: boardPx,
              image: _image,
              showNumber: _showNumbers,
            ),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Hue.panelDeep,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Hue.timberDeep, width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: SizedBox(
        width: boardPx,
        height: boardPx,
        child: Stack(
          children: [
            ...tiles,
            if (_solved) _winCard(),
          ],
        ),
      ),
    );
  }

  Widget _winCard() {
    final next = _level + 1;
    final hasNext = next < _grid.length;
    return ResultOverlay(
      title: 'Picture complete!',
      stars: _stars,
      detail: '$_moves moves',
      actions: [
        if (hasNext)
          ResultAction('Next puzzle', Icons.arrow_forward_rounded, BtnTone.ember,
              () => _start(next)),
        ResultAction('Play again', Icons.refresh_rounded, BtnTone.plank,
            () => _start(_level)),
      ],
    );
  }

  Widget _controls() {
    return Row(
      children: [
        Expanded(
          child: StorybookButton(
            label: 'Shuffle',
            tone: BtnTone.plank,
            icon: Icons.shuffle_rounded,
            onTap: () {
              SoundDesk.it.cue(Cue.tap);
              _start(_level);
            },
          ),
        ),
        const SizedBox(width: 12),
        StorybookButton(
          label: _showNumbers ? 'Numbers' : 'Picture',
          tone: BtnTone.moss,
          icon: _showNumbers ? Icons.tag_rounded : Icons.image_rounded,
          onTap: () => setState(() => _showNumbers = !_showNumbers),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.value,
    required this.size,
    required this.cell,
    required this.boardPx,
    required this.image,
    required this.showNumber,
  });

  final int value;
  final int size;
  final double cell;
  final double boardPx;
  final String image;
  final bool showNumber;

  @override
  Widget build(BuildContext context) {
    final hr = value ~/ size, hc = value % size;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
                color: Hue.timberDeep.withValues(alpha: 0.5), width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: -hc * cell,
                top: -hr * cell,
                width: boardPx,
                height: boardPx,
                child: Image.asset(image, fit: BoxFit.cover),
              ),
              if (showNumber)
                Positioned(
                  left: 4,
                  top: 2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Hue.panelDeep.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${value + 1}',
                      style: const TextStyle(
                        color: Hue.parchment,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
