# REVIEW REPORT — Qavex Backgammon Gold (v1.0.0+1)

**Review date:** October 10, 2026
**Reviewer:** build agent (self-review pass)
**Scope:** rules engine, AI, UI wiring, assets, audio, store/legal files

## Findings & fixes

### 1. Gammon/backgammon detection was inverted (FIXED — real bug)
`Position.isGammon` / `isBackgammon` checked the loser's checkers with the
wrong sign: when White won it looked for *black* checkers on points 1–6
under `loser == Checker.white`, so a genuine backgammon (black checker on
the bar or in White's home) was never detected, and phantom gammons were
possible in mirrored positions. Caught by unit test
`gammon when loser has borne off nothing`. Corrected to:
- winner White → gammon if a *black* checker (v<0) sits on points 1–6 or bar
- winner Black → gammon if a *white* checker (v>0) sits on points 19–24 or bar
Regression tests added for both colors.

### 2. Test expectations vs. engine (tests fixed, engine correct)
Three new tests encoded wrong expectations and were corrected:
- max-dice test: the "blocked" position still allowed a 2-move sequence;
  rebuilt so the maximal sequence is unambiguous.
- game-over test: bore off 1 of 2 remaining checkers (14≠15); fixed to
  a true last-checker bear-off.
- higher-die test: the position allowed a 2-move line; rebuilt with both
  the die-1 target and the die-6 follow-up blocked.

### 3. Missing Level Select screen (ADDED)
The spec requires 12 screens; the app had 11 (difficulty was an inline
chip). Added `lib/screens/level_select.dart` + `/level` route: Classic and
vs AI modes now flow through a dedicated difficulty picker.

### 4. Mode naming vs. spec (RENAMED)
`Local 2-Player` → **Pass & Play**, `Cube Challenge` → **Doubling Cube
Masters**, `Tournament` → **Tournament Ladder**; added **vs AI** quick
mode. 7 modes total.

### 5. Crawford rule (IMPLEMENTED)
Tournament Ladder round 5 now retires the doubling cube
(`GameConfig.crawfordActive/doublingActive`), with an in-game notice and
How-to-Play documentation. Previously the spec-listed rule was absent.

### 6. Theme lineup vs. spec (REPLACED)
9 ad-hoc themes replaced with the specified 8: Golden Table (signature,
gold #C9A227 / deep brown #3E2723), Midnight, Ocean, Neon, Classic Wood,
Royal Green, Mono, Desert — each a unique validated 6-color palette.
Palette specs extracted to pure-Dart `lib/theme/palettes.dart` so
`dart test` can validate them (uniqueness, hex format, brand colors).

### 7. Currency naming (RENAMED)
"gold coins" → **Doubloon Coins** across Home, Shop, Profile, achievements,
IAP thank-you copy.

### 8. Daily streak (ADDED)
`SaveData.recordPlayDay()` tracks consecutive-day play with best-streak
persistence; new achievements `daily_streak_3` / `daily_streak_7`.
60 achievements total (was 59).

### 9. Audio gaps (COMPLETED)
AudioManager referenced files that did not exist and several spec'd SFX
were missing. Now ships exactly 2 BGM + 12 SFX, all numpy-generated WAVs:
`bgm_theme, bgm_calm, dice_roll, checker_move, hit, bearoff, double, win,
button, cube_decline, gammon, tick, turn, lose`. New `lose`, `tick`,
`gammon`, `cubeDecline` hooks wired into the controller (blitz countdown
ticks, gammon fanfare, decline buzz).

### 10. Release signing (WIRED)
Per-game keystore `android/qavexbackgammongold.jks` generated (RSA-2048,
30-year validity); `android/key.properties` (gitignored, 0600) holds
random 24-char passwords; `build.gradle.kts` signs release builds with it
and falls back to debug keys when absent. `.gitignore` covers
`key.properties`, `*.jks`, `*.keystore`.

### 11. Analyze hygiene (CLEAN)
`flutter analyze`: **No issues found.** Fixed: missing `dart:async`
import, transitive-extension import for `AiLevel.label`, `config.`-scoped
Crawford/doubling getters, removed unused imports/variables.

### 12. Testability refactor
Achievements catalogue → pure-Dart `lib/state/achievements.dart`
(shared by `SaveData`); palettes → pure-Dart `lib/theme/palettes.dart`.
`dart test` suite: engine (20 tests), AI (9), content (11) — all green.

## Residual notes (not blockers)
- `flutter_launcher_icons` / `flutter_native_splash` configs reference
  generated PNGs but the generator CLIs were not run (outside the allowed
  command set); PNGs exist at the referenced paths.
- Expert AI at 2.2 s budget is strong but not a neural net; difficulty
  copy says "near-optimal", which is fair for heuristic + 21-roll reply.
- iOS: bundle id `com.qavex.qavexbackgammongold`; IAP product
  `qavexbackgammongoldcoffee` must be created in Play Console / App Store
  Connect before the coffee button can complete a purchase (graceful
  offline fallback included).
