import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Jewel Match: 8x8 match-3 score attack. 60 seconds, cascades, combos,
/// line blasters (match 4) and color bursts (match 5).
const int _n = 8;
const int _types = 6;

class _Gem {
  int type;
  int special; // 0 none, 1 line blaster, 2 color burst
  int burstType; // for color burst: which gem type it eats
  _Gem(this.type, [this.special = 0, this.burstType = -1]);
}

class JewelMatchScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;
  const JewelMatchScreen({super.key, required this.players, required this.callbacks});

  @override
  State<JewelMatchScreen> createState() => _JewelMatchScreenState();
}

class _JewelMatchScreenState extends State<JewelMatchScreen> with SingleTickerProviderStateMixin {
  late List<List<_Gem?>> _board;
  int _sr = -1, _sc = -1; // selected
  int _score = 0, _combo = 0, _bestCombo = 1;
  int _best = 0;
  double _time = 60.0;
  bool _busy = false, _over = false;
  String _banner = '';
  late AnimationController _pulse;
  Timer? _clock;
  final _rnd = Random();

  // jewel colors (the gems' identity, like player colors)
  static const _cols = [
    Color(0xFFFF5A5A), // ruby
    Color(0xFFFF9F2E), // amber
    Color(0xFFFFD93D), // topaz
    Color(0xFF3ED598), // emerald
    Color(0xFF3EA6FF), // sapphire
    Color(0xFFB15CFF), // amethyst
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _newBoard();
    _loadBest();
    _clock = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (_over) return;
      setState(() => _time -= 0.1);
      if (_time <= 0) {
        _time = 0;
        _endGame();
      }
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _loadBest() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _best = p.getInt('jewelmatch_best') ?? 0);
  }

  Future<void> _saveBest() async {
    final p = await SharedPreferences.getInstance();
    if (_score > _best) await p.setInt('jewelmatch_best', _score);
  }

  void _newBoard() {
    do {
      _board = List.generate(_n, (r) => List.generate(_n, (c) {
        int t;
        do {
          t = _rnd.nextInt(_types);
        } while ((c >= 2 && _board[r][c - 1]!.type == t && _board[r][c - 2]!.type == t) ||
            (r >= 2 && _board[r - 1][c]!.type == t && _board[r - 2][c]!.type == t));
        return _Gem(t);
      }));
    } while (!_hasMove());
    _sr = _sc = -1;
  }

  bool _hasMove() {
    for (int r = 0; r < _n; r++) {
      for (int c = 0; c < _n; c++) {
        for (final d in const [[0, 1], [1, 0]]) {
          final r2 = r + d[0], c2 = c + d[1];
          if (r2 >= _n || c2 >= _n) continue;
          final a = _board[r][c]!, b = _board[r2][c2]!;
          _board[r][c] = b;
          _board[r2][c2] = a;
          final m = _findMatches().isNotEmpty;
          _board[r][c] = a;
          _board[r2][c2] = b;
          if (m) return true;
        }
      }
    }
    return false;
  }

  /// Returns list of match groups (each a set of "r,c" keys).
  List<Set<String>> _findMatches() {
    final groups = <Set<String>>[];
    for (int r = 0; r < _n; r++) {
      int c = 0;
      while (c < _n) {
        final g = _board[r][c];
        if (g == null || g.special == 2) { c++; continue; }
        int c2 = c;
        while (c2 < _n && _board[r][c2] != null && _board[r][c2]!.type == g.type && _board[r][c2]!.special != 2) {
          c2++;
        }
        if (c2 - c >= 3) groups.add({for (int i = c; i < c2; i++) '$r,$i'});
        c = c2;
      }
    }
    for (int c = 0; c < _n; c++) {
      int r = 0;
      while (r < _n) {
        final g = _board[r][c];
        if (g == null || g.special == 2) { r++; continue; }
        int r2 = r;
        while (r2 < _n && _board[r2][c] != null && _board[r2][c]!.type == g.type && _board[r2][c]!.special != 2) {
          r2++;
        }
        if (r2 - r >= 3) groups.add({for (int i = r; i < r2; i++) '$i,$c'});
        r = r2;
      }
    }
    return groups;
  }

  int _kr(String k) => int.parse(k.split(',')[0]);
  int _kc(String k) => int.parse(k.split(',')[1]);

  Future<void> _onTap(int r, int c) async {
    if (_busy || _over || _board[r][c] == null) return;
    Sfx.tap();
    if (_sr == -1) {
      setState(() { _sr = r; _sc = c; });
      return;
    }
    if (_sr == r && _sc == c) {
      setState(() { _sr = _sc = -1; });
      return;
    }
    if ((_sr - r).abs() + (_sc - c).abs() == 1) {
      final a = _sr, b = _sc;
      setState(() { _sr = _sc = -1; });
      await _trySwap(a, b, r, c);
    } else {
      setState(() { _sr = r; _sc = c; });
    }
  }

  void _onPan(DragUpdateDetails d, double cell, int r, int c) {
    if (_busy || _over) return;
    final dx = d.delta.dx, dy = d.delta.dy;
    if (dx.abs() < 8 && dy.abs() < 8) return;
    int r2 = r, c2 = c;
    if (dx.abs() > dy.abs()) {
      c2 = c + (dx > 0 ? 1 : -1);
    } else {
      r2 = r + (dy > 0 ? 1 : -1);
    }
    if (r2 < 0 || r2 >= _n || c2 < 0 || c2 >= _n) return;
    _trySwap(r, c, r2, c2);
  }

  Future<void> _trySwap(int r1, int c1, int r2, int c2) async {
    if (_busy || _over) return;
    _busy = true;
    final a = _board[r1][c1]!, b = _board[r2][c2]!;
    _board[r1][c1] = b;
    _board[r2][c2] = a;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 140));

    // swapping with/into a special detonates it
    if (a.special != 0 || b.special != 0) {
      Sfx.win();
      final clear = <String>{'$r1,$c1', '$r2,$c2'};
      _triggerSpecial(r1, c1, a, clear);
      _triggerSpecial(r2, c2, b, clear);
      _combo = 1;
      await _clearAndRefill(clear, null);
      _busy = false;
      if (mounted) setState(() {});
      return;
    }

    final groups = _findMatches();
    if (groups.isEmpty) {
      // swap back
      _board[r1][c1] = a;
      _board[r2][c2] = b;
      Sfx.click();
      setState(() {});
      _busy = false;
      return;
    }
    _combo = 0;
    await _resolveLoop({'$r1,$c1', '$r2,$c2'});
    _busy = false;
    if (!_hasMove() && !_over) {
      _banner = 'No moves — reshuffling! 🔀';
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 700));
      final specials = <String, _Gem>{};
      for (int r = 0; r < _n; r++) {
        for (int c = 0; c < _n; c++) {
          final g = _board[r][c];
          if (g != null && g.special != 0) specials['$r,$c'] = g;
        }
      }
      _newBoard();
      for (final e in specials.entries) {
        _board[_kr(e.key)][_kc(e.key)] = e.value;
      }
      _banner = '';
      if (mounted) setState(() {});
    }
  }

  void _triggerSpecial(int r, int c, _Gem g, Set<String> clear) {
    if (g.special == 1) {
      for (int i = 0; i < _n; i++) {
        clear.add('$r,$i');
        clear.add('$i,$c');
      }
      _score += 150;
    } else if (g.special == 2) {
      final target = g.burstType >= 0 ? g.burstType : g.type;
      for (int rr = 0; rr < _n; rr++) {
        for (int cc = 0; cc < _n; cc++) {
          final o = _board[rr][cc];
          if (o != null && o.type == target) clear.add('$rr,$cc');
        }
      }
      _score += 300;
    }
  }

  Future<void> _resolveLoop(Set<String> swapCells) async {
    while (!_over) {
      final groups = _findMatches();
      if (groups.isEmpty) break;
      _combo++;
      _bestCombo = max(_bestCombo, _combo);
      final clear = <String>{};
      String? spawnKey;
      int spawnKind = 0, spawnType = 0;
      for (final grp in groups) {
        // spawn a special for big matches (only first big group per cascade)
        if (grp.length >= 4 && spawnKey == null) {
          final sorted = grp.toList();
          spawnKey = sorted.firstWhere((k) => swapCells.contains(k), orElse: () => sorted.first);
          final g = _board[_kr(spawnKey)][_kc(spawnKey)]!;
          spawnType = g.type;
          spawnKind = grp.length >= 5 ? 2 : 1;
        }
        for (final k in grp) {
          if (k == spawnKey) continue;
          clear.add(k);
          final g = _board[_kr(k)][_kc(k)];
          if (g != null && g.special != 0) _triggerSpecial(_kr(k), _kc(k), g, clear);
        }
      }
      if (grpHasSpecial(groups)) {
        Sfx.win();
      } else {
        Sfx.move();
      }
      await _clearAndRefill(clear, spawnKey == null ? null : _Spawn(spawnKey, spawnKind, spawnType));
      if (_combo > 1) {
        _banner = 'COMBO ×$_combo! 🔥';
        _pulse.forward(from: 0);
        setState(() {});
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (_combo > 1) {
      await Future.delayed(const Duration(milliseconds: 500));
      _banner = '';
      if (mounted) setState(() {});
    }
  }

  bool grpHasSpecial(List<Set<String>> groups) {
    for (final grp in groups) {
      for (final k in grp) {
        final g = _board[_kr(k)][_kc(k)];
        if (g != null && g.special != 0) return true;
      }
    }
    return false;
  }

  Future<void> _clearAndRefill(Set<String> clear, _Spawn? spawn) async {
    final mult = max(1, _combo);
    _score += clear.length * 10 * mult;
    for (final k in clear) {
      _board[_kr(k)][_kc(k)] = null;
    }
    if (spawn != null) {
      _board[_kr(spawn.key)][_kc(spawn.key)] =
          _Gem(spawn.type, spawn.kind, spawn.kind == 2 ? spawn.type : -1);
      _banner = spawn.kind == 2 ? 'COLOR BURST! 💥' : 'LINE BLASTER! ⚡';
      _pulse.forward(from: 0);
    }
    if (mounted) setState(() {});
    await Future.delayed(const Duration(milliseconds: 160));
    // gravity
    for (int c = 0; c < _n; c++) {
      int write = _n - 1;
      for (int r = _n - 1; r >= 0; r--) {
        if (_board[r][c] != null) {
          _board[write][c] = _board[r][c];
          if (write != r) _board[r][c] = null;
          write--;
        }
      }
      for (int r = write; r >= 0; r--) {
        _board[r][c] = _Gem(_rnd.nextInt(_types));
      }
    }
    if (mounted) setState(() {});
    await Future.delayed(const Duration(milliseconds: 160));
  }

  void _endGame() {
    if (_over) return;
    _over = true;
    _clock?.cancel();
    Sfx.win();
    _saveBest();
    final isBest = _score > _best && _best > 0 || (_best == 0 && _score > 0);
    widget.callbacks.finish(
      headline: 'You scored $_score! 💎',
      subline: isBest
          ? 'NEW BEST! You absolute gem! Best combo ×$_bestCombo.'
          : 'Best: ${max(_best, _score)} • Best combo ×$_bestCombo. One more run?',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              _hud(t, '💎', '$_score'),
              const SizedBox(width: 8),
              _hud(t, '🔥', '×$max(1,_combo)'),
              const SizedBox(width: 8),
              _hud(t, '🏆', '$_best'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _time <= 10 ? const Color(0xFFE5484D) : t.surface,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '⏱️ ${_time.ceil()}s',
                  style: TextStyle(
                      color: _time <= 10 ? Colors.white : t.text, fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: _time / 60.0,
              minHeight: 8,
              backgroundColor: t.surface,
              valueColor: AlwaysStoppedAnimation(_time <= 10 ? const Color(0xFFE5484D) : t.primary),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 30,
          child: ScaleTransition(
            scale: Tween(begin: 0.7, end: 1.15).animate(CurvedAnimation(parent: _pulse, curve: Curves.elasticOut)),
            child: Text(_banner,
                style: TextStyle(color: t.accent, fontWeight: FontWeight.w900, fontSize: 20)),
          ),
        ),
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (_, cons) {
                final size = min(cons.maxWidth, cons.maxHeight);
                final cell = size / _n;
                return SizedBox(
                  width: size,
                  height: size,
                  child: GestureDetector(
                    onPanUpdate: (d) {
                      final box = context.findRenderObject() as RenderBox?;
                      if (box == null) return;
                      final p = box.globalToLocal(d.globalPosition);
                      final r = (p.dy / cell).floor().clamp(0, _n - 1);
                      final c = (p.dx / cell).floor().clamp(0, _n - 1);
                      _onPan(d, cell, r, c);
                    },
                    child: CustomPaint(
                      painter: _BoardPainter(
                        board: _board,
                        colors: _cols,
                        selectedR: _sr,
                        selectedC: _sc,
                        surface: t.surface,
                        radius: 10,
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _n),
                        itemCount: _n * _n,
                        itemBuilder: (_, i) => GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _onTap(i ~/ _n, i % _n),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: Text(
            'Match 4 = ⚡ Line Blaster • Match 5 = 💥 Color Burst',
            style: TextStyle(color: t.muted, fontWeight: FontWeight.w700, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _hud(GameTheme t, String emoji, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(99)),
      child: Text('$emoji $value', style: TextStyle(color: t.text, fontWeight: FontWeight.w900)),
    );
  }
}

class _Spawn {
  final String key;
  final int kind;
  final int type;
  _Spawn(this.key, this.kind, this.type);
}

class _BoardPainter extends CustomPainter {
  final List<List<_Gem?>> board;
  final List<Color> colors;
  final int selectedR, selectedC;
  final Color surface;
  final double radius;
  _BoardPainter({
    required this.board,
    required this.colors,
    required this.selectedR,
    required this.selectedC,
    required this.surface,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _n;
    final bg = Paint()..color = surface;
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(radius)), bg);
    for (int r = 0; r < _n; r++) {
      for (int c = 0; c < _n; c++) {
        final g = board[r][c];
        if (g == null) continue;
        final cx = c * cell + cell / 2, cy = r * cell + cell / 2;
        final rad = cell * 0.38;
        if (r == selectedR && c == selectedC) {
          canvas.drawCircle(Offset(cx, cy), rad + 5,
              Paint()..color = Colors.white.withValues(alpha: 0.85)..style = PaintingStyle.stroke..strokeWidth = 3);
        }
        if (g.special == 2) {
          _drawBurst(canvas, Offset(cx, cy), rad + 3);
        } else {
          _drawGem(canvas, Offset(cx, cy), rad, colors[g.type]);
          if (g.special == 1) {
            canvas.drawCircle(
                Offset(cx, cy),
                rad + 2,
                Paint()
                  ..color = Colors.white
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2.5);
            final tp = TextPainter(
                text: const TextSpan(text: '⚡', style: TextStyle(fontSize: 14)),
                textDirection: TextDirection.ltr);
            tp.layout();
            tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
          }
        }
      }
    }
  }

  void _drawGem(Canvas canvas, Offset c, double rad, Color color) {
    final path = Path()
      ..moveTo(c.dx, c.dy - rad)
      ..lineTo(c.dx + rad * 0.8, c.dy)
      ..lineTo(c.dx, c.dy + rad)
      ..lineTo(c.dx - rad * 0.8, c.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    final shine = Path()
      ..moveTo(c.dx, c.dy - rad * 0.55)
      ..lineTo(c.dx + rad * 0.42, c.dy - rad * 0.1)
      ..lineTo(c.dx, c.dy + rad * 0.28)
      ..lineTo(c.dx - rad * 0.42, c.dy - rad * 0.1)
      ..close();
    canvas.drawPath(shine, Paint()..color = Colors.white.withValues(alpha: 0.45));
    // facet lines
    final facet = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(c.dx - rad * 0.8, c.dy), Offset(c.dx + rad * 0.8, c.dy), facet);
  }

  void _drawBurst(Canvas canvas, Offset c, double rad) {
    final path = Path();
    for (int i = 0; i < 12; i++) {
      final a = i * pi / 6;
      final rr = i.isEven ? rad : rad * 0.55;
      final p = Offset(c.dx + cos(a) * rr, c.dy + sin(a) * rr);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(colors: colors).createShader(Rect.fromCircle(center: c, radius: rad)));
    canvas.drawCircle(c, rad * 0.28, Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) => true;
}
