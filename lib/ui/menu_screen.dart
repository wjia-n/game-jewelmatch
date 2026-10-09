import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/atelier.dart';
import '../state/settings.dart';
import '../audio/sound_engine.dart';
import '../engine/game.dart';
import 'widgets.dart';
import 'board_screen.dart';
import 'settings_screen.dart';

/// Main menu — Stitch screen 1: walnut case, burgundy velvet backdrop,
/// brass title plaque, a velvet tray of scattered faceted gems with a
/// brass loupe, and brass plaque buttons.
class MenuScreen extends StatefulWidget {
  final AtelierSettings settings;
  final SoundEngine sound;
  const MenuScreen(
      {super.key, required this.settings, required this.sound});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with WidgetsBindingObserver {
  bool _hasSave = false;
  int _saveLevel = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.sound.startMenuMusic();
    _checkSave();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      widget.sound.stopMusic();
    } else if (state == AppLifecycleState.resumed) {
      widget.sound.startMenuMusic();
    }
  }

  Future<void> _checkSave() async {
    final data = await MidGameSave.load();
    if (!mounted) return;
    setState(() {
      _hasSave = data != null;
      _saveLevel = data == null
          ? 1
          : ((data['level'] as num?)?.toInt() ?? 1);
    });
  }

  void _openAtelier(int level, {bool restore = false}) {
    widget.sound.play(SfxKind.click);
    widget.sound.startGameMusic();
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => BoardScreen(
                  settings: widget.settings,
                  sound: widget.sound,
                  level: level,
                  restore: restore,
                )))
        .then((_) {
      widget.sound.startMenuMusic();
      _checkSave();
      if (mounted) setState(() {});
    });
  }

  void _showHowToPlay() {
    widget.sound.play(SfxKind.click);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: WalnutPanel(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Text('HOW TO PLAY',
                        style: Atelier.display.copyWith(
                            fontSize: 22, letterSpacing: 2))),
                const SizedBox(height: 8),
                const EngravedDivider(),
                const SizedBox(height: 12),
                _rule(0,
                    'Swap adjacent gems to line up 3 or more of a kind. Matched gems are cleared, the rest fall, and cascades multiply your score.'),
                _rule(1,
                    'Match 4 to forge a Faceted Bar — swap it to clear a whole row and column.'),
                _rule(2,
                    'Match 5 to forge a Prismatic Diamond — swap it to clear every gem of a kind.'),
                _rule(3,
                    'Match in an L or T shape to forge a Brilliant — swap it to blast a 3×3 area.'),
                _rule(4,
                    'Each move counts. Reach the atelier\'s target score before your moves run out. From Atelier 6, you must also collect the quota gems.'),
                _rule(5,
                    'Leftover moves polish your score: +250 each. Stuck? The apprentice\'s loupe offers a hint — 3 free per atelier.'),
                const SizedBox(height: 12),
                Center(
                  child: BrassButton(
                    label: 'TO THE BENCH',
                    fontSize: 16,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
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

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final nextLevel = s.unlockedLevel;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VelvetBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('✦  THE VINTAGE JEWELER\'S ATELIER  ✦',
                      textAlign: TextAlign.center,
                      style: Atelier.caption
                          .copyWith(letterSpacing: 3, fontSize: 12)),
                  const SizedBox(height: 12),
                  // Hero: velvet tray of scattered gems + brass loupe.
                  _GemTray(),
                  const SizedBox(height: 14),
                  const BrassPlaque(
                      text: 'JEWEL MATCH',
                      fontSize: 34,
                      letterSpacing: 5),
                  const SizedBox(height: 8),
                  Text(
                    'Cut gems. Forge specials.\nComplete every atelier.',
                    textAlign: TextAlign.center,
                    style: Atelier.bodyItalic
                        .copyWith(color: Atelier.creamDim),
                  ),
                  const SizedBox(height: 6),
                  const EngravedDivider(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: BrassButton(
                      label: _hasSave
                          ? 'CONTINUE ATELIER $_saveLevel'
                          : 'BEGIN ATELIER $nextLevel',
                      sublabel: _hasSave
                          ? 'Resume your work at the bench'
                          : 'Target ${LevelConfig.targetFor(nextLevel)} pts · ${LevelConfig.movesFor(nextLevel)} moves',
                      onTap: () => _openAtelier(
                          _hasSave ? _saveLevel : nextLevel,
                          restore: _hasSave),
                    ),
                  ),
                  if (_hasSave) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: BrassButton(
                        label: 'NEW · ATELIER $nextLevel',
                        primary: false,
                        fontSize: 16,
                        onTap: () {
                          MidGameSave.clear();
                          _openAtelier(nextLevel);
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: BrassButton(
                          label: 'HOW TO PLAY',
                          primary: false,
                          fontSize: 16,
                          onTap: _showHowToPlay,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: BrassButton(
                          label: 'SETTINGS',
                          primary: false,
                          fontSize: 16,
                          onTap: () {
                            widget.sound.play(SfxKind.click);
                            Navigator.of(context)
                                .push(MaterialPageRoute(
                                    builder: (_) => SettingsScreen(
                                        settings: s,
                                        sound: widget.sound)))
                                .then((_) {
                              if (mounted) setState(() {});
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Coin purse + star tally.
                  AnimatedBuilder(
                    animation: s,
                    builder: (_, _) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _counter(Icons.monetization_on,
                            '${s.coins}', Atelier.coinGold),
                        const SizedBox(width: 24),
                        _counter(Icons.star,
                            '${s.totalStars()}', Atelier.brassBright),
                        const SizedBox(width: 24),
                        _counter(Icons.workspace_premium,
                            'ATELIER ${s.unlockedLevel}',
                            Atelier.creamDim),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _counter(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Text(text,
            style:
                Atelier.numeral.copyWith(fontSize: 16, color: color)),
      ],
    );
  }
}

/// Velvet tray of scattered faceted gems with a brass loupe.
class _GemTray extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rng = Random(20261009);
    final gems = <Widget>[];
    for (int i = 0; i < 9; i++) {
      final size = 34.0 + rng.nextDouble() * 26;
      gems.add(Positioned(
        left: 8 + rng.nextDouble() * 240,
        top: 6 + rng.nextDouble() * 120,
        child: Transform.rotate(
          angle: (rng.nextDouble() - 0.5) * 0.6,
          child: GemStone(
              type: i % 6,
              special: i == 4 ? 2 : 0,
              size: size),
        ),
      ));
    }
    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Atelier.velvetNavy,
            Atelier.velvetNavyDeep,
            Color(0xFF0D1322),
          ],
        ),
        border: Border.all(color: Atelier.walnutDark, width: 5),
        boxShadow: const [
          BoxShadow(
              color: Colors.black54,
              blurRadius: 14,
              offset: Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          children: [
            ...gems,
            // brass loupe
            Positioned(
              right: 14,
              bottom: 10,
              child: Transform.rotate(
                angle: 0.5,
                child: _Loupe(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Decorative brass loupe.
class _Loupe extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 110,
      child: CustomPaint(painter: _LoupePainter()),
    );
  }
}

class _LoupePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.32);
    final r = size.width * 0.44;
    // handle
    final handle = Paint()
      ..shader = const LinearGradient(
        colors: [Atelier.walnutLight, Atelier.walnutDark],
      ).createShader(
          Rect.fromLTWH(c.dx - 8, c.dy + r * 0.7, 16, size.height * 0.4));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(c.dx - 8, c.dy + r * 0.7, 16,
                size.height * 0.38),
            const Radius.circular(7)),
        handle);
    // brass ring
    canvas.drawCircle(
        c + const Offset(2, 3), r, Paint()..color = Colors.black45);
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.3, -0.3),
            colors: [
              Atelier.brassBright,
              Atelier.brass,
              Atelier.brassDeep
            ],
          ).createShader(Rect.fromCircle(center: c, radius: r)));
    // glass
    canvas.drawCircle(
        c,
        r * 0.78,
        Paint()
          ..color = const Color(0xFFDCE6EC).withValues(alpha: 0.35));
    canvas.drawCircle(
        c,
        r * 0.78,
        Paint()
          ..color = Atelier.brassDeep
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    // glass glint
    canvas.drawOval(
      Rect.fromCenter(
          center: c + Offset(-r * 0.3, -r * 0.35),
          width: r * 0.5,
          height: r * 0.3),
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
