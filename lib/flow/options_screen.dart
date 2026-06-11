import 'package:flutter/material.dart';

import '../core/sound_desk.dart';
import '../main.dart';
import '../theme/palette.dart';
import '../theme/type_scale.dart';
import '../widgets/plank_panel.dart';
import '../widgets/sky_backdrop.dart';

class OptionsScreen extends StatelessWidget {
  const OptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Hue.noon,
      body: SkyBackdrop(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: player,
            builder: (context, _) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                    child: Row(
                      children: [
                        RoundIconButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Navigator.of(context).maybePop()),
                        const SizedBox(width: 12),
                        Text('Settings',
                            style: Lettering.heading(size: 22, color: Hue.parchment)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _toggle('Music', player.musicOn, (v) {
                          player.setMusic(v);
                          if (v) SoundDesk.maybe?.playBed(Bed.lobby);
                        }),
                        _slider('Music volume', player.musicLevel,
                            player.setMusicLevel, player.musicOn),
                        const SizedBox(height: 6),
                        _toggle('Sound effects', player.soundOn, player.setSound),
                        _slider('Effects volume', player.sfxLevel,
                            player.setSfxLevel, player.soundOn),
                        const SizedBox(height: 6),
                        _toggle('Haptics', player.hapticsOn, (v) {
                          player.setHaptics(v);
                          if (v) SoundDesk.maybe?.buzz();
                        }),
                        const SizedBox(height: 16),
                        PlankPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('About',
                                  style: Lettering.heading(size: 16, color: Hue.ink)),
                              const SizedBox(height: 6),
                              Text(
                                'Tower Building is a hand-built collection of '
                                'construction puzzles. Read the blueprint, place '
                                'your blocks, and raise every tower on the line.',
                                style: Lettering.body(size: 13, color: Hue.inkSoft),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PlankPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: Lettering.heading(size: 16, color: Hue.ink))),
            Switch(
              value: value,
              activeThumbColor: Hue.ember,
              onChanged: (v) {
                onChanged(v);
                SoundDesk.maybe?.cue(Cue.tap);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _slider(String label, double value, ValueChanged<double> onChanged,
      bool enabled) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PlankPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: Row(
          children: [
            SizedBox(
                width: 120,
                child:
                    Text(label, style: Lettering.body(size: 13, color: Hue.ink))),
            Expanded(
              child: Slider(
                value: value.clamp(0, 1),
                activeColor: Hue.moss,
                inactiveColor: Hue.panelDeep.withValues(alpha: 0.3),
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
