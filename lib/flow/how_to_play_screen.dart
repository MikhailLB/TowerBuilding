import 'package:flutter/material.dart';

import '../game/campaign.dart';
import '../meta/game_catalog.dart';
import '../theme/palette.dart';
import '../theme/type_scale.dart';
import '../widgets/plank_panel.dart';
import '../widgets/sky_backdrop.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  static const _how = {
    PuzzleType.assemble:
        'Read the blueprint, then place your tray blocks to match it. Blocks '
            'need support below or beside. Watch glass (fragile) and balance, '
            'then press BUILD. Fewer moves = more stars.',
    PuzzleType.wire:
        'Tap conduits to rotate them and connect the power vault to every unit. '
            'Some conduits are sealed. Fewer turns = more stars.',
    PuzzleType.windows:
        'Tap a window to flip it and its neighbours. Light every window — or '
            'match the orange-outlined pattern. Fewer taps = more stars.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Hue.noon,
      body: SkyBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: Row(
                  children: [
                    RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.of(context).maybePop()),
                    const SizedBox(width: 12),
                    Text('How to Play',
                        style: Lettering.heading(size: 22, color: Hue.parchment)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                child: Text(
                  'One tower, many levels. As you climb, new puzzle types and '
                  'twists appear — each is introduced the first time you reach it.',
                  style: Lettering.body(size: 13, color: Hue.parchment),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final t in PuzzleType.values) _card(t),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(PuzzleType t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PlankPanel(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: t.tint.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.tint, width: 1.6),
              ),
              child: Icon(t.icon, color: t.tint, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title, style: Lettering.heading(size: 17, color: Hue.ink)),
                  const SizedBox(height: 4),
                  Text(_how[t]!, style: Lettering.body(size: 13, color: Hue.inkSoft)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
