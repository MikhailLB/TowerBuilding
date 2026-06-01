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

// ── Tile identity model ──────────────────────────────────────────────────────

class _Tile {
  _Tile(this.id, this.value, this.row, this.col);
  final int id;
  int value;
  int row, col;
}

enum _Dir { left, right, up, down }

// ── Screen ───────────────────────────────────────────────────────────────────

/// "Cozy Merge" — slide a 4×4 board so matching houses fuse into the next tier.
/// Tiles animate smoothly to their new positions via [AnimatedPositioned] keyed
/// by unique tile ID; merge pops are handled by an entry animation on newly
/// created tiles.
class CozyMergeScreen extends StatefulWidget {
  const CozyMergeScreen({super.key, this.initialLevel = 0});

  final int initialLevel;

  @override
  State<CozyMergeScreen> createState() => _CozyMergeScreenState();
}

class _CozyMergeScreenState extends State<CozyMergeScreen>
    with SingleTickerProviderStateMixin {
  // ── Tutorial ──────────────────────────────────────────────────────────────
  static const _tutorialSteps = [
    TutorialStep(
      icon: Icons.dashboard_customize_rounded,
      title: 'Swipe to merge',
      body: 'Swipe left, right, up or down. All houses slide that way. '
          'Two matching houses on the same tile merge into the next tier.',
      iconColor: Hue.lavender,
    ),
    TutorialStep(
      icon: Icons.home_rounded,
      title: 'Grow your village',
      body: 'Tent + Tent = Hut, Hut + Hut = Cabin … all the way to Palace. '
          'Reach the target tier to win!',
      iconColor: Hue.ember,
    ),
    TutorialStep(
      icon: Icons.warning_amber_rounded,
      title: "Don't run out of room",
      body: 'A new house spawns after every swipe. '
          'If the board fills up with no moves left, the game ends.',
      iconColor: Hue.alarm,
    ),
  ];

  // ── Constants ────────────────────────────────────────────────────────────
  static const _targetForLevel = [5, 6, 7];
  static const _names = [
    'Tent', 'Hut', 'Cabin', 'Cottage', 'House', 'Manor', 'Tower', 'Castle', 'Palace'
  ];
  static const _colors = [
    Hue.meadowMid,
    Hue.moss,
    Color(0xFF4FA3C7),
    Hue.gold,
    Hue.ember,
    Hue.lavender,
    Color(0xFFC2452F),
    Hue.timber,
    Hue.timberDeep,
  ];

  // ── State ────────────────────────────────────────────────────────────────
  final _rng = math.Random();
  int _nextId = 0;
  late int _level;
  late int _target;
  late List<_Tile?> _grid; // flat 4×4, row-major
  int _score = 0;
  int _maxTier = 0;
  bool _won = false;
  bool _lost = false;
  bool _showTutorial = false;

  // Slide animation – plays for 150 ms after each move so AnimatedPositioned
  // can interpolate the tile positions.
  late final AnimationController _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _level = widget.initialLevel;
    _start(_level);
    _showTutorial = !player.introSeenFor(GameId.merge.code);
  }

  @override
  void dispose() {
    _slideAnim.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  _Tile? _at(int r, int c) => _grid[r * 4 + c];
  void _set(int r, int c, _Tile? t) => _grid[r * 4 + c] = t;
  _Tile _newTile(int value, int row, int col) =>
      _Tile(_nextId++, value, row, col);

  void _start(int level) {
    _level = level;
    _target = _targetForLevel[level];
    _grid = List<_Tile?>.filled(16, null);
    _score = 0;
    _maxTier = 0;
    _won = false;
    _lost = false;
    _nextId = 0;
    _spawn();
    _spawn();
    setState(() {});
  }

  void _spawn() {
    final empty = <int>[];
    for (var i = 0; i < 16; i++) {
      if (_grid[i] == null) empty.add(i);
    }
    if (empty.isEmpty) return;
    final pos = empty[_rng.nextInt(empty.length)];
    final r = pos ~/ 4, c = pos % 4;
    final tier = _rng.nextDouble() < 0.85 ? 1 : 2;
    _set(r, c, _newTile(tier, r, c));
    if (tier > _maxTier) _maxTier = tier;
  }

  // ── Move logic ────────────────────────────────────────────────────────────
  void _onPanEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond;
    if (v.distance < 80) return;
    _Dir dir;
    if (v.dx.abs() > v.dy.abs()) {
      dir = v.dx > 0 ? _Dir.right : _Dir.left;
    } else {
      dir = v.dy > 0 ? _Dir.down : _Dir.up;
    }
    _doMove(dir);
  }

  void _doMove(_Dir d) {
    if (_won || _lost) return;
    bool changed = false;

    // Slide and merge one line at a time (row or col depending on direction).
    for (var i = 0; i < 4; i++) {
      // Collect the non-null tiles in this line, ordered from the direction's
      // "near edge" (where tiles collapse toward).
      final indices = _lineIndices(i, d);
      final line = [for (final idx in indices) _grid[idx]];
      final nonNull = line.whereType<_Tile>().toList();
      final merged = _mergeLine(nonNull);

      // Place merged tiles back and update their row/col.
      for (var k = 0; k < 4; k++) {
        final idx = indices[k];
        final newTile = k < merged.length ? merged[k] : null;
        if (_grid[idx] != newTile) changed = true;
        _grid[idx] = newTile;
        if (newTile != null) {
          newTile.row = idx ~/ 4;
          newTile.col = idx % 4;
        }
      }
    }

    if (changed) {
      _spawn();
      SoundDesk.it.cue(Cue.tap);
      SoundDesk.it.buzz();
      if (_maxTier >= _target) {
        _win();
      } else if (!_anyMovePossible()) {
        _lost = true;
        SoundDesk.it.cue(Cue.collapse);
      }
      // Trigger slide animation then redraw final positions.
      _slideAnim.forward(from: 0).then((_) {
        if (mounted) setState(() {});
      });
      setState(() {}); // redraw immediately with new positions
    }
  }

  // Returns 4 flat-grid indices for line [i], ordered toward the merge edge.
  List<int> _lineIndices(int i, _Dir d) {
    switch (d) {
      case _Dir.left:
        return [i * 4, i * 4 + 1, i * 4 + 2, i * 4 + 3];
      case _Dir.right:
        return [i * 4 + 3, i * 4 + 2, i * 4 + 1, i * 4];
      case _Dir.up:
        return [i, 4 + i, 8 + i, 12 + i];
      case _Dir.down:
        return [12 + i, 8 + i, 4 + i, i];
    }
  }

  // Slide + merge a list of non-null tiles from left (index 0 = target edge).
  List<_Tile> _mergeLine(List<_Tile> tiles) {
    final result = <_Tile>[];
    var i = 0;
    while (i < tiles.length) {
      if (i + 1 < tiles.length && tiles[i].value == tiles[i + 1].value) {
        final tier = tiles[i].value + 1;
        // Reuse the first tile's object as the merged tile (keeps its ID stable
        // in the widget tree → no flicker).
        final merged = tiles[i]..value = tier;
        result.add(merged);
        _score += tier * 2;
        if (tier > _maxTier) _maxTier = tier;
        i += 2;
      } else {
        result.add(tiles[i]);
        i++;
      }
    }
    return result;
  }

  bool _anyMovePossible() {
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        if (_at(r, c) == null) return true;
        if (c < 3 && _at(r, c)!.value == _at(r, c + 1)?.value) return true;
        if (r < 3 && _at(r, c)!.value == _at(r + 1, c)?.value) return true;
      }
    }
    return false;
  }

  Future<void> _win() async {
    _won = true;
    SoundDesk.it.cue(Cue.settle);
    SoundDesk.it.buzz(strong: true);
    final newly = await player.recordGame(
      GameId.merge,
      _level,
      stars: 3,
      score: _score,
      higherBetter: true,
      coinReward: 30 + _level * 20,
    );
    if (mounted) showAchievementToast(context, newly);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final best = player.best(GameId.merge, _level);
    return _maybeWithTutorial(GameScaffold(
      title: 'Cozy Merge',
      subtitle: 'Reach a ${_names[_target - 1]}'
          '${best == null ? '' : ' · best $best pts'}',
      trailing: [
        StatChip(icon: Icons.stars_rounded, label: '$_score', iconColor: Hue.gold),
      ],
      body: Column(
        children: [
          LevelBar(
            game: GameId.merge,
            current: _level,
            labels: [for (final t in _targetForLevel) _names[t - 1]],
            onSelect: _start,
          ),
          const SizedBox(height: 8),
          Text('Swipe to merge houses · reach the ${_names[_target - 1]}',
              style: Lettering.body(size: 12.5, color: Hue.inkSoft),
              textAlign: TextAlign.center),
          const Spacer(),
          Center(
            child: GestureDetector(
              onPanEnd: _onPanEnd,
              child: _board(),
            ),
          ),
          const Spacer(),
          StorybookButton(
            label: 'New game',
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

  Widget _board() {
    final side = math.min(MediaQuery.of(context).size.width - 40, 360.0);
    const gap = 8.0;
    final cell = (side - gap * 5) / 4;

    // Collect active tiles from the grid.
    final tiles = _grid.whereType<_Tile>().toList();

    return Container(
      width: side,
      height: side,
      padding: const EdgeInsets.all(gap),
      decoration: BoxDecoration(
        color: Hue.panelDeep,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Hue.timberDeep, width: 3),
      ),
      child: Stack(
        children: [
          // Empty cell backgrounds.
          for (var r = 0; r < 4; r++)
            for (var c = 0; c < 4; c++)
              Positioned(
                left: c * (cell + gap),
                top: r * (cell + gap),
                width: cell,
                height: cell,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Hue.panel.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          // Animated tiles — each tile keeps its key = id so Flutter's engine
          // interpolates Positioned params (smooth sliding).
          for (final t in tiles)
            AnimatedPositioned(
              key: ValueKey(t.id),
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              left: t.col * (cell + gap),
              top: t.row * (cell + gap),
              width: cell,
              height: cell,
              child: _tileWidget(t.value, cell),
            ),
          if (_won || _lost) _resultCard(cell),
        ],
      ),
    );
  }

  Widget _tileWidget(int tier, double cell) {
    final color = _colors[(tier - 1).clamp(0, _colors.length - 1)];
    final houseId = ((tier - 1) % Art.houseCount) + 1;
    final label = _names[(tier - 1).clamp(0, _names.length - 1)];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 8,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(Art.house(houseId), fit: BoxFit.cover),
          Positioned(
            right: 3,
            top: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: (cell * 0.12).clamp(9.0, 14.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(double cell) {
    return ResultOverlay(
      title: _won ? 'New ${_names[_target - 1]}!' : 'Out of room',
      stars: _won ? 3 : 0,
      detail: _won ? 'Score $_score' : 'No moves left · score $_score',
      actions: [
        if (_won && _level + 1 < _targetForLevel.length)
          ResultAction('Bigger goal', Icons.arrow_forward_rounded, BtnTone.ember,
              () => _start(_level + 1)),
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
          await player.markGameIntroSeen(GameId.merge.code);
          if (mounted) setState(() => _showTutorial = false);
        },
      ),
    ]);
  }
}
