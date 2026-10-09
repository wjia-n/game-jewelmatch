import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/atelier.dart';
import '../state/settings.dart';
import '../audio/sound_engine.dart';
import '../engine/game.dart';
import '../services/iap_service.dart';
import 'widgets.dart';
import 'board_screen.dart';
import 'settings_screen.dart';
import 'theme_screen.dart';
import 'pro_screen.dart';
import 'how_to_play.dart';

/// Main menu — Stitch screen 1: walnut case, velvet backdrop, brass title
/// plaque, scattered faceted gems with a brass loupe, and brass plaque
/// buttons. Plus: profile name, offline modes (ateliers / endless / timed),
/// theme picker, Pro store and How to Play.
class MenuScreen extends StatefulWidget {
  final AtelierSettings settings;
  final SoundEngine sound;
  final StoreService store;
  const MenuScreen({
    super.key,
    required this.settings,
    required this.sound,
    required this.store,
  });

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
      widget.sound.onAppBackground();
    } else if (state == AppLifecycleState.resumed) {
      widget.sound.onAppForeground();
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

  void _openLevels(int level, {bool restore = false}) {
    widget.sound.play(SfxKind.click);
    widget.sound.startGameMusic();
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => BoardScreen(
                  settings: widget.settings,
                  sound: widget.sound,
                  store: widget.store,
                  mode: GameMode.levels,
                  level: level,
                  restore: restore,
                )))
        .then((_) {
      widget.sound.startMenuMusic();
      _checkSave();
      if (mounted) setState(() {});
    });
  }

  void _openEndless() {
    widget.sound.play(SfxKind.click);
    widget.sound.startGameMusic();
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => BoardScreen(
                  settings: widget.settings,
                  sound: widget.sound,
                  store: widget.store,
                  mode: GameMode.endless,
                )))
        .then((_) {
      widget.sound.startMenuMusic();
      if (mounted) setState(() {});
    });
  }

  void _openTimed() {
    widget.sound.play(SfxKind.click);
    widget.sound.startGameMusic();
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => BoardScreen(
                  settings: widget.settings,
                  sound: widget.sound,
                  store: widget.store,
                  mode: GameMode.timed,
                  timedSeconds: 120,
                )))
        .then((_) {
      widget.sound.startMenuMusic();
      if (mounted) setState(() {});
    });
  }

  Future<void> _editProfile() async {
    widget.sound.play(SfxKind.click);
    final ctrl =
        TextEditingController(text: widget.settings.profileName);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: WalnutPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('YOUR NAME, JEWELER',
                  style: Atelier.display
                      .copyWith(fontSize: 20, letterSpacing: 2)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLength: 18,
                textAlign: TextAlign.center,
                style: Atelier.numeral.copyWith(fontSize: 20),
                decoration: InputDecoration(
                  filled: true,
                  fillColor:
                      Colors.black.withValues(alpha: 0.35),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Atelier.brass),
                  ),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 14),
              BrassButton(
                label: 'ENGRAVE IT',
                fontSize: 16,
                onTap: () =>
                    Navigator.of(context).pop(ctrl.text),
              ),
            ],
          ),
        ),
      ),
    );
    if (name != null) {
      await widget.settings.setProfileName(name);
      if (mounted) setState(() {});
    }
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
                  Text('\u2726  THE VINTAGE JEWELER\u2019S ATELIER  \u2726',
                      textAlign: TextAlign.center,
                      style: Atelier.caption
                          .copyWith(letterSpacing: 3, fontSize: 12)),
                  const SizedBox(height: 12),
                  // Hero: velvet tray of scattered gems + brass loupe.
                  _GemTray(gemStyleId: s.gemStyleId),
                  const SizedBox(height: 14),
                  BrassPlaque(
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
                  const SizedBox(height: 10),
                  // Profile + purse row.
                  AnimatedBuilder(
                    animation: s,
                    builder: (_, _) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _editProfile,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black
                                  .withValues(alpha: 0.35),
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                  color: Atelier.brass
                                      .withValues(alpha: 0.6)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person,
                                    color: Atelier.brassBright,
                                    size: 16),
                                const SizedBox(width: 6),
                                Text(s.profileName,
                                    style: Atelier.numeral
                                        .copyWith(fontSize: 15)),
                                const SizedBox(width: 4),
                                Icon(Icons.edit,
                                    color: Atelier.creamDim,
                                    size: 13),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _counter(Icons.monetization_on,
                            '${s.coins}', Atelier.coinGold),
                        if (s.proUnlocked) ...[
                          const SizedBox(width: 10),
                          _proBadge(),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const EngravedDivider(),
                  const SizedBox(height: 14),
                  // ---- mode cards ----
                  SizedBox(
                    width: double.infinity,
                    child: BrassButton(
                      label: _hasSave
                          ? 'CONTINUE ATELIER $_saveLevel'
                          : 'ATELIERS · BEGIN $nextLevel',
                      sublabel: _hasSave
                          ? 'Resume your work at the bench'
                          : 'Target ${LevelConfig.targetFor(nextLevel)} pts \u00b7 ${LevelConfig.movesFor(nextLevel)} moves',
                      onTap: () => _openLevels(
                          _hasSave ? _saveLevel : nextLevel,
                          restore: _hasSave),
                    ),
                  ),
                  if (_hasSave) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: BrassButton(
                        label: 'NEW \u00b7 ATELIER $nextLevel',
                        primary: false,
                        fontSize: 16,
                        onTap: () {
                          MidGameSave.clear();
                          _openLevels(nextLevel);
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _ModeCard(
                          title: 'ENDLESS',
                          sub: s.endlessBest > 0
                              ? 'Best ${s.endlessBest}'
                              : 'No clock, no limit',
                          icon: Icons.all_inclusive,
                          onTap: _openEndless,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ModeCard(
                          title: 'TIMED',
                          sub: s.timedBest > 0
                              ? 'Best ${s.timedBest}'
                              : '2 minutes of fire',
                          icon: Icons.timer,
                          onTap: _openTimed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: BrassButton(
                          label: 'THEMES',
                          primary: false,
                          fontSize: 15,
                          onTap: () {
                            widget.sound.play(SfxKind.click);
                            Navigator.of(context)
                                .push(MaterialPageRoute(
                                    builder: (_) => ThemeScreen(
                                        settings: s,
                                        sound: widget.sound,
                                        store: widget.store)))
                                .then((_) {
                              if (mounted) setState(() {});
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: BrassButton(
                          label: s.proUnlocked ? 'PRO \u2713' : 'GET PRO',
                          primary: false,
                          fontSize: 15,
                          onTap: () {
                            widget.sound.play(SfxKind.click);
                            Navigator.of(context)
                                .push(MaterialPageRoute(
                                    builder: (_) => ProScreen(
                                        settings: s,
                                        sound: widget.sound,
                                        store: widget.store)))
                                .then((_) {
                              if (mounted) setState(() {});
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: BrassButton(
                          label: 'HOW TO PLAY',
                          primary: false,
                          fontSize: 15,
                          onTap: () {
                            widget.sound.play(SfxKind.click);
                            Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        HowToPlayScreen(
                                            sound: widget.sound)));
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: BrassButton(
                          label: 'SETTINGS',
                          primary: false,
                          fontSize: 15,
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
                  AnimatedBuilder(
                    animation: s,
                    builder: (_, _) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _counter(Icons.star, '${s.totalStars()}',
                            Atelier.brassBright),
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

  Widget _proBadge() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [Atelier.brassBright, Atelier.brass],
        ),
      ),
      child: Text('PRO',
          style: Atelier.numeralOnBrass.copyWith(fontSize: 13)),
    );
  }
}

/// Small brass mode card for Endless / Timed.
class _ModeCard extends StatelessWidget {
  final String title;
  final String sub;
  final IconData icon;
  final VoidCallback onTap;
  const _ModeCard(
      {required this.title,
      required this.sub,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Atelier.walnutMid, Atelier.walnutDark],
          ),
          border: Border.all(color: Atelier.brass, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Colors.black54,
                blurRadius: 8,
                offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Atelier.brassBright, size: 26),
            const SizedBox(height: 6),
            Text(title,
                style: Atelier.display
                    .copyWith(fontSize: 16, letterSpacing: 2)),
            const SizedBox(height: 2),
            Text(sub,
                style: Atelier.caption.copyWith(fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Velvet tray of scattered faceted gems with a brass loupe.
class _GemTray extends StatelessWidget {
  final String gemStyleId;
  const _GemTray({required this.gemStyleId});

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
              size: size,
              styleId: gemStyleId),
        ),
      ));
    }
    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Atelier.velvetNavy,
            Atelier.velvetNavyDeep,
            const Color(0xFF0D1322),
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
      ..shader = LinearGradient(
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
          ..shader = RadialGradient(
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
