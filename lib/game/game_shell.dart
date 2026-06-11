import 'package:flutter/material.dart';

import '../theme/palette.dart';
import '../theme/type_scale.dart';
import '../widgets/plank_panel.dart';
import '../widgets/sky_backdrop.dart';
import '../widgets/storybook_button.dart';

/// Outcome of a single level attempt.
class GameResult {
  const GameResult({
    required this.win,
    required this.stars,
    required this.score,
    required this.scoreLabel,
    this.coins = 0,
  });
  final bool win;
  final int stars;
  final int score;
  final String scoreLabel;
  final int coins;
}

/// Shared frame for every level: sky backdrop + top bar (back / title+level /
/// restart) + optional status row + body, with an optional overlay on top.
class GameShell extends StatelessWidget {
  const GameShell({
    super.key,
    required this.title,
    required this.body,
    this.levelLabel,
    this.onRestart,
    this.statusBar,
    this.overlay,
  });

  final String title;
  final Widget body;
  final String? levelLabel;
  final VoidCallback? onRestart;
  final Widget? statusBar;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Hue.dusk,
      body: SkyBackdrop(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                    child: Row(
                      children: [
                        RoundIconButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(title, style: Lettering.heading(size: 20, color: Hue.parchment)),
                              if (levelLabel != null)
                                Text(levelLabel!, style: Lettering.body(size: 12, color: Hue.parchment)),
                            ],
                          ),
                        ),
                        if (onRestart != null)
                          RoundIconButton(icon: Icons.refresh_rounded, onTap: onRestart)
                        else
                          const SizedBox(width: 46),
                      ],
                    ),
                  ),
                  if (statusBar != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      child: statusBar!,
                    ),
                  Expanded(child: body),
                ],
              ),
              if (overlay != null) Positioned.fill(child: overlay!),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row of up to [max] stars.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 22, this.max = 3});
  final int stars;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max, (i) {
        final on = i < stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            on ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: on ? Hue.gold : Hue.inkSoft,
          ),
        );
      }),
    );
  }
}

/// Win/lose card shown over the board when a level ends.
class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.result,
    required this.onRetry,
    required this.onExit,
    this.onNext,
  });

  final GameResult result;
  final VoidCallback onRetry;
  final VoidCallback onExit;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final win = result.win;
    return Container(
      color: Hue.scrim,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: PlankPanel(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                win ? Icons.verified_rounded : Icons.report_problem_rounded,
                color: win ? Hue.moss : Hue.alarm,
                size: 50,
              ),
              const SizedBox(height: 10),
              Text(win ? 'Topped Out!' : 'It Toppled!',
                  style: Lettering.heading(size: 24, color: Hue.ink)),
              const SizedBox(height: 14),
              if (win) StarRow(stars: result.stars, size: 34),
              const SizedBox(height: 12),
              Text('${result.scoreLabel}: ${result.score}',
                  style: Lettering.body(size: 15, color: Hue.inkSoft)),
              if (result.coins > 0) ...[
                const SizedBox(height: 6),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.toll_rounded, color: Hue.gold, size: 18),
                  const SizedBox(width: 6),
                  Text('+${result.coins}',
                      style: Lettering.heading(size: 16, color: Hue.gold)),
                ]),
              ],
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RoundIconButton(icon: Icons.home_rounded, onTap: onExit, size: 52),
                  const SizedBox(width: 14),
                  RoundIconButton(
                      icon: Icons.refresh_rounded,
                      onTap: onRetry,
                      tone: Hue.timber,
                      size: 52),
                  if (win && onNext != null) ...[
                    const SizedBox(width: 14),
                    StorybookButton(
                      label: 'Next',
                      icon: Icons.arrow_forward_rounded,
                      onTap: onNext,
                      height: 52,
                      fontSize: 17,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
