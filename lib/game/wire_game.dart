import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound_desk.dart';
import '../theme/palette.dart';
import '../theme/type_scale.dart';
import 'campaign.dart';
import 'game_shell.dart';
import 'level_host.dart';
import 'progress.dart';

const _n = 1, _e = 2, _s = 4, _w = 8;
int _rotCW(int m) => ((m << 1) | (m >> 3)) & 0xF;
int _rotN(int m, int t) {
  var x = m;
  for (var i = 0; i < t; i++) {
    x = _rotCW(x);
  }
  return x;
}

class _WireModel {
  _WireModel(this.n);
  final int n;
  late List<List<int>> mask;
  late List<List<int>> solution;
  late List<List<bool>> powered;
  late Set<int> locked;
  int sx = 0, sy = 0;
  int par = 1;

  bool _in(int x, int y) => x >= 0 && y >= 0 && x < n && y < n;
  int _opp(int b) => b == _n ? _s : b == _e ? _w : b == _s ? _n : _e;

  static _WireModel generate(int tier, int seed) {
    final rng = math.Random(seed);
    final n = (3 + tier).clamp(3, 6);
    final m = _WireModel(n);
    m._build(rng, tier);
    return m;
  }

  void _build(math.Random rng, int tier) {
    solution = List.generate(n, (_) => List.filled(n, 0));
    mask = List.generate(n, (_) => List.filled(n, 0));
    powered = List.generate(n, (_) => List.filled(n, false));
    locked = {};
    sx = rng.nextInt(n);
    sy = 0; // power vault at the base row

    final visited = List.generate(n, (_) => List.filled(n, false));
    final stack = <List<int>>[[sx, sy]];
    visited[sx][sy] = true;
    final dirs = [
      [_n, 0, -1],
      [_e, 1, 0],
      [_s, 0, 1],
      [_w, -1, 0],
    ];
    while (stack.isNotEmpty) {
      final cur = stack.last;
      final opts = <List<int>>[];
      for (final d in dirs) {
        final nx = cur[0] + d[1], ny = cur[1] + d[2];
        if (_in(nx, ny) && !visited[nx][ny]) opts.add(d);
      }
      if (opts.isEmpty) {
        stack.removeLast();
        continue;
      }
      final d = opts[rng.nextInt(opts.length)];
      final nx = cur[0] + d[1], ny = cur[1] + d[2];
      solution[cur[0]][cur[1]] |= d[0];
      solution[nx][ny] |= _opp(d[0]);
      visited[nx][ny] = true;
      stack.add([nx, ny]);
    }

    var twisted = 0;
    par = 0;
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < n; y++) {
        if (x == sx && y == sy) {
          mask[x][y] = solution[x][y];
          continue;
        }
        final r = rng.nextInt(4);
        mask[x][y] = _rotN(solution[x][y], r);
        final need = _minRot(mask[x][y], solution[x][y]);
        par += need;
        if (need > 0) twisted++;
      }
    }
    // tier 2+: lock a few already-correct tiles (fixed conduits)
    if (tier >= 2) {
      final fixedCandidates = <int>[];
      for (var x = 0; x < n; x++) {
        for (var y = 0; y < n; y++) {
          if ((x == sx && y == sy)) continue;
          if (_minRot(mask[x][y], solution[x][y]) == 0) {
            fixedCandidates.add(x * n + y);
          }
        }
      }
      fixedCandidates.shuffle(rng);
      for (final k in fixedCandidates.take(2)) {
        locked.add(k);
      }
    }
    if (twisted == 0) {
      for (var x = 0; x < n && twisted == 0; x++) {
        for (var y = 0; y < n && twisted == 0; y++) {
          if (x == sx && y == sy) continue;
          final r = _rotCW(mask[x][y]);
          if (r != mask[x][y]) {
            mask[x][y] = r;
            par += _minRot(mask[x][y], solution[x][y]);
            twisted = 1;
          }
        }
      }
    }
    if (par < 1) par = 1;
    flood();
  }

  int _minRot(int cur, int sol) {
    for (var r = 0; r < 4; r++) {
      if (_rotN(cur, r) == sol) return r;
    }
    return 0;
  }

  bool flood() {
    for (final row in powered) {
      row.fillRange(0, row.length, false);
    }
    final q = <List<int>>[[sx, sy]];
    powered[sx][sy] = true;
    final dirs = [
      [_n, 0, -1, _s],
      [_e, 1, 0, _w],
      [_s, 0, 1, _n],
      [_w, -1, 0, _e],
    ];
    while (q.isNotEmpty) {
      final cur = q.removeLast();
      for (final d in dirs) {
        if (mask[cur[0]][cur[1]] & d[0] == 0) continue;
        final nx = cur[0] + d[1], ny = cur[1] + d[2];
        if (!_in(nx, ny) || powered[nx][ny]) continue;
        if (mask[nx][ny] & d[3] == 0) continue;
        powered[nx][ny] = true;
        q.add([nx, ny]);
      }
    }
    for (final row in powered) {
      for (final on in row) {
        if (!on) return false;
      }
    }
    return true;
  }

  bool isLocked(int x, int y) => locked.contains(x * n + y);
  bool rotate(int x, int y) {
    mask[x][y] = _rotCW(mask[x][y]);
    return flood();
  }

  int popcount(int m) {
    var c = 0;
    for (var b = 0; b < 4; b++) {
      if (m & (1 << b) != 0) c++;
    }
    return c;
  }
}

