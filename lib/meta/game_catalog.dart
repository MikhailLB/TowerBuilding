import 'package:flutter/material.dart';

import '../theme/palette.dart';

/// Stable identifiers for every mini-game in the collection. The string [code]
/// is used as the key prefix for per-level stars/best in the save store.
enum GameId { movingDay, skyline, merge, memory, lights }

extension GameIdInfo on GameId {
  String get code {
    switch (this) {
      case GameId.movingDay:
        return 'mv';
      case GameId.skyline:
        return 'sk';
      case GameId.merge:
        return 'mg';
      case GameId.memory:
        return 'mm';
      case GameId.lights:
        return 'lt';
    }
  }

  String get title {
    switch (this) {
      case GameId.movingDay:
        return 'Moving Day';
      case GameId.skyline:
        return 'Skyline Movers';
      case GameId.merge:
        return 'Cozy Merge';
      case GameId.memory:
        return 'Neighbours';
      case GameId.lights:
        return 'Night Watch';
    }
  }

  String get blurb {
    switch (this) {
      case GameId.movingDay:
        return 'Slide the houses to rebuild the picture.';
      case GameId.skyline:
        return 'Move the stacked houses post to post — never a wide one on a narrow one.';
      case GameId.merge:
        return 'Swipe to merge matching houses into grander ones.';
      case GameId.memory:
        return 'Flip the windows and find every matching pair.';
      case GameId.lights:
        return 'Tap houses to light every window in the street.';
    }
  }

  IconData get icon {
    switch (this) {
      case GameId.movingDay:
        return Icons.grid_view_rounded;
      case GameId.skyline:
        return Icons.view_column_rounded;
      case GameId.merge:
        return Icons.dashboard_customize_rounded;
      case GameId.memory:
        return Icons.style_rounded;
      case GameId.lights:
        return Icons.lightbulb_rounded;
    }
  }

  Color get tint {
    switch (this) {
      case GameId.movingDay:
        return Hue.moss;
      case GameId.skyline:
        return Hue.ember;
      case GameId.merge:
        return Hue.lavender;
      case GameId.memory:
        return Hue.gold;
      case GameId.lights:
        return Hue.timber;
    }
  }

  /// How many difficulty levels each game ships with.
  int get levelCount {
    switch (this) {
      case GameId.movingDay:
        return 3;
      case GameId.skyline:
        return 5;
      case GameId.merge:
        return 3;
      case GameId.memory:
        return 3;
      case GameId.lights:
        return 3;
    }
  }
}
