import 'package:flutter/material.dart';

import '../core/sound_desk.dart';
import '../main.dart';
import '../meta/achievements.dart';
import '../theme/palette.dart';
import '../theme/type_scale.dart';
import '../widgets/plank_panel.dart';
import '../widgets/sky_backdrop.dart';

/// Trophy room. Achievements unlock automatically as their condition is met
/// (the player model grants their coin reward); this screen just displays them.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    // Catch up on anything earned offline.
    player.syncAchievements();
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

  @override
  Widget build(BuildContext context) {
    final total = AchievementBook.all.length;
    final done = player.achievementCount;
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
                      child: Text('Achievements',
                          style: Lettering.heading(size: 24, color: Hue.ink)),
                    ),
                    StatChip(
                      icon: Icons.emoji_events_rounded,
                      label: '$done/$total',
                      iconColor: Hue.gold,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: AchievementBook.all.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _row(AchievementBook.all[i]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(Achievement a) {
    final unlocked = player.achieved(a.id);
    return PlankPanel(
      padding: const EdgeInsets.all(12),
      tone: unlocked ? Hue.panel : Hue.panel.withValues(alpha: 0.7),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: unlocked ? Hue.gold : Hue.inkSoft.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              unlocked ? a.icon : Icons.lock_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: Lettering.heading(size: 16)),
                Text(a.detail, style: Lettering.body(size: 12.5)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                unlocked ? Icons.check_circle_rounded : Icons.savings_rounded,
                color: unlocked ? Hue.moss : Hue.timber,
                size: 18,
              ),
              const SizedBox(height: 2),
              Text('+${a.reward}',
                  style: Lettering.body(size: 12, color: Hue.inkSoft)),
            ],
          ),
        ],
      ),
    );
  }
}
