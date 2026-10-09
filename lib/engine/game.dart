import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Jewel Match engine — 8x8 match-3, adapted from the original implementation
/// to the authoritative RULES.md (stitch-batch5/jewelmatch/RULES.md):
/// level-based play with target scores and move limits (§2, §3), RULES §8
/// scoring (60/gem, Diamond 90, cascade multiplier, creation bonuses,
/// polishing bonus, coins), Faceted Bar / Prismatic / Brilliant specials (§7),
/// gem quotas from level 6 (§2, §9), seeded xorshift32 refills (§12), and
/// mid-game persistence (§12).
///
/// The engine exposes animation metadata (swap/clear/fall) with wall-clock
/// timestamps so the UI can paint weighty physical motion without the engine
/// awaiting UI futures.

const int kBoardN = 8;

/// Gem tiers (RULES.md §2).
enum GemTier { ruby, sapphire, emerald, amethyst, topaz, diamond }

/// Special gem kinds (RULES.md §7).
/// 0 = none, 1 = Faceted Bar, 2 = Prismatic Diamond, 3 = Brilliant.
class Gem {
  int type; // 0..5
  int special; // 0..3
  Gem(this.type, [this.special = 0]);
  Gem copy() => Gem(type, special);
  int get code => type + special * 10;
  static Gem fromCode(int c) => Gem(c % 10, c ~/ 10);
}

/// Seeded PRNG for refills (RULES.md §12).
class XorShift32 {
  int _s;
  XorShift32(int seed) : _s = seed == 0 ? 0x9E3779B9 : seed & 0xFFFFFFFF;
  int next() {
    int x = _s;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    _s = x & 0xFFFFFFFF;
    return _s;
  }
}

class LevelQuota {
  final int tier;
  final int count;
  const LevelQuota(this.tier, this.count);
}

class LevelConfig {
  /// Target score: 12,000 at level 1, growing ~15% per level (RULES.md §2).
  static int targetFor(int level) =>
      (12000 * pow(1.15, level - 1)).round();

  /// Move limit: 30 at level 1, then deterministic 22..35 (RULES.md §2).
  static int movesFor(int level) =>
      level == 1 ? 30 : 22 + ((level * 7 + 3) % 14);

  /// Gem quota from level 6+ (RULES.md §2, §9). Level 6 = 20 Rubies.
  static LevelQuota? quotaFor(int level) {
    if (level < 6) return null;
    return LevelQuota((level - 6) % 6, 20 + ((level - 6) ~/ 6) * 5);
  }
}

/// Game modes (RULES.md §3, §9 + offline mode maximums).
enum GameMode { levels, endless, timed }

/// Events the UI drains to play sounds / show banners / navigate.
enum EngineEventKind {
  select,
  swap,
  invalid,
  match, // step + gems
  specialCreated, // specialKind
  detonated,
  shuffled,
  hintUsed, // text carries free/paid
  quotaMet,
  polishingBonus, // gems = coins text via text
  win,
  lose,
  notice, // text
  moveDone, // a move fully resolved; persist state
}

class EngineEvent {
  final EngineEventKind kind;
  final int step;
  final int gems;
  final int specialKind;
  final String text;
  const EngineEvent(this.kind,
      {this.step = 0, this.gems = 0, this.specialKind = 0, this.text = ''});
}

/// Animation metadata with wall-clock timestamps (microseconds).
class SwapAnim {
  final int r1, c1, r2, c2;
  final bool bounce;
  final int t0;
  const SwapAnim(this.r1, this.c1, this.r2, this.c2, this.bounce, this.t0);
}

class ClearAnim {
  final Set<String> cells;
  final int t0;
  const ClearAnim(this.cells, this.t0);
}

class FallAnim {
  /// "r,c" -> row the gem fell FROM (negative = newly spawned above board).
  final Map<String, int> fromRow;
  final int t0;
  const FallAnim(this.fromRow, this.t0);
}

/// Shockwave metadata for special-gem detonations (cell-space center).
class BlastAnim {
  final double r, c;
  final int t0;
  const BlastAnim(this.r, this.c, this.t0);
}

class JewelEngine extends ChangeNotifier {
  List<List<Gem?>> board =
      List.generate(kBoardN, (_) => List.filled(kBoardN, null));

  int level = 1;
  int target = 12000;
  int movesLeft = 30;
  int moveCount = 0;
  int score = 0;
  int bestCombo = 1;
  LevelQuota? quota;
  int quotaCollected = 0;
  int hintsUsed = 0;
  bool _quotaAnnounced = false;

