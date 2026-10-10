// Unit tests for the backgammon AI: legality, difficulty tiers, time budgets.
// Run: dart test
import 'package:test/test.dart';
import 'package:qavexbackgammongold/ai/ai.dart';
import 'package:qavexbackgammongold/rules/backgammon_engine.dart';

/// Applies [seq] on a clone and verifies the result equals the AI's implied
/// position — i.e. every returned move is actually legal.
void expectLegalSequence(
    Position before, Checker ai, List<int> dice, List<BgMove> seq) {
  final q = before.copy();
  final e = RulesEngine(q, turn: ai, dice: List.of(dice));
  for (final m in seq) {
    // the move must be among currently-legal singles for its die
    final legal = e.legalSingles(m.die);
    expect(legal, contains(m),
        reason: 'AI returned illegal move $m on dice $dice');
    e.applyMove(m);
  }
}

void main() {
  final ai = BackgammonAi(seed: 42);

  group('choose()', () {
    test('returns a legal maximal sequence for every level', () {
      final dice = [4, 2];
      for (final level in AiLevel.values) {
        final pos = Position.standard();
        final result = ai.choose(pos, Checker.black, List.of(dice), level);
        expectLegalSequence(pos, Checker.black, dice, result.sequence);
        expect(result.sequence, isNotEmpty);
      }
    });

    test('empty sequence when no move is possible', () {
      final p = Position();
      p.points[23] = 1; // white on 24
      // black walls on every reachable point for dice 6,5
      for (final pt in [18, 19]) {
        p.points[pt - 1] = -2;
      }
      final result = ai.choose(p, Checker.white, [6, 5], AiLevel.medium);
      expect(result.sequence, isEmpty);
    });

    test('handles doubles and bear-off positions', () {
      final p = Position();
      p.points[0] = 3;
      p.points[1] = 3;
      p.points[2] = 3;
      p.points[3] = 2;
      p.points[4] = 2;
      p.points[5] = 2;
      final result =
          ai.choose(p, Checker.white, [6, 6, 6, 6], AiLevel.expert);
      expectLegalSequence(p, Checker.white, [6, 6, 6, 6], result.sequence);
      expect(result.sequence.length, greaterThan(0));
    });

    test('respects time budgets for hard/expert', () {
      final pos = Position.standard();
      for (final level in [AiLevel.hard, AiLevel.expert]) {
        final sw = Stopwatch()..start();
        ai.choose(pos, Checker.black, [3, 1], level);
        sw.stop();
        // generous ceiling: budget + 1.5s of scheduling slack
        expect(sw.elapsedMilliseconds,
            lessThan(level.timeBudgetMs + 1500),
            reason: '${level.label} exceeded its time budget');
      }
    });

    test('easy is fast and returns legal moves', () {
      final sw = Stopwatch()..start();
      final result =
          ai.choose(Position.standard(), Checker.black, [5, 3], AiLevel.easy);
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(2000));
      expectLegalSequence(
          Position.standard(), Checker.black, [5, 3], result.sequence);
    });
  });

  group('AiLevelInfo', () {
    test('four levels with labels and increasing budgets', () {
      expect(AiLevel.values.length, 4);
      final labels = AiLevel.values.map((l) => l.label).toList();
      expect(labels, ['Easy', 'Medium', 'Hard', 'Expert']);
      final budgets =
          AiLevel.values.map((l) => l.timeBudgetMs).toList();
      for (int i = 1; i < budgets.length; i++) {
        expect(budgets[i], greaterThan(budgets[i - 1]));
      }
    });
  });

  group('doubling decisions', () {
    test('shouldOfferDouble / shouldAcceptDouble return booleans safely', () {
      final p = Position.standard();
      for (final level in AiLevel.values) {
        final offer =
            ai.shouldOfferDouble(p, Checker.black, level, 1);
        final accept = ai.shouldAcceptDouble(p, Checker.black, level);
        expect(offer, isA<bool>());
        expect(accept, isA<bool>());
      }
    });

    test('expert accepts a roughly-even double', () {
      final p = Position.standard();
      expect(ai.shouldAcceptDouble(p, Checker.black, AiLevel.expert), isTrue);
    });
  });

  group('determinism with seed', () {
    test('same seed + easy level picks consistently', () {
      final a1 = BackgammonAi(seed: 7);
      final a2 = BackgammonAi(seed: 7);
      final pos = Position.standard();
      final r1 = a1.choose(pos, Checker.black, [6, 1], AiLevel.easy);
      final r2 = a2.choose(pos, Checker.black, [6, 1], AiLevel.easy);
      expect(r1.sequence.map((m) => m.toString()).toList(),
          r2.sequence.map((m) => m.toString()).toList());
    });
  });
}
