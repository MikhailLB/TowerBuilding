import 'package:flutter/material.dart';

import '../core/sound_desk.dart';
import '../main.dart';
import '../theme/palette.dart';
import '../theme/sky_theme.dart';
import '../theme/type_scale.dart';
import '../widgets/plank_panel.dart';
import '../widgets/sky_backdrop.dart';
import '../widgets/storybook_button.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  String? _msg;

  Future<void> _buy(SkyTheme t) async {
    final ok = await player.unlockTheme(t);
    SoundDesk.maybe?.cue(ok ? Cue.settle : Cue.collapse);
    setState(() => _msg = ok ? 'Unlocked ${t.name}!' : 'Not enough coins');
  }

  void _use(SkyTheme t) {
    player.selectTheme(t.id);
    SoundDesk.maybe?.cue(Cue.tap);
    setState(() => _msg = '${t.name} applied');
  }

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
                        Text('Sky Market',
                            style: Lettering.heading(size: 22, color: Hue.parchment)),
                        const Spacer(),
                        StatChip(
                            icon: Icons.toll_rounded,
                            label: '${player.coins}',
                            iconColor: Hue.gold),
                      ],
                    ),
                  ),
                  if (_msg != null)
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(_msg!,
                          style: Lettering.body(size: 13, color: Hue.parchment)),
                    ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [for (final t in SkyCatalogue.all) _row(t)],
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

  Widget _row(SkyTheme t) {
    final owned = player.ownsTheme(t.id);
    final selected = player.selectedTheme == t.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PlankPanel(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: t.phases.first,
                ),
                border: Border.all(color: Hue.timberDeep, width: 2),
              ),
              child: Icon(t.icon, color: Colors.white.withValues(alpha: 0.9)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name, style: Lettering.heading(size: 17, color: Hue.ink)),
                  Text(
                    owned ? (selected ? 'In use' : 'Owned') : '${t.cost} coins',
                    style: Lettering.body(size: 12, color: Hue.inkSoft),
                  ),
                ],
              ),
            ),
            if (!owned)
              StorybookButton(
                  label: 'Buy', tone: BtnTone.moss, height: 46, fontSize: 15, onTap: () => _buy(t))
            else if (!selected)
              StorybookButton(
                  label: 'Use', tone: BtnTone.plank, height: 46, fontSize: 15, onTap: () => _use(t))
            else
              const Icon(Icons.check_circle_rounded, color: Hue.moss, size: 28),
          ],
        ),
      ),
    );
  }
}
