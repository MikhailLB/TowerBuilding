import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound_desk.dart';
import '../game/level_host.dart';
import '../main.dart';
import '../meta/game_catalog.dart';
import '../theme/asset_paths.dart';
import '../theme/palette.dart';
import '../theme/type_scale.dart';
import '../widgets/plank_panel.dart';
import '../widgets/sky_backdrop.dart';
import '../widgets/storybook_button.dart';
import 'achievements_screen.dart';
import 'campaign_map_screen.dart';
import 'daily_rewards_screen.dart';
import 'how_to_play_screen.dart';
import 'market_screen.dart';
import 'options_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t;

  @override
  void initState() {
    super.initState();
    _t = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SoundDesk.maybe?.playBed(Bed.lobby);
    });
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  int get _current {
    final cleared = player.clearedLevels(GameId.tower);
    return cleared.clamp(0, GameId.tower.levelCount - 1);
  }

  void _open(Widget screen) {
    SoundDesk.maybe?.cue(Cue.tap);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen))
        .then((_) {
      if (mounted) {
        setState(() {});
        SoundDesk.maybe?.playBed(Bed.lobby);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Hue.noon,
      body: SkyBackdrop(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([player, _t]),
            builder: (context, _) {
              final cleared = player.clearedLevels(GameId.tower);
              final total = GameId.tower.levelCount;
              final wave = math.sin(_t.value * math.pi * 2);
              return Column(
                children: [
                  _header(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                      child: Column(
                        children: [
                          _hero(cleared, total, wave),
                          const SizedBox(height: 16),
                          Transform.scale(
                            scale: 1 + 0.02 * (0.5 + 0.5 * wave),
                            child: StorybookButton(
                              label: cleared == 0
                                  ? 'START BUILDING'
                                  : 'CONTINUE  ·  LEVEL ${_current + 1}',
                              icon: Icons.play_arrow_rounded,
                              tone: BtnTone.ember,
                              width: double.infinity,
                              height: 66,
                              onTap: () => _open(LevelHost(index: _current)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          StorybookButton(
                            label: 'LEVEL MAP',
                            icon: Icons.map_rounded,
                            tone: BtnTone.plank,
                            width: double.infinity,
                            onTap: () => _open(const CampaignMapScreen()),
                          ),
                          const SizedBox(height: 18),
                          _bottomRow(),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 14, 6),
      child: Row(
        children: [
          const Spacer(),
          StatChip(
              icon: Icons.star_rounded,
              label: '${player.totalStars}',
              iconColor: Hue.gold),
          const SizedBox(width: 8),
          StatChip(
              icon: Icons.toll_rounded,
              label: '${player.coins}',
              iconColor: Hue.gold),
          const SizedBox(width: 8),
          RoundIconButton(
              icon: Icons.settings_rounded,
              onTap: () => _open(const OptionsScreen())),
        ],
      ),
    );
  }

  Widget _hero(int cleared, int total, double wave) {
    final pct = total == 0 ? 0.0 : cleared / total;
    return Column(
      children: [
        // Title wordmark with a tiny sway.
        Transform.rotate(
          angle: wave * 0.012,
          child: SizedBox(
            height: 70,
            child: Image.asset(Art.wordmark, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 6),
        // Floating hero tower with bobbing decorative blocks.
        SizedBox(
          height: 188,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 6,
                top: 28 + wave * 8,
                child: _floatBlock(1, 30, wave),
              ),
              Positioned(
                right: 4,
                top: 70 - wave * 9,
                child: _floatBlock(3, 26, wave),
              ),
              Transform.translate(
                offset: Offset(0, -wave * 5),
                child: Image.asset(Art.homeTower, height: 188, fit: BoxFit.contain),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        PlankPanel(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            children: [
              Text('Raise the tower, floor by floor!',
                  style: Lettering.heading(size: 15, color: Hue.ink)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 12,
                  backgroundColor: Hue.panelDeep.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation(Hue.moss),
                ),
              ),
              const SizedBox(height: 6),
              Text('$cleared / $total levels built',
                  style: Lettering.body(size: 12, color: Hue.inkSoft)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _floatBlock(int asset, double size, double wave) {
    return Transform.rotate(
      angle: wave * 0.18,
      child: Opacity(
        opacity: 0.9,
        child: SizedBox(
          width: size,
          height: size,
          child: Image.asset(Art.house(asset), fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _bottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _action(Icons.calendar_month_rounded, 'Daily', const DailyRewardsScreen(),
            badge: player.dailyClaimable),
        _action(Icons.storefront_rounded, 'Market', const MarketScreen()),
        _action(Icons.emoji_events_rounded, 'Awards', const AchievementsScreen()),
        _action(Icons.help_outline_rounded, 'How', const HowToPlayScreen()),
      ],
    );
  }

  Widget _action(IconData icon, String label, Widget screen,
      {bool badge = false}) {
    return GestureDetector(
      onTap: () => _open(screen),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Hue.panelDeep.withValues(alpha: 0.86),
                  shape: BoxShape.circle,
                  border: Border.all(color: Hue.timberDeep, width: 2),
                ),
                child: Icon(icon, color: Hue.parchment, size: 26),
              ),
              if (badge)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Hue.alarm,
                      shape: BoxShape.circle,
                      border: Border.all(color: Hue.parchment, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(label, style: Lettering.body(size: 12, color: Hue.parchment)),
        ],
      ),
    );
  }
}
