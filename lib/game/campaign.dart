// The single linear campaign: one ordered line of levels (the tower you climb).
// Different puzzle TYPES are interleaved; each level carries a difficulty
// [tier] and, the first time a new mechanic appears, a [tutorialId].

enum PuzzleType { assemble, wire, windows }

class LevelSpec {
  const LevelSpec({
    required this.index,
    required this.type,
    required this.tier,
    required this.seed,
    this.tutorialId,
  });

  final int index;
  final PuzzleType type;
  final int tier;
  final int seed;

  /// Non-null only on the level that first introduces a mechanic; drives the
  /// "meaning + how to play" card.
  final String? tutorialId;
}

class Campaign {
  Campaign._();

  static const _maxA = 5, _maxW = 2, _maxWin = 2;

  static final List<LevelSpec> levels = _build();
  static int get length => levels.length;
  static LevelSpec at(int i) => levels[i.clamp(0, levels.length - 1)];

  static String? _featureKey(PuzzleType t, int tier) {
    switch (t) {
      case PuzzleType.assemble:
        if (tier == 0) return 'assemble';
        if (tier == 2) return 'asm_glass';
        if (tier == 3) return 'asm_balance';
        if (tier == 4) return 'asm_obstacle';
        return null;
      case PuzzleType.wire:
        if (tier == 0) return 'wire';
        if (tier == 2) return 'wire_locked';
        return null;
      case PuzzleType.windows:
        if (tier == 0) return 'windows';
        if (tier == 1) return 'win_pattern';
        return null;
    }
  }

  static List<LevelSpec> _build() {
    final out = <LevelSpec>[];
    final seen = <String>{};
    var seed = 1000;

    void add(PuzzleType t, int tier) {
      final key = _featureKey(t, tier);
      String? tut;
      if (key != null && !seen.contains(key)) {
        seen.add(key);
        tut = key;
      }
      out.add(LevelSpec(
        index: out.length,
        type: t,
        tier: tier,
        seed: seed++,
        tutorialId: tut,
      ));
    }

    for (var cycle = 0; cycle < 9; cycle++) {
      final a = (cycle * 2).clamp(0, _maxA);
      final a2 = (cycle * 2 + 1).clamp(0, _maxA);
      final w = cycle.clamp(0, _maxW);
      final win = cycle.clamp(0, _maxWin);
      add(PuzzleType.assemble, a);
      add(PuzzleType.assemble, a2);
      add(PuzzleType.wire, w);
      add(PuzzleType.assemble, a2);
      add(PuzzleType.windows, win);
      add(PuzzleType.assemble, a);
    }
    return out;
  }
}
