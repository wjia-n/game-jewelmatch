import 'package:flutter/material.dart';
import '../theme/atelier.dart';
import '../state/settings.dart';
import '../audio/sound_engine.dart';
import '../engine/game.dart';
import '../services/iap_service.dart';
import 'widgets.dart';
import 'board_screen.dart';

/// Result payload passed from the board screen.
class LevelResult {
  final GameMode mode;
  final int level;
  final bool won;
  final int score;
  final int target;
  final int stars;
  final int coins;
  final int polishingBonus;
  final int bestCombo;
  final LevelQuota? quota;
  final int quotaCollected;
  final bool isNewBest;
  const LevelResult({
    this.mode = GameMode.levels,
    required this.level,
    required this.won,
    required this.score,
    required this.target,
    required this.stars,
    required this.coins,
    required this.polishingBonus,
    required this.bestCombo,
    required this.quota,
    required this.quotaCollected,
    this.isNewBest = false,
  });
}

/// Victory / game over — Stitch screen 3: an open walnut jewelry box with
/// velvet interior, brass star medals, diamond centerpiece, score tablet,
/// coin inset; Replay / Next Atelier / Menu. Defeat: "Atelier Closed".
/// Timed mode: "Time's Up". Endless: "Bench Rested".
class GameOverScreen extends StatefulWidget {
  final AtelierSettings settings;
  final SoundEngine sound;
  final StoreService store;
  final LevelResult result;
  const GameOverScreen({
    super.key,
    required this.settings,
    required this.sound,
    required this.store,
    required this.result,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.sound.startMenuMusic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      widget.sound.onAppBackground();
    } else if (state == AppLifecycleState.resumed) {
      widget.sound.onAppForeground();
    }
  }

