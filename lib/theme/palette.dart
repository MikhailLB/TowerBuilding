import 'package:flutter/material.dart';

/// Storybook colour palette for the balance-village game. Warm parchment +
/// ink + moss tones replace the old flat candy theme so the UI reads as a
/// hand-painted picture book rather than a generic arcade skin.
class Hue {
  Hue._();

  // Sky / atmosphere
  static const dawn = Color(0xFFBFE3EC);
  static const noon = Color(0xFF8FCBDD);
  static const dusk = Color(0xFF6FA8C0);

  // Wood / structure
  static const timber = Color(0xFF8A5A33);
  static const timberDeep = Color(0xFF513418);
  static const plank = Color(0xFFE9D2A6);
  static const plankEdge = Color(0xFFC9A86E);

  // Ink / text
  static const ink = Color(0xFF2E2014);
  static const inkSoft = Color(0xFF5A4631);
  static const parchment = Color(0xFFFBEFD2);

  // Accents
  static const ember = Color(0xFFE8743B); // terracotta accent
  static const moss = Color(0xFF6F8F4E); // healthy / safe
  static const gold = Color(0xFFEDB200); // rewards / stars
  static const alarm = Color(0xFFC2452F); // danger / topple
  static const lavender = Color(0xFF8E7BB5); // special houses

  // Panels
  static const panel = Color(0xFFF3E2BC);
  static const panelDeep = Color(0xFF3A2A1A);
  static const scrim = Color(0x99201408);

  // Extended sky moods (used by SkyBackdrop themes).
  static const sunsetTop = Color(0xFFFFD79B);
  static const sunsetMid = Color(0xFFFF9A6B);
  static const sunsetLow = Color(0xFFC9587A);

  static const nightTop = Color(0xFF0E1A3A);
  static const nightMid = Color(0xFF24305C);
  static const nightLow = Color(0xFF44518A);

  static const auroraTop = Color(0xFF0B2A3A);
  static const auroraMid = Color(0xFF1E6F6E);
  static const auroraLow = Color(0xFF6FE0B0);

  static const meadowTop = Color(0xFFCDEBC0);
  static const meadowMid = Color(0xFF9FD08A);
  static const meadowLow = Color(0xFF6FA8C0);
}
