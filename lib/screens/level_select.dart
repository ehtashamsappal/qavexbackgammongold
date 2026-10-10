/// Level Select: pick an AI difficulty before a versus-AI game.
library;

import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../state/game_controller.dart';
import '../ai/ai.dart';
import '../state/save_data.dart';
import '../audio/audio_manager.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  static const _blurbs = {
    AiLevel.easy: 'Relaxed and forgiving. Great for learning the ropes.',
    AiLevel.medium: 'A solid club player. Thinks a few moves ahead.',
    AiLevel.hard: 'Sharp tactics and smart cube play. A real test.',
    AiLevel.expert: 'Near-optimal play with deep lookahead. Good luck.',
  };

  static const _icons = {
    AiLevel.easy: Icons.sentiment_satisfied,
    AiLevel.medium: Icons.psychology,
    AiLevel.hard: Icons.bolt,
    AiLevel.expert: Icons.workspace_premium,
  };

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final GameMode mode =
        args is GameMode ? args : GameMode.classic;
    final save = SaveData.instance;
    final kids = save.kidsMode;
    return QavScaffold(
      title: 'Select Difficulty',
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ThemedText(
              mode == GameMode.quickVsAi
                  ? 'Quick match vs AI — casual rules, no doubling cube.'
                  : 'Classic match vs AI — full official rules with the doubling cube.',
              size: 13,
            ),
          ),
          for (final level in AiLevel.values)
            SectionCard(
              title: '${level.label} AI',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ThemedText(_blurbs[level]!, size: 13),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: GoldButton(
                      label: 'Play vs ${level.label}',
                      icon: _icons[level],
                      onTap: () {
                        AudioManager.instance.button();
                        Navigator.of(context).pushNamed('/game',
                            arguments: GameConfig(
                              mode: mode,
                              aiLevel: level,
                              doublingEnabled:
                                  mode == GameMode.classic && !kids,
                              kidsMode: kids,
                            ));
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
