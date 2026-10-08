import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const JewelMatchApp());

class JewelMatchApp extends StatelessWidget {
  const JewelMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.elegantSerif,
      title: 'Jewel Match',
      tagline: 'Swap and blast sparkling gems in a 60-second score attack. Shiny chaos!',
      emoji: '💎',
      slug: 'jewelmatch',
      howToPlay:
          '• Swap two neighboring gems to line up 3 or more — they pop, gems fall, cascades rain!\n• Match 4 to forge a LINE BLASTER, match 5 for a COLOR BURST. Chain cascades for a combo multiplier!\n• 60 seconds on the clock. Most points wins — yes, you\'re competing with yourself. Beat that best score! 💎',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) => JewelMatchScreen(players: players, callbacks: cb),
    );
  }
}
