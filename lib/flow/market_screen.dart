import 'package:flutter/material.dart';

import '../core/sound_desk.dart';
import '../main.dart';
import '../theme/palette.dart';
import '../theme/sky_theme.dart';
import '../theme/type_scale.dart';
import '../widgets/plank_panel.dart';
import '../widgets/sky_backdrop.dart';

/// The Market — spend earned coins on new backdrop skies. The selected sky is
/// applied everywhere via [SkyBackdrop].
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
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

  Future<void> _onTap(SkyTheme t) async {
    SoundDesk.it.cue(Cue.tap);
    if (player.ownsTheme(t.id)) {
      await player.selectTheme(t.id);
      return;
    }
    final ok = await player.unlockTheme(t);
    if (!ok) {
      _toast('Not enough coins for ${t.name}');
      return;
    }
    await player.selectTheme(t.id);
    _toast('${t.name} unlocked & applied');
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: Hue.panelDeep,
        content: Text(text, style: Lettering.body(color: Hue.parchment)),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Hue.noon,
      body: SkyBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
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
                      child: Text('Sky Market',
                          style: Lettering.heading(size: 24, color: Hue.ink)),
                    ),
                    StatChip(
                        icon: Icons.savings_rounded, label: '${player.coins}'),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 0.92,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children:
                        SkyCatalogue.all.map(_themeCard).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _themeCard(SkyTheme t) {
    final owned = player.ownsTheme(t.id);
    final selected = player.selectedTheme == t.id;
    final preview = t.phases.first;
    return GestureDetector(
      onTap: () => _onTap(t),
      child: Container(
        decoration: BoxDecoration(
          color: Hue.panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Hue.gold : Hue.timberDeep,
            width: 3,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: preview,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(t.icon, color: Colors.white, size: 24),
                    ),
                  ),
                  if (t.animated)
                    const Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.loop_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  if (!owned)
                    const Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.lock_rounded, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(t.name,
                        style: Lettering.heading(size: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  _pill(t, owned, selected),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(SkyTheme t, bool owned, bool selected) {
    late final String label;
    late final Color bg;
    late final IconData icon;
    if (selected) {
      label = 'Active';
      bg = Hue.gold;
      icon = Icons.check_rounded;
    } else if (owned) {
      label = 'Use';
      bg = Hue.moss;
      icon = Icons.brush_rounded;
    } else {
      label = '${t.cost}';
      bg = Hue.timber;
      icon = Icons.savings_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: selected ? Hue.ink : Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: Lettering.caption(
                  size: 12, color: selected ? Hue.ink : Colors.white)),
        ],
      ),
    );
  }
}
