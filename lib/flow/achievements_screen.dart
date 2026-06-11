import 'package:flutter/material.dart';

import '../main.dart';
import '../meta/achievements.dart';
import '../theme/palette.dart';
import '../theme/type_scale.dart';
import '../widgets/plank_panel.dart';
import '../widgets/sky_backdrop.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final all = AchievementBook.all;
    final done = all.where((a) => player.achieved(a.id)).length;
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
                    Text('Awards',
                        style: Lettering.heading(size: 22, color: Hue.parchment)),
                    const Spacer(),
                    StatChip(
                        icon: Icons.emoji_events_rounded,
                        label: '$done / ${all.length}',
                        iconColor: Hue.gold),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [for (final a in all) _row(a)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(Achievement a) {
    final got = player.achieved(a.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PlankPanel(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: got ? Hue.gold.withValues(alpha: 0.22) : Hue.panelDeep.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Hue.timberDeep, width: 2),
              ),
              child: Icon(a.icon, color: got ? Hue.gold : Hue.inkSoft, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title, style: Lettering.heading(size: 16, color: Hue.ink)),
                  Text(a.detail, style: Lettering.body(size: 12, color: Hue.inkSoft)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(got ? Icons.check_circle_rounded : Icons.lock_rounded,
                    color: got ? Hue.moss : Hue.inkSoft, size: 20),
                const SizedBox(height: 4),
                Text('+${a.reward}',
                    style: Lettering.heading(size: 14, color: Hue.gold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