class WireGame extends StatefulWidget {
  const WireGame({super.key, required this.spec});
  final LevelSpec spec;

  @override
  State<WireGame> createState() => _WireGameState();
}

class _WireGameState extends State<WireGame> {
  late _WireModel _m;
  int _turns = 0;
  GameResult? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _m = _WireModel.generate(widget.spec.tier, widget.spec.seed);
    _turns = 0;
    _result = null;
    setState(() {});
  }

  void _tap(int x, int y) {
    if (_result != null) return;
    if ((x == _m.sx && y == _m.sy) || _m.isLocked(x, y)) {
      SoundDesk.maybe?.cue(Cue.tap);
      return;
    }
    final solved = _m.rotate(x, y);
    _turns++;
    SoundDesk.maybe?.cue(Cue.tap);
    SoundDesk.maybe?.buzz();
    setState(() {});
    if (solved) _finish();
  }

  Future<void> _finish() async {
    final stars = _turns <= _m.par
        ? 3
        : _turns <= _m.par + _m.n
            ? 2
            : 1;
    SoundDesk.maybe?.cue(Cue.settle);
    final res = await commitLevel(widget.spec.index, stars: stars, score: _turns);
    if (!mounted) return;
    setState(() {
      _result = GameResult(
          win: true, stars: stars, score: _turns, scoreLabel: 'Turns', coins: res.coins);
    });
  }

  void _next() => Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LevelHost(index: widget.spec.index + 1)));

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Wiring',
      levelLabel: 'Level ${widget.spec.index + 1}  ·  power every unit',
      onRestart: _load,
      statusBar: Center(
        child: Text('Turns $_turns  ·  Par ${_m.par}',
            style: Lettering.body(size: 13, color: Hue.parchment)),
      ),
      overlay: _result == null
          ? null
          : ResultCard(
              result: _result!,
              onRetry: _load,
              onExit: () => Navigator.of(context).maybePop(),
              onNext: hasNextLevel(widget.spec.index) ? _next : null,
            ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(builder: (context, c) {
          final side = math.min(c.maxWidth, c.maxHeight);
          return Center(
            child: SizedBox(
              width: side,
              height: side,
              child: GestureDetector(
                onTapUp: (d) {
                  final cell = side / _m.n;
                  _tap((d.localPosition.dx / cell).floor(),
                      (d.localPosition.dy / cell).floor());
                },
                child: CustomPaint(painter: _WirePainter(_m)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _WirePainter extends CustomPainter {
  _WirePainter(this.m);
  final _WireModel m;

  @override
  void paint(Canvas canvas, Size size) {
    final n = m.n;
    final cs = size.width / n;
    final pipeW = cs * 0.18;
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < n; y++) {
        final center = Offset((x + 0.5) * cs, (y + 0.5) * cs);
        final on = m.powered[x][y];
        final base = Rect.fromLTWH(x * cs + 1, y * cs + 1, cs - 2, cs - 2);
        canvas.drawRRect(
            RRect.fromRectAndRadius(base, Radius.circular(cs * 0.12)),
            Paint()..color = Hue.panelDeep.withValues(alpha: 0.5));
        if (m.isLocked(x, y)) {
          canvas.drawRRect(
              RRect.fromRectAndRadius(base, Radius.circular(cs * 0.12)),
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = Hue.gold.withValues(alpha: 0.6));
        }
        final col = on ? Hue.gold : Hue.inkSoft;
        final paint = Paint()
          ..color = col
          ..strokeWidth = pipeW
          ..strokeCap = StrokeCap.round;
        if (on) {
          _pipes(canvas, center, cs, m.mask[x][y],
              Paint()
                ..color = Hue.gold.withValues(alpha: 0.4)
                ..strokeWidth = pipeW * 1.9
                ..strokeCap = StrokeCap.round
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        }
        _pipes(canvas, center, cs, m.mask[x][y], paint);

        if (x == m.sx && y == m.sy) {
          canvas.drawCircle(center, cs * 0.2, Paint()..color = Hue.ember);
          canvas.drawCircle(center, cs * 0.09, Paint()..color = Hue.parchment);
        } else {
          final pop = m.popcount(m.mask[x][y]);
          if (pop == 1) {
            canvas.drawCircle(center, cs * 0.12,
                Paint()..color = on ? Hue.gold : Hue.inkSoft);
          } else {
            canvas.drawCircle(center, cs * 0.07, Paint()..color = col);
          }
        }
      }
    }
  }

  void _pipes(Canvas canvas, Offset c, double cs, int mask, Paint p) {
    final reach = cs * 0.5;
    if (mask & _n != 0) canvas.drawLine(c, c + Offset(0, -reach), p);
    if (mask & _e != 0) canvas.drawLine(c, c + Offset(reach, 0), p);
    if (mask & _s != 0) canvas.drawLine(c, c + Offset(0, reach), p);
    if (mask & _w != 0) canvas.drawLine(c, c + Offset(-reach, 0), p);
  }

  @override
  bool shouldRepaint(covariant _WirePainter old) => true;
}
