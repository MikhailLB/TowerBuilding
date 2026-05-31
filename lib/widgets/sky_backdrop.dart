import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/asset_paths.dart';
import '../theme/sky_theme.dart';

/// Living gradient backdrop shared by every screen. It reads the player's
/// chosen [SkyTheme]; animated themes ease between their phases while drifting
/// clouds and (for dark moods) a sprinkle of stars add depth. Hand-built — no
/// shared parallax package.
class SkyBackdrop extends StatefulWidget {
  const SkyBackdrop({
    super.key,
    required this.child,
    this.clouds = true,
  });

  final Widget child;
  final bool clouds;

  @override
  State<SkyBackdrop> createState() => _SkyBackdropState();
}

class _SkyBackdropState extends State<SkyBackdrop>
    with TickerProviderStateMixin {
  late final AnimationController _phase; // cycles animated themes
  late final AnimationController _drift; // cloud movement
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _phase = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    final rng = math.Random(7);
    _stars = List.generate(
      36,
      (_) => _Star(
        dx: rng.nextDouble(),
        dy: rng.nextDouble() * 0.6,
        r: 0.6 + rng.nextDouble() * 1.6,
        twinkle: rng.nextDouble(),
      ),
    );
    player.addListener(_onChange);
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    player.removeListener(_onChange);
    _phase.dispose();
    _drift.dispose();
    super.dispose();
  }

  List<Color> _lerpPhases(SkyTheme theme, double t) {
    final phases = theme.phases;
    if (phases.length == 1) return phases.first;
    final scaled = t * phases.length;
    final i = scaled.floor() % phases.length;
    final j = (i + 1) % phases.length;
    final f = Curves.easeInOut.transform(scaled - scaled.floor());
    final a = phases[i], b = phases[j];
    return [
      Color.lerp(a[0], b[0], f)!,
      Color.lerp(a[1], b[1], f)!,
      Color.lerp(a[2], b[2], f)!,
    ];
  }

  double _darkness(List<Color> colors) {
    final c = colors[0];
    final lum = (0.299 * c.r + 0.587 * c.g + 0.114 * c.b);
    return (1 - lum).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = SkyCatalogue.byId(player.selectedTheme);
    return AnimatedBuilder(
      animation: Listenable.merge([_phase, _drift]),
      builder: (context, _) {
        final colors = _lerpPhases(theme, _phase.value);
        final dark = theme.starsAtNight ? _darkness(colors) : 0.0;
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors,
                ),
              ),
            ),
            if (dark > 0.15)
              Opacity(
                opacity: dark,
                child: CustomPaint(
                  painter: _StarPainter(_stars, _drift.value),
                ),
              ),
            if (widget.clouds) _cloudLayer(dark),
            widget.child,
          ],
        );
      },
    );
  }

  Widget _cloudLayer(double dark) {
    final size = MediaQuery.of(context).size;
    final specs = <List<double>>[
      [0.08, 0.50, 1.0, 0.0],
      [0.18, 0.34, 1.6, 0.45],
      [0.27, 0.42, 0.7, 0.75],
    ];
    final opacity = (0.85 - dark * 0.55).clamp(0.2, 0.85);
    return IgnorePointer(
      child: Stack(
        children: [
          for (final c in specs)
            () {
              final cloudW = size.width * c[1];
              final span = size.width + cloudW;
              final x = (((_drift.value * c[2]) + c[3]) % 1.0) * span - cloudW;
              return Positioned(
                top: size.height * c[0],
                left: x,
                width: cloudW,
                child: Opacity(
                  opacity: opacity,
                  child: Image.asset(Art.cloud, fit: BoxFit.contain),
                ),
              );
            }(),
        ],
      ),
    );
  }
}

class _Star {
  const _Star({
    required this.dx,
    required this.dy,
    required this.r,
    required this.twinkle,
  });
  final double dx, dy, r, twinkle;
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.stars, this.t);

  final List<_Star> stars;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (final s in stars) {
      final flicker = 0.4 + 0.6 * (0.5 + 0.5 * math.sin((t + s.twinkle) * math.pi * 2));
      paint.color = Colors.white.withValues(alpha: flicker);
      canvas.drawCircle(
        Offset(s.dx * size.width, s.dy * size.height),
        s.r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.t != t;
}
