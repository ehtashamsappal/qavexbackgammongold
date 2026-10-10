/// Backgammon AI with four difficulty levels.
///
/// Search strategy: generate all legal move sequences, score the resulting
/// position with a heuristic evaluation, and (for harder levels) subtract the
/// opponent's expected reply value sampled over the 21 distinct dice rolls.
/// Every level honours a strict wall-clock budget and can never hang.
library;

import 'dart:math';
import '../rules/backgammon_engine.dart';

enum AiLevel { easy, medium, hard, expert }

extension AiLevelInfo on AiLevel {
  String get label {
    switch (this) {
      case AiLevel.easy:
        return 'Easy';
      case AiLevel.medium:
        return 'Medium';
      case AiLevel.hard:
        return 'Hard';
      case AiLevel.expert:
        return 'Expert';
    }
  }

  /// Wall-clock budget in milliseconds.
  int get timeBudgetMs {
    switch (this) {
      case AiLevel.easy:
        return 50;
      case AiLevel.medium:
        return 250;
      case AiLevel.hard:
        return 900;
      case AiLevel.expert:
        return 2200;
    }
  }

  /// How many of the 21 distinct opponent dice rolls to sample.
  int get replySamples {
    switch (this) {
      case AiLevel.easy:
        return 0;
      case AiLevel.medium:
        return 0;
      case AiLevel.hard:
        return 7;
      case AiLevel.expert:
        return 21;
    }
  }
}

class AiMove {
  final List<BgMove> sequence;
  final double score;
  AiMove(this.sequence, this.score);
}

class BackgammonAi {
  final Random _rng;

  BackgammonAi({int? seed}) : _rng = Random(seed);

  /// Choose a move sequence for [ai] given the position and remaining [dice].
  /// Returns the empty sequence when no move is possible.
  AiMove choose(Position pos, Checker ai, List<int> dice, AiLevel level) {
    final stopwatch = Stopwatch()..start();
    final budget = level.timeBudgetMs;
    final engine = RulesEngine(pos, turn: ai, dice: List.of(dice));
    final sequences = engine.generateSequences();
    if (sequences.isEmpty || sequences.every((s) => s.isEmpty)) {
      return AiMove(const [], 0);
    }
    final legal = sequences.where((s) => s.isNotEmpty).toList();

    if (level == AiLevel.easy) {
      return AiMove(legal[_rng.nextInt(legal.length)], 0);
    }

    AiMove? best;
    final shuffled = List.of(legal)..shuffle(_rng);
    for (final seq in shuffled) {
      if (stopwatch.elapsedMilliseconds > budget) break;
      final after = pos.copy();
      final e = RulesEngine(after, turn: ai, dice: List.of(dice));
      for (final m in seq) {
        e.applyMove(m);
      }
      double score = _evaluate(after, ai);
      if (level.replySamples > 0) {
        score -= _expectedReply(after, ai, level, stopwatch, budget);
      }
      if (best == null || score > best.score) {
        best = AiMove(seq, score);
      }
    }
    return best ?? AiMove(legal.first, 0);
  }

  /// Heuristic evaluation from [me]'s perspective.
  double _evaluate(Position p, Checker me) {
    final opp = otherChecker(me);
    if (p.winner == me) return 100000;
    if (p.winner == opp) return -100000;

    double score = 0;
    // Pip race: fewer pips is better.
    score += (p.pipCount(opp) - p.pipCount(me)) * 1.0;
    // Borne-off checkers are very good.
    score += (p.off(me) - p.off(opp)) * 25.0;
    // Blots exposed are bad; enemy blots are good.
    score += (p.blots(opp) - p.blots(me)) * 8.0;
    // Checkers on the bar are bad.
    score += (p.bar(opp) - p.bar(me)) * 20.0;
    // Anchors / made points: count points held with 2+.
    int madeMe = 0, madeOpp = 0;
    for (int i = 0; i < 24; i++) {
      final v = p.points[i];
      if (me == Checker.white && v >= 2) madeMe++;
      if (me == Checker.black && v <= -2) madeMe++;
      if (me == Checker.white && v <= -2) madeOpp++;
      if (me == Checker.black && v >= 2) madeOpp++;
    }
    score += (madeMe - madeOpp) * 3.0;
    // Primes in home board.
    score += _homePrime(p, me) * 4.0 - _homePrime(p, opp) * 4.0;
    return score;
  }

  double _homePrime(Position p, Checker c) {
    int run = 0, best = 0;
    final lo = c == Checker.white ? 0 : 18;
    final hi = c == Checker.white ? 5 : 23;
    for (int i = lo; i <= hi; i++) {
      final v = p.points[i];
      final mine = c == Checker.white ? v >= 2 : v <= -2;
      if (mine) {
        run++;
        if (run > best) best = run;
      } else {
        run = 0;
      }
    }
    return best >= 3 ? best.toDouble() : 0;
  }

  /// Expected value of the opponent's best reply, sampled over distinct rolls.
  double _expectedReply(
      Position after, Checker me, AiLevel level, Stopwatch sw, int budget) {
    final opp = otherChecker(me);
    final rolls = _distinctRolls();
    final samples = level.replySamples;
    final step = (rolls.length / samples).ceil();
    double total = 0;
    int count = 0;
    for (int i = 0; i < rolls.length; i += step) {
      if (sw.elapsedMilliseconds > budget) break;
      final dice = rolls[i];
      final replyPos = after.copy();
      final e = RulesEngine(replyPos, turn: opp, dice: List.of(dice));
      final seqs = e.generateSequences().where((s) => s.isNotEmpty).toList();
      double bestReply = 0;
      for (final s in seqs) {
        if (sw.elapsedMilliseconds > budget) break;
        final p2 = after.copy();
        final e2 = RulesEngine(p2, turn: opp, dice: List.of(dice));
        for (final m in s) {
          e2.applyMove(m);
        }
        // Evaluate from opponent's perspective, then negate.
        final v = _evaluate(p2, opp);
        if (v > bestReply) bestReply = v;
      }
      // Weight doubles rolls half (probability 1/36 vs 1/18).
      final weight = dice[0] == dice[1] ? 1.0 : 2.0;
      total += bestReply * weight;
      count += weight.toInt();
    }
    if (count == 0) return 0;
    return total / count;
  }

  /// The 21 distinct dice rolls (unordered), doubles expanded to 4 dice.
  List<List<int>> _distinctRolls() {
    final out = <List<int>>[];
    for (int a = 1; a <= 6; a++) {
      for (int b = a; b <= 6; b++) {
        out.add(a == b ? [a, a, a, a] : [a, b]);
      }
    }
    return out;
  }

  /// Should the AI offer the doubling cube? Heuristic for harder levels.
  bool shouldOfferDouble(Position p, Checker me, AiLevel level, int cubeValue) {
    if (level == AiLevel.easy) return _rng.nextDouble() < 0.05;
    final eval = _evaluate(p, me);
    final threshold = level == AiLevel.expert ? 40.0 : 70.0;
    return eval > threshold && _rng.nextDouble() < (level == AiLevel.hard ? 0.6 : 0.85);
  }

  /// Should the AI accept an offered double?
  bool shouldAcceptDouble(Position p, Checker me, AiLevel level) {
    if (level == AiLevel.easy) return _rng.nextDouble() < 0.8;
    final eval = _evaluate(p, me);
    // Accept unless clearly losing.
    return eval > (level == AiLevel.expert ? -60.0 : -35.0);
  }
}
