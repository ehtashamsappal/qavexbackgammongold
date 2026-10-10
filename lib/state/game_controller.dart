/// GameController: drives the game screen.
///
/// Owns the [Position], dice, doubling cube, undo stack, move history,
/// AI scheduling, blitz timer, tournament ladder and kids-mode flags.
/// Pure turn logic lives in the rules engine; this class orchestrates UI state.
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../rules/backgammon_engine.dart';
import '../ai/ai.dart';
import '../state/save_data.dart';
import '../audio/audio_manager.dart';

enum GameMode {
  classic, // standard match vs AI, full official rules (doubling cube on)
  quickVsAi, // casual single game vs AI, no doubling cube
  local2p, // pass & play: local two players
  blitz, // timed blitz vs AI
  tournament, // ladder vs escalating AI (Crawford rule in the final round)
  cubeChallenge, // doubling-cube challenge vs aggressive AI
  practice, // relaxed vs easy AI with hints forced on
}

extension GameModeInfo on GameMode {
  String get label {
    switch (this) {
      case GameMode.classic:
        return 'Classic';
      case GameMode.quickVsAi:
        return 'vs AI';
      case GameMode.local2p:
        return 'Pass & Play';
      case GameMode.blitz:
        return 'Timed Blitz';
      case GameMode.tournament:
        return 'Tournament Ladder';
      case GameMode.cubeChallenge:
        return 'Doubling Cube Masters';
      case GameMode.practice:
        return 'Practice';
    }
  }

  String get modeKey {
    switch (this) {
      case GameMode.classic:
        return 'classic';
      case GameMode.quickVsAi:
        return 'quickai';
      case GameMode.local2p:
        return 'local2p';
      case GameMode.blitz:
        return 'blitz';
      case GameMode.tournament:
        return 'tournament';
      case GameMode.cubeChallenge:
        return 'cube';
      case GameMode.practice:
        return 'practice';
    }
  }
}

class GameConfig {
  final GameMode mode;
  final AiLevel aiLevel;
  final bool doublingEnabled;
  final bool kidsMode;
  final int tournamentRound; // 1..5 for tournament mode

  const GameConfig({
    required this.mode,
    this.aiLevel = AiLevel.medium,
    this.doublingEnabled = true,
    this.kidsMode = false,
    this.tournamentRound = 1,
  });

  AiLevel get effectiveAi {
    if (mode == GameMode.tournament) {
      const ladder = [
        AiLevel.easy,
        AiLevel.medium,
        AiLevel.medium,
        AiLevel.hard,
        AiLevel.expert
      ];
      return ladder[(tournamentRound - 1).clamp(0, 4)];
    }
    if (mode == GameMode.practice) return AiLevel.easy;
    if (mode == GameMode.cubeChallenge) return AiLevel.hard;
    return aiLevel;
  }

  /// Crawford rule: in the final round of the tournament ladder the match is
  /// at "match point", so the doubling cube is retired for that game.
  bool get crawfordActive =>
      mode == GameMode.tournament && tournamentRound >= 5;

  /// Doubling cube is usable only when enabled and the Crawford rule
  /// does not retire it.
  bool get doublingActive =>
      doublingEnabled && !crawfordActive && !kidsMode;
}

class _Snapshot {
  final Position pos;
  final List<int> dice;
  final DoublingCube cube;
  _Snapshot(this.pos, this.dice, this.cube);
}

class GameController extends ChangeNotifier {
  final GameConfig config;
  final Random _rng = Random();

  Position pos = Position.standard();
  DoublingCube cube = DoublingCube();
  Checker turn = Checker.white;
  List<int> dice = [];
  bool diceRolled = false;
  List<List<BgMove>> legalSequences = [];
  List<BgMove> playedThisTurn = [];
  List<String> moveHistory = [];
  final List<_Snapshot> _undoStack = [];

  int? selectedPoint; // 1..24, 25 = bar
  List<BgMove> hintsForSelected = [];

  bool gameOver = false;
  Checker? winner;
  int stakeMultiplier = 1; // gammon/backgammon multiplier
  bool cubeOfferPending = false; // waiting on human decision
  Checker? cubeOfferedBy;

  // Blitz
  int blitzSecondsLeft = 300;
  Timer? _blitzTimer;
  int blitzScore = 0;

  // Per-game tracking for achievements/stats
  int hitsByHuman = 0;
  int hitsSuffered = 0;
  int barReentries = 0;
  int moveCount = 0;
  bool humanIsWhite = true;

  bool aiThinking = false;
  String statusMessage = '';

