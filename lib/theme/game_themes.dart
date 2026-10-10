/// Board & app themes, built from the pure-Dart palette specs.
/// Each theme carries a unique 6-color core palette. Persisted via
/// shared_preferences. The signature theme is "Golden Table".
library;

import 'package:flutter/material.dart';
import 'palettes.dart';

Color _hex(String s) {
  final v = int.parse(s.substring(1), radix: 16);
  return Color(0xFF000000 | v);
}

class GameTheme {
  final String id;
  final String name;
  // Core 6-color palette:
  final Color background; // app background
  final Color felt; // board playing surface
  final Color pointA; // light points
  final Color pointB; // dark points
  final Color checkerLight; // player-1 checkers
  final Color checkerDark; // player-2 checkers
  // Derived accents:
  final Color frame;
  final Color accent;
  final bool dark;

  const GameTheme({
    required this.id,
    required this.name,
    required this.background,
    required this.felt,
    required this.pointA,
    required this.pointB,
    required this.checkerLight,
    required this.checkerDark,
    required this.frame,
    required this.accent,
    required this.dark,
  });

  factory GameTheme.fromPalette(ThemePalette p) => GameTheme(
        id: p.id,
        name: p.name,
        background: _hex(p.background),
        felt: _hex(p.felt),
        pointA: _hex(p.pointA),
        pointB: _hex(p.pointB),
        checkerLight: _hex(p.checkerLight),
        checkerDark: _hex(p.checkerDark),
        frame: _hex(p.frame),
        accent: _hex(p.accent),
        dark: p.dark,
      );

  Color get textColor => dark ? const Color(0xFFF5EFE0) : const Color(0xFF2B2118);
  Color get subText =>
      dark ? const Color(0xFFC9BFA9) : const Color(0xFF6B5F4E);
}

class GameThemes {
  static final List<GameTheme> all =
      themePalettes.map(GameTheme.fromPalette).toList(growable: false);

  static GameTheme byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }
}
