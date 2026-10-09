import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../theme/atelier.dart';
import '../state/settings.dart';
import '../audio/sound_engine.dart';
import '../engine/game.dart';
import 'widgets.dart';
import 'gameover_screen.dart';
import 'settings_screen.dart';

/// Gameplay — Stitch screen 2: top bar (atelier plaque, moves dial,
/// goal plaque, pause), 8×8 recessed velvet cells with faceted gems,
/// brass score plate + progress, quota insets, apprentice hint loupe.
class BoardScreen extends StatefulWidget {
  final AtelierSettings settings;
  final SoundEngine sound;
  final int level;
  final bool restore;
  const BoardScreen({
    super.key,
    required this.settings,
    required this.sound,
    required this.level,
    this.restore = false,
  });

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen>
    with WidgetsBindingObserver {
  late final JewelEngine _engine;
  bool _pausedUi = false;
  String _banner = '';
  int _bannerId = 0;
  List<int>? _hint;
  Timer? _hintTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = JewelEngine();
    _engine.addListener(_onEngine);
    if (widget.restore) {
      MidGameSave.load().then((data) {
        if (!mounted) return;
        if (data != null && _engine.restore(data)) {
          setState(() {});
        } else {
          _engine.startLevel(widget.level);
        }
        widget.sound.play(SfxKind.start);
      });
    } else {
      _engine.startLevel(widget.level);
      MidGameSave.clear();
      widget.sound.play(SfxKind.start);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hintTimer?.cancel();
    _engine.removeListener(_onEngine);
    _engine.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      widget.sound.stopMusic();
      if (!_engine.over) {
        MidGameSave.save(_engine.toJson()); // RULES.md §12
      }
    } else if (state == AppLifecycleState.resumed) {
      widget.sound.startGameMusic();
    }
  }

  void _onEngine() {
    if (_navigated) return;
    for (final e in _engine.takeEvents()) {
      _handleEvent(e);
    }
    if (mounted) setState(() {});
  }

  Future<void> _handleEvent(EngineEvent e) async {
    final sound = widget.sound;
    switch (e.kind) {
      case EngineEventKind.select:
        sound.play(SfxKind.select, vol: 0.6);
        break;
      case EngineEventKind.swap:
        if (e.text == 'detonate') {
          sound.play(SfxKind.detonate);
        } else {
          sound.play(SfxKind.swap);
        }
        break;
      case EngineEventKind.invalid:
        sound.play(SfxKind.invalid);
        _showBanner('No match — the gems settle back');
        break;
      case EngineEventKind.match:
        sound.playMatch(e.step, e.gems);
        if (e.step > 1) _showBanner('CASCADE ×${min(e.step, 8)}!');
        break;
      case EngineEventKind.specialCreated:
        sound.play(SfxKind.specialCreate);
        _showBanner(switch (e.specialKind) {
          2 => 'PRISMATIC DIAMOND FORGED!',
          3 => 'BRILLIANT FORGED!',
          _ => 'FACETED BAR FORGED!',
        });
        break;
      case EngineEventKind.detonated:
        sound.play(SfxKind.detonate);
        break;
      case EngineEventKind.shuffled:
        sound.play(SfxKind.shuffle);
        _showBanner('Tray Reshuffled');
        break;
      case EngineEventKind.hintUsed:
        sound.play(SfxKind.hint);
        break;
      case EngineEventKind.quotaMet:
        _showBanner('Quota collected!');
        break;
      case EngineEventKind.polishingBonus:
        sound.play(SfxKind.coin);
        break;
      case EngineEventKind.moveDone:
        MidGameSave.save(_engine.toJson()); // RULES.md §12
        break;
      case EngineEventKind.win:
        await _onWin(int.parse(e.text), e.gems);
        break;
      case EngineEventKind.lose:
        await _onLose(int.parse(e.text));
        break;
      case EngineEventKind.notice:
        _showBanner(e.text);
        break;
    }
  }

