import 'package:flutter/material.dart';

import '../core/sound_desk.dart';
import '../main.dart';
import '../meta/achievements.dart';
import '../theme/palette.dart';
import '../theme/type_scale.dart';
import '../widgets/game_shell.dart';
import '../widgets/plank_panel.dart';
import '../widgets/sky_backdrop.dart';
import '../widgets/storybook_button.dart';

/// Daily reward ladder. Visiting each day advances a 7-day streak; missing a
/// day resets it. Claiming grants coins and may trip the streak achievement.
class DailyRewardsScreen extends StatefulWidget {
  const DailyRewardsScreen({super.key});

  @override
  State<DailyRewardsScreen> createState() => _DailyRewardsScreenState();
}

class _DailyRewardsScreenState extends State<DailyRewardsScreen> {
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

  Future<void> _claim() async {
    final reward = await player.claimDaily();
    if (reward <= 0 || !mounted) return;
    SoundDesk.it.cue(Cue.settle);
    SoundDesk.it.buzz(strong: true);
    showAchievementToast(context, player.syncAchievements());
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: Hue.panelDeep,
        content: Text('Claimed +$reward coins!',
            style: Lettering.body(color: Hue.parchment)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final claimable = player.dailyClaimable;
    // Day index in the visible 7-tile ladder.
    final activeIndex = ((player.pendingStreak - 1) % 7);

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
                      child: Text('Daily Reward',
                          style: Lettering.heading(size: 24, color: Hue.ink)),
                    ),
                    StatChip(
                        icon: Icons.savings_rounded, label: '${player.coins}'),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Visit every day — the longer the streak, the bigger the gift.',
                    textAlign: TextAlign.center,
                    style: Lettering.body(size: 13, color: Hue.inkSoft)),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    childAspectRatio: 0.95,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      for (var i = 0; i < 7; i++)
                        _dayTile(i, activeIndex, claimable),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                StorybookButton(
                  label: claimable
                      ? 'Claim +${player.pendingReward} coins'
                      : 'Come back tomorrow',
                  icon: claimable
                      ? Icons.card_giftcard_rounded
                      : Icons.schedule_rounded,
                  tone: claimable ? BtnTone.ember : BtnTone.plank,
                  width: double.infinity,
                  onTap: claimable ? _claim : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dayTile(int i, int activeIndex, bool claimable) {
    final reward = DailyLadder.rewards[i];
    final isToday = i == activeIndex;
    final claimedDay = !claimable && i == activeIndex;
    final past = i < activeIndex;
    final highlight = isToday && claimable;

    return Container(
      decoration: BoxDecoration(
        color: highlight ? Hue.gold.withValues(alpha: 0.9) : Hue.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? Hue.ember : Hue.timberDeep,
          width: highlight ? 3 : 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Day ${i + 1}',
              style: Lettering.body(size: 12, color: Hue.inkSoft)),
          const SizedBox(height: 4),
          Icon(
            (past || claimedDay)
                ? Icons.check_circle_rounded
                : Icons.savings_rounded,
            color: (past || claimedDay) ? Hue.moss : Hue.gold,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text('$reward',
              style: Lettering.heading(
                  size: 16, color: highlight ? Colors.white : Hue.ink)),
        ],
      ),
    );
  }
}