  void _openLevel(int level) {
    widget.sound.play(SfxKind.click);
    widget.sound.startGameMusic();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BoardScreen(
          settings: widget.settings,
          sound: widget.sound,
          store: widget.store,
          mode: GameMode.levels,
          level: level,
        ),
      ),
    );
  }

  void _openEndless() {
    widget.sound.play(SfxKind.click);
    widget.sound.startGameMusic();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BoardScreen(
          settings: widget.settings,
          sound: widget.sound,
          store: widget.store,
          mode: GameMode.endless,
        ),
      ),
    );
  }

  void _openTimed() {
    widget.sound.play(SfxKind.click);
    widget.sound.startGameMusic();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BoardScreen(
          settings: widget.settings,
          sound: widget.sound,
          store: widget.store,
          mode: GameMode.timed,
          timedSeconds: 120,
        ),
      ),
    );
  }

  void _toMenu() {
    widget.sound.play(SfxKind.click);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  String get _title {
    final r = widget.result;
    switch (r.mode) {
      case GameMode.timed:
        return 'TIME\u2019S UP';
      case GameMode.endless:
        return 'BENCH RESTED';
      case GameMode.levels:
        return r.won ? 'ATELIER COMPLETE' : 'ATELIER CLOSED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final s = widget.settings;
    final isBest = r.mode == GameMode.levels
        ? (s.bestScores[r.level] ?? 0) == r.score && r.score > 0
        : r.isNewBest;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VelvetBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 26, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BrassPlaque(
                    text: _title,
                    fontSize: 24,
                    letterSpacing: 3,
                  ),
                  const SizedBox(height: 14),
                  // Jewelry box: walnut case, velvet interior.
                  _JewelryBox(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (r.won || r.mode != GameMode.levels) ...[
                          // diamond centerpiece
                          GemStone(
                              type: 5,
                              special: 2,
                              size: 64,
                              styleId: s.gemStyleId),
                          const SizedBox(height: 8),
                          if (r.mode == GameMode.levels)
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                for (int i = 0; i < 3; i++)
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 6),
                                    child: StarMedal(
                                        earned: i < r.stars,
                                        size: 52),
                                  ),
                              ],
                            )
                          else
                            Text(
                              r.mode == GameMode.timed
                                  ? 'Two minutes of fire \u2014 well cut, ${s.profileName}.'
                                  : 'The bench is yours whenever, ${s.profileName}.',
                              textAlign: TextAlign.center,
                              style: Atelier.bodyItalic.copyWith(
                                  color: Atelier.creamDim),
                            ),
                        ] else ...[
                          GemStone(
                              type: 0,
                              size: 56,
                              styleId: s.gemStyleId),
                          const SizedBox(height: 8),
                          Text(
                            'The target slipped away.\nThe bench is still warm \u2014 try again.',
                            textAlign: TextAlign.center,
                            style: Atelier.bodyItalic.copyWith(
                                color: Atelier.creamDim),
                          ),
                        ],
                        const SizedBox(height: 10),
                        const EngravedDivider(),
                        const SizedBox(height: 10),
                        // score tablet
                        Text(
                            r.mode == GameMode.levels
                                ? 'FINAL SCORE'
                                : 'SESSION SCORE',
                            style: Atelier.caption),
                        Text(_fmt(r.score),
                            style: Atelier.numeral.copyWith(
                                fontSize: 34,
                                color: Atelier.brassBright)),
                        Text(
                            r.mode == GameMode.levels
                                ? 'Target ${_fmt(r.target)}${isBest ? '  \u00b7  BEST' : ''}'
                                : isBest
                                    ? 'NEW BEST \u2726'
                                    : 'Best ${_fmt(r.mode == GameMode.timed ? s.timedBest : s.endlessBest)}',
                            style: Atelier.caption),
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            if (r.won && r.polishingBonus > 0)
                              _chip(
                                  Icons.auto_fix_high,
                                  'Polishing +${_fmt(r.polishingBonus)}'),
                            _chip(Icons.monetization_on,
                                '+${r.coins} coins'),
                            _chip(Icons.bolt,
                                'Best cascade \u00d7${r.bestCombo}'),
                            if (r.quota != null)
                              _chip(Icons.diamond,
                                  '${Atelier.gemNames[r.quota!.tier]} ${r.quotaCollected}/${r.quota!.count}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (r.mode == GameMode.levels && r.won)
                    SizedBox(
                      width: double.infinity,
                      child: BrassButton(
                        label:
                            'NEXT ATELIER \u00b7 ${r.level + 1}',
                        sublabel:
                            'Target ${_fmt(LevelConfig.targetFor(r.level + 1))} pts',
                        onTap: () => _openLevel(r.level + 1),
                      ),
                    )
                  else if (r.mode == GameMode.levels)
                    SizedBox(
                      width: double.infinity,
                      child: BrassButton(
                        label: 'TRY AGAIN',
                        sublabel:
                            'Atelier ${r.level} awaits',
                        onTap: () => _openLevel(r.level),
                      ),
                    )
                  else if (r.mode == GameMode.timed)
                    SizedBox(
                      width: double.infinity,
                      child: BrassButton(
                        label: 'ANOTHER 2 MINUTES',
                        onTap: _openTimed,
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: BrassButton(
                        label: 'BACK TO THE BENCH',
                        onTap: _openEndless,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: BrassButton(
                          label: 'REPLAY',
                          primary: false,
                          fontSize: 16,
                          onTap: () {
                            switch (r.mode) {
                              case GameMode.levels:
                                _openLevel(r.level);
                                break;
                              case GameMode.timed:
                                _openTimed();
                                break;
                              case GameMode.endless:
                                _openEndless();
                                break;
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: BrassButton(
                          label: 'MENU',
                          primary: false,
                          fontSize: 16,
                          onTap: _toMenu,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: Atelier.velvetNavyDeep,
        border: Border.all(color: Atelier.brassDeep, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Atelier.brassBright, size: 15),
          const SizedBox(width: 5),
          Text(text,
              style:
                  Atelier.caption.copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  static String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

/// Open walnut jewelry box with a velvet interior.
class _JewelryBox extends StatelessWidget {
  final Widget child;
  const _JewelryBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Atelier.walnutLight,
            Atelier.walnutMid,
            Atelier.walnutDark,
          ],
        ),
        border: Border.all(color: Atelier.brassDeep, width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Colors.black54,
              blurRadius: 16,
              offset: Offset(0, 7)),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.5),
            radius: 1.2,
            colors: [
              Atelier.velvet,
              Atelier.velvetDeep,
              const Color(0xFF220C13),
            ],
          ),
          border:
              Border.all(color: Atelier.walnutDark, width: 2),
        ),
        child: child,
      ),
    );
  }
}
