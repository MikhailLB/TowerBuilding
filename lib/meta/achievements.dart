import 'package:flutter/material.dart';

import '../core/player_state.dart';
import 'game_catalog.dart';

/// A one-time goal. [earned] is a pure predicate over [PlayerState]; the player
/// model evaluates them after key events and grants [reward] coins the first
/// time each flips true.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.detail,
    required this.icon,
    required this.reward,
    required this.earned,
  });

  final String id;
  final String title;
  final String detail;
  final IconData icon;
  final int reward;
  final bool Function(PlayerState p) earned;
}

class AchievementBook {
  AchievementBook._();

  static final List<Achievement> all = [
    Achievement(
      id: 'first_win',
      title: 'Housewarming',
      detail: 'Clear any puzzle for the first time.',
      icon: Icons.celebration_rounded,
      reward: 25,
      earned: (p) => p.totalStars > 0,
    ),
    Achievement(
      id: 'movers_master',
      title: 'Moving Master',
      detail: 'Solve every Moving Day grid.',
      icon: Icons.grid_view_rounded,
      reward: 60,
      earned: (p) => _allLevels(p, GameId.movingDay),
    ),
    Achievement(
      id: 'tall_order',
      title: 'Tall Order',
      detail: 'Beat the 7-house Skyline Movers tower.',
      icon: Icons.view_column_rounded,
      reward: 80,
      earned: (p) => p.stars(GameId.skyline, 4) > 0,
    ),
    Achievement(
      id: 'big_merge',
      title: 'Grand Estate',
      detail: 'Reach the top tier in Cozy Merge.',
      icon: Icons.dashboard_customize_rounded,
      reward: 70,
      earned: (p) => p.stars(GameId.merge, 2) > 0,
    ),
    Achievement(
      id: 'sharp_eye',
      title: 'Sharp Eye',
      detail: 'Clear the largest Neighbours board.',
      icon: Icons.visibility_rounded,
      reward: 60,
      earned: (p) => p.stars(GameId.memory, 2) > 0,
    ),
    Achievement(
      id: 'lights_on',
      title: 'Lamplighter',
      detail: 'Light up the toughest Night Watch street.',
      icon: Icons.lightbulb_rounded,
      reward: 60,
      earned: (p) => p.stars(GameId.lights, 2) > 0,
    ),
    Achievement(
      id: 'collector_25',
      title: 'Star Collector',
      detail: 'Earn 25 stars across all games.',
      icon: Icons.star_rounded,
      reward: 50,
      earned: (p) => p.totalStars >= 25,
    ),
    Achievement(
      id: 'collector_45',
      title: 'Constellation',
      detail: 'Earn 45 stars across all games.',
      icon: Icons.auto_awesome_rounded,
      reward: 120,
      earned: (p) => p.totalStars >= 45,
    ),
    Achievement(
      id: 'decorator',
      title: 'Decorator',
      detail: 'Unlock a new sky from the Market.',
      icon: Icons.palette_rounded,
      reward: 40,
      earned: (p) => p.ownedThemes.length > 2,
    ),
    Achievement(
      id: 'streak_3',
      title: 'Regular Visitor',
      detail: 'Reach a 3-day daily streak.',
      icon: Icons.calendar_month_rounded,
      reward: 40,
      earned: (p) => p.dailyStreak >= 3,
    ),
    Achievement(
      id: 'rich',
      title: 'Town Treasurer',
      detail: 'Earn 500 coins in total.',
      icon: Icons.savings_rounded,
      reward: 100,
      earned: (p) => p.lifetimeCoins >= 500,
    ),
  ];

  static bool _allLevels(PlayerState p, GameId game) {
    for (var l = 0; l < game.levelCount; l++) {
      if (p.stars(game, l) == 0) return false;
    }
    return true;
  }
}

/// Seven-day daily reward ladder (coins per consecutive day, looping).
class DailyLadder {
  DailyLadder._();
  static const rewards = [20, 30, 40, 60, 80, 100, 200];
  static int rewardFor(int streak) => rewards[(streak - 1).clamp(0, 999) % 7];
}
