import 'package:flutter/material.dart';

import '../game/campaign.dart';
import '../theme/palette.dart';

/// The app is now a single campaign. [GameId] keeps one entry so the existing
/// per-level progress/stars APIs in PlayerState keep working unchanged; the
/// `code` is the save-key prefix and must stay stable once shipped.
enum GameId { tower }

extension GameIdInfo on GameId {
  String get code => 'tw';

  String get title => 'Tower Building';

  /// Total number of levels on the campaign line.
  int get levelCount => Campaign.length;
}

/// Per-puzzle-type display metadata (titles, colours, icons) used by cards.
extension PuzzleTypeInfo on PuzzleType {
  String get title {
    switch (this) {
      case PuzzleType.assemble:
        return 'Assembly';
      case PuzzleType.wire:
        return 'Wiring';
      case PuzzleType.windows:
        return 'Windows';
    }
  }

  IconData get icon {
    switch (this) {
      case PuzzleType.assemble:
        return Icons.apartment_rounded;
      case PuzzleType.wire:
        return Icons.bolt_rounded;
      case PuzzleType.windows:
        return Icons.window_rounded;
    }
  }

  Color get tint {
    switch (this) {
      case PuzzleType.assemble:
        return Hue.ember;
      case PuzzleType.wire:
        return Hue.gold;
      case PuzzleType.windows:
        return Hue.lavender;
    }
  }
}
