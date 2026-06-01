import 'package:flutter/material.dart';

import '../core/sound_desk.dart';
import '../games/cozy_merge_screen.dart';
import '../games/moving_day_screen.dart';
import '../games/neighbours_screen.dart';
import '../games/night_watch_screen.dart';
import '../games/skyline_movers_screen.dart';
import '../main.dart';
import '../meta/game_catalog.dart';
import '../theme/asset_paths.dart';
import '../theme/palette.dart';
import '../theme/type_scale.dart';
import '../widgets/plank_panel.dart';
import '../widgets/sky_backdrop.dart';
import 'achievements_screen.dart';
import 'daily_rewards_screen.dart';
import 'market_screen.dart';

/// Hub of every game and meta screen. Designed so the app reads as a small
/// collection of village puzzles rather than a single loop.
class ModesHubScreen extends StatefulWidget {
  const ModesHubScreen({super.key});

  @override
  State<ModesHubScreen> createState() => _ModesHubScreenState();
}

class _ModesHubScreenState extends State<ModesHubScreen> {
  @override
  void initState() {
    super.initState();
    player.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    player.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _open(Widget screen) async {
    SoundDesk.it.cue(Cue.tap);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    _refresh();
  }

  Widget _gameScreen(GameId g) {
    switch (g) {
      case GameId.movingDay:
        return const MovingDayScreen();
      case GameId.skyline:
        return const SkylineMoversScreen();
      case GameId.merge:
        return const CozyMergeScreen();
      case GameId.memory:
        return const NeighboursScreen();
      case GameId.lights:
        return const NightWatchScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Hue.noon,
      body: SkyBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () {
                        SoundDesk.it.cue(Cue.tap);
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Village Games',
                          style: Lettering.heading(size: 24, color: Hue.ink)),
                    ),
                    StatChip(
                        icon: Icons.savings_rounded, label: '${player.coins}'),
                  ],
                ),
              ),
              _metaRow(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    for (final g in GameId.values) ...[
                      _gameCard(g),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _metaTile(
              icon: Icons.card_giftcard_rounded,
              label: 'Daily',
              tint: Hue.ember,
              badge: player.dailyClaimable,
              onTap: () => _open(const DailyRewardsScreen()),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _metaTile(
              icon: Icons.emoji_events_rounded,
              label: 'Trophies',
              tint: Hue.gold,
              onTap: () => _open(const AchievementsScreen()),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _metaTile(
              icon: Icons.palette_rounded,
              label: 'Market',
              tint: Hue.lavender,
              onTap: () => _open(const MarketScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaTile({
    required IconData icon,
    required String label,
    required Color tint,
    required VoidCallback onTap,
    bool badge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: PlankPanel(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                if (badge)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Hue.alarm,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(label, style: Lettering.heading(size: 12.5)),
          ],
        ),
      ),
    );
  }

  Widget _gameCard(GameId g) {
    final cleared = player.clearedLevels(g);
    final total = g.levelCount;
    final stars = player.starsForGame(g);
    final preview = _previewFor(g);
    return _PressCard(
      onTap: () => _open(_gameScreen(g)),
      child: PlankPanel(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: g.tint.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Hue.timberDeep, width: 2.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(preview, fit: BoxFit.cover),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.all(4),
                      decoration:
                          BoxDecoration(color: g.tint, shape: BoxShape.circle),
                      child: Icon(g.icon, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.title, style: Lettering.heading(size: 18)),
                  const SizedBox(height: 3),
                  Text(g.blurb,
                      style: Lettering.body(size: 12.5, color: Hue.inkSoft),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.flag_rounded, size: 14, color: g.tint),
                      const SizedBox(width: 4),
                      Text('$cleared/$total cleared',
                          style: Lettering.body(size: 12, color: Hue.ink)),
                      const SizedBox(width: 10),
                      const Icon(Icons.star_rounded, size: 14, color: Hue.gold),
                      const SizedBox(width: 3),
                      Text('$stars', style: Lettering.body(size: 12, color: Hue.ink)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Hue.timber, size: 30),
          ],
        ),
      ),
    );
  }

  String _previewFor(GameId g) {
    switch (g) {
      case GameId.movingDay:
        return Art.house(4);
      case GameId.skyline:
        return Art.house(1);
      case GameId.merge:
        return Art.house(3);
      case GameId.memory:
        return Art.house(5);
      case GameId.lights:
        return Art.house(2);
    }
  }
}

class _PressCard extends StatefulWidget {
  const _PressCard({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressCard> createState() => _PressCardState();
}

class _PressCardState extends State<_PressCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: widget.child,
      ),
    );
  }
}
