import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../state/save_data.dart';

class HowToScreen extends StatelessWidget {
  const HowToScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SaveData.instance.unlock('scholar');
    return QavScaffold(
      title: 'How to Play',
      body: ListView(
        children: const [
          _Rule('The goal',
              'Move all 15 of your checkers around the board and bear them off before your opponent. White moves from point 24 down to point 1; Black moves from 1 up to 24.'),
          _Rule('Rolling the dice',
              'Tap ROLL, then tap one of your checkers and tap a highlighted destination. Doubles give you four moves instead of two. You must use as many dice as legally possible — when only one die can be played, the higher one must be used.'),
          _Rule('Hitting blots',
              'A point with a single enemy checker is a "blot". Landing on it sends that checker to the bar. A point with two or more enemy checkers is blocked.'),
          _Rule('The bar',
              'Checkers on the bar must re-enter before anything else moves. White re-enters onto points 24–19, Black onto points 1–6, using the dice values.'),
          _Rule('Bearing off',
              'Once all 15 checkers are in your home board (points 1–6 for White, 19–24 for Black), you may bear them off. You may use a higher die to bear off from a lower point when no checkers sit on higher points.'),
          _Rule('The doubling cube',
              'Before rolling, you may offer the doubling cube to raise the stakes. Your opponent may accept (stakes double) or decline (you win immediately). The cube starts at 1 and can reach 64.'),
          _Rule('The Crawford rule',
              'In match play, when a player is one point away from winning the match, the doubling cube is retired for the next game. Qavex Backgammon Gold applies this automatically in the final round of the Tournament Ladder.'),
          _Rule('Gammons',
              'Win a gammon (double stakes) if your opponent has not borne off a single checker. It becomes a backgammon (triple stakes) if they also have a checker on the bar or in your home board.'),
          _Rule('Kids mode',
              'Enable Kids mode in Settings for bigger text, automatic hints, and no doubling cube.'),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  final String title;
  final String body;
  const _Rule(this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return SectionCard(title: title, child: ThemedText(body, size: 14));
  }
}
