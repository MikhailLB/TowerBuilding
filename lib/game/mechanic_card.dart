import 'package:flutter/material.dart';

import '../theme/palette.dart';
import '../widgets/tutorial_overlay.dart';

/// Returns the "meaning + how to play" coaching steps for a mechanic id.
/// Each mechanic shows one "what you're building" card and one "how to play".
List<TutorialStep> tutorialSteps(String id) {
  switch (id) {
    case 'assemble':
      return const [
        TutorialStep(
          icon: Icons.apartment_rounded,
          title: 'You are the foreman',
          body: 'Every level hands you a blueprint of a building. Your job is '
              'to rebuild it exactly with the blocks in your tray.',
        ),
        TutorialStep(
          icon: Icons.touch_app_rounded,
          title: 'Place & build',
          body: 'Pick a block from the tray, then tap a cell to set it. Blocks '
              'must rest on the ground or on a block below or beside them. Tap a '
              'top block to lift it. When the plan is filled, press BUILD.',
          iconColor: Hue.moss,
        ),
      ];
    case 'asm_glass':
      return const [
        TutorialStep(
          icon: Icons.water_drop_rounded,
          title: 'Glass is fragile',
          body: 'Glass panels (the blue blocks) crack under heavy loads.',
          iconColor: Hue.lavender,
        ),
        TutorialStep(
          icon: Icons.layers_rounded,
          title: 'Mind the load order',
          body: 'You cannot place a heavy block directly on top of glass. Plan '
              'the order so glass only carries light blocks — or nothing.',
        ),
      ];
    case 'asm_balance':
      return const [
        TutorialStep(
          icon: Icons.balance_rounded,
          title: 'Keep it balanced',
          body: 'Blocks can lean out past their base, but if the weight tips '
              'too far the whole tower topples when you build.',
          iconColor: Hue.alarm,
        ),
        TutorialStep(
          icon: Icons.fitness_center_rounded,
          title: 'Use Ballast',
          body: 'Heavy Ballast blocks pull the center of mass back over the '
              'base. Counter your overhangs so the structure stands.',
        ),
      ];
    case 'asm_obstacle':
      return const [
        TutorialStep(
          icon: Icons.construction_rounded,
          title: 'Work around the site',
          body: 'Some blocks are already fixed in place (gold outline) and some '
              'cells are blocked off.',
          iconColor: Hue.gold,
        ),
        TutorialStep(
          icon: Icons.alt_route_rounded,
          title: 'Build around them',
          body: 'You cannot move fixed blocks or use blocked cells. Fit the rest '
              'of the blueprint around them.',
        ),
      ];
    case 'wire':
      return const [
        TutorialStep(
          icon: Icons.bolt_rounded,
          title: 'Power the building',
          body: 'The glowing vault feeds the building through conduits. Every '
              'unit needs current.',
          iconColor: Hue.gold,
        ),
        TutorialStep(
          icon: Icons.rotate_right_rounded,
          title: 'Rotate the conduits',
          body: 'Tap a conduit to turn it 90°. Connect the vault to every '
              'endpoint. Fewer turns earn more stars.',
        ),
      ];
    case 'wire_locked':
      return const [
        TutorialStep(
          icon: Icons.lock_rounded,
          title: 'Sealed conduits',
          body: 'Conduits with a gold ring are sealed and cannot be turned. '
              'Route the current around them.',
          iconColor: Hue.gold,
        ),
      ];
    case 'windows':
      return const [
        TutorialStep(
          icon: Icons.window_rounded,
          title: 'Light the facade',
          body: 'Flip the building\'s windows on to finish the night shot.',
          iconColor: Hue.lavender,
        ),
        TutorialStep(
          icon: Icons.highlight_rounded,
          title: 'Lights affect neighbours',
          body: 'Tapping a window also flips the windows around it. Find the '
              'taps that light them all.',
        ),
      ];
    case 'win_pattern':
      return const [
        TutorialStep(
          icon: Icons.grid_view_rounded,
          title: 'Match the pattern',
          body: 'Now you must match an exact pattern. The windows outlined in '
              'orange are the ones that should end up lit.',
          iconColor: Hue.ember,
        ),
      ];
    default:
      return const [];
  }
}
