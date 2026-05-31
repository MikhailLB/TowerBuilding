import 'package:flutter/material.dart';

import '../core/sound_desk.dart';
import '../main.dart';
import '../theme/palette.dart';
import '../theme/type_scale.dart';
import '../widgets/plank_panel.dart';
import '../widgets/storybook_button.dart';

/// Audio and haptic preferences. Mutations flow straight into [player], which
/// [SoundDesk] is already listening to, so changes apply live.
class OptionsScreen extends StatefulWidget {
  const OptionsScreen({super.key});

  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  @override
  void initState() {
    super.initState();
    player.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    player.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Hue.dusk, Hue.noon],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () {
                        SoundDesk.it.cue(Cue.tap);
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Options',
                          style: Lettering.banner(size: 28),
                          textAlign: TextAlign.center),
                    ),
                    const SizedBox(width: 46),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView(
                    children: [
                      _toggle(
                        'Music',
                        'Lobby and build themes',
                        Icons.library_music_rounded,
                        player.musicOn,
                        (v) {
                          SoundDesk.it.cue(Cue.tap);
                          player.setMusic(v);
                        },
                      ),
                      _slider('Music volume', Icons.volume_up_rounded,
                          player.musicLevel, player.musicOn,
                          (v) => player.setMusicLevel(v)),
                      const SizedBox(height: 8),
                      _toggle(
                        'Sound effects',
                        'Settling, taps and tumbles',
                        Icons.graphic_eq_rounded,
                        player.soundOn,
                        (v) {
                          player.setSound(v);
                          if (v) SoundDesk.it.cue(Cue.tap);
                        },
                      ),
                      _slider('SFX volume', Icons.volume_up_rounded,
                          player.sfxLevel, player.soundOn,
                          (v) => player.setSfxLevel(v)),
                      const SizedBox(height: 8),
                      _toggle(
                        'Haptics',
                        'Gentle taps on key moments',
                        Icons.vibration_rounded,
                        player.hapticsOn,
                        (v) {
                          player.setHaptics(v);
                          if (v) SoundDesk.it.buzz();
                        },
                      ),
                    ],
                  ),
                ),
                StorybookButton(
                  label: 'Done',
                  width: double.infinity,
                  onTap: () {
                    SoundDesk.it.cue(Cue.tap);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggle(String title, String sub, IconData icon, bool value,
      ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: PlankPanel(
        tone: Hue.panel,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Hue.ember.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Hue.ember, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Lettering.heading(size: 16)),
                  Text(sub, style: Lettering.body(size: 12)),
                ],
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: Hue.moss,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _slider(String title, IconData icon, double value, bool enabled,
      ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: Hue.panel.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Hue.timberDeep, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: enabled ? Hue.ember : Hue.inkSoft, size: 18),
            const SizedBox(width: 8),
            SizedBox(
              width: 96,
              child: Text(title,
                  style: Lettering.body(
                      size: 12, color: enabled ? Hue.ink : Hue.inkSoft)),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Hue.ember,
                  inactiveTrackColor: Hue.plankEdge,
                  thumbColor: Hue.ember,
                  trackHeight: 4,
                ),
                child: Slider(
                  value: value,
                  onChanged: enabled ? onChanged : null,
                ),
              ),
            ),
            SizedBox(
              width: 34,
              child: Text('${(value * 100).round()}',
                  textAlign: TextAlign.right,
                  style: Lettering.body(size: 12, color: Hue.ink)),
            ),
          ],
        ),
      ),
    );
  }
}