  GameController(this.config) {
    if (config.mode == GameMode.blitz) {
      blitzSecondsLeft = 300;
      _blitzTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (gameOver) {
          t.cancel();
          return;
        }
        blitzSecondsLeft--;
        if (blitzSecondsLeft <= 10 && blitzSecondsLeft > 0) {
          AudioManager.instance.tick();
        }
        if (blitzSecondsLeft <= 0) {
          _finishGame(humanIsWhite ? Checker.black : Checker.white,
              reason: 'Time ran out');
        }
        notifyListeners();
      });
    }
    SaveData.instance.recordPlayDay();
    _openingRoll();
  }

  bool get vsAi => config.mode != GameMode.local2p;
  bool get isHumanTurn =>
      !gameOver && (!vsAi || turn == (humanIsWhite ? Checker.white : Checker.black));
  bool get canUndo =>
      _undoStack.isNotEmpty && isHumanTurn && diceRolled && !gameOver;

  // ---------------- setup ----------------

  void _openingRoll() {
    // Each side rolls one die; higher goes first (ties re-roll).
    int w, b;
    do {
      w = _rng.nextInt(6) + 1;
      b = _rng.nextInt(6) + 1;
    } while (w == b);
    turn = w > b ? Checker.white : Checker.black;
    dice = [w, b];
    diceRolled = true;
    _refreshLegal();
    statusMessage =
        '${turn == Checker.white ? 'White' : 'Black'} won the opening roll ($w vs $b).';
    if (config.crawfordActive) {
      statusMessage +=
          ' Crawford rule: the doubling cube is retired for the final round.';
    }
    _maybeAiTurn();
  }

  // ---------------- dice ----------------

  void rollDice() {
    if (gameOver || diceRolled || !isHumanTurn) return;
    final d1 = _rng.nextInt(6) + 1;
    final d2 = _rng.nextInt(6) + 1;
    dice = d1 == d2 ? [d1, d1, d1, d1] : [d1, d2];
    diceRolled = true;
    if (d1 == d2) {
      SaveData.instance.addStat('doubles_rolled', 1);
      if (d1 == 6) SaveData.instance.unlock('doubles_6x6');
      SaveData.instance.unlock('doubles_1');
    }
    AudioManager.instance.dice();
    _refreshLegal();
    if (legalSequences.every((s) => s.isEmpty)) {
      statusMessage = 'No legal moves — turn passes.';
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!gameOver) endTurn(auto: true);
      });
    }
    notifyListeners();
  }

  // ---------------- move selection ----------------

  void _refreshLegal() {
    final engine = RulesEngine(pos, turn: turn, dice: List.of(dice));
    legalSequences = engine.generateSequences();
    selectedPoint = null;
    hintsForSelected = [];
  }

  /// Points the currently selected checker may move to (for the active die set).
  void selectPoint(int point) {
    if (!isHumanTurn || !diceRolled || gameOver) return;
    if (selectedPoint == point) {
      selectedPoint = null;
      hintsForSelected = [];
    } else {
      selectedPoint = point;
      hintsForSelected = [];
      for (final seq in legalSequences) {
        if (seq.isNotEmpty && seq.first.from == point) {
          hintsForSelected.add(seq.first);
        }
      }
    }
    AudioManager.instance.button();
    notifyListeners();
  }

  /// Attempt to move the selected checker to [destPoint] (0 = bear off).
  void tapDestination(int destPoint) {
    if (selectedPoint == null || !isHumanTurn || !diceRolled || gameOver) {
      return;
    }
    BgMove? chosen;
    for (final m in hintsForSelected) {
      if (m.to == destPoint) {
        chosen = m;
        break;
      }
    }
    if (chosen == null) return;
    _pushUndo();
    final engine = RulesEngine(pos, turn: turn, dice: List.of(dice));
    engine.applyMove(chosen);
    dice.remove(chosen.die);
    playedThisTurn.add(chosen);
    moveCount++;
    moveHistory.add(
        '${_sideName(turn)}: ${_fmtMove(chosen)}${chosen.hit ? ' (hit!)' : ''}');
    if (chosen.hit) {
      if (_isHuman(turn)) {
        hitsByHuman++;
        SaveData.instance.addStat('total_hits', 1);
        SaveData.instance.unlock('hit_1');
      } else {
        hitsSuffered++;
      }
      AudioManager.instance.hit();
    } else if (chosen.to == 0) {
      AudioManager.instance.bearOff();
    } else {
      AudioManager.instance.move();
    }
    if (chosen.from == 25 && _isHuman(turn)) barReentries++;
    selectedPoint = null;
    hintsForSelected = [];
    if (pos.isGameOver) {
      _finishGame(pos.winner!, reason: 'All checkers borne off');
      return;
    }
    _refreshLegalAfterPartial();
    notifyListeners();
  }

  void _refreshLegalAfterPartial() {
    final engine = RulesEngine(pos, turn: turn, dice: List.of(dice));
    legalSequences = engine.generateSequences();
    if (dice.isNotEmpty && legalSequences.every((s) => s.isEmpty)) {
      statusMessage = 'No more moves — ending turn.';
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!gameOver && isHumanTurn) endTurn(auto: true);
      });
    }
  }

  void _pushUndo() {
    _undoStack.add(_Snapshot(pos.copy(), List.of(dice), cube.copy()));
    if (_undoStack.length > 64) _undoStack.removeAt(0);
  }

  void undo() {
    if (!canUndo) return;
    final snap = _undoStack.removeLast();
    pos = snap.pos;
    dice = snap.dice;
    cube = snap.cube;
    if (playedThisTurn.isNotEmpty) {
      playedThisTurn.removeLast();
      if (moveHistory.isNotEmpty) moveHistory.removeLast();
    }
    SaveData.instance.unlock('undo_user');
    AudioManager.instance.button();
    _refreshLegal();
    statusMessage = 'Move undone.';
    notifyListeners();
  }

  /// Highlight one suggested full sequence (hint).
  List<BgMove> requestHint() {
    if (!isHumanTurn || !diceRolled || gameOver) return [];
    final ai = BackgammonAi();
    final result =
        ai.choose(pos, turn, List.of(dice), AiLevel.medium);
    if (result.sequence.isNotEmpty) {
      SaveData.instance.unlock('hint_user');
      AudioManager.instance.button();
      // Pre-select the first move's origin for convenience.
      selectedPoint = result.sequence.first.from;
      hintsForSelected = [];
      for (final seq in legalSequences) {
        if (seq.isNotEmpty && seq.first.from == selectedPoint) {
          hintsForSelected.add(seq.first);
        }
      }
      statusMessage = 'Hint: ${_fmtMove(result.sequence.first)} …';
      notifyListeners();
    }
    return result.sequence;
  }

  // ---------------- turn flow ----------------

  void endTurn({bool auto = false}) {
    if (gameOver) return;
    if (!auto && dice.isNotEmpty) {
      // Officially you must play all possible moves; allow ending early only
      // when the player confirms via UI dialog (handled by the screen).
    }
    turn = otherChecker(turn);
    dice = [];
    diceRolled = false;
    playedThisTurn = [];
    _undoStack.clear();
    selectedPoint = null;
    hintsForSelected = [];
    statusMessage = '';
    notifyListeners();
    _maybeAiTurn();
  }

  void _maybeAiTurn() {
    if (gameOver || !vsAi) return;
    final aiColor = humanIsWhite ? Checker.black : Checker.white;
    if (turn != aiColor) return;
    aiThinking = true;
    notifyListeners();
    final level = config.effectiveAi;
    final ai = BackgammonAi();
    Future.delayed(const Duration(milliseconds: 450), () {
      if (gameOver) return;
      // AI doubling decision (cube challenge: aggressive).
      // Retired under the Crawford rule (tournament final round).
      if (config.doublingActive && cube.canOffer(aiColor)) {
        final aggressive = config.mode == GameMode.cubeChallenge;
        final offer = aggressive
            ? ai.shouldOfferDouble(pos, aiColor, AiLevel.hard, cube.value)
            : ai.shouldOfferDouble(pos, aiColor, level, cube.value);
        if (offer) {
          _aiOffersDouble(aiColor);
          return;
        }
      }
      _aiMove(ai, level, aiColor);
    });
  }

  void _aiMove(BackgammonAi ai, AiLevel level, Checker aiColor) {
    final d1 = _rng.nextInt(6) + 1;
    final d2 = _rng.nextInt(6) + 1;
    final rolledDice = d1 == d2 ? [d1, d1, d1, d1] : [d1, d2];
    final result = ai.choose(pos, aiColor, List.of(rolledDice), level);
    final engine = RulesEngine(pos, turn: aiColor, dice: List.of(rolledDice));
    for (final m in result.sequence) {
      engine.applyMove(m);
      moveHistory.add('${_sideName(aiColor)}: ${_fmtMove(m)}${m.hit ? ' (hit!)' : ''}');
      if (m.hit) hitsSuffered++;
    }
    if (result.sequence.any((m) => m.hit)) {
      AudioManager.instance.hit();
    } else if (result.sequence.isNotEmpty) {
      AudioManager.instance.move();
    }
    aiThinking = false;
    if (pos.isGameOver) {
      _finishGame(pos.winner!, reason: 'All checkers borne off');
      return;
    }
    turn = otherChecker(turn);
    dice = [];
    diceRolled = false;
    playedThisTurn = [];
    _undoStack.clear();
    statusMessage = '${_sideName(aiColor)} played ${result.sequence.length} move(s).';
    notifyListeners();
  }

  void _aiOffersDouble(Checker aiColor) {
    cubeOfferPending = true;
    cubeOfferedBy = aiColor;
    aiThinking = false;
    AudioManager.instance.cube();
    statusMessage = '${_sideName(aiColor)} offers the doubling cube!';
    SaveData.instance.addStat('cubes_offered', 1);
    notifyListeners();
  }

  // ---------------- doubling cube (human) ----------------

  bool get humanCanDouble =>
      config.doublingActive &&
      !gameOver &&
      isHumanTurn &&
      !cubeOfferPending &&
      cube.canOffer(turn);

  void humanOffersDouble() {
    if (!humanCanDouble) return;
    if (!vsAi) {
      // Local 2-player: auto-accept by opponent for simplicity of offline play
      // is wrong — instead the screen shows an accept/decline dialog.
      cubeOfferPending = true;
      cubeOfferedBy = turn;
      AudioManager.instance.cube();
      statusMessage = '${_sideName(turn)} offers the doubling cube!';
      SaveData.instance.addStat('cubes_offered', 1);
      SaveData.instance.unlock('double_cube');
      notifyListeners();
      return;
    }
    final aiColor = humanIsWhite ? Checker.black : Checker.white;
    final ai = BackgammonAi();
    final accept = ai.shouldAcceptDouble(pos, aiColor, config.effectiveAi);
    AudioManager.instance.cube();
    SaveData.instance.addStat('cubes_offered', 1);
    SaveData.instance.unlock('double_cube');
    if (accept) {
      cube.accept(aiColor);
      SaveData.instance.unlock('cube_accepted');
      statusMessage = '${_sideName(aiColor)} accepts the double. Cube is now ${cube.value}.';
    } else {
      _finishGame(turn, reason: 'Double declined');
      return;
    }
    notifyListeners();
  }

  /// Human answers a pending AI (or local-opponent) double offer.
  void answerDouble(bool accept) {
    if (!cubeOfferPending) return;
    final offeredBy = cubeOfferedBy ?? otherChecker(turn);
    final decider = vsAi ? turn : otherChecker(offeredBy);
    cubeOfferPending = false;
    cubeOfferedBy = null;
    if (accept) {
      cube.accept(decider);
      SaveData.instance.unlock('cube_accepted');
      statusMessage = '${_sideName(decider)} takes the cube at ${cube.value}.';
      notifyListeners();
      if (vsAi) {
        // Continue the AI turn that was interrupted.
        aiThinking = true;
        notifyListeners();
        final aiColor = humanIsWhite ? Checker.black : Checker.white;
        Future.delayed(const Duration(milliseconds: 450), () {
          if (!gameOver) _aiMove(BackgammonAi(), config.effectiveAi, aiColor);
        });
      }
    } else {
      _finishGame(offeredBy, reason: 'Double declined');
      AudioManager.instance.cubeDecline();
    }
  }

  // ---------------- game end ----------------

  void _finishGame(Checker w, {required String reason}) {
    if (gameOver) return;
    gameOver = true;
    winner = w;
    _blitzTimer?.cancel();
    final gammon = pos.isGammon(w);
    final backgammon = gammon && pos.isBackgammon(w);
    stakeMultiplier = backgammon ? 3 : (gammon ? 2 : 1);
    final stake = cube.value * stakeMultiplier;
    final humanWon = _isHuman(w);

    if (humanWon) {
      AudioManager.instance.win();
      if (gammon || backgammon) AudioManager.instance.gammon();
    } else {
      AudioManager.instance.lose();
    }
    final save = SaveData.instance;
    save.addStat('games_played', 1);
    if (humanWon) {
      save.addStat('games_won', 1);
      save.setInt('current_streak', save.currentStreak + 1);
      if (save.currentStreak > save.bestStreak) {
        save.setInt('best_streak', save.currentStreak);
      }
      // Coins: win 50 + 25 per cube level + gammon bonuses.
      int reward = 50 + (cube.value - 1) * 25;
      if (gammon) reward += 50;
      if (backgammon) reward += 100;
      if (config.mode == GameMode.blitz) {
        blitzScore = reward + blitzSecondsLeft;
        save.submitScore('blitz', blitzScore);
        save.unlock('blitz_win');
      }
      if (config.mode == GameMode.tournament) {
        if (config.tournamentRound >= 5) save.unlock('tournament_5');
        if (config.tournamentRound >= 3) save.unlock('tournament_3');
        save.unlock('tournament_1');
      }
      if (config.mode == GameMode.cubeChallenge) save.unlock('cube_challenge');
      if (config.mode == GameMode.practice) {
        final n = save.getInt('practice_done') + 1;
        save.setInt('practice_done', n);
        if (n >= 10) save.unlock('practice_10');
      }
      if (config.mode == GameMode.local2p) save.unlock('local_duel');
      if (config.kidsMode) save.unlock('kids_mode');
      if (gammon) {
        save.addStat('total_gammons', 1);
        save.unlock('gammon_1');
        if (save.totalGammons >= 5) save.unlock('gammon_5');
      }
      if (backgammon) {
        save.addStat('total_backgammons', 1);
        save.unlock('backgammon_1');
      }
      if (cube.value >= 4) save.unlock('cube_win');
      if (reason == 'Double declined' && humanWon) {
        save.unlock('cube_decline_win');
      }
      if (hitsByHuman >= 5) save.unlock('hit_5_game');
      if (hitsSuffered == 0) save.unlock('no_hit_win');
      if (moveCount <= 40) save.unlock('bearoff_fast');
      if (barReentries >= 3) save.unlock('bar_escape');
      if (config.mode == GameMode.classic || config.mode == GameMode.cubeChallenge) {
        final lvl = config.effectiveAi;
        if (lvl == AiLevel.easy) save.unlock('beat_easy');
        if (lvl == AiLevel.medium) save.unlock('beat_medium');
        if (lvl == AiLevel.hard) save.unlock('beat_hard');
        if (lvl == AiLevel.expert) {
          save.unlock('beat_expert');
          if (config.doublingEnabled) save.unlock('beat_expert_cube');
        }
      }
      final streak = save.currentStreak;
      if (streak >= 3) save.unlock('streak_3');
      if (streak >= 5) save.unlock('streak_5');
      if (streak >= 10) save.unlock('streak_10');
      final now = DateTime.now();
      if (now.hour < 7) save.unlock('early_bird');
      if (now.hour >= 0 && now.hour < 5) save.unlock('night_owl');
      save.addCoins(reward);
      if (save.coins >= 1000) save.unlock('rich_1000');
      if (save.coins >= 5000) save.unlock('rich_5000');
      // Daily play tracking.
      final today = '${now.year}-${now.month}-${now.day}';
      final daysRaw = save.getString('play_days', '');
      final days = daysRaw.isEmpty ? <String>{} : daysRaw.split(',').toSet();
      if (days.add(today)) {
        save.setString('play_days', days.join(','));
        if (days.length >= 3) save.unlock('daily_grind');
        if (days.length >= 7) save.unlock('week_warrior');
      }
    } else {
      save.setInt('current_streak', 0);
      save.addCoins(10); // participation
    }
    save.unlock('first_roll');
    if (save.gamesPlayed >= 10) save.unlock('play_10');
    if (save.gamesPlayed >= 50) save.unlock('play_50');
    if (save.gamesPlayed >= 200) save.unlock('play_200');
    if (save.gamesWon >= 10) save.unlock('win_10');
    if (save.gamesWon >= 50) save.unlock('win_50');
    if (save.gamesWon >= 100) save.unlock('win_100');
    if (save.totalHits >= 25) save.unlock('hit_25');
    if (save.totalHits >= 100) save.unlock('hit_100');

    statusMessage =
        '${_sideName(w)} wins${gammon ? (backgammon ? ' — BACKGAMMON!' : ' — GAMMON!') : ''} ($reason) · Stake ×$stake';
    notifyListeners();
  }

  bool _isHuman(Checker c) =>
      !vsAi || c == (humanIsWhite ? Checker.white : Checker.black);

  String _sideName(Checker c) {
    if (!vsAi) return c == Checker.white ? 'White' : 'Black';
    if (c == (humanIsWhite ? Checker.white : Checker.black)) {
      return SaveData.instance.playerName;
    }
    return 'AI (${config.effectiveAi.label})';
  }

  String _fmtMove(BgMove m) {
    final from = m.from == 25 ? 'bar' : '${m.from}';
    final to = m.to == 0 ? 'off' : '${m.to}';
    return '$from → $to';
  }

  @override
  void dispose() {
    _blitzTimer?.cancel();
    super.dispose();
  }
}
