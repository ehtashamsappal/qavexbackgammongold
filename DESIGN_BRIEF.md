# DESIGN BRIEF — Qavex Backgammon Gold

**Game:** QAVEX Backgammon Gold · `com.qavex.qavexbackgammongold` · Board
**Developer:** muhammad ehtasham (QAVEX — https://www.qavex.company/)
**Version:** 1.0.0+1 · SDK 36 / min SDK 24 · Offline, no ads

## 1. Concept
The world's oldest board game, presented as a luxury object. Qavex
Backgammon Gold is a premium-feeling, fully offline backgammon app:
official tournament rules, four AI opponents, seven game modes, and a
signature golden table aesthetic. No accounts, no ads, no tracking —
just the game.

## 2. Audience
- Casual players learning backgammon (How to Play, Practice, Kids Mode)
- Club-level players wanting serious AI practice (Hard/Expert, Cube Masters)
- Local two-player sessions (Pass & Play)
- US / UAE / Gulf markets: English-first UI, timeless theme

## 3. Visual identity
- **Signature theme "Golden Table":** gold `#C9A227`, deep brown `#3E2723`,
  ivory `#F5ECD7`, brass `#8C6A2F`, burgundy `#5C1F27`, cream `#FFF8E7`
- 8 themes total, each a unique 6-color palette:
  Golden Table · Midnight · Ocean · Neon · Classic Wood · Royal Green ·
  Mono · Desert (light)
- Typography: system default (clean, legible); heavy weights for titles
- Board: top-down 2D board with triangular points, circular checkers with
  gold rims, dice with gold pips frames, doubling cube rendered as a die
- Icon: gold ring + cream/brown checkers + dice on deep brown

## 4. Audio identity
- 2 original synthesized BGM loops (warm "theme", airy "calm"), 22050 Hz WAV
- 12 SFX: dice rattle, checker knock, hit, bear-off chime, double thud,
  win arpeggio, lose descent, button click, cube-decline buzz, gammon
  fanfare, blitz tick, turn whoosh — all generated offline with numpy

## 5. Rules fidelity (official)
- Standard opening position, 167-pip counts
- Hitting blots → bar; forced bar re-entry before other moves
- Bearing off: exact rolls, plus oversized-die-from-highest-point rule
- Maximum-dice rule; higher-die rule when only one die is playable
- Gammon (×2) / backgammon (×3) detection and scoring
- Doubling cube 1→64 with offer/accept/decline and ownership
- Crawford rule: cube retired in the Tournament Ladder final round

## 6. AI design
- Pure-Dart engine + heuristic evaluation (pip race, blots, bar, made
  points, home primes, borne-off weight)
- Easy: random legal play · Medium: 1-ply heuristic (250 ms)
- Hard: 1-ply + 7 sampled opponent replies (900 ms)
- Expert: 1-ply + all 21 distinct opponent rolls (2.2 s)
- Strict wall-clock budgets; cube offer/accept heuristics per level

## 7. Modes (7)
Classic (full rules vs AI) · vs AI (quick casual) · Pass & Play ·
Timed Blitz (5 min) · Tournament Ladder (5 rounds, Crawford final) ·
Doubling Cube Masters (aggressive doubling AI) · Practice (Easy, hints on)

## 8. Progression & economy
- 60 achievements across wins, hits, gammons, cube play, streaks, themes
- Stats: games, wins, hits, gammons, streaks, best blitz scores
- Daily streak (consecutive days played) with 3/7-day achievements
- Soft currency "Doubloon Coins": earned by playing (win 50+, bonuses),
  spent in the Shop on board frames & checker skins
- Exactly ONE IAP: "Buy Me a Coffee" $0.99 (`qavexbackgammongoldcoffee`) —
  a voluntary tip; never gates gameplay; grants Supporter achievement +
  250 Doubloon Coins thank-you

## 9. Accessibility & Kids Mode
- Kids Mode toggle: larger text/buttons, hints always on, doubling cube
  disabled, calmer AI
- Large touch targets on board points, high-contrast Mono theme,
  scalable text via OS settings, no time pressure outside Blitz

## 10. Screens (12)
Splash · Home · Mode Select · Level Select · Game · Shop · Settings ·
Themes · Profile (Players) · Stats & Achievements · How to Play ·
About & Privacy

## 11. Technical
- Flutter 3.47.7 · pure-Dart rules engine (`lib/rules/`) with zero
  Flutter imports — fully unit-tested via `dart test`
- State via ChangeNotifier + shared_preferences; audio via flame_audio;
  IAP via in_app_purchase
- Release signing: per-game keystore (`android/qavexbackgammongold.jks`),
  credentials in gitignored `android/key.properties`
- Assets: Pillow-generated icon/splash/board art/feature graphic +
  8 store screenshots; numpy-generated WAV audio

## 12. Store & legal
- `store/STORE_LISTING.txt`, `store/SEO_AEO_GEO.txt`,
  `store/PRIVACY_POLICY.txt`
- Privacy: no data collection, no ads, no trackers, on-device storage
- Support: games@qavex.company · +923375621550
