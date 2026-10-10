// Unit tests for theme palettes and the achievement catalogue.
// Pure Dart — no Flutter imports. Run: dart test
import 'package:test/test.dart';
import 'package:qavexbackgammongold/theme/palettes.dart';
import 'package:qavexbackgammongold/state/achievements.dart';

bool _isHex(String s) =>
    RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(s);

void main() {
  group('theme palettes', () {
    test('exactly 8 themes with unique ids and names', () {
      expect(themePalettes.length, 8);
      final ids = themePalettes.map((t) => t.id).toSet();
      final names = themePalettes.map((t) => t.name).toSet();
      expect(ids.length, 8);
      expect(names.length, 8);
    });

    test('required theme lineup is present', () {
      final ids = themePalettes.map((t) => t.id).toSet();
      for (final id in [
        'golden_table',
        'midnight',
        'ocean',
        'neon',
        'classic_wood',
        'royal_green',
        'mono',
        'desert'
      ]) {
        expect(ids, contains(id));
      }
    });

    test('signature Golden Table palette matches the brand spec', () {
      final g = paletteById('golden_table');
      expect(g.name, 'Golden Table');
      expect(g.accent.toUpperCase(), '#C9A227'); // gold
      expect(g.checkerDark.toUpperCase(), '#3E2723'); // deep brown
    });

    test('every core color is a valid 6-digit hex', () {
      for (final t in themePalettes) {
        for (final c in [
          ...t.coreSix,
          t.frame,
          t.accent,
        ]) {
          expect(_isHex(c), isTrue, reason: '${t.id} has bad color $c');
        }
      }
    });

    test('each theme has a unique 6-color core palette', () {
      final seen = <String>{};
      for (final t in themePalettes) {
        final key = t.coreSix.join('|').toUpperCase();
        expect(seen.add(key), isTrue,
            reason: '${t.id} duplicates another theme\'s palette');
      }
    });

    test('at least one light and one dark theme exist', () {
      expect(themePalettes.any((t) => t.dark), isTrue);
      expect(themePalettes.any((t) => !t.dark), isTrue);
    });

    test('paletteById falls back to the signature theme', () {
      expect(paletteById('nope').id, 'golden_table');
    });
  });

  group('achievements catalogue', () {
    test('at least 50 achievements', () {
      expect(achievements.length, greaterThanOrEqualTo(50));
    });

    test('ids are unique and non-empty; names/descs non-empty', () {
      final ids = achievements.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final a in achievements) {
        expect(a.id, isNotEmpty);
        expect(a.name, isNotEmpty);
        expect(a.desc, isNotEmpty);
      }
    });

    test('key achievements exist', () {
      final ids = achievements.map((a) => a.id).toSet();
      for (final id in [
        'first_win',
        'backgammon_1',
        'beat_expert',
        'tournament_5',
        'blitz_win',
        'daily_streak_7',
        'kids_mode',
        'supporter',
      ]) {
        expect(ids, contains(id));
      }
    });
  });
}
