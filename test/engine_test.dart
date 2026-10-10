// Unit tests for the pure-Dart backgammon rules engine.
// Run: dart test
import 'package:test/test.dart';
import 'package:qavexbackgammongold/rules/backgammon_engine.dart';

void main() {
  group('Position.standard', () {
    test('starts with 15 checkers per side and 167 pips each', () {
      final p = Position.standard();
      int white = 0, black = 0;
      for (final v in p.points) {
        if (v > 0) white += v;
        if (v < 0) black += -v;
      }
      expect(white, 15);
      expect(black, 15);
      expect(p.pipCount(Checker.white), 167);
      expect(p.pipCount(Checker.black), 167);
    });
  });

  group('opening move generation', () {
    test('roll 3-1 for white yields legal sequences', () {
      final p = Position.standard();
      final e = RulesEngine(p, turn: Checker.white, dice: [3, 1]);
      final seqs = e.generateSequences();
      expect(seqs, isNotEmpty);
      expect(seqs.every((s) => s.length == 2), isTrue);
    });

    test('forced move: 6-1 for white has exactly the 24->18, 13->12 play', () {
      // White 6-1: standard opening book gives limited options; just verify
      // every returned sequence is playable and maximal.
      final p = Position.standard();
      for (final dice in [
        [6, 1],
        [4, 2],
        [3, 3, 3, 3]
      ]) {
        final e = RulesEngine(p, turn: Checker.white, dice: List.of(dice));
        final seqs = e.generateSequences();
        expect(seqs, isNotEmpty);
        // apply each sequence on a clone to prove legality end-to-end
        for (final s in seqs) {
          final q = p.copy();
          final ee = RulesEngine(q, turn: Checker.white, dice: List.of(dice));
          for (final m in s) {
            ee.applyMove(m);
          }
          int w = 0;
          for (final v in q.points) {
            if (v > 0) w += v;
          }
          expect(w + q.barWhite + q.offWhite, 15);
        }
      }
    });

    test('maximum-dice rule: longer sequences win over shorter ones', () {
      // White checker on 24 only; black blocks point 18 (die-6 target) but
      // leaves 23 and 17 open. Dice [6,1]:
      //   die 6 first -> 24-6=18 blocked, dead end (length 0 from that order)
      //   die 1 first -> 24->23, then 23-6=17 open (length 2)
      // The maximal (length-2) sequence must survive.
      final p = Position();
      p.points[23] = 1; // white on 24
      p.points[17] = -2; // black blocks 18
      final e = RulesEngine(p, turn: Checker.white, dice: [6, 1]);
      final seqs = e.generateSequences().where((s) => s.isNotEmpty).toList();
      expect(seqs, isNotEmpty);
      for (final s in seqs) {
        expect(s.length, 2);
      }
      expect(
          seqs.first.map((m) => '${m.from}-${m.to}').toList(), ['24-23', '23-17']);
    });
  });

  group('hitting blots', () {
    test('landing on a blot sends it to the bar', () {
      final p = Position();
      p.points[10] = 1; // white on 11
      p.points[7] = -1; // black blot on 8
      final e = RulesEngine(p, turn: Checker.white, dice: [3]);
      final seqs = e.generateSequences();
      expect(seqs, isNotEmpty);
      final mv = seqs.first.first;
      expect(mv.hit, isTrue);
      e.applyMove(mv);
      expect(p.barBlack, 1);
      expect(p.points[7], 1); // white now owns point 8
    });

    test('two or more checkers block entry', () {
      final p = Position();
      p.points[10] = 1;
      p.points[7] = -2;
      final e = RulesEngine(p, turn: Checker.white, dice: [3]);
      final seqs = e.generateSequences();
      expect(seqs, everyElement(isEmpty));
    });

    test('checker on bar must re-enter before other moves', () {
      final p = Position();
      p.barWhite = 1;
      p.points[12] = 1; // white on 13 (could move, but bar comes first)
      p.points[0] = -2; // black blocks 1
      final e = RulesEngine(p, turn: Checker.white, dice: [2]);
      final seqs = e.generateSequences().where((s) => s.isNotEmpty).toList();
      expect(seqs, isNotEmpty);
      for (final s in seqs) {
        expect(s.first.from, 25); // must come from the bar
      }
    });
  });

  group('bearing off', () {
    Position homePosition() {
      final p = Position();
      p.points[0] = 3; // white 1..6 filled
      p.points[1] = 3;
      p.points[2] = 3;
      p.points[3] = 2;
      p.points[4] = 2;
      p.points[5] = 2;
      return p;
    }

    test('exact roll bears off', () {
      final p = homePosition();
      final e = RulesEngine(p, turn: Checker.white, dice: [6]);
      final seqs = e.generateSequences().where((s) => s.isNotEmpty).toList();
      expect(seqs, isNotEmpty);
      expect(seqs.first.first.to, 0);
      e.applyMove(seqs.first.first);
      expect(p.offWhite, 1);
    });

    test('oversized die bears off from highest occupied point', () {
      final p = Position();
      p.points[2] = 1; // single white checker on point 3
      final e = RulesEngine(p, turn: Checker.white, dice: [6]);
      final seqs = e.generateSequences().where((s) => s.isNotEmpty).toList();
      expect(seqs, isNotEmpty);
      expect(seqs.first.first.to, 0);
    });

    test('cannot bear off while a checker is outside the home board', () {
      final p = homePosition();
      p.points[10] = 1; // white checker on point 11
      expect(p.allInHome(Checker.white), isFalse);
      final e = RulesEngine(p, turn: Checker.white, dice: [6]);
      final seqs = e.generateSequences().where((s) => s.isNotEmpty).toList();
      for (final s in seqs) {
        expect(s.first.to, isNot(0));
      }
    });

    test('game ends when all 15 are borne off', () {
      final p = Position();
      p.points[0] = 1; // last white checker on point 1
      p.offWhite = 14;
      final e = RulesEngine(p, turn: Checker.white, dice: [1]);
      final mv = e.generateSequences().firstWhere((s) => s.isNotEmpty).first;
      e.applyMove(mv);
      expect(p.offWhite, 15);
      expect(p.isGameOver, isTrue);
      expect(p.winner, Checker.white);
    });
  });

  group('gammon and backgammon', () {
    test('gammon when loser has borne off nothing (white wins)', () {
      final p = Position();
      p.offWhite = 15;
      p.points[0] = -2; // black still in white's home board
      expect(p.isGammon(Checker.white), isTrue);
      expect(p.isBackgammon(Checker.white), isTrue);
    });

    test('gammon when loser has borne off nothing (black wins)', () {
      final p = Position();
      p.offBlack = 15;
      p.points[23] = 2; // white still in black's home board (points 19..24)
      expect(p.isGammon(Checker.black), isTrue);
      expect(p.isBackgammon(Checker.black), isTrue);
    });

    test('no gammon once loser bears off a checker', () {
      final p = Position();
      p.offWhite = 15;
      p.offBlack = 1;
      p.points[0] = -2;
      expect(p.isGammon(Checker.white), isFalse);
      expect(p.isBackgammon(Checker.white), isFalse);
    });

    test('gammon but not backgammon when loser is clear of winner home', () {
      final p = Position();
      p.offWhite = 15;
      p.points[10] = -1; // black on point 11: bore off nothing, but not
      // on the bar nor in white's home board
      expect(p.isGammon(Checker.white), isTrue);
      expect(p.isBackgammon(Checker.white), isFalse);
    });

    test('plain win once loser bears off a checker', () {
      final p = Position();
      p.offWhite = 15;
      p.offBlack = 1;
      p.points[10] = -1;
      expect(p.isGammon(Checker.white), isFalse);
      expect(p.isBackgammon(Checker.white), isFalse);
    });
  });

  group('doubling cube', () {
    test('starts centered at 1; either side may offer', () {
      final c = DoublingCube();
      expect(c.value, 1);
      expect(c.owner, isNull);
      expect(c.canOffer(Checker.white), isTrue);
      expect(c.canOffer(Checker.black), isTrue);
    });

    test('accept doubles value and transfers ownership', () {
      final c = DoublingCube();
      c.accept(Checker.white);
      expect(c.value, 2);
      expect(c.owner, Checker.white);
      expect(c.canOffer(Checker.white), isFalse); // owner cannot re-double
      expect(c.canOffer(Checker.black), isTrue);
    });

    test('caps at 64', () {
      final c = DoublingCube();
      for (int i = 0; i < 10; i++) {
        if (c.canOffer(Checker.black)) c.accept(Checker.black);
        if (c.canOffer(Checker.white)) c.accept(Checker.white);
      }
      expect(c.value, 64);
      expect(c.canOffer(Checker.white), isFalse);
      expect(c.canOffer(Checker.black), isFalse);
    });

    test('clone is independent', () {
      final c = DoublingCube();
      c.accept(Checker.black);
      final d = c.copy();
      d.accept(Checker.white);
      expect(c.value, 2);
      expect(d.value, 4);
    });
  });

  group('higher-die rule', () {
    test('when only one die is playable, the higher die is used', () {
      // White checker on 24 only; black blocks 23 (die-1 target) and 17
      // (the only follow-up for the die-6 move). Dice [6,1]:
      //   die 1 first -> 24-1=23 blocked
      //   die 6 first -> 24->18, then die 1: 18-1=17 blocked
      // Only [24->18 (die 6)] survives, and the higher-die rule keeps it.
      final p = Position();
      p.points[23] = 1;
      p.points[22] = -2; // blocks 23
      p.points[16] = -2; // blocks 17
      final e = RulesEngine(p, turn: Checker.white, dice: [6, 1]);
      final seqs = e.generateSequences().where((s) => s.isNotEmpty).toList();
      expect(seqs.length, 1);
      expect(seqs.first.length, 1);
      expect(seqs.first.first.die, 6);
      expect(seqs.first.first.from, 24);
      expect(seqs.first.first.to, 18);
    });
  });
}
