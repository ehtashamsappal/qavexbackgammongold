/// Pure-Dart theme palette specs for Qavex Backgammon Gold.
///
/// No Flutter imports: unit tests (dart test) can validate these directly.
/// The Flutter-facing [GameTheme] list is built from these specs.
library;

/// One theme's palette: six core colors plus derived accents, as hex strings.
class ThemePalette {
  final String id;
  final String name;
  final String background;
  final String felt;
  final String pointA;
  final String pointB;
  final String checkerLight;
  final String checkerDark;
  final String frame;
  final String accent;
  final bool dark;

  const ThemePalette({
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

  /// The six core palette colors in canonical order.
  List<String> get coreSix => [
        background,
        felt,
        pointA,
        pointB,
        checkerLight,
        checkerDark,
      ];
}

/// All eight themes. The first is the signature "Golden Table".
const List<ThemePalette> themePalettes = [
  ThemePalette(
    id: 'golden_table',
    name: 'Golden Table',
    background: '#241610',
    felt: '#5C1F27', // burgundy
    pointA: '#F5ECD7', // ivory
    pointB: '#8C6A2F', // brass
    checkerLight: '#FFF8E7', // cream
    checkerDark: '#3E2723', // deep brown
    frame: '#1A0F08',
    accent: '#C9A227', // gold
    dark: true,
  ),
  ThemePalette(
    id: 'midnight',
    name: 'Midnight',
    background: '#0A0E1A',
    felt: '#16233F',
    pointA: '#DCE6F5',
    pointB: '#3A5A8C',
    checkerLight: '#F0F4FA',
    checkerDark: '#101623',
    frame: '#060913',
    accent: '#7FB2F0',
    dark: true,
  ),
  ThemePalette(
    id: 'ocean',
    name: 'Ocean',
    background: '#06222B',
    felt: '#0E5E6B',
    pointA: '#DFF3F0',
    pointB: '#2A7F8E',
    checkerLight: '#FFFFFF',
    checkerDark: '#0A2E36',
    frame: '#04161B',
    accent: '#3FD0C9',
    dark: true,
  ),
  ThemePalette(
    id: 'neon',
    name: 'Neon',
    background: '#0D0D14',
    felt: '#1B1B2E',
    pointA: '#F5F0FF',
    pointB: '#3D2B63',
    checkerLight: '#00F5D4',
    checkerDark: '#F15BB5',
    frame: '#08080F',
    accent: '#FEE440',
    dark: true,
  ),
  ThemePalette(
    id: 'classic_wood',
    name: 'Classic Wood',
    background: '#201509',
    felt: '#6B4226',
    pointA: '#D9B98A',
    pointB: '#3E2413',
    checkerLight: '#F0DFC0',
    checkerDark: '#1F130B',
    frame: '#120C05',
    accent: '#DAA94E',
    dark: true,
  ),
  ThemePalette(
    id: 'royal_green',
    name: 'Royal Green',
    background: '#0B1F14',
    felt: '#1D5C3A',
    pointA: '#EDE6CF',
    pointB: '#0F3A24',
    checkerLight: '#F7F2DE',
    checkerDark: '#10241A',
    frame: '#07130C',
    accent: '#D4AF37',
    dark: true,
  ),
  ThemePalette(
    id: 'mono',
    name: 'Mono',
    background: '#141414',
    felt: '#2E2E2E',
    pointA: '#E8E8E8',
    pointB: '#5A5A5A',
    checkerLight: '#FFFFFF',
    checkerDark: '#1A1A1A',
    frame: '#0A0A0A',
    accent: '#B0B0B0',
    dark: true,
  ),
  ThemePalette(
    id: 'desert',
    name: 'Desert',
    background: '#F3E7CE',
    felt: '#D9B06A',
    pointA: '#FFF6DE',
    pointB: '#8A5A24',
    checkerLight: '#FFFFFF',
    checkerDark: '#4A2E12',
    frame: '#8A6A3A',
    accent: '#B8860B',
    dark: false,
  ),
];

/// Look up a palette by id, falling back to the signature theme.
ThemePalette paletteById(String id) {
  for (final p in themePalettes) {
    if (p.id == id) return p;
  }
  return themePalettes.first;
}
