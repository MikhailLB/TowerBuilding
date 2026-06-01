import 'package:flutter/material.dart';

import '../core/sound_desk.dart';
import '../main.dart';
import '../meta/achievements.dart';
import '../meta/game_catalog.dart';
import '../theme/palette.dart';
import '../theme/type_scale.dart';
import 'plank_panel.dart';
import 'sky_backdrop.dart';
import 'storybook_button.dart';

/// Standard chrome for every mini-game: living backdrop, a header with a back
/// button + live coin chip, and a body area.
class GameScaffold extends StatelessWidget {
  const GameScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.trailing = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> trailing;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Hue.noon,
      body: SkyBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () {
                        SoundDesk.it.cue(Cue.tap);
                        Navigator.of(context).maybePop();
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: Lettering.heading(size: 21, color: Hue.ink)),
                          if (subtitle != null)
                            Text(subtitle!,
                                style:
                                    Lettering.body(size: 12.5, color: Hue.inkSoft)),
                        ],
                      ),
                    ),
                    ...trailing,
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of stars (filled vs outline).
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.max = 3, this.size = 34});

  final int stars;
  final int max;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++)
          Icon(
            i < stars ? Icons.star_rounded : Icons.star_border_rounded,
            color: Hue.gold,
            size: size,
          ),
      ],
    );
  }
}

/// Difficulty selector shared by the level-based games. Locked levels show a
/// padlock; cleared levels show their star count.
class LevelBar extends StatelessWidget {
  const LevelBar({
    super.key,
    required this.game,
    required this.current,
    required this.labels,
    required this.onSelect,
  });

  final GameId game;
  final int current;
  final List<String> labels;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < labels.length; i++)
          _pill(context, i),
      ],
    );
  }

  Widget _pill(BuildContext context, int i) {
    final unlocked = player.levelUnlocked(game, i);
    final selected = i == current;
    final stars = player.stars(game, i);
    return GestureDetector(
      onTap: unlocked
          ? () {
              SoundDesk.it.cue(Cue.tap);
              onSelect(i);
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? game.tint
              : (unlocked ? Hue.panel : Hue.panel.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Hue.timberDeep, width: 2.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!unlocked)
              const Icon(Icons.lock_rounded, size: 14, color: Hue.inkSoft)
            else
              Text(
                labels[i],
                style: Lettering.heading(
                  size: 14,
                  color: selected ? Colors.white : Hue.ink,
                ),
              ),
            if (unlocked && stars > 0) ...[
              const SizedBox(width: 5),
              Icon(Icons.star_rounded,
                  size: 13, color: selected ? Hue.parchment : Hue.gold),
              Text('$stars',
                  style: Lettering.body(
                      size: 12,
                      color: selected ? Hue.parchment : Hue.inkSoft)),
            ],
          ],
        ),
      ),
    );
  }
}

/// A simple action descriptor for [ResultOverlay].
class ResultAction {
  const ResultAction(this.label, this.icon, this.tone, this.onTap);
  final String label;
  final IconData icon;
  final BtnTone tone;
  final VoidCallback onTap;
}

/// Win / finish card drawn over a game board.
class ResultOverlay extends StatelessWidget {
  const ResultOverlay({
    super.key,
    required this.title,
    required this.stars,
    required this.detail,
    required this.actions,
  });

  final String title;
  final int stars;
  final String detail;
  final List<ResultAction> actions;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          color: Hue.scrim,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(20),
          child: PlankPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Lettering.banner(size: 28, color: Hue.ink)),
                const SizedBox(height: 10),
                StarRow(stars: stars),
                const SizedBox(height: 8),
                Text(detail,
                    textAlign: TextAlign.center,
                    style: Lettering.body(size: 14, color: Hue.inkSoft)),
                const SizedBox(height: 16),
                for (final a in actions) ...[
                  StorybookButton(
                    label: a.label,
                    icon: a.icon,
                    tone: a.tone,
                    width: double.infinity,
                    onTap: a.onTap,
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a quick toast when achievements unlock during play.
void showAchievementToast(BuildContext context, List<Achievement> unlocked) {
  if (unlocked.isEmpty) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  for (final a in unlocked) {
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Hue.panelDeep,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(a.icon, color: Hue.gold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Achievement: ${a.title}',
                      style: Lettering.heading(size: 14, color: Hue.parchment)),
                  Text('+${a.reward} coins',
                      style: Lettering.body(size: 12, color: Hue.gold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
