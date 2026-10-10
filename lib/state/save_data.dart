/// Persistent player data: stats, achievements, currency, skins, settings.
/// Backed by shared_preferences. All writes are best-effort and offline.
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'achievements.dart' as catalog;

/// Backwards-compatible achievement catalogue view (map-shaped rows).
class Achievements {
  static List<Map<String, String>> get all => catalog.achievements
      .map((a) => {'id': a.id, 'name': a.name, 'desc': a.desc})
      .toList(growable: false);

  static int get count => catalog.achievements.length;
}

class SaveData {
  static SaveData? _instance;
  static SaveData get instance => _instance ??= SaveData._();
  SaveData._();

  late SharedPreferences _prefs;
  bool _ready = false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _ready = true;
  }

  bool get ready => _ready;

  int getInt(String key, [int def = 0]) =>
      _ready ? _prefs.getInt(key) ?? def : def;
  Future<void> setInt(String key, int v) async {
    if (_ready) await _prefs.setInt(key, v);
  }

  String getString(String key, [String def = '']) =>
      _ready ? _prefs.getString(key) ?? def : def;
  Future<void> setString(String key, String v) async {
    if (_ready) await _prefs.setString(key, v);
  }

  bool getBool(String key, [bool def = false]) =>
      _ready ? _prefs.getBool(key) ?? def : def;
  Future<void> setBool(String key, bool v) async {
    if (_ready) await _prefs.setBool(key, v);
  }

  double getDouble(String key, [double def = 1.0]) =>
      _ready ? _prefs.getDouble(key) ?? def : def;
  Future<void> setDouble(String key, double v) async {
    if (_ready) await _prefs.setDouble(key, v);
  }

  // ---- stats ----
  int get gamesPlayed => getInt('games_played');
  int get gamesWon => getInt('games_won');
  int get totalHits => getInt('total_hits');
  int get totalGammons => getInt('total_gammons');
  int get totalBackgammons => getInt('total_backgammons');
  int get currentStreak => getInt('current_streak');
  int get bestStreak => getInt('best_streak');
  int get doublesRolled => getInt('doubles_rolled');
  int get cubesOffered => getInt('cubes_offered');

  Future<void> addStat(String key, int delta) =>
      setInt(key, getInt(key) + delta);

  // ---- currency ----
  int get coins => getInt('coins', 100); // starter grant
  Future<void> addCoins(int delta) => setInt('coins', coins + delta);
  Future<bool> spendCoins(int amount) async {
    if (coins < amount) return false;
    await setInt('coins', coins - amount);
    return true;
  }

  // ---- achievements ----
  Set<String> get unlockedAchievements {
    final raw = getString('achievements', '');
    if (raw.isEmpty) return {};
    return raw.split(',').toSet();
  }

  /// Returns true if newly unlocked.
  Future<bool> unlock(String id) async {
    final set = unlockedAchievements;
    if (set.contains(id)) return false;
    set.add(id);
    await setString('achievements', set.join(','));
    return true;
  }

  // ---- skins ----
  static const List<Map<String, dynamic>> boardSkins = [
    {'id': 'classic', 'name': 'Classic Frame', 'price': 0},
    {'id': 'gold_trim', 'name': 'Gold Trim', 'price': 500},
    {'id': 'obsidian', 'name': 'Obsidian Edge', 'price': 1200},
    {'id': 'pearl', 'name': 'Pearl Inlay', 'price': 2000},
  ];
  static const List<Map<String, dynamic>> checkerSkins = [
    {'id': 'classic', 'name': 'Classic Discs', 'price': 0},
    {'id': 'marble', 'name': 'Marble', 'price': 600},
    {'id': 'onyx_gold', 'name': 'Onyx & Gold', 'price': 1500},
    {'id': 'jade', 'name': 'Jade', 'price': 2500},
  ];

  Set<String> _owned(String key) {
    final raw = getString(key, 'classic');
    return raw.split(',').toSet();
  }

  bool ownsBoardSkin(String id) => _owned('owned_board_skins').contains(id);
  bool ownsCheckerSkin(String id) => _owned('owned_checker_skins').contains(id);

  Future<bool> buyBoardSkin(String id, int price) async {
    if (ownsBoardSkin(id)) return true;
    if (!await spendCoins(price)) return false;
    final s = _owned('owned_board_skins')..add(id);
    await setString('owned_board_skins', s.join(','));
    return true;
  }

  Future<bool> buyCheckerSkin(String id, int price) async {
    if (ownsCheckerSkin(id)) return true;
    if (!await spendCoins(price)) return false;
    final s = _owned('owned_checker_skins')..add(id);
    await setString('owned_checker_skins', s.join(','));
    return true;
  }

  String get activeBoardSkin => getString('active_board_skin', 'classic');
  String get activeCheckerSkin => getString('active_checker_skin', 'classic');
  Future<void> setActiveBoardSkin(String id) =>
      setString('active_board_skin', id);
  Future<void> setActiveCheckerSkin(String id) =>
      setString('active_checker_skin', id);

  // ---- settings ----
  String get themeId => getString('theme_id', 'golden_table');
  Future<void> setThemeId(String id) => setString('theme_id', id);
  double get musicVolume => getDouble('music_volume', 0.7);
  double get sfxVolume => getDouble('sfx_volume', 0.9);
  Future<void> setMusicVolume(double v) => setDouble('music_volume', v);
  Future<void> setSfxVolume(double v) => setDouble('sfx_volume', v);
  bool get kidsMode => getBool('kids_mode', false);
  Future<void> setKidsMode(bool v) => setBool('kids_mode', v);
  bool get hintsEnabled => getBool('hints', true);
  Future<void> setHintsEnabled(bool v) => setBool('hints', v);
  String get playerName => getString('player_name', 'Player');
  Future<void> setPlayerName(String v) => setString('player_name', v);

  // ---- daily streak (consecutive days played) ----
  int get dailyStreak => getInt('daily_streak', 0);
  String get lastPlayDay => getString('last_play_day', '');

  /// Records today's play; returns the updated consecutive-day streak.
  Future<int> recordPlayDay() async {
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    if (lastPlayDay == today) return dailyStreak;
    final yesterday = now.subtract(const Duration(days: 1));
    final yday = '${yesterday.year}-${yesterday.month}-${yesterday.day}';
    final streak = lastPlayDay == yday ? dailyStreak + 1 : 1;
    await setString('last_play_day', today);
    await setInt('daily_streak', streak);
    final best = getInt('best_daily_streak', 0);
    if (streak > best) await setInt('best_daily_streak', streak);
    if (streak >= 3) await unlock('daily_streak_3');
    if (streak >= 7) await unlock('daily_streak_7');
    return streak;
  }

  // ---- leaderboard (local, best results per mode) ----
  int bestBlitzScore(String modeKey) => getInt('best_$modeKey', 0);
  Future<void> submitScore(String modeKey, int score) async {
    if (score > bestBlitzScore(modeKey)) {
      await setInt('best_$modeKey', score);
    }
  }
}
