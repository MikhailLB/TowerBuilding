import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound_desk.dart';
import '../theme/palette.dart';
import '../theme/type_scale.dart';
import 'campaign.dart';
import 'game_shell.dart';
import 'level_host.dart';
import 'progress.dart';

class _WinModel {
  _WinModel(this.n);
  final int n;
  late List<List<bool>> lit;
  late List<List<bool>> target;
  late List<List<int>> shape; // 0 = plus, 1 = X
  int par = 1;

  bool _in(int x, int y) => x >= 0 && y >= 0 && x < n && y < n;

  static _WinModel generate(int tier, int seed) {
    final rng = math.Random(seed);
    final n = (3 + tier).clamp(3, 6);
    final m = _WinModel(n);
    m._build(rng, tier);
    return m;
  }

  void _build(math.Random rng, int tier) {
    target = List.generate(n, (_) => List.filled(n, true));
    if (tier >= 1) {
      // random target pattern (at least a few lit)
      do {
        for (var x = 0; x < n; x++) {
          for (var y = 0; y < n; y++) {
            target[x][y] = rng.nextDouble() < 0.6;
          }
        }
      } while (!_anyLit());
    }
    shape = List.generate(n, (_) => List.filled(n, 0));
    if (tier >= 2) {
      for (var x = 0; x < n; x++) {
        for (var y = 0; y < n; y++) {
          if (rng.nextDouble() < 0.3) shape[x][y] = 1; // X fixture
        }
      }
    }

    lit = List.generate(n, (i) => List<bool>.from(target[i]));
    final all = <int>[for (var i = 0; i < n * n; i++) i]..shuffle(rng);
    final count = (n + tier).clamp(2, n * n - 1);
    final set = all.take(count).toList();
    for (final k in set) {
      _toggle(k % n, k ~/ n);
    }
    par = set.length;
    if (_matches()) {
      _toggle(0, 0);
      par += 1;
    }
  }

  bool _anyLit() {
    for (final row in target) {
      for (final v in row) {
        if (v) return true;
      }
    }
    return false;
  }

  void _toggle(int x, int y) {
    final offsets = shape[x][y] == 0
        ? const [
            [0, 0],
            [0, -1],
            [0, 1],
            [-1, 0],
            [1, 0],
          ]
        : const [
            [0, 0],
            [-1, -1],
            [1, -1],
            [-1, 1],
            [1, 1],
          ];
    for (final d in offsets) {
      final nx = x + d[0], ny = y + d[1];
      if (_in(nx, ny)) lit[nx][ny] = !lit[nx][ny];
    }
  }

  bool _matches() {
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < n; y++) {
        if (lit[x][y] != target[x][y]) return false;
      }
    }
    return true;
  }

  bool press(int x, int y) {
    _toggle(x, y);
    return _matches();
  }
}

class WindowsGame extends StatefulWidget {
  const WindowsGame({super.key, required this.spec});
  final LevelSpec spec;

  @override
  State<WindowsGame> createState() => _WindowsGameState();
}

class _WindowsGameState extends State<WindowsGame> {
  late _WinModel _m;
  int _taps = 0;
  GameResult? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _m = _WinModel.generate(widget.spec.tier, widget.spec.seed);
    _taps = 0;
    _result = null;
    setState(() {});
  }

  void _tap(int x, int y) {
    if (_result != null || !_m._in(x, y)) return;
    final solved = _m.press(x, y);
    _taps++;
    SoundDesk.maybe?.cue(Cue.tap);
    SoundDesk.maybe?.buzz();
    setState(() {});
    if (solved) _finish();
  }

  Future<void> _finish() async {
    final stars = _taps <= _m.par
        ? 3
        : _taps <= _m.par + _m.n
            ? 2
            : 1;
    SoundDesk.maybe?.cue(Cue.settle);
    final res = await commitLevel(widget.spec.index, stars: stars, score: _taps);
    if (!mounted) return;
    setState(() {
      _result = GameResult(
          win: true, stars: stars, score: _taps, scoreLabel: 'Taps', coins: res.coins);
    });
  }

  void _next() => Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LevelHost(index: widget.spec.index + 1)));

  @override
  Widget build(BuildContext context) {
    final patterned = widget.spec.tier >= 1;
    return GameShell(
      title: 'Windows',
      levelLabel:
          'Level ${widget.spec.index + 1}  ·  ${patterned ? 'match the lit pattern' : 'light every window'}',
      onRestart: _load,
      statusBar: Center(
        child: Text('Taps $_taps  ·  Par ${_m.par}',
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
        padding: const EdgeInsets.all(20),
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
                child: CustomPaint(painter: _WinPainter(_m, patterned)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _WinPainter extends CustomPainter {
  _WinPainter(this.m, this.patterned);
  final _WinModel m;
  final bool patterned;

  @override
  void paint(Canvas canvas, Size size) {
    final n = m.n;
    final cs = size.width / n;

    // facade backing
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(cs * 0.18)),
      Paint()..color = Hue.timberDeep.withValues(alpha: 0.55),
    );

    for (var x = 0; x < n; x++) {
      for (var y = 0; y < n; y++) {
        final rect = Rect.fromLTWH(
            x * cs + cs * 0.12, y * cs + cs * 0.12, cs * 0.76, cs * 0.76);
        final rr = RRect.fromRectAndRadius(rect, Radius.circular(cs * 0.1));
        final on = m.lit[x][y];
        if (on) {
          canvas.drawRRect(
              rr.inflate(cs * 0.06),
              Paint()
                ..color = Hue.gold.withValues(alpha: 0.4)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
        }
        canvas.drawRRect(
            rr, Paint()..color = on ? Hue.gold : const Color(0xFF22304A));
        // window cross frame
        final fp = Paint()
          ..color = (on ? Hue.timberDeep : Colors.black).withValues(alpha: 0.4)
          ..strokeWidth = 1.4;
        canvas.drawLine(Offset(rect.center.dx, rect.top),
            Offset(rect.center.dx, rect.bottom), fp);
        canvas.drawLine(Offset(rect.left, rect.center.dy),
            Offset(rect.right, rect.center.dy), fp);

        // goal hint: outline windows that should be lit
        if (patterned && m.target[x][y]) {
          canvas.drawRRect(
              rr,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = Hue.ember.withValues(alpha: 0.9));
        }
        // X-fixture marker
        if (m.shape[x][y] == 1) {
          final mp = Paint()
            ..color = Hue.lavender.withValues(alpha: 0.8)
            ..strokeWidth = 1.5;
          canvas.drawLine(rect.topLeft, rect.topLeft + Offset(cs * 0.14, cs * 0.14), mp);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WinPainter old) => true;
}
