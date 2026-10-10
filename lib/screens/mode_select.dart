/// Mode Select: seven game modes.
library;

import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../state/game_controller.dart';
import '../ai/ai.dart';
import '../state/save_data.dart';
import '../audio/audio_manager.dart';

class ModeSelectScreen extends StatefulWidget {
  const ModeSelectScreen({super.key});

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen> {
  bool doubling = true;

  void _start(GameConfig config) {
    AudioManager.instance.button();
    Navigator.of(context).pushNamed('/game', arguments: config);
  }

  void _toLevelSelect(GameMode mode) {
    AudioManager.instance.button();
    Navigator.of(context).pushNamed('/level', arguments: mode);
  }

  @override
  Widget build(BuildContext context) {
    final save = SaveData.instance;
    final kids = save.kidsMode;
    return QavScaffold(
      title: 'Choose Mode',
      body: ListView(
        children: [
          SectionCard(
            title: 'Versus AI',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ThemedText('Doubling cube (Classic)'),
                    Switch(
                        value: doubling && !kids,
                        onChanged: kids
                            ? null
                            : (v) => setState(() => doubling = v)),
                  ],
                ),
                if (kids)
                  const ThemedText(
                      'Kids mode is on: doubling cube disabled, hints always shown.',
                      size: 12),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: GoldButton(
                    label: 'Classic — full rules',
                    icon: Icons.casino,
                    onTap: () => _toLevelSelect(GameMode.classic),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: GoldButton(
                    label: 'vs AI — quick casual game',
                    icon: Icons.flash_on,
                    onTap: () => _start(GameConfig(
                        mode: GameMode.quickVsAi,
                        aiLevel: _defaultQuickLevel(),
                        doublingEnabled: false,
                        kidsMode: kids)),
                  ),
                ),
                TextButton(
                  onPressed: () => _toLevelSelect(GameMode.quickVsAi),
                  child: const ThemedText('Choose difficulty first',
                      size: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          _modeCard(
            'Timed Blitz',
            'Beat the clock: 5 minutes. Score = Doubloon Coins + seconds left.',
            Icons.timer,
            () => _start(GameConfig(
                mode: GameMode.blitz,
                doublingEnabled: doubling && !kids,
                kidsMode: kids)),
          ),
          _modeCard(
            'Tournament Ladder',
            'Five rounds: Easy → Expert. Crawford rule retires the cube in the final.',
            Icons.emoji_events,
            () => _start(GameConfig(
                mode: GameMode.tournament,
                doublingEnabled: doubling && !kids,
                kidsMode: kids,
                tournamentRound: 1)),
          ),
          _modeCard(
            'Doubling Cube Masters',
            'An aggressive AI doubles early and often. Survive the stakes.',
            Icons.casino_outlined,
            () => _start(const GameConfig(
                mode: GameMode.cubeChallenge, doublingEnabled: true)),
          ),
          _modeCard(
            'Practice',
            'Relaxed game vs Easy AI. Hints always on, no pressure.',
            Icons.school,
            () => _start(GameConfig(
                mode: GameMode.practice,
                doublingEnabled: false,
                kidsMode: kids)),
          ),
          _modeCard(
            'Pass & Play',
            'Two players, one device. Pass it back and forth.',
            Icons.people,
            () => _start(GameConfig(
                mode: GameMode.local2p,
                doublingEnabled: doubling && !kids,
                kidsMode: kids)),
          ),
        ],
      ),
    );
  }

  /// A friendly rotating default difficulty for one-tap quick matches.
  AiLevel _defaultQuickLevel() {
    const levels = [AiLevel.easy, AiLevel.medium, AiLevel.medium];
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return levels[dayOfYear % levels.length];
  }

  Widget _modeCard(
      String title, String desc, IconData icon, VoidCallback onTap) {
    return SectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThemedText(desc, size: 13),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: GoldButton(label: 'Play', icon: icon, onTap: onTap),
          ),
        ],
      ),
    );
  }
}
