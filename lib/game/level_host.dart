import 'package:flutter/material.dart';

import '../main.dart';
import 'assemble_game.dart';
import 'campaign.dart';
import 'mechanic_card.dart';
import 'wire_game.dart';
import 'windows_game.dart';
import '../widgets/tutorial_overlay.dart';

/// Hosts one campaign level: shows the mechanic's "meaning + how to play" card
/// the first time it appears, then renders the right puzzle type.
class LevelHost extends StatefulWidget {
  const LevelHost({super.key, required this.index});
  final int index;

  @override
  State<LevelHost> createState() => _LevelHostState();
}

class _LevelHostState extends State<LevelHost> {
  late bool _showTutorial;
  late LevelSpec _spec;

  @override
  void initState() {
    super.initState();
    _spec = Campaign.at(widget.index);
    final id = _spec.tutorialId;
    _showTutorial = id != null && !player.introSeenFor(id);
  }

  Future<void> _dismissTutorial() async {
    final id = _spec.tutorialId;
    if (id != null) await player.markGameIntroSeen(id);
    if (mounted) setState(() => _showTutorial = false);
  }

  Widget _gameForType() {
    switch (_spec.type) {
      case PuzzleType.assemble:
        return AssembleGame(spec: _spec);
      case PuzzleType.wire:
        return WireGame(spec: _spec);
      case PuzzleType.windows:
        return WindowsGame(spec: _spec);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _gameForType(),
        if (_showTutorial && _spec.tutorialId != null)
          TutorialOverlay(
            steps: tutorialSteps(_spec.tutorialId!),
            onDone: _dismissTutorial,
          ),
      ],
    );
  }
}
