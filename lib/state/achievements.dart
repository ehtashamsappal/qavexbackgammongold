/// Pure-Dart achievement catalogue for Qavex Backgammon Gold.
///
/// No Flutter imports: unit tests (dart test) validate count and id
/// uniqueness here. The save layer reads this catalogue.
library;

/// One achievement definition.
class AchievementDef {
  final String id;
  final String name;
  final String desc;

  const AchievementDef(this.id, this.name, this.desc);
}

/// Full catalogue — 60 achievements.
const List<AchievementDef> achievements = [
  AchievementDef('first_roll', 'First Roll', 'Finish your first game.'),
  AchievementDef('first_win', 'Taste of Victory', 'Win your first game.'),
  AchievementDef('win_10', 'Rising Star', 'Win 10 games.'),
  AchievementDef('win_50', 'Board Master', 'Win 50 games.'),
  AchievementDef('win_100', 'Century Club', 'Win 100 games.'),
  AchievementDef('play_10', 'Warming Up', 'Play 10 games.'),
  AchievementDef('play_50', 'Regular', 'Play 50 games.'),
  AchievementDef('play_200', 'Dedicated', 'Play 200 games.'),
  AchievementDef('hit_1', 'First Blood', 'Hit an enemy blot.'),
  AchievementDef('hit_25', 'Hunter', 'Hit 25 blots in total.'),
  AchievementDef('hit_100', 'Blot Slayer', 'Hit 100 blots in total.'),
  AchievementDef('hit_5_game', 'Rampage', 'Hit 5 blots in one game.'),
  AchievementDef('gammon_1', 'Shutout', 'Win by gammon.'),
  AchievementDef('gammon_5', 'Dominant', 'Win 5 gammons.'),
  AchievementDef('backgammon_1', 'Triple Crown', 'Win by backgammon.'),
  AchievementDef('doubles_1', 'Lucky Sixes', 'Roll doubles.'),
  AchievementDef('doubles_6x6', 'Double Six', 'Roll double sixes.'),
  AchievementDef('double_cube', 'High Roller', 'Offer the doubling cube.'),
  AchievementDef(
      'cube_accepted', 'Stakes Raised', 'Have a double accepted.'),
  AchievementDef(
      'cube_win', 'Cube Gambler', 'Win a game at cube value 4+.'),
  AchievementDef(
      'cube_decline_win', 'Intimidator', 'Win by opponent declining.'),
  AchievementDef('bearoff_fast', 'Swift Exit', 'Bear off in under 40 moves.'),
  AchievementDef(
      'comeback', 'Comeback King', 'Win after 3+ checkers were hit.'),
  AchievementDef(
      'no_hit_win', 'Untouchable', 'Win without being hit once.'),
  AchievementDef('perfect_game', 'Flawless',
      'Win without losing a checker to the bar.'),
  AchievementDef('beat_easy', 'Apprentice', 'Beat Easy AI.'),
  AchievementDef('beat_medium', 'Contender', 'Beat Medium AI.'),
  AchievementDef('beat_hard', 'Champion', 'Beat Hard AI.'),
  AchievementDef('beat_expert', 'Grandmaster', 'Beat Expert AI.'),
  AchievementDef('beat_expert_cube', 'Cube Tamer',
      'Beat Expert AI with doubling on.'),
  AchievementDef('blitz_win', 'Speed Demon', 'Win a Timed Blitz game.'),
  AchievementDef('blitz_3', 'Blitz Streak', 'Win 3 Timed Blitz games.'),
  AchievementDef(
      'tournament_1', 'Ladder Climber', 'Clear tournament round 1.'),
  AchievementDef(
      'tournament_3', 'Semifinalist', 'Clear tournament round 3.'),
  AchievementDef(
      'tournament_5', 'Tournament Legend', 'Win the tournament ladder.'),
  AchievementDef(
      'practice_10', 'Student', 'Finish 10 practice games.'),
  AchievementDef('hint_user', 'Seeking Wisdom', 'Use a hint.'),
  AchievementDef('undo_user', 'Second Thoughts', 'Undo a move.'),
  AchievementDef('theme_changer', 'Decorator', 'Try a different theme.'),
  AchievementDef('all_themes', 'Connoisseur', 'Try all 8 themes.'),
  AchievementDef('skin_unlock', 'New Look', 'Unlock a board or checker skin.'),
  AchievementDef('skin_all', 'Collector', 'Unlock every skin.'),
  AchievementDef('rich_1000', 'Gold Hoarder', 'Hold 1,000 Doubloon Coins.'),
  AchievementDef('rich_5000', 'Tycoon', 'Hold 5,000 Doubloon Coins.'),
  AchievementDef('supporter', 'Supporter', 'Buy the team a coffee.'),
  AchievementDef('kids_mode', 'Family Time', 'Play a game in Kids mode.'),
  AchievementDef(
      'local_duel', 'Couch Rivalry', 'Finish a local 2-player game.'),
  AchievementDef('streak_3', 'Hot Streak', 'Win 3 games in a row.'),
  AchievementDef('streak_5', 'Unstoppable', 'Win 5 games in a row.'),
  AchievementDef('streak_10', 'Legendary Run', 'Win 10 games in a row.'),
  AchievementDef('daily_streak_3', 'Regular Visitor',
      'Play on 3 days in a row.'),
  AchievementDef(
      'daily_streak_7', 'Devoted', 'Play on 7 days in a row.'),
  AchievementDef('marathon', 'Marathon', 'Play 5 games in one day.'),
  AchievementDef('night_owl', 'Night Owl', 'Win a game after midnight.'),
  AchievementDef('early_bird', 'Early Bird', 'Win a game before 7 AM.'),
  AchievementDef('cube_challenge', 'Cube Warrior',
      'Win a doubling-cube challenge.'),
  AchievementDef('zero_blots', 'Fortress',
      'Finish a game with zero blots left.'),
  AchievementDef('prime_5', 'Prime Time', 'Build a 5-point prime.'),
  AchievementDef('anchor_both', 'Double Anchor',
      'Hold two anchors at once.'),
  AchievementDef('bar_escape', 'Great Escape',
      'Re-enter 3 checkers from the bar in one game.'),
  AchievementDef('daily_grind', 'Daily Grind', 'Play on 3 different days.'),
  AchievementDef('week_warrior', 'Week Warrior', 'Play on 7 different days.'),
  AchievementDef('scholar', 'Scholar', 'Read the How to Play guide.'),
];
