import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound_desk.dart';
import '../theme/asset_paths.dart';
import '../theme/palette.dart';
import '../theme/type_scale.dart';
import '../widgets/plank_panel.dart';
import '../widgets/storybook_button.dart';
import 'assemble_model.dart';
import 'campaign.dart';
import 'game_shell.dart';
import 'level_host.dart';
import 'progress.dart';

class AssembleGame extends StatefulWidget {
  const AssembleGame({super.key, required this.spec});
  final LevelSpec spec;

  @override
  State<AssembleGame> createState() => _AssembleGameState();
}

class _AssembleGameState extends State<AssembleGame>
    with SingleTickerProviderStateMixin {
  late AssembleModel _m;
  late AnimationController _anim;
  BlockType? _sel;
  int _moves = 0;
  GameResult? _result;
  bool _toppling = false;
  bool _rising = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..addListener(() => setState(() {}));
    _load();
  }

  void _load() {
    _m = AssembleModel.generate(widget.spec.tier, widget.spec.seed);
    _moves = 0;
    _result = null;
    _toppling = false;
    _rising = false;
    _anim.value = 0;
    _sel = _m.trayRemaining().keys.isNotEmpty
        ? _m.trayRemaining().keys.first
        : null;
    setState(() {});
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _ensureSelection() {
    final rem = _m.trayRemaining();
    if (_sel == null || (rem[_sel] ?? 0) <= 0) {
      _sel = rem.keys.isNotEmpty ? rem.keys.first : null;
    }
  }

  void _tapCell(int r, int c) {
    if (_result != null || _toppling || _rising) return;
    if (_m.canLift(r, c)) {
      _m.lift(r, c);
      _moves++;
      SoundDesk.maybe?.cue(Cue.tap);
      _ensureSelection();
      setState(() {});
      return;
    }
    final t = _sel;
    if (t != null && _m.canPlace(r, c, t)) {
      _m.place(r, c, t);
      _moves++;
      SoundDesk.maybe?.cue(Cue.settle);
      SoundDesk.maybe?.buzz();
      _ensureSelection();
      setState(() {});
    }
  }

  void _build() {
    if (_result != null || _toppling || _rising) return;
    final ok = _m.matchesBlueprint() && _m.isStable();
    if (ok) {
      _rising = true;
      SoundDesk.maybe?.cue(Cue.settle);
      _anim.forward(from: 0).whenComplete(_finishWin);
    } else {
      _toppling = true;
      SoundDesk.maybe?.cue(Cue.collapse);
      SoundDesk.maybe?.buzz(strong: true);
      _anim.forward(from: 0).whenComplete(_finishLose);
    }
    setState(() {});
  }

  Future<void> _finishWin() async {
    final stars = _moves <= _m.par
        ? 3
        : _moves <= _m.par + 3
            ? 2
            : 1;
    final res = await commitLevel(widget.spec.index, stars: stars, score: _moves);
    if (!mounted) return;
    setState(() {
      _rising = false;
      _result = GameResult(
          win: true, stars: stars, score: _moves, scoreLabel: 'Moves', coins: res.coins);
    });
  }

  void _finishLose() {
    if (!mounted) return;
    setState(() {
      _toppling = false;
      _result = const GameResult(
          win: false, stars: 0, score: 0, scoreLabel: 'Moves');
      // reset board for a clean retry view behind the card
    });
    _m.reset();
    _moves = 0;
    _ensureSelection();
  }

  void _next() => Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LevelHost(index: widget.spec.index + 1)));

  @override
  Widget build(BuildContext context) {
    final placedCount = _m.placed.length - _m.locked.length;
    final targetCount = _m.target.length - _m.locked.length;
    return GameShell(
      title: 'Assembly',
      levelLabel: 'Level ${widget.spec.index + 1}  ·  match the blueprint',
      onRestart: _load,
      statusBar: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Placed $placedCount / $targetCount',
              style: Lettering.body(size: 13, color: Hue.parchment)),
          Text('Moves $_moves  ·  Par ${_m.par}',
              style: Lettering.body(size: 13, color: Hue.parchment)),
        ],
      ),
      overlay: _result == null
          ? null
          : ResultCard(
              result: _result!,
              onRetry: _load,
              onExit: () => Navigator.of(context).maybePop(),
              onNext: _result!.win && hasNextLevel(widget.spec.index) ? _next : null,
            ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: LayoutBuilder(builder: (context, c) {
                final cell = math.min(c.maxWidth / _m.cols, c.maxHeight / _m.rows);
                final w = cell * _m.cols, h = cell * _m.rows;
                return Center(
                  child: SizedBox(
                    width: w,
                    height: h,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _BoardPainter(_m),
                          ),
                        ),
                        ..._blockWidgets(cell),
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (d) {
                              final c2 = (d.localPosition.dx / cell).floor();
                              final r2 = _m.rows - 1 - (d.localPosition.dy / cell).floor();
                              _tapCell(r2, c2);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          _tray(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: StorybookButton(
              label: 'BUILD IT',
              icon: Icons.construction_rounded,
              tone: BtnTone.moss,
              width: double.infinity,
              onTap: (_toppling || _rising) ? null : _build,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _blockWidgets(double cell) {
    final widgets = <Widget>[];
    final rng = math.Random(7);
    _m.placed.forEach((k, t) {
      final r = k ~/ _m.cols, c = k % _m.cols;
      final baseLeft = c * cell;
      final baseTop = (_m.rows - 1 - r) * cell;
      var dx = 0.0, dy = 0.0, rot = 0.0;
      final tilt = (rng.nextDouble() - 0.5);
      if (_toppling) {
        final e = Curves.easeIn.transform(_anim.value);
        dy = e * cell * _m.rows * 1.2;
        dx = e * tilt * cell * 3;
        rot = e * tilt * 2.4;
      } else if (_rising) {
        final e = Curves.elasticOut.transform(_anim.value.clamp(0, 1));
        dy = (1 - e) * -cell * 0.4;
      }
      final spec = specOf(t);
      widgets.add(Positioned(
        left: baseLeft + dx,
        top: baseTop + dy,
        width: cell,
        height: cell,
        child: Transform.rotate(
          angle: rot,
          child: Padding(
            padding: EdgeInsets.all(cell * 0.04),
            child: Opacity(
              opacity: spec.fragile ? 0.85 : 1.0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cell * 0.16),
                  border: _m.isLocked(r, c)
                      ? Border.all(color: Hue.gold, width: 2)
                      : null,
                ),
                child: Image.asset(Art.house(spec.asset), fit: BoxFit.fill),
              ),
            ),
          ),
        ),
      ));
    });
    return widgets;
  }

  Widget _tray() {
    final rem = _m.trayRemaining();
    final types = kBlockSpecs.keys.where((t) => (rem[t] ?? 0) > 0).toList();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: PlankPanel(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (types.isEmpty)
              Text('All blocks placed — press BUILD',
                  style: Lettering.body(size: 13, color: Hue.inkSoft))
            else
              for (final t in types) _trayChip(t, rem[t]!),
          ],
        ),
      ),
    );
  }

  Widget _trayChip(BlockType t, int count) {
    final selected = _sel == t;
    final spec = specOf(t);
    return GestureDetector(
      onTap: () {
        SoundDesk.maybe?.cue(Cue.tap);
        setState(() => _sel = t);
      },
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: selected ? Hue.ember.withValues(alpha: 0.30) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? Hue.ember : Hue.timberDeep.withValues(alpha: 0.4),
              width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: Image.asset(Art.house(spec.asset), fit: BoxFit.contain),
            ),
            const SizedBox(height: 2),
            Text('${spec.name}  x$count',
                style: Lettering.body(size: 11, color: Hue.ink)),
          ],
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter(this.m);
  final AssembleModel m;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / m.cols;

    // ground line
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 3, size.width, 3),
      Paint()..color = Hue.timberDeep,
    );

    for (var r = 0; r < m.rows; r++) {
      for (var c = 0; c < m.cols; c++) {
        final left = c * cell;
        final top = (m.rows - 1 - r) * cell;
        final rect = Rect.fromLTWH(left + 1, top + 1, cell - 2, cell - 2);
        final rr = RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.16));
        final k = m.key(r, c);

        // faint grid cell
        canvas.drawRRect(
            rr, Paint()..color = Colors.white.withValues(alpha: 0.05));

        if (m.obstacles.contains(k)) {
          canvas.drawRRect(rr, Paint()..color = Hue.timberDeep.withValues(alpha: 0.6));
          final p = Paint()
            ..color = Hue.alarm
            ..strokeWidth = 2;
          canvas.drawLine(rect.topLeft, rect.bottomRight, p);
          canvas.drawLine(rect.topRight, rect.bottomLeft, p);
          continue;
        }

        // blueprint ghost for target cells not yet filled
        final target = m.target[k];
        if (target != null && !m.placed.containsKey(k)) {
          final col = specOf(target).color;
          canvas.drawRRect(rr, Paint()..color = col.withValues(alpha: 0.16));
          canvas.drawRRect(
            rr,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6
              ..color = col.withValues(alpha: 0.7),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) => true;
}