  bool busy = false;
  bool paused = false;
  bool over = false;
  bool won = false;

  int selR = -1, selC = -1;

  // ---- mode state -------------------------------------------------------
  GameMode mode = GameMode.levels;
  int timeLeftMs = 0;
  int _timedSeconds = 120;
  Timer? _modeTimer;

  /// True when the level/mode has no move limit and no target (endless,
  /// timed). The HUD shows an infinity dial / countdown instead.
  bool get limitless => mode != GameMode.levels;

  // ---- watchdog (stuck-state recovery, exemplar pattern) ----------------
  Timer? _watchdog;
  int _lastStamp = 0;
  bool _disposed = false;

  /// Heartbeat: call at every await boundary of a resolution so the
  /// watchdog can tell a progressing resolution from a dead one.
  void _stamp() => _lastStamp = DateTime.now().millisecondsSinceEpoch;

  /// Watchdog tick: if the engine looks busy but no progress happened for
  /// 8+ seconds (and we're not paused), the await chain died — recover by
  /// clearing animation metadata, dropping the busy lock, and letting the
  /// move settle. Stuck states are impossible by construction.
  void _watch() {
    if (_disposed || over || paused) return;
    if (!busy) return;
    final idle = DateTime.now().millisecondsSinceEpoch - _lastStamp;
    if (idle < 8000) return;
    swapAnim = null;
    clearAnim = null;
    fallAnim = null;
    spawnCell = null;
    busy = false;
    _stamp();
    try {
      _afterMove();
    } catch (_) {
      // never let recovery itself throw
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _watchdog?.cancel();
    _modeTimer?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------- test hooks

  /// Force the watchdog to see a stall (test only).
  @visibleForTesting
  void debugAgeStamp(int ms) => _lastStamp -= ms;

  /// Run one watchdog tick immediately (test only).
  @visibleForTesting
  void debugWatchdogTick() => _watch();

  /// Force a tray reshuffle (test only).
  @visibleForTesting
  void debugShuffle() => _shuffleBoard();

  // Animation metadata for the painter.
  SwapAnim? swapAnim;
  ClearAnim? clearAnim;
  FallAnim? fallAnim;
  BlastAnim? blastAnim;

  /// Newly forged special gem, for the scale-in pop ("r,c" key).
  String? spawnCell;
  int spawnT0 = 0;

  final List<EngineEvent> _events = [];
  List<EngineEvent> takeEvents() {
    final e = List<EngineEvent>.of(_events);
    _events.clear();
    return e;
  }

  void _emit(EngineEvent e) {
    _events.add(e);
    notifyListeners();
  }

  static int _now() => DateTime.now().microsecondsSinceEpoch;

  static const _swapMs = 170;
  static const _bounceMs = 300;
  static const _clearMs = 200;
  static const _fallMs = 240;

  XorShift32 _rng = XorShift32(1);

  // ---------------------------------------------------------------- setup

  void _resetCommon() {
    moveCount = 0;
    score = 0;
    bestCombo = 1;
    quotaCollected = 0;
    hintsUsed = 0;
    busy = false;
    paused = false;
    over = false;
    won = false;
    selR = selC = -1;
    swapAnim = null;
    clearAnim = null;
    fallAnim = null;
    blastAnim = null;
    spawnCell = null;
    _quotaAnnounced = false;
    _modeTimer?.cancel();
    _modeTimer = null;
    _watchdog?.cancel();
    _stamp();
    _watchdog = Timer.periodic(const Duration(seconds: 3), (_) => _watch());
  }

  void startLevel(int lv) {
    mode = GameMode.levels;
    level = lv;
    target = LevelConfig.targetFor(lv);
    movesLeft = LevelConfig.movesFor(lv);
    quota = LevelConfig.quotaFor(lv);
    _resetCommon();
    _rng = XorShift32(level * 100003);
    _newBoard();
    notifyListeners();
  }

  /// Endless bench: no move limit, no target — chase the highest score.
  /// The bench never ends on its own; quitting banks score/1000 coins.
  void startEndless() {
    mode = GameMode.endless;
    level = 0;
    target = 0;
    movesLeft = -1; // unlimited; HUD shows infinity
    quota = null;
    _resetCommon();
    _rng = XorShift32(DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF);
    _newBoard();
    notifyListeners();
  }

  /// Timed bench: [seconds] on the clock, unlimited moves, no target.
  /// When the clock runs out the session ends and the score is banked.
  void startTimed([int seconds = 120]) {
    mode = GameMode.timed;
    level = 0;
    target = 0;
    movesLeft = -1; // unlimited; HUD shows the clock
    quota = null;
    _timedSeconds = seconds;
    _resetCommon();
    _rng = XorShift32(DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF);
    _newBoard();
    timeLeftMs = seconds * 1000;
    _modeTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_disposed || paused || over) return;
      _stamp();
      timeLeftMs -= 200;
      if (timeLeftMs <= 0) {
        timeLeftMs = 0;
        _modeTimer?.cancel();
        _modeTimer = null;
        _doTimedEnd();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void _doTimedEnd() {
    if (over) return;
    over = true;
    won = true; // a timed session always "completes"; score decides glory
    final coins = score ~/ 1000; // RULES.md §8 rate
    _emit(EngineEvent(EngineEventKind.lose, text: '$coins'));
    // NOTE: reuse `lose` event kind as "session over" for timed mode; the
    // UI distinguishes via engine.mode == GameMode.timed.
    notifyListeners();
  }

  void restart() {
    switch (mode) {
      case GameMode.levels:
        startLevel(level);
        break;
      case GameMode.endless:
        startEndless();
        break;
      case GameMode.timed:
        startTimed(_timedSeconds);
        break;
    }
  }

  void _newBoard() {
    // Fill with no pre-existing matches; max 200 attempts per cell, then
    // a full regenerate (RULES.md §2). Then require >= 1 legal swap.
    for (int regen = 0; regen < 60; regen++) {
      var ok = true;
      for (int r = 0; r < kBoardN && ok; r++) {
        for (int c = 0; c < kBoardN && ok; c++) {
          int attempts = 0;
          int t = _weightedType();
          while (attempts < 200 && _createsMatch(r, c, t)) {
            t = _weightedType();
            attempts++;
          }
          if (attempts >= 200) {
            ok = false; // full regenerate
          } else {
            board[r][c] = Gem(t);
          }
        }
      }
      if (ok && _hasMove()) return;
    }
    // Fallback (practically unreachable): accept last board.
  }

  bool _createsMatch(int r, int c, int t) {
    return (c >= 2 &&
            board[r][c - 1]?.type == t &&
            board[r][c - 2]?.type == t) ||
        (r >= 2 && board[r - 1][c]?.type == t && board[r - 2][c]?.type == t);
  }

  /// Diamond is rarer: weight 1 vs 2 for the other tiers (RULES.md §8).
  int _weightedType() {
    final v = _rng.next() % 11; // 0..10
    return v == 10 ? 5 : v ~/ 2;
  }

  // ------------------------------------------------------------- matching

  /// Returns list of match groups (each a set of "r,c" keys). Prismatic
  /// gems never participate in natural matches.
  List<Set<String>> _findMatches([List<List<Gem?>>? b]) {
    final bd = b ?? board;
    final groups = <Set<String>>[];
    for (int r = 0; r < kBoardN; r++) {
      int c = 0;
      while (c < kBoardN) {
        final g = bd[r][c];
        if (g == null || g.special == 2) {
          c++;
          continue;
        }
        int c2 = c;
        while (c2 < kBoardN &&
            bd[r][c2] != null &&
            bd[r][c2]!.type == g.type &&
            bd[r][c2]!.special != 2) {
          c2++;
        }
        if (c2 - c >= 3) {
          groups.add({for (int i = c; i < c2; i++) '$r,$i'});
        }
        c = c2;
      }
    }
    for (int c = 0; c < kBoardN; c++) {
      int r = 0;
      while (r < kBoardN) {
        final g = bd[r][c];
        if (g == null || g.special == 2) {
          r++;
          continue;
        }
        int r2 = r;
        while (r2 < kBoardN &&
            bd[r2][c] != null &&
            bd[r2][c]!.type == g.type &&
            bd[r2][c]!.special != 2) {
          r2++;
        }
        if (r2 - r >= 3) {
          groups.add({for (int i = r; i < r2; i++) '$i,$c'});
        }
        r = r2;
      }
    }
    return groups;
  }

  static int _kr(String k) => int.parse(k.split(',')[0]);
  static int _kc(String k) => int.parse(k.split(',')[1]);

  /// Any legal swap available? Includes special-gem activation swaps
  /// (RULES.md §4: a special may be swapped with ANY adjacent gem).
  bool _hasMove() {
    for (int r = 0; r < kBoardN; r++) {
      for (int c = 0; c < kBoardN; c++) {
        final g = board[r][c];
        if (g == null) continue;
        for (final d in const [
          [0, 1],
          [1, 0]
        ]) {
          final r2 = r + d[0], c2 = c + d[1];
          if (r2 >= kBoardN || c2 >= kBoardN) continue;
          final h = board[r2][c2];
          if (h == null) continue;
          if (g.special != 0 || h.special != 0) return true;
          board[r][c] = h;
          board[r2][c2] = g;
          final m = _findMatches().isNotEmpty;
          board[r][c] = g;
          board[r2][c2] = h;
          if (m) return true;
        }
      }
    }
    return false;
  }

  // ---------------------------------------------------------------- input

  void tapCell(int r, int c) {
    if (busy || paused || over || board[r][c] == null) return;
    if (selR == -1) {
      selR = r;
      selC = c;
      _emit(const EngineEvent(EngineEventKind.select));
      return;
    }
    if (selR == r && selC == c) {
      selR = selC = -1;
      notifyListeners();
      return;
    }
    if ((selR - r).abs() + (selC - c).abs() == 1) {
      final a = selR, b = selC;
      selR = selC = -1;
      trySwap(a, b, r, c);
    } else {
      selR = r;
      selC = c;
      _emit(const EngineEvent(EngineEventKind.select));
    }
  }

  /// Drag/swipe: attempt a swap in the flick direction.
  void flick(int r, int c, int dr, int dc) {
    if (busy || paused || over) return;
    final r2 = r + dr, c2 = c + dc;
    if (r2 < 0 || r2 >= kBoardN || c2 < 0 || c2 >= kBoardN) return;
    selR = selC = -1;
    trySwap(r, c, r2, c2);
  }

  Future<void> trySwap(int r1, int c1, int r2, int c2) async {
    if (busy || paused || over) return;
    final a = board[r1][c1];
    final b = board[r2][c2];
    if (a == null || b == null) return;
    busy = true;
    _stamp();
    try {
      moveCount++;
      _rng = XorShift32(level * 100003 + moveCount); // RULES.md §12

      // Swap the gems visually first.
      board[r1][c1] = b;
      board[r2][c2] = a;
      swapAnim = SwapAnim(r1, c1, r2, c2, false, _now());
      _emit(EngineEvent(EngineEventKind.swap,
          text: a.special != 0 || b.special != 0 ? 'detonate' : ''));
      _stamp();
      await Future.delayed(const Duration(milliseconds: _swapMs));
      _stamp();

      if (a.special != 0 || b.special != 0) {
        // Special-gem activation: always a legal move (RULES.md §4, §7).
        if (!limitless) movesLeft--;
        swapAnim = null;
        _emit(const EngineEvent(EngineEventKind.detonated));
        final clear = <String>{'$r1,$c1', '$r2,$c2'};
        _activateSpecialPair(r1, c1, a, r2, c2, b, clear);
        final bothPrismatic = a.special == 2 && b.special == 2;
        blastAnim = BlastAnim(
            bothPrismatic ? 3.5 : (r1 + r2) / 2,
            bothPrismatic ? 3.5 : (c1 + c2) / 2,
            _now());
        await _clearAndRefill(clear, const [], 1);
        await _resolveCascades();
        _afterMove();
        return;
      }

      final groups = _findMatches();
      if (groups.isEmpty) {
        // Illegal swap: bounce back, move NOT consumed (RULES.md §5).
        board[r1][c1] = a;
        board[r2][c2] = b;
        moveCount--; // the attempt never happened
        swapAnim = SwapAnim(r1, c1, r2, c2, true, _now());
        _emit(const EngineEvent(EngineEventKind.invalid));
        _stamp();
        await Future.delayed(const Duration(milliseconds: _bounceMs));
        swapAnim = null;
        return;
      }

      if (!limitless) movesLeft--;
      swapAnim = null;
      await _resolveLoop({'$r1,$c1', '$r2,$c2'});
      _afterMove();
    } finally {
      // The busy lock ALWAYS releases — even if a resolution step throws.
      busy = false;
      _stamp();
      notifyListeners();
    }
  }

  /// Detonate a special pair swapped together (RULES.md §7, §12).
  void _activateSpecialPair(
      int r1, int c1, Gem a, int r2, int c2, Gem b, Set<String> clear) {
    if (a.special == 2 && b.special == 2) {
      // Prismatic + Prismatic clears the entire board.
      for (int r = 0; r < kBoardN; r++) {
        for (int c = 0; c < kBoardN; c++) {
          clear.add('$r,$c');
        }
      }
      return;
    }
    if (a.special == 2 || b.special == 2) {
      // Prismatic clears ALL gems of the OTHER gem's tier (RULES.md §7,
      // test case 7).
      final other = a.special == 2 ? b : a;
      for (int r = 0; r < kBoardN; r++) {
        for (int c = 0; c < kBoardN; c++) {
          if (board[r][c]?.type == other.type) clear.add('$r,$c');
        }
      }
      // The other special still detonates if it is one.
      final or_ = a.special == 2 ? r2 : r1;
      final oc = a.special == 2 ? c2 : c1;
      _detonateSingle(or_, oc, other, clear);
      return;
    }
    if ((a.special == 1 && b.special == 3) ||
        (a.special == 3 && b.special == 1)) {
      // Bar + Brilliant: 5x5 area plus the Bar's row/column (RULES.md §12).
      final cr = (r1 + r2) ~/ 2, cc = (c1 + c2) ~/ 2;
      for (int r = cr - 2; r <= cr + 2; r++) {
        for (int c = cc - 2; c <= cc + 2; c++) {
          if (r >= 0 && r < kBoardN && c >= 0 && c < kBoardN) {
            clear.add('$r,$c');
          }
        }
      }
      final br = a.special == 1 ? r1 : r2;
      final bc = a.special == 1 ? c1 : c2;
      for (int i = 0; i < kBoardN; i++) {
        clear.add('$br,$i');
        clear.add('$i,$bc');
      }
      return;
    }
    _detonateSingle(r1, c1, a, clear);
    _detonateSingle(r2, c2, b, clear);
  }

  /// Detonate one Bar (row+column) or Brilliant (3x3) (RULES.md §7).
  void _detonateSingle(int r, int c, Gem g, Set<String> clear) {
    if (g.special == 1) {
      for (int i = 0; i < kBoardN; i++) {
        clear.add('$r,$i');
        clear.add('$i,$c');
      }
    } else if (g.special == 3) {
      for (int rr = r - 1; rr <= r + 1; rr++) {
        for (int cc = c - 1; cc <= c + 1; cc++) {
          if (rr >= 0 && rr < kBoardN && cc >= 0 && cc < kBoardN) {
            clear.add('$rr,$cc');
          }
        }
      }
    }
  }

  // ------------------------------------------------------------ resolution

  /// Resolve matches until the board is quiet. [swapCells] prefers the
  /// creation cell for forged specials; [startStep] is 1 after a
  /// special-gem detonation (the detonation itself was step ×1), else 0.
  /// Every 4+ group forges its own special in the step it appears
  /// (RULES.md §7) — including cascades after a detonation.
  Future<void> _resolveMatches(Set<String> swapCells,
      {int startStep = 0}) async {
    int step = startStep;
    while (!over) {
      // Pause freezes the board mid-cascade (RULES.md §12); resume continues.
      while (paused && !over) {
        await Future.delayed(const Duration(milliseconds: 100));
        _stamp(); // waiting on purpose — not a stall
      }
      if (over) break;
      _stamp();
      final groups = _findMatches();
      if (groups.isEmpty) break;
      step++;
      bestCombo = max(bestCombo, step);
      final mult = min(step, 8); // RULES.md §7 cascade multiplier, cap x8

      final clear = <String>{};
      final detonated = <String>{};

      // First pass: a Bar/Brilliant caught in a natural match detonates
      // instead of clearing normally (RULES.md §12). This must run BEFORE
      // special-creation picks its cell, so a detonated special is never
      // chosen as the forge cell.
      var detonatedThisStep = false;
      for (final grp in groups) {
        for (final k in grp) {
          final g = board[_kr(k)][_kc(k)];
          if (g != null && (g.special == 1 || g.special == 3)) {
            _detonateSingle(_kr(k), _kc(k), g, clear);
            detonated.add(k);
            clear.add(k);
            detonatedThisStep = true;
          } else {
            clear.add(k);
          }
        }
      }

      // L/T detection: two intersecting 3-matches in one step -> one
      // Brilliant at the intersection (RULES.md §7, §12).
      String? ltCell;
      outer:
      for (int i = 0; i < groups.length; i++) {
        for (int j = i + 1; j < groups.length; j++) {
          final inter = groups[i].intersection(groups[j]);
          if (inter.isNotEmpty) {
            ltCell = (inter.toList()..sort()).first;
            break outer;
          }
        }
      }

      // Special forging: EVERY 4+ group forges its own special in the same
      // step (RULES.md §7); the swap-origin cell is preferred, else the
      // first matched cell in reading order that is not a detonated
      // special (RULES.md §12).
      final spawns = <_Spawn>[];
      String? pickKey(Set<String> grp) {
        final sorted = grp.toList()..sort();
        var key = sorted.firstWhere(
          (k) => swapCells.contains(k),
          orElse: () => sorted.first,
        );
        if (detonated.contains(key)) {
          final rest = sorted.where((k) => !detonated.contains(k));
          if (rest.isEmpty) return null;
          key = rest.first;
        }
        final g = board[_kr(key)][_kc(key)];
        if (g == null) return null; // safety: never spawn on empty cell
        return key;
      }

      if (ltCell != null) {
        final key = detonated.contains(ltCell)
            ? pickKey(groups.expand((g) => g).toSet())
            : ltCell;
        if (key != null) {
          spawns.add(_Spawn(
              key, 3, board[_kr(key)][_kc(key)]!.type));
        }
      } else {
        for (final grp in groups) {
          if (grp.length < 4) continue;
          final key = pickKey(grp);
          if (key != null) {
            spawns.add(_Spawn(key, grp.length >= 5 ? 2 : 1,
                board[_kr(key)][_kc(key)]!.type));
          }
        }
      }

      // Final creation cells: each spawn key is guaranteed non-detonated
      // and non-empty by pickKey above (RULES.md §12).
      if (detonatedThisStep) {
        var br = 0.0, bc = 0.0;
        for (final k in detonated) {
          br += _kr(k);
          bc += _kc(k);
        }
        blastAnim = BlastAnim(
            br / detonated.length, bc / detonated.length, _now());
        _emit(const EngineEvent(EngineEventKind.detonated));
      } else {
        _emit(EngineEvent(EngineEventKind.match,
            step: step, gems: clear.length));
      }
      await _clearAndRefill(clear, spawns, mult);
      for (final s in spawns) {
        _emit(EngineEvent(EngineEventKind.specialCreated,
            specialKind: s.kind));
        score += s.kind == 2
            ? 2000
            : s.kind == 3
                ? 1000
                : 500; // RULES.md §8 creation bonuses
      }
      _stamp();
      await Future.delayed(const Duration(milliseconds: 120));
      _stamp();
    }
  }

  /// After a normal swap: resolve the initial matches plus all cascades.
  Future<void> _resolveLoop(Set<String> swapCells) =>
      _resolveMatches(swapCells);

  /// After a special-swap detonation: resolve follow-up cascades. The
  /// detonation itself scored at ×1, so cascades start at step 2
  /// (RULES.md §7, §8).
  Future<void> _resolveCascades() =>
      _resolveMatches(const {}, startStep: 1);

  Future<void> _clearAndRefill(
      Set<String> clear, List<_Spawn> spawns, int mult) async {
    _stamp();
    // Score each cleared gem: base x cascade multiplier (RULES.md §8).
    for (final k in clear) {
      final g = board[_kr(k)][_kc(k)];
      if (g != null) {
        score += _baseScore(g.type) * mult;
        if (quota != null && g.type == quota!.tier) {
          quotaCollected++;
        }
      }
    }
    if (quota != null &&
        !_quotaAnnounced &&
        quotaCollected >= quota!.count) {
      _quotaAnnounced = true;
      _emit(EngineEvent(EngineEventKind.quotaMet,
          text: '$quotaCollected/${quota!.count}'));
    }

    clearAnim = ClearAnim(Set.of(clear), _now());
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: _clearMs));
    _stamp();
    for (final k in clear) {
      board[_kr(k)][_kc(k)] = null;
    }
    for (final spawn in spawns) {
      board[_kr(spawn.key)][_kc(spawn.key)] = Gem(spawn.type, spawn.kind);
    }
    if (spawns.isNotEmpty) {
      // Animate the first forged special popping in; the painter keys off
      // spawnCell for the scale-in.
      spawnCell = spawns.first.key;
      spawnT0 = _now();
    }
    clearAnim = null;

    // Gravity with fall metadata for the painter.
    final fromRow = <String, int>{};
    for (int c = 0; c < kBoardN; c++) {
      int write = kBoardN - 1;
      for (int r = kBoardN - 1; r >= 0; r--) {
        final g = board[r][c];
        if (g != null) {
          if (write != r) {
            board[write][c] = g;
            board[r][c] = null;
            fromRow['$write,$c'] = r;
          }
          write--;
        }
      }
      for (int r = write; r >= 0; r--) {
        board[r][c] = Gem(_weightedType());
        fromRow['$r,$c'] = r - (write + 1); // spawned above the board
      }
    }
    fallAnim = FallAnim(fromRow, _now());
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: _fallMs));
    fallAnim = null;
    notifyListeners();
  }

  static int _baseScore(int type) =>
      type == GemTier.diamond.index ? 90 : 60; // RULES.md §8

  // -------------------------------------------------------------- endgame

  void _afterMove() {
    blastAnim = null; // the shockwave has played out
    if (over) return;
    if (mode == GameMode.levels) {
      if (_checkWin()) {
        _doWin();
        return;
      }
      if (movesLeft <= 0) {
        _doLose();
        return;
      }
    }
    // Persist on every move completion (RULES.md §12; levels mode only —
    // endless/timed benches bank their score on exit instead).
    if (mode == GameMode.levels) {
      _emit(const EngineEvent(EngineEventKind.moveDone));
    }
    if (!_hasMove()) {
      _shuffleBoard();
    } else {
      notifyListeners();
    }
  }

  bool _checkWin() {
    if (score < target) return false;
    if (quota != null && quotaCollected < quota!.count) return false;
    return true; // movesLeft may be 0: last-move rule (RULES.md §7, §12)
  }

  void _doWin() {
    over = true;
    won = true;
    // Polishing bonus: +250 per leftover move (RULES.md §8).
    final bonus = movesLeft * 250;
    score += bonus;
    final coins = score ~/ 1000 + 20; // §8: 1/1000 + 20 completion bonus
    final stars = score >= target * 2
        ? 3
        : score >= (target * 1.5).round()
            ? 2
            : 1; // RULES.md §9
    _emit(EngineEvent(EngineEventKind.polishingBonus,
        gems: bonus, text: '$coins'));
    _emit(EngineEvent(EngineEventKind.win, gems: stars, text: '$coins'));
    notifyListeners();
  }

  void _doLose() {
    over = true;
    won = false;
    final coins = score ~/ 1000; // retained on defeat (RULES.md §10)
    _emit(EngineEvent(EngineEventKind.lose, text: '$coins'));
    notifyListeners();
  }

  void _shuffleBoard() {
    final specials = <String, Gem>{};
    for (int r = 0; r < kBoardN; r++) {
      for (int c = 0; c < kBoardN; c++) {
        final g = board[r][c];
        if (g != null && g.special != 0) specials['$r,$c'] = g.copy();
      }
    }
    // Regenerate until the board (with specials restored) has no
    // pre-existing matches and at least one legal swap (RULES.md §7:
    // "still no pre-existing matches").
    for (int attempt = 0; attempt < 40; attempt++) {
      _newBoard();
      for (final e in specials.entries) {
        board[_kr(e.key)][_kc(e.key)] = e.value;
      }
      if (_findMatches().isEmpty) break;
    }
    _emit(const EngineEvent(EngineEventKind.shuffled,
        text: 'Tray Reshuffled')); // RULES.md §7
    notifyListeners();
  }

  // ----------------------------------------------------------------- hint

  /// Apprentice hint: 1-ply evaluation (RULES.md §11).
  /// Returns (r1,c1,r2,c2) of the suggested swap, or null if none.
  List<int>? computeHint() {
    List<int>? best;
    var bestValue = -1.0;
    for (int r = 0; r < kBoardN; r++) {
      for (int c = 0; c < kBoardN; c++) {
        for (final d in const [
          [0, 1],
          [1, 0]
        ]) {
          final r2 = r + d[0], c2 = c + d[1];
          if (r2 >= kBoardN || c2 >= kBoardN) continue;
          final v = _evalSwap(r, c, r2, c2);
          if (v != null && v > bestValue) {
            bestValue = v;
            best = [r, c, r2, c2];
          }
        }
      }
    }
    return best;
  }

  /// Null when the swap is not legal (no match, no special).
  double? _evalSwap(int r1, int c1, int r2, int c2) {
    final a = board[r1][c1];
    final b = board[r2][c2];
    if (a == null || b == null) return null;
    if (a.special != 0 || b.special != 0) {
      // Special activation: rough value by effect size.
      var size = 0;
      if (a.special == 2 && b.special == 2) {
        size = 64;
      } else if (a.special == 2 || b.special == 2) {
        final t = a.special == 2 ? b.type : a.type;
        size = _countTier(t);
      } else if ((a.special == 1 && b.special == 3) ||
          (a.special == 3 && b.special == 1)) {
        size = 25 + 15;
      } else {
        if (a.special == 1) size += 15;
        if (b.special == 1) size += 15;
        if (a.special == 3) size += 9;
        if (b.special == 3) size += 9;
      }
      return size * 60.0;
    }
    // Clone, swap, score immediate matches.
    final bd =
        List.generate(kBoardN, (r) => List.generate(kBoardN, (c) => board[r][c]?.copy()));
    bd[r1][c1] = b.copy();
    bd[r2][c2] = a.copy();
    final groups = _findMatches(bd);
    if (groups.isEmpty) return null;
    var immediate = 0.0;
    for (final g in groups) {
      immediate += g.length * 60.0;
      if (g.length >= 5) {
        immediate += 2000;
      } else if (g.length == 4) {
        immediate += 500;
      }
    }
    // One simulated gravity+refill pass for cascade estimate.
    final rng = XorShift32(0xC10C);
    for (final grp in groups) {
      for (final k in grp) {
        bd[_kr(k)][_kc(k)] = null;
      }
    }
    for (int c = 0; c < kBoardN; c++) {
      int write = kBoardN - 1;
      for (int r = kBoardN - 1; r >= 0; r--) {
        if (bd[r][c] != null) {
          bd[write][c] = bd[r][c];
          if (write != r) bd[r][c] = null;
          write--;
        }
      }
      for (int r = write; r >= 0; r--) {
        final v = rng.next() % 11;
        bd[r][c] = Gem(v == 10 ? 5 : v ~/ 2);
      }
    }
    var cascade = 0.0;
    for (final g in _findMatches(bd)) {
      cascade += g.length * 60.0 * 2;
    }
    return immediate + 0.5 * cascade; // RULES.md §11
  }

  int _countTier(int tier) {
    var n = 0;
    for (int r = 0; r < kBoardN; r++) {
      for (int c = 0; c < kBoardN; c++) {
        if (board[r][c]?.type == tier) n++;
      }
    }
    return n;
  }

  void markHintUsed() {
    hintsUsed++;
    notifyListeners();
  }

  // ------------------------------------------------------------ lifecycle

  void setPaused(bool v) {
    paused = v;
    notifyListeners();
  }

  // ------------------------------------------------------------ lifecycle
  // (restart() is defined with the mode-aware setup methods above)

  // ---------------------------------------------------------- persistence

  Map<String, dynamic> toJson() => {
        'v': 2,
        'mode': mode.index,
        'level': level,
        'score': score,
        'movesLeft': movesLeft,
        'moveCount': moveCount,
        'quotaCollected': quotaCollected,
        'hintsUsed': hintsUsed,
        'timeLeftMs': timeLeftMs,
        'board': [
          for (int r = 0; r < kBoardN; r++)
            [for (int c = 0; c < kBoardN; c++) board[r][c]?.code ?? -1]
        ],
      };

  bool restore(Map<String, dynamic> data) {
    try {
      mode = GameMode.values[(data['mode'] as num?)?.toInt() ?? 0];
      level = (data['level'] as num).toInt();
      target = LevelConfig.targetFor(level);
      movesLeft = (data['movesLeft'] as num).toInt();
      moveCount = (data['moveCount'] as num).toInt();
      score = (data['score'] as num).toInt();
      quota = LevelConfig.quotaFor(level);
      quotaCollected = (data['quotaCollected'] as num).toInt();
      hintsUsed = (data['hintsUsed'] as num).toInt();
      timeLeftMs = (data['timeLeftMs'] as num?)?.toInt() ?? 0;
      final rows = data['board'] as List;
      for (int r = 0; r < kBoardN; r++) {
        final row = rows[r] as List;
        for (int c = 0; c < kBoardN; c++) {
          final code = (row[c] as num).toInt();
          board[r][c] = code < 0 ? null : Gem.fromCode(code);
        }
      }
      busy = false;
      paused = false;
      over = false;
      won = false;
      selR = selC = -1;
      swapAnim = clearAnim = fallAnim = null;
      blastAnim = null;
      spawnCell = null;
      _quotaAnnounced = quota != null && quotaCollected >= quota!.count;
      _rng = XorShift32(level * 100003 + moveCount);
      _stamp();
      _watchdog?.cancel();
      _watchdog = Timer.periodic(const Duration(seconds: 3), (_) => _watch());
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}

class _Spawn {
  final String key;
  final int kind;
  final int type;
  _Spawn(this.key, this.kind, this.type);
}
