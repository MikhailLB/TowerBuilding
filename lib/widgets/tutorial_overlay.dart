import 'package:flutter/material.dart';

import '../theme/palette.dart';
import '../theme/type_scale.dart';
import 'plank_panel.dart';
import 'storybook_button.dart';

/// A single coaching card.
class TutorialStep {
  const TutorialStep({
    required this.icon,
    required this.title,
    required this.body,
    this.iconColor = Hue.ember,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color iconColor;
}

/// Full-screen darkened overlay that walks the player through [steps] one at a
/// time. Calls [onDone] when the last step is dismissed. Intended to appear
/// once per game, controlled by [PlayerState.introSeenFor].
class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onDone,
  });

  final List<TutorialStep> steps;
  final VoidCallback onDone;

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _current = 0;
  late final AnimationController _anim;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _slide = Tween<double>(begin: 0.14, end: 0.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOut),
    );
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _next() {
    if (_current < widget.steps.length - 1) {
      _anim.reverse().then((_) {
        if (!mounted) return;
        setState(() => _current++);
        _anim.forward();
      });
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_current];
    final isLast = _current == widget.steps.length - 1;
    return Positioned.fill(
      child: Material(
        color: Hue.scrim,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Step dots.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.steps.length; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _current ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _current
                              ? Hue.parchment
                              : Hue.parchment.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                AnimatedBuilder(
                  animation: _anim,
                  builder: (_, child) => Opacity(
                    opacity: _anim.value,
                    child: Transform.translate(
                      offset: Offset(0, _slide.value * 60),
                      child: child,
                    ),
                  ),
                  child: PlankPanel(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: step.iconColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(step.icon, color: step.iconColor, size: 44),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          step.title,
                          style: Lettering.heading(size: 22, color: Hue.ink),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          step.body,
                          style: Lettering.body(size: 14.5, color: Hue.inkSoft),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                StorybookButton(
                  label: isLast ? "Let's go!" : 'Next →',
                  tone: isLast ? BtnTone.ember : BtnTone.plank,
                  icon: isLast ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded,
                  width: double.infinity,
                  onTap: _next,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
