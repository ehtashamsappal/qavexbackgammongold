import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../state/save_data.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final save = SaveData.instance;
    final unlocked = save.unlockedAchievements;
    return QavScaffold(
      title: 'Stats & Achievements',
      body: ListView(
        children: [
          SectionCard(
            title: 'Lifetime stats',
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _stat('Played', '${save.gamesPlayed}'),
                _stat('Won', '${save.gamesWon}'),
                _stat('Hits', '${save.totalHits}'),
                _stat('Gammons', '${save.totalGammons}'),
                _stat('Backgammons', '${save.totalBackgammons}'),
                _stat('Best streak', '${save.bestStreak}'),
                _stat('Doubles', '${save.doublesRolled}'),
                _stat('Cubes offered', '${save.cubesOffered}'),
              ],
            ),
          ),
          SectionCard(
            title:
                'Achievements (${unlocked.length}/${Achievements.count})',
            child: Column(
              children: Achievements.all.map((a) {
                final got = unlocked.contains(a['id']);
                return ListTile(
                  dense: true,
                  leading: Icon(
                      got ? Icons.emoji_events : Icons.lock_outline,
                      color: got ? Colors.amber : Colors.grey),
                  title: ThemedText(a['name']!,
                      weight: FontWeight.w700,
                      color: got ? null : Colors.grey),
                  subtitle: ThemedText(a['desc']!,
                      size: 12, color: Colors.grey),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        ThemedText(value, size: 20, weight: FontWeight.w900),
        ThemedText(label, size: 11),
      ],
    );
  }
}
