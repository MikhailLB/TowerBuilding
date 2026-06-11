import 'package:flutter/material.dart';

import '../game/campaign.dart';
import '../game/game_shell.dart';
import '../game/level_host.dart';
import '../main.dart';
import '../meta/game_catalog.dart';
import '../theme/palette.dart';
import '../theme/type_scale.dart';
import '../widgets/plank_panel.dart';
import '../widgets/sky_backdrop.dart';

/// The campaign line shown as a tower you climb: level 1 at the bottom, the
/// summit at the top. Nodes unlock as you clear the previous one.
class CampaignMapScreen extends StatefulWidget {
  const CampaignMapScreen({super.key});

  @override
  State<CampaignMapScreen> createState() => _CampaignMapScreenState();
}

class _CampaignMapScreenState extends State<CampaignMapScreen> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // start near the current level (list is bottom-anchored)
      if (_controller.hasClients) {
        _controller.jumpTo(_controller.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _play(int index) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => LevelHost(index: index)))
        .then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = Campaign.length;
    return Scaffold(
      backgroundColor: Hue.noon,
      body: SkyBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: Row(
                  children: [
                    RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.of(context).maybePop()),
                    const SizedBox(width: 12),
                    Text('The Tower', style: Lettering.heading(size: 22, color: Hue.parchment)),
                    const Spacer(),
                    StatChip(
                        icon: Icons.star_rounded,
                        label: '${player.totalStars}',
                        iconColor: Hue.gold),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _controller,
                  reverse: true, // index 0 at the bottom
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  itemCount: total,
                  itemBuilder: (context, i) => _node(i),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _node(int index) {
    final spec = Campaign.at(index);
    final unlocked = player.levelUnlocked(GameId.tower, index);
    final stars = player.stars(GameId.tower, index);
    final tint = spec.type.tint;
    final align = index.isEven ? Alignment.centerLeft : Alignment.centerRight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Align(
        alignment: align,
        child: GestureDetector(
          onTap: unlocked ? () => _play(index) : null,
          child: Opacity(
            opacity: unlocked ? 1 : 0.45,
            child: SizedBox(
              width: 230,
              child: PlankPanel(
                tone: stars > 0 ? Hue.plank : Hue.panel,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: tint.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tint, width: 1.6),
                      ),
                      child: unlocked
                          ? Icon(spec.type.icon, color: tint, size: 24)
                          : const Icon(Icons.lock_rounded,
                              color: Hue.inkSoft, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Level ${index + 1}',
                              style: Lettering.heading(size: 16, color: Hue.ink)),
                          Text(spec.type.title,
                              style: Lettering.body(size: 12, color: Hue.inkSoft)),
                          const SizedBox(height: 3),
                          StarRow(stars: stars, size: 13),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
