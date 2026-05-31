import 'package:flutter/material.dart';

import 'palette.dart';

/// A purchasable / selectable backdrop mood. Each theme is a list of gradient
/// "phases" (top→bottom colour stops). A theme with several phases animates
/// through them (the free `auto` theme cycles day → sunset → night → dawn);
/// single-phase themes hold one fixed mood.
class SkyTheme {
  const SkyTheme({
    required this.id,
    required this.name,
    required this.icon,
    required this.cost,
    required this.phases,
    this.starsAtNight = false,
  });

  final String id;
  final String name;
  final IconData icon;
  final int cost;
  final List<List<Color>> phases;

  /// Whether faint stars should be drawn (for dark moods).
  final bool starsAtNight;

  bool get isFree => cost == 0;
  bool get animated => phases.length > 1;
}

/// Catalogue of every backdrop. Order defines the Market layout.
class SkyCatalogue {
  SkyCatalogue._();

  static const _day = [Hue.dawn, Hue.noon, Hue.dusk];
  static const _sunset = [Hue.sunsetTop, Hue.sunsetMid, Hue.sunsetLow];
  static const _night = [Hue.nightTop, Hue.nightMid, Hue.nightLow];
  static const _aurora = [Hue.auroraTop, Hue.auroraMid, Hue.auroraLow];
  static const _meadow = [Hue.meadowTop, Hue.meadowMid, Hue.meadowLow];

  static const all = <SkyTheme>[
    SkyTheme(
      id: 'auto',
      name: 'Day & Night',
      icon: Icons.brightness_6_rounded,
      cost: 0,
      phases: [_day, _sunset, _night, _sunset],
      starsAtNight: true,
    ),
    SkyTheme(
      id: 'day',
      name: 'Clear Day',
      icon: Icons.wb_sunny_rounded,
      cost: 0,
      phases: [_day],
    ),
    SkyTheme(
      id: 'sunset',
      name: 'Golden Hour',
      icon: Icons.wb_twilight_rounded,
      cost: 120,
      phases: [_sunset],
    ),
    SkyTheme(
      id: 'night',
      name: 'Starlit Night',
      icon: Icons.nightlight_round,
      cost: 180,
      phases: [_night],
      starsAtNight: true,
    ),
    SkyTheme(
      id: 'aurora',
      name: 'Aurora',
      icon: Icons.auto_awesome_rounded,
      cost: 260,
      phases: [_aurora],
      starsAtNight: true,
    ),
    SkyTheme(
      id: 'meadow',
      name: 'Spring Meadow',
      icon: Icons.local_florist_rounded,
      cost: 150,
      phases: [_meadow],
    ),
  ];

  static SkyTheme byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all.first);

  static const defaultUnlocked = ['auto', 'day'];
}
