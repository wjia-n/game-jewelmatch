import 'package:flutter_test/flutter_test.dart';
import 'package:jewelmatch/engine/game.dart';

/// RULES.md §13 test cases against the engine.
void fillSafe(JewelEngine e) {
  for (int r = 0; r < kBoardN; r++) {
    for (int c = 0; c < kBoardN; c++) {
      e.board[r][c] = Gem((r + 2 * c) % 6);
    }
  }
}

bool hasAnyMatch(JewelEngine e) {
  for (int r = 0; r < kBoardN; r++) {
    for (int c = 0; c < kBoardN; c++) {
      final g = e.board[r][c];
      if (g == null || g.special == 2) continue;
      if (c + 2 < kBoardN &&
          e.board[r][c + 1]?.type == g.type &&
          e.board[r][c + 1]?.special != 2 &&
          e.board[r][c + 2]?.type == g.type &&
          e.board[r][c + 2]?.special != 2) {
        return true;
      }
      if (r + 2 < kBoardN &&
          e.board[r + 1][c]?.type == g.type &&
          e.board[r + 1][c]?.special != 2 &&
          e.board[r + 2][c]?.type == g.type &&
          e.board[r + 2][c]?.special != 2) {
        return true;
      }
    }
  }
  return false;
}

void main() {
  test('startLevel: no pre-existing matches, target/moves per RULES §2',
      () {
    final e = JewelEngine();
    e.startLevel(1);
    expect(e.target, 12000);
    expect(e.movesLeft, 30);
    expect(hasAnyMatch(e), isFalse);
  });

  test('RULES 1: swap produces horizontal 3 → +180, move consumed', () async {
    final e = JewelEngine();
    e.startLevel(1);
    fillSafe(e);
    // col 0: (0,0)=0,(1,0)=1,(2,0)=0 → swap (1,0)<->(1,1) with (1,1)=0
    e.board[2][0] = Gem(0);
    e.board[1][1] = Gem(0);
    e.movesLeft = 30;
    e.score = 0;
    await e.trySwap(1, 0, 1, 1);
    expect(e.movesLeft, 29);
    expect(e.score >= 180, isTrue,
        reason: '3 rubies x 60 = 180, got ${e.score}');
    expect(hasAnyMatch(e), isFalse);
    expect(e.busy, isFalse);
  });

  test('RULES 2: horizontal 4 → Faceted Bar + 740', () async {
    final e = JewelEngine();
    e.startLevel(1);
    fillSafe(e);
    // row2: (2,0)=0,(2,1)=0,(2,2)=1,(2,3)=0 → swap (2,2)<->(3,2) w/ (3,2)=0
    e.board[2][0] = Gem(0);
    e.board[2][1] = Gem(0);
    e.board[2][2] = Gem(1);
    e.board[2][3] = Gem(0);
    e.board[3][2] = Gem(0);
    e.movesLeft = 30;
    e.score = 0;
    var barForged = false;
    e.addListener(() {
      for (final ev in e.takeEvents()) {
        if (ev.kind == EngineEventKind.specialCreated &&
            ev.specialKind == 1) {
          barForged = true;
        }
      }
    });
    await e.trySwap(2, 2, 3, 2);
    expect(barForged, isTrue,
        reason: 'Faceted Bar forged at swap origin');
    expect(e.score >= 740, isTrue,
        reason: '4x60 + 500 bar bonus = 740, got ${e.score}');
  });

  test('RULES 3: match 5 → Prismatic Diamond + 2300', () async {
    final e = JewelEngine();
    e.startLevel(1);
    fillSafe(e);
    // row1: 2,2,1,2,2 → swap (1,2)<->(2,2) with (2,2)=2 → five 2s
    e.board[1][0] = Gem(2);
    e.board[1][1] = Gem(2);
    e.board[1][2] = Gem(1);
    e.board[1][3] = Gem(2);
    e.board[1][4] = Gem(2);
    e.board[2][2] = Gem(2);
    e.movesLeft = 30;
    e.score = 0;
    await e.trySwap(1, 2, 2, 2);
    expect(e.board[1][2]?.special, 2,
        reason: 'Prismatic Diamond forged at swap origin');
    expect(e.score >= 2300, isTrue,
        reason: '5x60 + 2000 prismatic bonus = 2300, got ${e.score}');
  });

  test('RULES 4: L-shaped 5-match → Brilliant + 1300', () async {
    final e = JewelEngine();
    e.startLevel(1);
    fillSafe(e);
    // corner (2,3): row2 c1..c3 and col3 r0..r2 complete on swap (2,3)<->(2,4)
    e.board[2][1] = Gem(0);
    e.board[2][3] = Gem(1);
    e.board[2][4] = Gem(0);
    e.board[1][3] = Gem(0);
    e.movesLeft = 30;
    e.score = 0;
    await e.trySwap(2, 3, 2, 4);
    expect(e.score >= 1300, isTrue,
        reason: '5x60 + 1000 brilliant bonus = 1300, got ${e.score}');
    final specials = <String>[];
    for (int r = 0; r < kBoardN; r++) {
      for (int c = 0; c < kBoardN; c++) {
        if (e.board[r][c]?.special == 3) specials.add('$r,$c');
      }
    }
    expect(specials.isNotEmpty, isTrue,
        reason: 'a Brilliant should exist on the board');
  });

  test('RULES 5: illegal swap bounces back, move not consumed', () async {
    final e = JewelEngine();
    e.startLevel(1);
    fillSafe(e);
    e.movesLeft = 30;
    final before = e.board[0][0]!.type;
    await e.trySwap(0, 0, 0, 1); // 0 vs 2 in safe pattern: no match
    expect(e.movesLeft, 30);
    expect(e.board[0][0]!.type, before);
    expect(e.busy, isFalse);
  });

  test('RULES 7: Prismatic activation clears the other gem tier',
      () async {
    final e = JewelEngine();
    e.startLevel(1);
    fillSafe(e);
    e.board[3][3] = Gem(0, 2); // prismatic
    e.board[3][4] = Gem(4); // topaz
    e.movesLeft = 30;
    e.score = 0;
    var topaz = 0;
    for (int r = 0; r < kBoardN; r++) {
      for (int c = 0; c < kBoardN; c++) {
        if (e.board[r][c]?.type == 4) topaz++;
      }
    }
    await e.trySwap(3, 3, 3, 4);
    var topazAfter = 0;
    for (int r = 0; r < kBoardN; r++) {
      for (int c = 0; c < kBoardN; c++) {
        if (e.board[r][c]?.type == 4) topazAfter++;
      }
    }
    // All topazes cleared (refills may reintroduce some, but the
    // detonation cleared at least the original count).
    expect(topazAfter < topaz, isTrue,
        reason: 'topaz $topaz → $topazAfter');
    expect(e.movesLeft, 29);
  });

  test('RULES 10: win on last move', () async {
    final e = JewelEngine();
    e.startLevel(1);
    fillSafe(e);
    e.board[2][0] = Gem(0);
    e.board[1][1] = Gem(0);
    e.movesLeft = 1;
    e.score = 11900; // target 12000
    var won = false;
    e.addListener(() {
      for (final ev in e.takeEvents()) {
        if (ev.kind == EngineEventKind.win) won = true;
      }
    });
    await e.trySwap(1, 0, 1, 1);
    expect(e.over, isTrue);
    expect(e.won, isTrue);
    expect(won, isTrue);
  });

  test('RULES 11: defeat when moves run out below target', () async {
    final e = JewelEngine();
    e.startLevel(1);
    fillSafe(e);
    e.board[2][0] = Gem(0);
    e.board[1][1] = Gem(0);
    e.movesLeft = 1;
    e.score = 0;
    var lost = false;
    e.addListener(() {
      for (final ev in e.takeEvents()) {
        if (ev.kind == EngineEventKind.lose) lost = true;
      }
    });
    await e.trySwap(1, 0, 1, 1);
    expect(e.over, isTrue);
    expect(e.won, isFalse);
    expect(lost, isTrue);
  });

  test('RULES 12: quota level config (level 6 = 20 Rubies)', () {
    expect(LevelConfig.quotaFor(5), isNull);
    final q = LevelConfig.quotaFor(6)!;
    expect(q.tier, 0);
    expect(q.count, 20);
  });

  test('persistence round-trip', () {
    final e = JewelEngine();
    e.startLevel(7);
    fillSafe(e);
    e.score = 4242;
    e.movesLeft = 17;
    final data = e.toJson();
    final e2 = JewelEngine();
    expect(e2.restore(data), isTrue);
    expect(e2.level, 7);
    expect(e2.score, 4242);
    expect(e2.movesLeft, 17);
    expect(e2.quota, isNotNull);
  });

  test('watchdog: recovers a stalled busy lock (no stuck states)', () {
    final e = JewelEngine();
    e.startLevel(1);
    // Simulate a dead await chain: busy with no heartbeat for 9s.
    e.busy = true;
    e.debugAgeStamp(9000);
    e.debugWatchdogTick();
    expect(e.busy, isFalse,
        reason: 'watchdog must release a stalled busy lock');
    e.dispose();
  });

  test('watchdog: leaves a progressing resolution alone', () async {
    final e = JewelEngine();
    e.startLevel(1);
    fillSafe(e);
    e.board[2][0] = Gem(0);
    e.board[1][1] = Gem(0);
    // Start a swap (busy), tick the watchdog mid-flight: fresh heartbeat
    // means no recovery.
    final f = e.trySwap(1, 0, 1, 1);
    e.debugWatchdogTick();
    expect(e.busy, isTrue);
    await f;
    expect(e.busy, isFalse);
    e.dispose();
  });

  test('RULES 6: cascade multiplier x2 on the refill cascade', () async {
    final e = JewelEngine();
    e.startLevel(1);
    fillSafe(e);
    // Seeded refill RNG for level 1, first move: seed = 100003 + 1.
    // Column 0 refills rows 2,1,0 with the first three draws.
    final rng = XorShift32(100003 + 1);
    int wtype() {
      final v = rng.next() % 11;
      return v == 10 ? 5 : v ~/ 2;
    }

    final t1 = wtype();
    wtype(); // row-1 refill type (documented draw order)
    wtype(); // row-0 refill type (documented draw order)
    // Rows 0,1 will fall to rows 3,4; refill row 2 = t1 → vertical 3.
    e.board[0][0] = Gem(t1);
    e.board[1][0] = Gem(t1);
    // Swap completes a vertical 3 of type 1 at rows 5,6,7 col 0.
    e.board[5][0] = Gem(1);
    e.board[6][0] = Gem(1);
    e.board[7][0] = Gem(2);
    e.board[7][1] = Gem(1);
    e.movesLeft = 30;
    e.score = 0;
    await e.trySwap(7, 0, 7, 1);
    // Step 1: 3x60x1 = 180; cascade step 2: 3x60x2 = 360 → ≥ 540 total.
    expect(e.score >= 540, isTrue,
        reason: 'cascade x2 expected, score=${e.score}');
    expect(e.bestCombo >= 2, isTrue,
        reason: 'bestCombo should record the cascade');
    e.dispose();
  });

  test('RULES 7/12: prismatic + prismatic clears the whole tray',
      () async {
    final e = JewelEngine();
    e.startLevel(1);
    fillSafe(e);
    e.board[3][3] = Gem(0, 2);
    e.board[3][4] = Gem(1, 2);
    e.movesLeft = 30;
    e.score = 0;
    await e.trySwap(3, 3, 3, 4);
    var nulls = 0;
    for (int r = 0; r < kBoardN; r++) {
      for (int c = 0; c < kBoardN; c++) {
        if (e.board[r][c] == null) nulls++;
      }
    }
    expect(nulls, 0, reason: 'whole tray cleared and refilled');
    expect(e.score >= 64 * 60, isTrue,
        reason: 'all 64 cells score, got ${e.score}');
    expect(e.movesLeft, 29);
    e.dispose();
  });

  test('RULES 8/9: shuffle keeps specials, no pre-existing matches', () {
    final e = JewelEngine();
    e.startLevel(1);
    fillSafe(e);
    e.board[0][0] = Gem(2, 1); // bar
    e.board[7][7] = Gem(4, 3); // brilliant
    e.board[3][3] = Gem(0, 2); // prismatic
    e.debugShuffle();
    var specials = 0;
    for (int r = 0; r < kBoardN; r++) {
      for (int c = 0; c < kBoardN; c++) {
        if (e.board[r][c]?.special != 0) specials++;
      }
    }
    expect(specials, 3, reason: 'specials survive the reshuffle');
    expect(hasAnyMatch(e), isFalse,
        reason: 'reshuffled tray has no pre-existing matches');
    e.dispose();
  });

  test('RULES 13: hint is deterministic on the same board', () {
    final e = JewelEngine();
    e.startLevel(3); // real generated board: guaranteed >= 1 legal swap
    final h1 = e.computeHint();
    final h2 = e.computeHint();
    expect(h1, isNotNull);
    expect(h2, isNotNull);
    expect(h1.toString(), h2.toString());
    e.dispose();
  });

  test('RULES 14: refill determinism — same setup, same score', () async {
    Future<int> runOnce() async {
      final e = JewelEngine();
      e.startLevel(1);
      fillSafe(e);
      e.board[2][0] = Gem(0);
      e.board[1][1] = Gem(0);
      e.movesLeft = 30;
      e.score = 0;
      await e.trySwap(1, 0, 1, 1);
      final s = e.score;
      e.dispose();
      return s;
    }

    final a = await runOnce();
    final b = await runOnce();
    expect(a, b, reason: 'seeded refills must be deterministic');
  });

  test('endless mode: unlimited moves, never wins or loses by itself',
      () async {
    final e = JewelEngine();
    e.startEndless();
    expect(e.mode, GameMode.endless);
    expect(e.movesLeft, -1);
    fillSafe(e);
    e.board[2][0] = Gem(0);
    e.board[1][1] = Gem(0);
    await e.trySwap(1, 0, 1, 1);
    expect(e.movesLeft, -1, reason: 'endless never consumes the dial');
    expect(e.over, isFalse);
    expect(e.score > 0, isTrue);
    e.dispose();
  });

  test('timed mode: clock armed, unlimited moves', () {
    final e = JewelEngine();
    e.startTimed(120);
    expect(e.mode, GameMode.timed);
    expect(e.timeLeftMs, 120000);
    expect(e.movesLeft, -1);
    expect(e.over, isFalse);
    e.dispose();
  });

  test('identical swaps are rejected without consuming a move', () async {
    final e = JewelEngine();
    e.startLevel(1);
    fillSafe(e);
    // (0,0)=0 and (0,1)=2 in the safe pattern; force identical pair.
    e.board[0][1] = Gem(0);
    e.movesLeft = 30;
    await e.trySwap(0, 0, 0, 1);
    expect(e.movesLeft, 30, reason: 'RULES §5: no-op swap is free');
    expect(e.busy, isFalse);
    e.dispose();
  });
}
