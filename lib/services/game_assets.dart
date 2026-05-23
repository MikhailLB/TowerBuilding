import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ui/resource_paths.dart';

/// Preloads Flame game textures. Must run before any [TowerGame] session.
///
/// [LoadingScreen] used to do this; gray-flow now skips that screen, so we
/// warm assets during app startup instead.
class GameAssets {
  GameAssets._();

  static Future<void>? _loadFuture;

  static Future<void> ensureLoaded() =>
      _loadFuture ??= _preload();

  static Future<void> _preload() async {
    Flame.images.prefix = '';
    final paths = <String>[
      ResourcePaths.sky,
      ResourcePaths.ground,
      ResourcePaths.cloud,
      ResourcePaths.hook,
      ResourcePaths.startBg,
      ResourcePaths.startBuilding,
      ResourcePaths.logo,
      ResourcePaths.logoName,
      ...ResourcePaths.allBlocks,
    ];
    for (final path in paths) {
      try {
        await Flame.images.load(path);
      } catch (e) {
        debugPrint('GameAssets: failed to preload $path: $e');
      }
    }
    try {
      GoogleFonts.bangers();
      GoogleFonts.fredoka();
      await GoogleFonts.pendingFonts(<TextStyle>[
        GoogleFonts.bangers(),
        GoogleFonts.fredoka(),
      ]);
    } catch (e) {
      debugPrint('GameAssets: Google Fonts preload failed: $e');
    }
  }
}
