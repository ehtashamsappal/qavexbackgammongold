# Qavex Backgammon Gold

Classic backgammon with a golden soul. Official tournament rules, four AI
opponents, seven game modes, eight hand-crafted themes — fully offline,
no ads.

**Package:** `com.qavex.qavexbackgammongold` · **Category:** Board
**Developer:** muhammad ehtasham (QAVEX — https://www.qavex.company/)
**Contact:** games@qavex.company · +923375621550

## Features

- **Official rules engine** (pure Dart, fully unit-tested): hitting blots,
  bar re-entry, bearing off (exact + oversized-die rule), maximum-dice and
  higher-die rules, gammon/backgammon scoring, doubling cube 1→64,
  Crawford rule in tournament finals
- **4 AI levels** — Easy / Medium / Hard / Expert: time-capped heuristic
  search with opponent-reply evaluation at higher levels
- **7 modes** — Classic, vs AI, Pass & Play, Timed Blitz, Tournament
  Ladder, Doubling Cube Masters, Practice
- **8 themes** with unique 6-color palettes; signature **Golden Table**
  (gold `#C9A227`, deep brown `#3E2723`, ivory, brass, burgundy, cream)
- **60 achievements**, stats, win streaks, daily streaks, and
  **Doubloon Coins** soft currency earned by playing (Shop skins)
- **Kids Mode** (bigger text, hints always on, no doubling cube) and
  accessibility-minded design
- **12 screens**: Splash, Home, Mode Select, Level Select, Game, Shop,
  Settings, Themes, Profile, Stats & Achievements, How to Play,
  About & Privacy
- **One IAP only**: "Buy Me a Coffee" $0.99
  (`qavexbackgammongoldcoffee`) — a voluntary tip, never gates gameplay
- **Offline, no ads, no tracking** — all progress stored on-device

## Project layout

```
lib/
  rules/backgammon_engine.dart  # pure-Dart rules: move gen, cube, scoring
  ai/ai.dart                    # Easy/Medium/Hard/Expert (time-capped)
  state/game_controller.dart    # turn flow, modes, blitz, tournament
  state/save_data.dart          # stats, achievements, coins, settings
  state/achievements.dart       # pure-Dart achievement catalogue
  theme/palettes.dart           # pure-Dart 8-theme palette specs
  theme/game_themes.dart        # Flutter Color wrappers
  audio/audio_manager.dart      # BGM + 12 SFX
  shop/iap_manager.dart         # "Buy Me a Coffee" IAP
  screens/ (12) · widgets/      # UI
assets/images/                  # Pillow-generated art (icon, splash, board)
assets/audio/                   # numpy-generated WAVs (2 BGM + 12 SFX)
store/                          # STORE_LISTING.txt, SEO_AEO_GEO.txt, PRIVACY_POLICY.txt
store_art/                      # feature graphic + 8 screenshots
tools/make_images.py            # regenerate image assets
tools/make_audio.py             # regenerate audio assets
test/                           # dart test suite (40 tests)
```

## Build & verify

Allowed commands for this project (per build policy):

```bash
export PATH=~/sdks/flutter/bin:$PATH
flutter create --org com.qavex --project-name qavexbackgammongold qavexbackgammongold  # once
flutter pub get
flutter analyze        # must report "No issues found!"
dart test              # 40 tests, all green
```

Release signing: `android/qavexbackgammongold.jks` (unique per game) +
gitignored `android/key.properties` (see `key.properties.example`).
`.gitignore` covers `key.properties`, `*.jks`, `*.keystore`.

## Regenerating assets

```bash
python3 tools/make_images.py   # Pillow: icon, splash, board art, feature, 8 screenshots
python3 tools/make_audio.py    # numpy: 2 BGM + 12 SFX WAVs
```

## Docs

- `DESIGN_BRIEF.md` — concept, identity, rules fidelity, AI, economy
- `REVIEW_REPORT.md` — self-review findings and fixes (incl. a real
  gammon-scoring bug caught by tests)
- `store/` — Play Store listing, SEO/AEO/GEO kit, privacy policy
