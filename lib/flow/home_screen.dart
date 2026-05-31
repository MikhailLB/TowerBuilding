import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sound_desk.dart';
import '../main.dart';
import '../theme/asset_paths.dart';
import '../theme/palette.dart';
import '../theme/type_scale.dart';
import '../widgets/plank_panel.dart';
import '../widgets/sky_backdrop.dart';
import 'how_to_play_screen.dart';
import 'market_screen.dart';
import 'modes_hub_screen.dart';
import 'options_screen.dart';
import 'web_panel_screen.dart';

/// Animated storybook lobby on the living [SkyBackdrop]: a swinging crane, a
/// floating wordmark and a swaying town. First launch shows the rule book once.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _swing;
  late final AnimationController _float;
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _swing = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat(reverse: true);
    _float = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3600))
      ..repeat(reverse: true);
    _enter = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850))
      ..forward();

    player.addListener(_refresh);
    SoundDesk.it.playBed(Bed.lobby);

    if (!player.introSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showIntro());
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    player.removeListener(_refresh);
    _swing.dispose();
    _float.dispose();
    _enter.dispose();
    super.dispose();
  }

  Future<void> _showIntro() async {
    await player.markIntroSeen();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const HowToPlayScreen()),
    );
  }

  Future<void> _open(Widget screen) async {
    SoundDesk.it.cue(Cue.tap);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    if (mounted) SoundDesk.it.playBed(Bed.lobby);
  }

  void _legal(String title, String url) {
    SoundDesk.it.cue(Cue.tap);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WebPanelScreen(title: title, url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Hue.noon,
      body: SkyBackdrop(
        child: Stack(
          children: [
            _TownStrip(sway: _float, size: size),
            _CraneHero(swing: _swing, size: size),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                child: Column(
                  children: [
                    _EnterFade(controller: _enter, begin: 0.0, child: _topBar()),
                    Expanded(
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _float,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(0, -6 + 12 * _float.value),
                            child: child,
                          ),
                          child: _EnterFade(
                            controller: _enter,
                            begin: 0.1,
                            child: Image.asset(
                              Art.wordmark,
                              width: size.width * 0.8,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _bottomPanel(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            StatChip(
                icon: Icons.star_rounded,
                label: '${player.totalStars}',
                iconColor: Hue.gold),
            const SizedBox(width: 8),
            StatChip(
                icon: Icons.savings_rounded,
                label: '${player.coins}',
                iconColor: Hue.gold),
          ],
        ),
        RoundIconButton(
          icon: Icons.tune_rounded,
          onTap: () => _open(const OptionsScreen()),
        ),
      ],
    );
  }

  Widget _bottomPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _EnterSlide(
          controller: _enter,
          begin: 0.15,
          child: _BigPlayButton(
            pulse: _float,
            onTap: () => _open(const ModesHubScreen()),
          ),
        ),
        const SizedBox(height: 8),
          _EnterSlide(
            controller: _enter,
            begin: 0.3,
            child: _CompactMenuRow(
              items: [
                _CompactItem(Icons.menu_book_rounded,  'Guide',   Hue.timber,  () => _open(const HowToPlayScreen())),
                _CompactItem(Icons.palette_rounded,    'Market',  Hue.lavender,() => _open(const MarketScreen())),
                _CompactItem(Icons.tune_rounded,       'Options', Hue.moss,    () => _open(const OptionsScreen())),
              ],
            ),
          ),
          const SizedBox(height: 6),
        _EnterFade(controller: _enter, begin: 0.5, child: _legalRow()),
      ],
    );
  }

  Widget _legalRow() {
    Widget link(String label, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: Text(
            label,
            style: Lettering.body(size: 13, color: Hue.ink)
                .copyWith(decoration: TextDecoration.underline),
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        link(
          'Privacy',
          () => _legal('Privacy Policy',
              'https://towerbuildingstackbalance.com/privacy-policy.html'),
        ),
        Text('   ·   ', style: Lettering.body(size: 13, color: Hue.ink)),
        link(
          'Support',
          () => _legal('Support',
              'https://towerbuildingstackbalance.com/support.html'),
        ),
      ],
    );
  }
}

// ── Background hero elements ─────────────────────────────────────────────────

class _CraneHero extends StatelessWidget {
  const _CraneHero({required this.swing, required this.size});

  final AnimationController swing;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final craneH = size.height * 0.20;
    final houseW = size.width * 0.2;
    return AnimatedBuilder(
      animation: swing,
      builder: (_, _) {
        final angle = (swing.value - 0.5) * 0.18;
        return Positioned(
          top: -size.height * 0.01,
          left: 0,
          right: 0,
          height: size.height * 0.38,
          child: Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()..rotateZ(angle),
            origin: Offset(size.width * 0.5, 0),
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(Art.crane, height: craneH, fit: BoxFit.contain),
                  SizedBox(
                    width: houseW,
                    child: Image.asset(Art.house(1), fit: BoxFit.contain),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TownStrip extends StatelessWidget {
  const _TownStrip({required this.sway, required this.size});

  final AnimationController sway;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final town = <List<double>>[
      [2, 0.00, 0.26, 0.0],
      [6, 0.21, 0.22, 1.1],
      [4, 0.39, 0.27, 2.0],
      [5, 0.61, 0.23, 0.6],
      [3, 0.79, 0.26, 1.6],
    ];
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: size.height * 0.3,
      child: AnimatedBuilder(
        animation: sway,
        builder: (_, _) {
          final base = sway.value * math.pi;
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Image.asset(Art.street,
                    fit: BoxFit.cover, width: size.width),
              ),
              for (final h in town)
                Positioned(
                  left: size.width * h[1],
                  bottom: size.height * 0.015,
                  width: size.width * h[2],
                  child: Transform.rotate(
                    angle: math.sin(base + h[3]) * 0.012,
                    alignment: Alignment.bottomCenter,
                    child: Image.asset(Art.house(h[0].toInt()),
                        fit: BoxFit.contain),
                  ),
                ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x33000000), Color(0x00000000)],
                      stops: [0.0, 0.4],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Foreground controls ──────────────────────────────────────────────────────

class _BigPlayButton extends StatefulWidget {
  const _BigPlayButton({required this.pulse, required this.onTap});

  final AnimationController pulse;
  final VoidCallback onTap;

  @override
  State<_BigPlayButton> createState() => _BigPlayButtonState();
}

class _BigPlayButtonState extends State<_BigPlayButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: widget.pulse,
        builder: (_, child) {
          final s = (_down ? 0.96 : 1.0) +
              math.sin(widget.pulse.value * math.pi) * 0.012;
          return Transform.scale(scale: s, child: child);
        },
        child: Container(
          height: 68,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF6A85C), Hue.ember, Color(0xFFB24E20)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Hue.timberDeep, width: 3),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 8)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_fill_rounded,
                  color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Text(
                'PLAY',
                style: Lettering.caption(size: 24, color: Colors.white).copyWith(
                  shadows: const [
                    Shadow(color: Hue.timberDeep, offset: Offset(0, 2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactItem {
  const _CompactItem(this.icon, this.label, this.tint, this.onTap);
  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;
}

/// A horizontal strip of small icon+label pill buttons — single-line so they
/// never overflow regardless of screen size.
class _CompactMenuRow extends StatefulWidget {
  const _CompactMenuRow({required this.items});
  final List<_CompactItem> items;

  @override
  State<_CompactMenuRow> createState() => _CompactMenuRowState();
}

class _CompactMenuRowState extends State<_CompactMenuRow> {
  int? _pressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < widget.items.length; i++) ...[
          Expanded(child: _pill(widget.items[i], i)),
          if (i < widget.items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _pill(_CompactItem item, int index) {
    final down = _pressed == index;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = index),
      onTapUp: (_) => setState(() => _pressed = null),
      onTapCancel: () => setState(() => _pressed = null),
      onTap: item.onTap,
      child: AnimatedScale(
        scale: down ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Hue.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Hue.timberDeep, width: 3),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: item.tint, shape: BoxShape.circle),
                child: Icon(item.icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 6),
              Text(
                item.label,
                style: Lettering.heading(size: 13, color: Hue.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnterFade extends StatelessWidget {
  const _EnterFade(
      {required this.controller, required this.begin, required this.child});

  final AnimationController controller;
  final double begin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(begin, (begin + 0.5).clamp(0.0, 1.0), curve: Curves.easeOut),
    );
    return FadeTransition(opacity: anim, child: child);
  }
}

class _EnterSlide extends StatelessWidget {
  const _EnterSlide(
      {required this.controller, required this.begin, required this.child});

  final AnimationController controller;
  final double begin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(
      parent: controller,
      curve:
          Interval(begin, (begin + 0.55).clamp(0.0, 1.0), curve: Curves.easeOutBack),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) => Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(
            offset: Offset(0, 24 * (1 - anim.value)), child: child),
      ),
      child: child,
    );
  }
}
