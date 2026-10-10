import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../state/save_data.dart';
import '../audio/audio_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final save = SaveData.instance;

  @override
  Widget build(BuildContext context) {
    return QavScaffold(
      title: 'Settings',
      body: ListView(
        children: [
          SectionCard(
            title: 'Audio',
            child: Column(
              children: [
                Row(
                  children: [
                    const ThemedText('Music'),
                    Expanded(
                      child: Slider(
                        value: save.musicVolume,
                        onChanged: (v) {
                          setState(() {});
                          save.setMusicVolume(v);
                          AudioManager.instance.setMusicVolume(v);
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const ThemedText('Sound effects'),
                    Expanded(
                      child: Slider(
                        value: save.sfxVolume,
                        onChanged: (v) {
                          setState(() {});
                          save.setSfxVolume(v);
                          AudioManager.instance.button();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Gameplay',
            child: Column(
              children: [
                SwitchListTile(
                  title: const ThemedText('Kids mode'),
                  subtitle: const ThemedText(
                      'Bigger text, hints always on, no doubling cube.', size: 12),
                  value: save.kidsMode,
                  onChanged: (v) async {
                    await save.setKidsMode(v);
                    setState(() {});
                  },
                ),
                SwitchListTile(
                  title: const ThemedText('Hints enabled'),
                  subtitle: const ThemedText(
                      'Show hint button during your turn.', size: 12),
                  value: save.hintsEnabled,
                  onChanged: (v) async {
                    await save.setHintsEnabled(v);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Data',
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: GoldButton(
                    label: 'Reset all progress',
                    icon: Icons.delete_forever,
                    small: true,
                    onTap: _confirmReset,
                  ),
                ),
                const SizedBox(height: 8),
                const ThemedText(
                    'Everything is stored offline on this device only.',
                    size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text(
            'Stats, achievements, coins and unlocked skins will be erased.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                // Best-effort: clear known keys.
                final s = SaveData.instance;
                for (final k in [
                  'games_played', 'games_won', 'total_hits', 'total_gammons',
                  'total_backgammons', 'current_streak', 'best_streak',
                  'doubles_rolled', 'cubes_offered', 'coins', 'achievements',
                  'owned_board_skins', 'owned_checker_skins', 'practice_done',
                  'play_days',
                ]) {
                  await s.setInt(k, 0);
                }
                await s.setString('achievements', '');
                await s.setInt('coins', 100);
                setState(() {});
              },
              child: const Text('Reset')),
        ],
      ),
    );
  }
}
