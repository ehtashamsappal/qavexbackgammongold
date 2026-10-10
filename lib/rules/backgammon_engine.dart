/// Pure-Dart official backgammon rules engine.
///
/// Board model: 24 points numbered 1..24 (internal index 0..23).
/// WHITE moves from point 24 down to point 1 and bears off from 1..6.
/// BLACK moves from point 1 up to point 24 and bears off from 19..24.
///
/// [points] holds signed checker counts: positive = white, negative = black.
/// Bar counts and borne-off counts are tracked separately.
library;

enum Checker { white, black }

Checker otherChecker(Checker c) => c == Checker.white ? Checker.black : Checker.white;

/// A single checker move: from point 1..24, 25 = player's bar, 0 = borne off.
class BgMove {
  final int from;
  final int to;
  final int die;
  final bool hit;

  const BgMove(this.from, this.to, this.die, {this.hit = false});

  @override
  String toString() => 'Move($from->$to d$die${hit ? ' HIT' : ''})';

  @override
  bool operator ==(Object other) =>
      other is BgMove && other.from == from && other.to == to && other.die == die;

  @override
  int get hashCode => Object.hash(from, to, die);
}

/// Complete, immutable-ish snapshot of a backgammon position.
class Position {
  final List<int> points; // len 24, signed
  int barWhite = 0;
  int barBlack = 0;
  int offWhite = 0;
  int offBlack = 0;

  Position({List<int>? points}) : points = points ?? List<int>.filled(24, 0);

  Position.clone(Position o)
      : points = List<int>.of(o.points),
        barWhite = o.barWhite,
        barBlack = o.barBlack,
        offWhite = o.offWhite,
        offBlack = o.offBlack;

  Position copy() => Position.clone(this);

  /// Standard starting position.
  factory Position.standard() {
    final p = Position();
    // White: 24:2, 13:5, 8:3, 6:5
    p.points[23] = 2;
    p.points[12] = 5;
    p.points[7] = 3;
    p.points[5] = 5;
    // Black: 1:2, 12:5, 17:3, 19:5
    p.points[0] = -2;
    p.points[11] = -5;
    p.points[16] = -3;
    p.points[18] = -5;
    return p;
  }

  int bar(Checker c) => c == Checker.white ? barWhite : barBlack;
  int off(Checker c) => c == Checker.white ? offWhite : offBlack;

  int pipCount(Checker c) {
    int total = 0;
    for (int i = 0; i < 24; i++) {
      final n = points[i];
      if (n == 0) continue;
      final pt = i + 1; // point number 1..24
      if (c == Checker.white && n > 0) {
        total += n * pt;
      } else if (c == Checker.black && n < 0) {
        total += (-n) * (25 - pt);
      }
    }
    total += bar(c) * 25;
    return total;
  }

  /// Number of blots (single exposed checkers) for [c].
  int blots(Checker c) {
    int n = 0;
    for (int i = 0; i < 24; i++) {
      final v = points[i];
      if (c == Checker.white && v == 1) n++;
      if (c == Checker.black && v == -1) n++;
    }
    return n;
  }

  /// All checkers of [c] are inside the home board (and none on bar/off excluded).
  bool allInHome(Checker c) {
    if (bar(c) > 0) return false;
    for (int i = 0; i < 24; i++) {
      final v = points[i];
      if (v == 0) continue;
      final pt = i + 1;
      if (c == Checker.white && v > 0 && pt > 6) return false;
      if (c == Checker.black && v < 0 && pt < 19) return false;
    }
    return true;
  }

  bool get isGameOver => offWhite == 15 || offBlack == 15;
  Checker? get winner =>
      offWhite == 15 ? Checker.white : (offBlack == 15 ? Checker.black : null);

  /// Gammon: the loser has not borne off a single checker. (Position of the
  /// loser's remaining checkers does not matter for a gammon.)
  bool isGammon(Checker winnerC) {
    final loser = otherChecker(winnerC);
    return off(loser) == 0;
  }

  /// Backgammon: a gammon, and the loser still has a checker on the bar or
  /// inside the winner's home board.
  bool isBackgammon(Checker winnerC) {
    final loser = otherChecker(winnerC);
    if (off(loser) > 0) return false;
    if (bar(loser) > 0) return true;
    for (int i = 0; i < 24; i++) {
      final v = points[i];
      if (v == 0) continue;
      final pt = i + 1;
      // Winner white -> winner's home is points 1..6: black (v<0) there?
      // Winner black -> winner's home is points 19..24: white (v>0) there?
      if (loser == Checker.black && v < 0 && pt <= 6) return true;
      if (loser == Checker.white && v > 0 && pt >= 19) return true;
    }
    return false;
  }
}

/// Legal move generation and move application for a single turn.
class RulesEngine {
  final Position pos;
  Checker turn;
  List<int> dice; // remaining dice values

  RulesEngine(this.pos, {required this.turn, required this.dice});

