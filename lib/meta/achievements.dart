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

  static int _cleared(PlayerState p) => p.clearedLevels(GameId.tower);

  static final List<Achievement> all = [
    Achievement(
      id: 'first_build',
      title: 'Groundbreaking',
      detail: 'Clear the first level.',
      icon: Icons.flag_rounded,
      reward: 25,
      earned: (p) => _cleared(p) >= 1,
    ),
    Achievement(
      id: 'floor_5',
      title: 'Five Floors Up',
      detail: 'Clear 5 levels.',
      icon: Icons.stairs_rounded,
      reward: 40,
      earned: (p) => _cleared(p) >= 5,
    ),
    Achievement(
      id: 'floor_15',
      title: 'Mid-Rise',
      detail: 'Clear 15 levels.',
      icon: Icons.apartment_rounded,
      reward: 80,
      earned: (p) => _cleared(p) >= 15,
    ),
    Achievement(
      id: 'floor_30',
      title: 'High-Rise',
      detail: 'Clear 30 levels.',
      icon: Icons.location_city_rounded,
      reward: 140,
      earned: (p) => _cleared(p) >= 30,
    ),
    Achievement(
      id: 'topped_out',
      title: 'Topped Out',
      detail: 'Clear the whole tower.',
      icon: Icons.emoji_events_rounded,
      reward: 300,
      earned: (p) => _cleared(p) >= GameId.tower.levelCount,
    ),
    Achievement(
      id: 'stars_30',
      title: 'Star Foreman',
      detail: 'Earn 30 stars.',
      icon: Icons.star_rounded,
      reward: 60,
      earned: (p) => p.totalStars >= 30,
    ),
    Achievement(
      id: 'stars_90',
      title: 'Master Builder',
      detail: 'Earn 90 stars.',
      icon: Icons.workspace_premium_rounded,
      reward: 200,
      earned: (p) => p.totalStars >= 90,
    ),
    Achievement(
      id: 'decorator',
      title: 'Sky Decorator',
      detail: 'Unlock a new sky from the Market.',
      icon: Icons.palette_rounded,
      reward: 40,
      earned: (p) => p.ownedThemes.length > 2,
    ),
    Achievement(
      id: 'streak_3',
      title: 'Regular Crew',
      detail: 'Reach a 3-day daily streak.',
      icon: Icons.calendar_month_rounded,
      reward: 40,
      earned: (p) => p.dailyStreak >= 3,
    ),
    Achievement(
      id: 'rich',
      title: 'Site Treasurer',
      detail: 'Earn 600 coins in total.',
      icon: Icons.savings_rounded,
      reward: 120,
      earned: (p) => p.lifetimeCoins >= 600,
    ),
  ];
}

/// Seven-day daily reward ladder (coins per consecutive day, looping).
class DailyLadder {
  DailyLadder._();
  static const rewards = [20, 30, 40, 60, 80, 100, 220];
  static int rewardFor(int streak) => rewards[(streak - 1).clamp(0, 999) % 7];
}
