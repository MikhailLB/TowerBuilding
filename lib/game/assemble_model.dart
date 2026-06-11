import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Block kinds. Each maps to one of the bundled building-block images
/// (block_asset_0[asset].webp) and carries weight + fragility used by the
/// placement rules and the balance check.
enum BlockType { brick, stone, timber, glass, steel, weight }

class BlockSpec {
  const BlockSpec(this.asset, this.weight, this.fragile, this.name, this.color);
  final int asset; // 1..6 -> block_asset_0N.webp
  final int weight;
  final bool fragile;
  final String name;
  final Color color;
}

const Map<BlockType, BlockSpec> kBlockSpecs = {
  BlockType.brick: BlockSpec(1, 1, false, 'Brick', Color(0xFFC4683B)),
  BlockType.stone: BlockSpec(2, 2, false, 'Stone', Color(0xFF8C8F99)),
  BlockType.timber: BlockSpec(3, 1, false, 'Timber', Color(0xFFB78A4E)),
  BlockType.glass: BlockSpec(4, 1, true, 'Glass', Color(0xFF7FC8D8)),
  BlockType.steel: BlockSpec(5, 2, false, 'Steel', Color(0xFF6E7C8C)),
  BlockType.weight: BlockSpec(6, 3, false, 'Ballast', Color(0xFF5A4631)),
};

BlockSpec specOf(BlockType t) => kBlockSpecs[t]!;

/// Pure logic model for the Assembly puzzle. The board is a [rows] x [cols]
/// grid, row 0 at the bottom. You reproduce the [target] blueprint with the
/// exact tray of blocks, then BUILD to verify the structure stands.
class AssembleModel {
  AssembleModel({
    required this.cols,
    required this.rows,
    required this.target,
    required this.locked,
    required this.obstacles,
    required this.trayTotal,
    required this.par,
    required this.hasGlass,
    required this.hasBalance,
  }) {
    for (final c in locked) {
      placed[c] = target[c]!;
    }
  }

  final int cols;
  final int rows;
  final Map<int, BlockType> target; // r*cols+c -> type (full blueprint)
  final Set<int> locked; // pre-built, immovable (subset of target)
  final Set<int> obstacles; // blocked empty cells
  final Map<BlockType, int> trayTotal; // blocks the player must place
  final int par;
  final bool hasGlass;
  final bool hasBalance;

  final Map<int, BlockType> placed = {};

  int key(int r, int c) => r * cols + c;
  bool _in(int r, int c) => r >= 0 && c >= 0 && r < rows && c < cols;
  bool filled(int r, int c) => _in(r, c) && placed.containsKey(key(r, c));
  bool isObstacle(int r, int c) => obstacles.contains(key(r, c));
  bool isLocked(int r, int c) => locked.contains(key(r, c));

  /// Remaining count per type in the tray.
  Map<BlockType, int> trayRemaining() {
    final m = Map<BlockType, int>.from(trayTotal);
    placed.forEach((k, t) {
      if (!locked.contains(k)) m[t] = (m[t] ?? 0) - 1;
    });
    m.removeWhere((_, v) => v <= 0);
    return m;
  }

  bool _supported(int r, int c) =>
      r == 0 || filled(r - 1, c) || filled(r, c - 1) || filled(r, c + 1);

  /// Cannot drop a heavy block onto fragile glass directly below.
  bool _glassOk(int r, int c, BlockType t) {
    if (r == 0) return true;
    final below = placed[key(r - 1, c)];
    if (below != null && specOf(below).fragile && specOf(t).weight >= 2) {
      return false;
    }
    return true;
  }

  bool canPlace(int r, int c, BlockType t) {
    if (!_in(r, c) || isObstacle(r, c) || filled(r, c)) return false;
    if ((trayRemaining()[t] ?? 0) <= 0) return false;
    if (!_supported(r, c)) return false;
    if (!_glassOk(r, c, t)) return false;
    return true;
  }

  void place(int r, int c, BlockType t) => placed[key(r, c)] = t;

  bool canLift(int r, int c) =>
      filled(r, c) && !isLocked(r, c) && !filled(r + 1, c);

  void lift(int r, int c) => placed.remove(key(r, c));

  void reset() {
    placed.clear();
    for (final c in locked) {
      placed[c] = target[c]!;
    }
  }

  bool matchesBlueprint() {
    if (placed.length != target.length) return false;
    for (final e in placed.entries) {
      if (target[e.key] != e.value) return false;
    }
    return true;
  }

  /// Global balance: center of mass must sit over the grounded base, and every
  /// block must connect to the ground.
  bool isStable() {
    if (placed.isEmpty) return false;
    // base = columns with a block on the ground row
    final baseCols = <int>{};
    for (var c = 0; c < cols; c++) {
      if (filled(0, c)) baseCols.add(c);
    }
    if (baseCols.isEmpty) return false;
    final baseMin = baseCols.reduce(math.min).toDouble();
    final baseMax = baseCols.reduce(math.max) + 1.0;

    var mass = 0.0, mx = 0.0;
    placed.forEach((k, t) {
      final c = k % cols;
      final w = specOf(t).weight.toDouble();
      mass += w;
      mx += w * (c + 0.5);
    });
    final com = mx / mass;
    if (com < baseMin || com > baseMax) return false;

    // connectivity to ground
    final seen = <int>{};
    final stack = <int>[];
    for (var c = 0; c < cols; c++) {
      if (filled(0, c)) {
        stack.add(key(0, c));
        seen.add(key(0, c));
      }
    }
    while (stack.isNotEmpty) {
      final k = stack.removeLast();
      final r = k ~/ cols, c = k % cols;
      for (final d in const [
        [1, 0],
        [-1, 0],
        [0, 1],
        [0, -1],
      ]) {
        final nr = r + d[0], nc = c + d[1];
        if (filled(nr, nc) && seen.add(key(nr, nc))) {
          stack.add(key(nr, nc));
        }
      }
    }
    return seen.length == placed.length;
  }

