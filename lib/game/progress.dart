import '../main.dart';
import '../meta/achievements.dart';
import '../meta/game_catalog.dart';

/// Records a finished campaign level and returns coins awarded (first clear).
Future<({int coins, List<Achievement> unlocked})> commitLevel(
  int index, {
  required int stars,
  required int score,
}) async {
  final prev = player.stars(GameId.tower, index);
  final coins = (stars > 0 && prev == 0) ? 20 + stars * 10 : 0;
  final unlocked = await player.recordGame(
    GameId.tower,
    index,
    stars: stars,
    score: score,
    higherBetter: false,
    coinReward: coins,
  );
  return (coins: coins, unlocked: unlocked);
}

bool hasNextLevel(int index) => index + 1 < GameId.tower.levelCount;
