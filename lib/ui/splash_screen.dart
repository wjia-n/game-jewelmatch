import 'package:flutter/material.dart';
import '../theme/atelier.dart';
import '../state/settings.dart';
import '../audio/sound_engine.dart';
import '../services/iap_service.dart';
import 'menu_screen.dart';
import 'widgets.dart';

/// Launch splash — the single splash moment per MASTER_RULES.md:
/// game logo + game name, an animated loading line, and the
/// "Credits: WAJIHA" line with the official company logo.
///
/// While it shows: pre-warms audio, starts menu music, initializes the
/// Play Billing store, and applies the player's atelier theme.
class SplashScreen extends StatefulWidget {
  final AtelierSettings settings;
  final SoundEngine sound;
  final StoreService store;
  const SplashScreen({
    super.key,
    required this.settings,
    required this.sound,
    required this.store,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  String _status = 'Lighting the lamp…';

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _run();
  }

  Future<void> _run() async {
    _loader.forward();
    // Pre-warm audio while the splash shows, then start menu music.
    widget.sound.prewarm();
    setState(() => _status = 'Polishing the gems…');
    await widget.store.init();
    if (widget.store.proPurchased.value) {
      // A restored/known Pro purchase is mirrored into settings.
      await widget.settings.setProUnlocked(true);
    }
    widget.store.proPurchased.addListener(_onPro);
    setState(() => _status = 'Setting the tray…');
    widget.sound.startMenuMusic();
    await Future.delayed(const Duration(milliseconds: 2100));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          settings: widget.settings,
          sound: widget.sound,
          store: widget.store,
        ),
      ),
    );
  }

  void _onPro() {
    if (widget.store.proPurchased.value) {
      widget.settings.setProUnlocked(true);
    }
  }

  @override
  void dispose() {
    widget.store.proPurchased.removeListener(_onPro);
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Atelier.velvetDeep,
      body: VelvetBackdrop(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Atelier.brass, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      offset: const Offset(0, 10),
                      blurRadius: 24,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/jewelmatch_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.diamond,
                    size: 90,
                    color: Atelier.brassBright,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'JEWEL MATCH',
                style: Atelier.display.copyWith(fontSize: 40),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'THE VINTAGE JEWELER\u2019S ATELIER',
                style: Atelier.caption.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 30),
              // Animated loading line.
              SizedBox(
                width: 220,
                child: AnimatedBuilder(
                  animation: _loader,
                  builder: (_, _) => Column(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.black.withValues(alpha: 0.45),
                          border: Border.all(
                              color: Atelier.brass.withValues(alpha: 0.5)),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _loader.value.clamp(0.02, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: LinearGradient(
                                colors: [
                                  Atelier.brassBright,
                                  Atelier.brass,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _loader.value < 1 ? _status : 'Ready!',
                        style: Atelier.body.copyWith(
                            fontSize: 13,
                            color: Atelier.creamDim,
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 44),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/wajiha_logo.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(
                        width: 30, height: 30),
                  ),
                  const SizedBox(width: 10),
                  Text('Credits: WAJIHA',
                      style: Atelier.caption.copyWith(fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