  /// Internal: destination point number for a checker of [c] on point [from]
  /// (1..24, 25 = bar) using die [d]. Returns null if the move is illegal.
  /// to == 0 means bear off.
  _Dest? _destination(Checker c, int from, int d) {
    int target;
    if (from == 25) {
      // re-enter from bar
      target = c == Checker.white ? 25 - d : d;
    } else {
      target = c == Checker.white ? from - d : from + d;
    }
    // Bear off?
    if (c == Checker.white && target < 1) {
      if (!pos.allInHome(c)) return null;
      if (target == 0) return const _Dest(0, true);
      // target < 0: allowed only from the highest occupied point when no
      // checker sits on a higher point than [from].
      if (from - d < 0) {
        for (int pt = from + 1; pt <= 6; pt++) {
          if (pos.points[pt - 1] > 0) return null;
        }
        return const _Dest(0, true);
      }
      return null;
    }
    if (c == Checker.black && target > 24) {
      if (!pos.allInHome(c)) return null;
      if (target == 25) return const _Dest(0, true);
      if (from + d > 25) {
        for (int pt = 18; pt < from; pt++) {
          if (pos.points[pt] < 0) return null;
        }
        return const _Dest(0, true);
      }
      return null;
    }
    if (target < 1 || target > 24) return null;
    final v = pos.points[target - 1];
    if (c == Checker.white && v <= -2) return null;
    if (c == Checker.black && v >= 2) return null;
    final hit = (c == Checker.white && v == -1) || (c == Checker.black && v == 1);
    return _Dest(target, false, hit: hit);
  }

  /// All origin points (1..24, 25 = bar) that currently hold a movable checker.
  List<int> _origins(Checker c) {
    if (pos.bar(c) > 0) return [25]; // must enter from bar first
    final out = <int>[];
    for (int pt = 1; pt <= 24; pt++) {
      final v = pos.points[pt - 1];
      if (c == Checker.white && v > 0) out.add(pt);
      if (c == Checker.black && v < 0) out.add(pt);
    }
    return out;
  }

  /// Apply a single move to [pos] (mutating). Assumes the move is legal.
  void applyMove(BgMove m) {
    // remove from origin
    if (m.from == 25) {
      if (turn == Checker.white) {
        pos.barWhite--;
      } else {
        pos.barBlack--;
      }
    } else {
      final i = m.from - 1;
      pos.points[i] += turn == Checker.white ? -1 : 1;
    }
    // place at destination
    if (m.to == 0) {
      if (turn == Checker.white) {
        pos.offWhite++;
      } else {
        pos.offBlack++;
      }
    } else {
      final i = m.to - 1;
      if (m.hit) {
        pos.points[i] = 0;
        if (turn == Checker.white) {
          pos.barBlack++;
          pos.points[i] = 1;
        } else {
          pos.barWhite++;
          pos.points[i] = -1;
        }
      } else {
        pos.points[i] += turn == Checker.white ? 1 : -1;
      }
    }
  }

  /// Generate every maximally-legal move sequence for the current dice,
  /// enforcing the "use the maximum number of dice" rule and, when only one
  /// die can be played, the "use the higher die" rule.
  List<List<BgMove>> generateSequences() {
    final results = <List<BgMove>>[];
    _expand(dice, <BgMove>[], results);
    if (results.isEmpty) return [[]];
    int maxLen = 0;
    for (final s in results) {
      if (s.length > maxLen) maxLen = s.length;
    }
    var kept = results.where((s) => s.length == maxLen).toList();
    if (maxLen == 1) {
      int maxDie = 0;
      for (final s in kept) {
        if (s.first.die > maxDie) maxDie = s.first.die;
      }
      kept = kept.where((s) => s.first.die == maxDie).toList();
    }
    // de-duplicate
    final seen = <String>{};
    final unique = <List<BgMove>>[];
    for (final s in kept) {
      final key = s.map((m) => '${m.from}-${m.to}-${m.die}').join('|');
      if (seen.add(key)) unique.add(s);
    }
    return unique;
  }

  void _expand(List<int> remaining, List<BgMove> prefix, List<List<BgMove>> out) {
    if (remaining.isEmpty) {
      out.add(List<BgMove>.of(prefix));
      return;
    }
    bool moved = false;
    final tried = <String>{};
    final diceSet = remaining.toSet().toList()..sort();
    for (final origin in _origins(turn)) {
      for (final d in diceSet) {
        final dest = _destination(turn, origin, d);
        if (dest == null) continue;
        final key = '$origin-${dest.point}-$d';
        if (!tried.add(key)) continue;
        moved = true;
        final snapshot = pos.copy();
        final mv = BgMove(origin, dest.point, d, hit: dest.hit);
        applyMove(mv);
        final next = List<int>.of(remaining)..remove(d);
        prefix.add(mv);
        _expand(next, prefix, out);
        prefix.removeLast();
        // restore
        pos.points.setAll(0, snapshot.points);
        pos.barWhite = snapshot.barWhite;
        pos.barBlack = snapshot.barBlack;
        pos.offWhite = snapshot.offWhite;
        pos.offBlack = snapshot.offBlack;
      }
    }
    if (!moved) out.add(List<BgMove>.of(prefix));
  }

  /// Convenience: legal single moves for one die value (used for UI hints).
  List<BgMove> legalSingles(int die) {
    final out = <BgMove>[];
    for (final origin in _origins(turn)) {
      final dest = _destination(turn, origin, die);
      if (dest != null) {
        out.add(BgMove(origin, dest.point, die, hit: dest.hit));
      }
    }
    return out;
  }
}

class _Dest {
  final int point; // 0 = bear off
  final bool bearOff;
  final bool hit;
  const _Dest(this.point, this.bearOff, {this.hit = false});
}

/// Doubling cube state.
class DoublingCube {
  int value = 1;
  Checker? owner; // null = in the center (either may double)

  DoublingCube();

  DoublingCube.clone(DoublingCube o) {
    value = o.value;
    owner = o.owner;
  }

  DoublingCube copy() => DoublingCube.clone(this);

  bool canOffer(Checker c) => value < 64 && (owner == null || owner != c);

  /// Opponent accepts: cube doubles and ownership passes to the accepter.
  void accept(Checker accepter) {
    value *= 2;
    owner = accepter;
  }
}
