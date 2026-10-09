import 'package:flutter/material.dart';
import '../theme/atelier.dart';
import '../audio/sound_engine.dart';
import 'widgets.dart';

/// How to Play — the jeweler's handbook. Full RULES.md summary.
class HowToPlayScreen extends StatelessWidget {
  final SoundEngine sound;
  const HowToPlayScreen({super.key, required this.sound});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VelvetBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
                child: Row(
                  children: [
                    BrassIconButton(
                      icon: Icons.arrow_back,
                      size: 42,
                      onTap: () {
                        sound.play(SfxKind.click);
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: BrassPlaque(
                        text: 'THE HANDBOOK',
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 50),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: WalnutPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                            child: Text('HOW TO PLAY',
                                style: Atelier.display.copyWith(
                                    fontSize: 22,
                                    letterSpacing: 2))),
                        const SizedBox(height: 8),
                        const EngravedDivider(),
                        const SizedBox(height: 12),
                        _rule(0,
                            'Swap adjacent gems to line up 3 or more of a kind. Matched gems are cleared, the rest fall, and cascades multiply your score (\u00d72, \u00d73 \u2026 up to \u00d78).'),
                        _rule(1,
                            'Match 4 to forge a Faceted Bar \u2014 swap it with any gem to clear its whole row AND column.'),
                        _rule(2,
                            'Match 5 to forge a Prismatic Diamond \u2014 swap it with any gem to clear every gem of that kind. Two Prismatics together clear the whole tray!'),
                        _rule(3,
                            'Match in an L or T shape to forge a Brilliant \u2014 swap it to blast a 3\u00d73 area.'),
                        _rule(4,
                            'A swap that makes no match bounces back and costs nothing. Special gems always work, even swapped with a non-matching gem.'),
                        _rule(0,
                            'ATELIERS: each has a target score and a move limit. From Atelier 6 you must also collect quota gems. Leftover moves polish your score: +250 each.'),
                        _rule(1,
                            'ENDLESS: no clock, no move limit \u2014 chase the highest score. Your best is engraved on the menu.'),
                        _rule(2,
                            'TIMED: 2 minutes, unlimited moves \u2014 score as much as you can before the clock runs out.'),
                        _rule(3,
                            'Stuck with no moves? The tray reshuffles itself, free of charge.'),
                        _rule(4,
                            'The apprentice\u2019s loupe (hint button) suggests a swap \u2014 3 free per atelier, then 5 coins each. PRO jewelers get unlimited hints.'),
                        _rule(5,
                            'Coins: 1 per 1,000 points, plus 20 for completing an atelier. Spend them on hints and the tip jar.'),
                        const SizedBox(height: 12),
                        Center(
                          child: BrassButton(
                            label: 'TO THE BENCH',
                            fontSize: 16,
                            onTap: () {
                              sound.play(SfxKind.click);
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rule(int gem, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 8),
            child: GemStone(type: gem % 6, size: 16),
          ),
          Expanded(child: Text(text, style: Atelier.body)),
        ],
      ),
    );
  }
}
