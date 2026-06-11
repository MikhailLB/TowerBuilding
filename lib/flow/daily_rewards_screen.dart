import 'package:flutter/material.dart';

import '../core/sound_desk.dart';
import '../main.dart';
import '../meta/achievements.dart';
import '../theme/palette.dart';
import '../theme/type_scale.dart';
import '../widgets/plank_panel.dart';
import '../widgets/sky_backdrop.dart';
import '../widgets/storybook_button.dart';

class DailyRewardsScreen extends StatefulWidget {
  const DailyRewardsScreen({super.key});

  @override
  State<DailyRewardsScreen> createState() => _DailyRewardsScreenState();
}

class _DailyRewardsScreenState extends State<DailyRewardsScreen> {
  String? _msg;

  Future<void> _claim() async {
    final got = await player.claimDaily();
    if (got > 0) {
      SoundDesk.maybe?.cue(Cue.settle);
      SoundDesk.maybe?.buzz(strong: true);
      setState(() => _msg = 'Claimed $got coins!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Hue.noon,
      body: SkyBackdrop(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: player,
            builder: (context, _) {
              final claimable = player.dailyClaimable;
              final streak = player.dailyStreak;
              final pending = player.pendingStreak;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                    child: Row(
                      children: [
                        RoundIconButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Navigator.of(context).maybePop()),
                        const SizedBox(width: 12),
                        Text('Daily Bonus',
                            style: Lettering.heading(size: 22, color: Hue.parchment)),
                        const Spacer(),
                        StatChip(
                            icon: Icons.local_fire_department_rounded,
                            label: '$streak',
                            iconColor: Hue.ember),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: GridView.count(
                        crossAxisCount: 4,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.82,
                        children: [
                          for (var i = 0; i < 7; i++)
                            _dayTile(i + 1, pending, claimable),
                        ],
                      ),
                    ),
                  ),
                  if (_msg != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_msg!,
                          style: Lettering.body(size: 14, color: Hue.parchment)),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: StorybookButton(
                      label: claimable
                          ? 'CLAIM +${player.pendingReward}'
                          : 'COME BACK TOMORROW',
                      icon: Icons.redeem_rounded,
                      tone: claimable ? BtnTone.ember : BtnTone.plank,
                      width: double.infinity,
                      onTap: claimable ? _claim : null,
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

  Widget _dayTile(int day, int pending, bool claimable) {
    final reward = DailyLadder.rewardFor(day);
    final isToday = claimable && day == pending;
    final claimed = day < pending || (!claimable && day <= pending);
    return PlankPanel(
      padding: const EdgeInsets.all(6),
      tone: isToday ? Hue.plank : Hue.panel,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Day $day', style: Lettering.body(size: 11, color: Hue.inkSoft)),
          const SizedBox(height: 4),
          Icon(claimed ? Icons.check_circle_rounded : Icons.toll_rounded,
              color: claimed ? Hue.moss : Hue.gold, size: 22),
          const SizedBox(height: 2),
          Text('$reward', style: Lettering.heading(size: 13, color: Hue.ink)),
        ],
      ),
    );
  }
}
