import 'package:flutter/material.dart';

import '../core/sound_desk.dart';
import '../meta/game_catalog.dart';
import '../theme/palette.dart';
import '../theme/type_scale.dart';
import '../widgets/plank_panel.dart';
import '../widgets/sky_backdrop.dart';

/// A short rule book describing each game in the collection plus how stars,
/// coins, daily rewards and skies fit together.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Hue.noon,
      body: SkyBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Row(
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
                      child: Text('How to Play',
                          style: Lettering.heading(size: 24, color: Hue.ink)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      _intro(),
                      const SizedBox(height: 12),
                      for (final g in GameId.values) ...[
                        _gameRule(g),
                        const SizedBox(height: 10),
                      ],
                      _extras(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _intro() {
    return PlankPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A village of puzzles',
              style: Lettering.heading(size: 18, color: Hue.ink)),
          const SizedBox(height: 6),
          Text(
            'Five hand-made puzzle games share one little town. Clear a level to '
            'earn up to three stars and coins, then unlock the next one. Spend '
            'coins in the Sky Market to repaint the heavens.',
            style: Lettering.body(size: 13.5, color: Hue.inkSoft),
          ),
        ],
      ),
    );
  }

  Widget _gameRule(GameId g) {
    return PlankPanel(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: g.tint, shape: BoxShape.circle),
            child: Icon(g.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.title, style: Lettering.heading(size: 16)),
                Text(g.blurb, style: Lettering.body(size: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _extras() {
    return PlankPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(Icons.star_rounded, 'Stars',
              'Fewer moves (or bigger merges) earn more stars per level.'),
          _line(Icons.savings_rounded, 'Coins',
              'Clearing a level the first time and unlocking achievements pays coins.'),
          _line(Icons.card_giftcard_rounded, 'Daily reward',
              'Visit every day to keep your streak and bank growing bonuses.'),
          _line(Icons.palette_rounded, 'Sky Market',
              'Buy day, sunset, night and aurora skies that drift behind everything.'),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Hue.ember, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Lettering.heading(size: 15)),
                Text(body, style: Lettering.body(size: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