  void _showBanner(String text) {
    final id = ++_bannerId;
    setState(() => _banner = text);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted && _bannerId == id) setState(() => _banner = '');
    });
  }

  Future<void> _onWin(int coins, int stars) async {
    _navigated = true;
    await widget.settings.recordWin(
        _engine.level, _engine.score, stars);
    await widget.settings.earnCoins(coins);
    await MidGameSave.clear();
    await widget.sound.play(SfxKind.win);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameOverScreen(
          settings: widget.settings,
          sound: widget.sound,
          result: LevelResult(
            level: _engine.level,
            won: true,
            score: _engine.score,
            target: _engine.target,
            stars: stars,
            coins: coins,
            polishingBonus: _engine.movesLeft * 250,
            bestCombo: _engine.bestCombo,
            quota: _engine.quota,
            quotaCollected: _engine.quotaCollected,
          ),
        ),
      ),
    );
  }

  Future<void> _onLose(int coins) async {
    _navigated = true;
    if (coins > 0) await widget.settings.earnCoins(coins);
    await MidGameSave.clear();
    await widget.sound.play(SfxKind.lose);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameOverScreen(
          settings: widget.settings,
          sound: widget.sound,
          result: LevelResult(
            level: _engine.level,
            won: false,
            score: _engine.score,
            target: _engine.target,
            stars: 0,
            coins: coins,
            polishingBonus: 0,
            bestCombo: _engine.bestCombo,
            quota: _engine.quota,
            quotaCollected: _engine.quotaCollected,
          ),
        ),
      ),
    );
  }

  void _togglePause() {
    widget.sound.play(SfxKind.click);
    setState(() {
      _pausedUi = !_pausedUi;
      _engine.setPaused(_pausedUi);
    });
  }

  void _resume() {
    widget.sound.play(SfxKind.click);
    setState(() {
      _pausedUi = false;
      _engine.setPaused(false);
    });
  }

  void _restart() {
    widget.sound.play(SfxKind.start);
    setState(() {
      _pausedUi = false;
      _engine.setPaused(false);
      _hint = null;
    });
    _engine.restart();
    MidGameSave.clear();
  }

  void _quitToMenu() {
    widget.sound.play(SfxKind.click);
    if (!_engine.over) {
      MidGameSave.save(_engine.toJson());
    }
    Navigator.of(context).pop();
  }

  Future<void> _useHint() async {
    if (_engine.busy || _engine.over || _engine.paused) return;
    final free = _engine.hintsUsed < 3;
    if (!free) {
      final ok = await widget.settings.spendCoins(5);
      if (!ok) {
        _showBanner('Not enough coins for the apprentice');
        widget.sound.play(SfxKind.invalid);
        return;
      }
    }
    final hint = _engine.computeHint();
    if (hint == null) {
      _showBanner('No move found — reshuffling soon');
      return;
    }
    _engine.markHintUsed();
    widget.sound.play(SfxKind.hint);
    setState(() => _hint = hint);
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _hint = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final e = _engine;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VelvetBackdrop(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // ---- top bar ----
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
                    child: Row(
                      children: [
                        BrassIconButton(
                          icon: Icons.arrow_back,
                          size: 42,
                          onTap: _quitToMenu,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: BrassPlaque(
                            text: 'ATELIER ${e.level}',
                            fontSize: 17,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        MovesDial(moves: e.movesLeft, size: 56),
                        const SizedBox(width: 8),
                        BrassIconButton(
                          icon: _pausedUi
                              ? Icons.play_arrow
                              : Icons.pause,
                          size: 42,
                          onTap: _togglePause,
                        ),
                      ],
                    ),
                  ),
                  // ---- score + quota ----
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScorePlate(score: e.score, target: e.target),
                        if (e.quota != null) ...[
                          const SizedBox(width: 10),
                          QuotaInset(
                            tier: e.quota!.tier,
                            collected: e.quotaCollected,
                            count: e.quota!.count,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // ---- banner ----
                  SizedBox(
                    height: 28,
                    child: AnimatedOpacity(
                      opacity: _banner.isEmpty ? 0 : 1,
                      duration:
                          const Duration(milliseconds: 200),
                      child: Text(_banner,
                          style: Atelier.display.copyWith(
                              fontSize: 16,
                              letterSpacing: 2,
                              color: Atelier.brassBright)),
                    ),
                  ),
                  // ---- board ----
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _GemBoard(
                            engine: e,
                            hint: _hint,
                            onTap: (r, c) => e.tapCell(r, c),
                            onFlick: (r, c, dr, dc) =>
                                e.flick(r, c, dr, dc),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ---- bottom bar ----
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 2, 16, 10),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        BrassIconButton(
                          icon: Icons.search,
                          size: 46,
                          badge: e.hintsUsed < 3
                              ? 'FREE'
                              : '5c',
                          onTap: _useHint,
                        ),
                        Text(
                          'Best cascade ×${e.bestCombo}',
                          style: Atelier.caption,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on,
                                color: Atelier.coinGold, size: 18),
                            const SizedBox(width: 4),
                            AnimatedBuilder(
                              animation: widget.settings,
                              builder: (_, _) => Text(
                                  '${widget.settings.coins}',
                                  style: Atelier.numeral
                                      .copyWith(fontSize: 15)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // ---- pause overlay ----
              if (_pausedUi)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.62),
                    child: Center(
                      child: WalnutPanel(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('PAUSED',
                                style: Atelier.display.copyWith(
                                    fontSize: 28,
                                    letterSpacing: 4)),
                            const SizedBox(height: 6),
                            Text(
                                'The bench waits. Your atelier is safe.',
                                style: Atelier.bodyItalic.copyWith(
                                    color: Atelier.creamDim)),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: 240,
                              child: BrassButton(
                                  label: 'RESUME',
                                  onTap: _resume),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: 240,
                              child: BrassButton(
                                  label: 'RESTART',
                                  primary: false,
                                  fontSize: 16,
                                  onTap: _restart),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: 240,
                              child: BrassButton(
                                  label: 'SETTINGS',
                                  primary: false,
                                  fontSize: 16,
                                  onTap: () {
                                    widget.sound
                                        .play(SfxKind.click);
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(
                                            builder: (_) =>
                                                SettingsScreen(
                                                  settings:
                                                      widget.settings,
                                                  sound:
                                                      widget.sound,
                                                )));
                                  }),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: 240,
                              child: BrassButton(
                                  label: 'LEAVE BENCH',
                                  primary: false,
                                  fontSize: 16,
                                  onTap: _quitToMenu),
                            ),
                          ],
                        ),
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
}

/// Animated 8×8 board: recessed velvet cells, faceted gems, swap/clear/fall
/// motion from the engine's animation metadata, tap + flick input.
class _GemBoard extends StatefulWidget {
  final JewelEngine engine;
  final List<int>? hint;
  final void Function(int r, int c) onTap;
  final void Function(int r, int c, int dr, int dc) onFlick;
  const _GemBoard({
    required this.engine,
    required this.hint,
    required this.onTap,
    required this.onFlick,
  });

  @override
  State<_GemBoard> createState() => _GemBoardState();
}

class _GemBoardState extends State<_GemBoard>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  int _panR = -1, _panC = -1;
  bool _panFired = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (mounted) setState(() {});
    });
    widget.engine.addListener(_syncTicker);
    _syncTicker();
  }

  @override
  void dispose() {
    widget.engine.removeListener(_syncTicker);
    _ticker.dispose();
    super.dispose();
  }

  void _syncTicker() {
    final e = widget.engine;
    final active = e.swapAnim != null ||
        e.clearAnim != null ||
        e.fallAnim != null ||
        e.spawnCell != null;
    if (active && !_ticker.isActive) {
      _ticker.start();
    } else if (!active && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void didUpdateWidget(covariant _GemBoard old) {
    super.didUpdateWidget(old);
    _syncTicker();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, cons) {
        final size = min(cons.maxWidth, cons.maxHeight);
        final cell = size / kBoardN;
        return SizedBox(
          width: size,
          height: size,
          child: GestureDetector(
            onTapUp: (d) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final p = box.globalToLocal(d.globalPosition);
              final r =
                  (p.dy / cell).floor().clamp(0, kBoardN - 1);
              final c =
                  (p.dx / cell).floor().clamp(0, kBoardN - 1);
              widget.onTap(r, c);
            },
            onPanStart: (d) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final p = box.globalToLocal(d.globalPosition);
              _panR = (p.dy / cell).floor().clamp(0, kBoardN - 1);
              _panC = (p.dx / cell).floor().clamp(0, kBoardN - 1);
              _panFired = false;
            },
            onPanUpdate: (d) {
              if (_panFired || _panR < 0) return;
              final dx = d.delta.dx, dy = d.delta.dy;
              if (dx.abs() < 10 && dy.abs() < 10) return;
              _panFired = true;
              if (dx.abs() > dy.abs()) {
                widget.onFlick(
                    _panR, _panC, 0, dx > 0 ? 1 : -1);
              } else {
                widget.onFlick(
                    _panR, _panC, dy > 0 ? 1 : -1, 0);
              }
            },
            onPanEnd: (_) => _panR = -1,
            child: CustomPaint(
              painter: _BoardPainter(
                  engine: widget.engine, hint: widget.hint),
            ),
          ),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  final JewelEngine engine;
  final List<int>? hint;
  _BoardPainter({required this.engine, required this.hint});

  static const _swapDur = 170000; // microseconds
  static const _bounceDur = 300000;
  static const _clearDur = 200000;
  static const _fallDur = 240000;
  static const _spawnDur = 260000;

  double _progress(int t0, int dur) {
    final now = DateTime.now().microsecondsSinceEpoch;
    return ((now - t0) / dur).clamp(0.0, 1.0);
  }

  double _easeInOut(double t) =>
      t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2;
  double _easeOut(double t) => 1 - pow(1 - t, 3).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / kBoardN;
    final e = engine;

    // Tray: walnut rim + navy velvet bed.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(14)),
      Paint()..color = Atelier.walnutDark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(5, 5, size.width - 10, size.height - 10),
          const Radius.circular(10)),
      Paint()..color = Atelier.velvetNavyDeep,
    );
    // top-left lamplight edge on the tray
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(5, 5, size.width - 10, size.height - 10),
          const Radius.circular(10)),
      Paint()
        ..color = Atelier.brassBright.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);

    final swap = e.swapAnim;
    final clear = e.clearAnim;
    final fall = e.fallAnim;
    final swapT = swap == null
        ? 1.0
        : _progress(swap.t0, swap.bounce ? _bounceDur : _swapDur);
    final clearT =
        clear == null ? 1.0 : _progress(clear.t0, _clearDur);
    final fallT = fall == null ? 1.0 : _progress(fall.t0, _fallDur);
    final spawnT = e.spawnCell == null
        ? 1.0
        : _progress(e.spawnT0, _spawnDur);

    for (int r = 0; r < kBoardN; r++) {
      for (int c = 0; c < kBoardN; c++) {
        final x = c * cell, y = r * cell;
        // recessed velvet cell
        final cellRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(
                x + 2, y + 2, cell - 4, cell - 4),
            const Radius.circular(8));
        canvas.drawRRect(
            cellRect, Paint()..color = Atelier.velvetNavy);
        canvas.drawLine(
            Offset(x + 6, y + 3), Offset(x + cell - 6, y + 3),
            Paint()
              ..color = Colors.black.withValues(alpha: 0.45)
              ..strokeWidth = 2);
        canvas.drawLine(
            Offset(x + 6, y + cell - 3),
            Offset(x + cell - 6, y + cell - 3),
            Paint()
              ..color =
                  Atelier.brassBright.withValues(alpha: 0.10)
              ..strokeWidth = 1.5);

        final g = e.board[r][c];
        if (g == null) continue;
        final key = '$r,$c';

        var dx = 0.0, dy = 0.0;
        var scale = 1.0, alpha = 1.0;

        // swap / bounce-back motion
        if (swap != null && swapT < 1.0) {
          if (r == swap.r1 && c == swap.c1) {
            final k = swap.bounce
                ? sin(pi * swapT)
                : _easeInOut(swapT);
            dx = (swap.c2 - swap.c1) * k * cell;
            dy = (swap.r2 - swap.r1) * k * cell;
          } else if (r == swap.r2 && c == swap.c2) {
            final k = swap.bounce
                ? sin(pi * swapT)
                : _easeInOut(swapT);
            dx = (swap.c1 - swap.c2) * k * cell;
            dy = (swap.r1 - swap.r2) * k * cell;
          }
        }
        // clearing pop
        if (clear != null &&
            clear.cells.contains(key) &&
            clearT < 1.0) {
          scale = 1.0 - _easeInOut(clearT);
          alpha = 1.0 - clearT;
        }
        // falling
        if (fall != null &&
            fallT < 1.0 &&
            fall.fromRow.containsKey(key)) {
          final from = fall.fromRow[key]!;
          dy = (from - r) * cell * (1 - _easeOut(fallT));
        }

        final lifted =
            (r == e.selR && c == e.selC) || _inHint(r, c);
        var gemScale = scale * (lifted ? 1.1 : 1.0);
        if (e.spawnCell == key && spawnT < 1.0) {
          // scale-in pop for a newly forged special
          final s = _easeOut(spawnT);
          gemScale *= 0.3 + 0.7 * s;
        }

        final center = Offset(
            x + cell / 2 + dx, y + cell / 2 + dy);
        GemRenderer.paint(
            canvas, center, cell * 0.44, g.type, g.special,
            lifted: lifted && clearT >= 1.0,
            scale: gemScale,
            alpha: alpha);

        // hint ring
        if (_inHint(r, c)) {
          canvas.drawCircle(
              Offset(x + cell / 2, y + cell / 2),
              cell * 0.46,
              Paint()
                ..color = Atelier.brassBright
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3);
        }
        // selection ring
        if (r == e.selR && c == e.selC) {
          canvas.drawRRect(
              cellRect,
              Paint()
                ..color = Atelier.brassBright.withValues(alpha: 0.85)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.5);
        }
      }
    }
  }

  bool _inHint(int r, int c) {
    final h = hint;
    if (h == null) return false;
    return (r == h[0] && c == h[1]) || (r == h[2] && c == h[3]);
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) => true;
}