  // ── Generation ──────────────────────────────────────────────────────────
  static AssembleModel generate(int tier, int seed) {
    final rng = math.Random(seed);
    for (var attempt = 0; attempt < 80; attempt++) {
      final m = _tryGenerate(tier, rng);
      if (m != null) return m;
    }
    return _trivial();
  }

  static AssembleModel? _tryGenerate(int tier, math.Random rng) {
    final cols = (4 + tier ~/ 2).clamp(4, 7);
    final rows = (5 + tier).clamp(5, 9);
    final blocks = (4 + tier * 2).clamp(4, cols * rows ~/ 2 + 4);

    final allowed = <BlockType>[BlockType.brick, BlockType.timber, BlockType.stone];
    if (tier >= 2) allowed.add(BlockType.glass);
    if (tier >= 3) {
      allowed.add(BlockType.steel);
      allowed.add(BlockType.weight);
    }

    final filledSet = <int>{};
    int key(int r, int c) => r * cols + c;
    bool inB(int r, int c) => r >= 0 && c >= 0 && r < rows && c < cols;

    // Base of 2..cols-1 contiguous cells on the ground.
    final baseW = (2 + rng.nextInt(cols - 1)).clamp(2, cols);
    final baseStart = rng.nextInt(cols - baseW + 1);
    for (var c = baseStart; c < baseStart + baseW; c++) {
      filledSet.add(key(0, c));
    }

    final baseMin = baseStart.toDouble();
    final baseMax = (baseStart + baseW).toDouble();

    double comOf(Set<int> s) {
      var mass = 0.0, mx = 0.0;
      for (final k in s) {
        mass += 1;
        mx += (k % cols) + 0.5;
      }
      return mx / mass;
    }

    var guard = 0;
    while (filledSet.length < blocks && guard++ < 400) {
      final list = filledSet.toList();
      final from = list[rng.nextInt(list.length)];
      final fr = from ~/ cols, fc = from % cols;
      final dirs = [
        [1, 0],
        [0, 1],
        [0, -1],
      ]..shuffle(rng);
      var added = false;
      for (final d in dirs) {
        final nr = fr + d[0], nc = fc + d[1];
        if (!inB(nr, nc)) continue;
        final nk = key(nr, nc);
        if (filledSet.contains(nk)) continue;
        // candidate must be supported by existing
        final supported = nr == 0 ||
            filledSet.contains(key(nr - 1, nc)) ||
            filledSet.contains(key(nr, nc - 1)) ||
            filledSet.contains(key(nr, nc + 1));
        if (!supported) continue;
        final test = {...filledSet, nk};
        final com = comOf(test);
        if (com < baseMin || com > baseMax) continue; // keep balanced
        filledSet.add(nk);
        added = true;
        break;
      }
      if (!added) continue;
    }

    if (filledSet.length < 4) return null;

    // Assign types (top-down so glass never has a heavier block above it).
    final cellsByRowDesc = filledSet.toList()
      ..sort((a, b) => (b ~/ cols).compareTo(a ~/ cols));
    final target = <int, BlockType>{};
    for (final k in cellsByRowDesc) {
      final r = k ~/ cols, c = k % cols;
      // is there a heavier-or-any block already above? (already assigned)
      final above = target[key(r + 1, c)];
      final canGlass = allowed.contains(BlockType.glass) &&
          (above == null) &&
          rng.nextDouble() < 0.5;
      if (canGlass) {
        target[k] = BlockType.glass;
      } else {
        // pick a non-glass allowed type
        final pool = allowed.where((t) => t != BlockType.glass).toList();
        target[k] = pool[rng.nextInt(pool.length)];
      }
    }

    // Locked / obstacles for higher tiers.
    final locked = <int>{};
    final obstacles = <int>{};
    if (tier >= 4) {
      final groundCells =
          target.keys.where((k) => k ~/ cols == 0).toList()..shuffle(rng);
      for (final k in groundCells.take(1 + rng.nextInt(2))) {
        locked.add(k); // pre-built scaffolding to build around
      }
      // a couple of blocked empty cells
      for (var i = 0; i < 2; i++) {
        final r = 1 + rng.nextInt(rows - 1);
        final c = rng.nextInt(cols);
        final k = key(r, c);
        if (!target.containsKey(k)) obstacles.add(k);
      }
    }

    final trayTotal = <BlockType, int>{};
    target.forEach((k, t) {
      if (!locked.contains(k)) trayTotal[t] = (trayTotal[t] ?? 0) + 1;
    });
    if (trayTotal.isEmpty) return null;

    final par = trayTotal.values.fold<int>(0, (a, b) => a + b);

    return AssembleModel(
      cols: cols,
      rows: rows,
      target: target,
      locked: locked,
      obstacles: obstacles,
      trayTotal: trayTotal,
      par: par,
      hasGlass: tier >= 2,
      hasBalance: tier >= 3,
    );
  }

  static AssembleModel _trivial() {
    final target = {0: BlockType.brick, 1: BlockType.brick, 3: BlockType.timber};
    return AssembleModel(
      cols: 3,
      rows: 4,
      target: target,
      locked: const {},
      obstacles: const {},
      trayTotal: const {BlockType.brick: 2, BlockType.timber: 1},
      par: 3,
      hasGlass: false,
      hasBalance: false,
    );
  }
}
