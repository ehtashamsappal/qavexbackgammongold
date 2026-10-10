import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../widgets/board.dart';
import '../state/game_controller.dart';
import '../state/save_data.dart';
import '../rules/backgammon_engine.dart';
import '../ai/ai.dart';

class GameScreen extends StatefulWidget {
  final GameConfig config;
  const GameScreen({super.key, required this.config});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController ctrl;
  bool _doubleDialogShown = false;
  bool _overDialogShown = false;

  @override
  void initState() {
    super.initState();
    ctrl = GameController(widget.config);
    ctrl.addListener(_onChange);
  }

  @override
  void dispose() {
    ctrl.removeListener(_onChange);
    ctrl.dispose();
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});
    if (ctrl.cubeOfferPending && !_doubleDialogShown) {
      _doubleDialogShown = true;
      _showDoubleDialog();
    }
    if (ctrl.gameOver && !_overDialogShown) {
      _overDialogShown = true;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _showGameOver();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeState.instance,
      builder: (context, _) {
        final t = AppThemeState.instance.theme;
        final save = SaveData.instance;
        final kids = widget.config.kidsMode;
        return Scaffold(
          backgroundColor: t.background,
          appBar: AppBar(
            backgroundColor: t.frame,
            foregroundColor: t.accent,
            title: Text(widget.config.mode.label,
                style: TextStyle(
                    color: t.accent, fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'Move history',
                onPressed: _showHistory,
              ),
              IconButton(
                icon: const Icon(Icons.flag),
                tooltip: 'Resign',
                onPressed: _confirmResign,
              ),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _scoreboard(t, save),
                      if (widget.config.mode == GameMode.blitz)
                        _blitzBar(t),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: BoardWidget(
                          pos: ctrl.pos,
                          theme: t,
                          selectedPoint: ctrl.selectedPoint,
                          hintMoves: ctrl.hintsForSelected,
                          cubeValue: ctrl.cube.value,
                          cubeOwner: ctrl.cube.owner,
                          onTapPoint: _onTapPoint,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DiceRow(
                        dice: ctrl.dice,
                        pipColor: t.frame,
                        faceColor: t.checkerLight,
                      ),
                      const SizedBox(height: 6),
                      _controls(t, kids),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          ctrl.statusMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: t.subText,
                              fontSize: kids ? 17 : 14,
                              fontStyle: FontStyle.italic),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                if (ctrl.aiThinking)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black45,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: t.accent),
                            const SizedBox(height: 12),
                            Text('AI is thinking…',
                                style: TextStyle(
                                    color: t.accent,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _scoreboard(dynamic t, SaveData save) {
    final humanName = widget.config.mode == GameMode.local2p
        ? 'White'
        : save.playerName;
    final oppName = widget.config.mode == GameMode.local2p
        ? 'Black'
        : 'AI ${widget.config.effectiveAi.label}';
    final whitePips = ctrl.pos.pipCount(Checker.white);
    final blackPips = ctrl.pos.pipCount(Checker.black);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _playerChip(t, humanName, whitePips, ctrl.pos.offWhite,
              active: ctrl.turn == Checker.white),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: t.accent,
                borderRadius: BorderRadius.circular(10)),
            child: Text('×${ctrl.cube.value}',
                style: TextStyle(
                    color: t.frame,
                    fontWeight: FontWeight.w900,
                    fontSize: 16)),
          ),
          _playerChip(t, oppName, blackPips, ctrl.pos.offBlack,
              active: ctrl.turn == Checker.black),
        ],
      ),
    );
  }

  Widget _playerChip(dynamic t, String name, int pips, int off,
      {required bool active}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? t.accent.withValues(alpha: 0.25)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: active ? t.accent : t.subText.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(name,
              style: TextStyle(
                  color: t.textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
          Text('pip $pips · off $off/15',
              style: TextStyle(color: t.subText, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _blitzBar(dynamic t) {
    final m = ctrl.blitzSecondsLeft ~/ 60;
    final s = ctrl.blitzSecondsLeft % 60;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer, color: t.accent, size: 18),
          const SizedBox(width: 6),
          Text('$m:${s.toString().padLeft(2, '0')}',
              style: TextStyle(
                  color: t.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _controls(dynamic t, bool kids) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          if (!ctrl.diceRolled && ctrl.isHumanTurn && !ctrl.gameOver)
            GoldButton(
              label: 'ROLL',
              icon: Icons.casino,
              small: !kids,
              onTap: ctrl.rollDice,
            ),
          if (ctrl.diceRolled && ctrl.isHumanTurn && !ctrl.gameOver)
            GoldButton(
              label: 'END TURN',
              icon: Icons.done,
              small: !kids,
              onTap: () => _confirmEndTurn(),
            ),
          GoldButton(
            label: 'UNDO',
            icon: Icons.undo,
            small: true,
            onTap: ctrl.canUndo ? ctrl.undo : null,
          ),
          GoldButton(
            label: 'HINT',
            icon: Icons.lightbulb,
            small: true,
            onTap: (ctrl.isHumanTurn && ctrl.diceRolled && !ctrl.gameOver)
                ? () => ctrl.requestHint()
                : null,
          ),
          if (ctrl.humanCanDouble)
            GoldButton(
              label: 'DOUBLE ×${ctrl.cube.value * 2}',
              icon: Icons.casino_outlined,
              small: true,
              onTap: ctrl.humanOffersDouble,
            ),
        ],
      ),
    );
  }

  void _onTapPoint(int point) {
    if (ctrl.gameOver || !ctrl.isHumanTurn) return;
    if (ctrl.selectedPoint != null &&
        ctrl.hintsForSelected.any((m) => m.to == point)) {
      ctrl.tapDestination(point);
      return;
    }
    if (point == 0) {
      // bear-off tray tapped: try to bear off selected checker
      if (ctrl.selectedPoint != null &&
          ctrl.hintsForSelected.any((m) => m.to == 0)) {
        ctrl.tapDestination(0);
      }
      return;
    }
    ctrl.selectPoint(point);
  }

  void _confirmEndTurn() {
    if (ctrl.dice.isEmpty) {
      ctrl.endTurn();
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End turn early?'),
        content: Text(
            'You still have dice left (${ctrl.dice.join(', ')}). Unused dice are forfeited.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Keep playing')),
          TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ctrl.endTurn();
              },
              child: const Text('End turn')),
        ],
      ),
    );
  }

  void _confirmResign() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resign game?'),
        content: const Text('Your opponent will be declared the winner.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Resign')),
        ],
      ),
    );
  }

  void _showHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move history'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ctrl.moveHistory.isEmpty
              ? const Text('No moves yet.')
              : ListView.builder(
                  itemCount: ctrl.moveHistory.length,
                  itemBuilder: (_, i) => Text(
                      '${i + 1}. ${ctrl.moveHistory[i]}',
                      style: const TextStyle(fontSize: 13)),
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close')),
        ],
      ),
    );
  }

  void _showDoubleDialog() {
    final offeredBy = ctrl.cubeOfferedBy;
    final byName = offeredBy == Checker.white ? 'White' : 'Black';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Doubling cube offered!'),
        content: Text(
            '$byName offers to double the stakes from ${ctrl.cube.value} to ${ctrl.cube.value * 2}. Accept, or decline and lose the game.'),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _doubleDialogShown = false;
                ctrl.answerDouble(false);
              },
              child: const Text('Decline (lose)')),
          ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _doubleDialogShown = false;
                ctrl.answerDouble(true);
              },
              child: const Text('Accept')),
        ],
      ),
    );
  }

  void _showGameOver() {
    final humanWon = ctrl.winner != null &&
        (widget.config.mode == GameMode.local2p ||
            ctrl.winner ==
                (ctrl.humanIsWhite ? Checker.white : Checker.black));
    final isTournament = widget.config.mode == GameMode.tournament;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(humanWon ? 'Victory!' : 'Game over'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ctrl.statusMessage),
            const SizedBox(height: 8),
            Text('Moves played: ${ctrl.moveCount}'),
            Text('Blots hit: ${ctrl.hitsByHuman}'),
            if (widget.config.mode == GameMode.blitz)
              Text('Blitz score: ${ctrl.blitzScore}'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Home')),
          if (isTournament && humanWon && widget.config.tournamentRound < 5)
            ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushReplacementNamed('/game',
                      arguments: GameConfig(
                          mode: GameMode.tournament,
                          tournamentRound:
                              widget.config.tournamentRound + 1));
                },
                child: Text(
                    'Next round (${widget.config.tournamentRound + 1}/5)')),
          ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacementNamed('/game',
                    arguments: widget.config);
              },
              child: const Text('Rematch')),
        ],
      ),
    );
  }
}
