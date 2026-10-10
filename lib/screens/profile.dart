import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../state/save_data.dart';
import '../audio/audio_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final save = SaveData.instance;
  late final TextEditingController _nameCtrl =
      TextEditingController(text: save.playerName);

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wins = save.gamesWon;
    final played = save.gamesPlayed;
    final winRate = played == 0 ? 0 : (wins * 100 / played).round();
    return QavScaffold(
      title: 'Player Profile',
      body: ListView(
        children: [
          SectionCard(
            title: 'Identity',
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Display name',
                      border: OutlineInputBorder()),
                  onSubmitted: (v) async {
                    final name = v.trim().isEmpty ? 'Player' : v.trim();
                    await save.setPlayerName(name);
                    AudioManager.instance.button();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                const ThemedText(
                    'Your name appears on the scoreboard in AI games.',
                    size: 12),
              ],
            ),
          ),
          SectionCard(
            title: 'Career',
            child: Column(
              children: [
                _row('Games played', '$played'),
                _row('Games won', '$wins'),
                _row('Win rate', '$winRate%'),
                _row('Best win streak', '${save.bestStreak}'),
                _row('Blots hit', '${save.totalHits}'),
                _row('Gammons', '${save.totalGammons}'),
                _row('Backgammons', '${save.totalBackgammons}'),
                _row('Doubloon Coins', '${save.coins}'),
              ],
            ),
          ),
          SectionCard(
            title: 'Local Leaderboards (best)',
            child: Column(
              children: [
                _row('Timed Blitz best score',
                    '${save.bestBlitzScore('blitz')}'),
                _row('Tournament best round',
                    '${save.getInt('best_tournament', 0)}/5'),
                _row('Cube Challenge wins',
                    '${save.getInt('cube_wins', 0)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ThemedText(label),
          ThemedText(value, weight: FontWeight.w800),
        ],
      ),
    );
  }
}
