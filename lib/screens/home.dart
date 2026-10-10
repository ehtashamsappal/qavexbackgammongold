import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../state/save_data.dart';
import '../audio/audio_manager.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeState.instance,
      builder: (context, _) {
        final t = AppThemeState.instance.theme;
        final save = SaveData.instance;
        return Scaffold(
          backgroundColor: t.background,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 28),
                  Text('QAVEX',
                      style: TextStyle(
                          color: t.subText,
                          fontSize: 15,
                          letterSpacing: 8,
                          fontWeight: FontWeight.w600)),
                  Text('BACKGAMMON GOLD',
                      style: TextStyle(
                          color: t.accent,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.monetization_on,
                          color: t.accent, size: 18),
                      const SizedBox(width: 4),
                      Text('${save.coins} Doubloon Coins',
                          style: TextStyle(
                              color: t.textColor,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _menuButton(context, 'PLAY', Icons.play_arrow, '/modes',
                      primary: true),
                  _menuButton(context, 'How to Play', Icons.school, '/howto'),
                  _menuButton(context, 'Themes', Icons.palette, '/themes'),
                  _menuButton(
                      context, 'Profile', Icons.person, '/profile'),
                  _menuButton(
                      context, 'Stats & Achievements', Icons.emoji_events, '/stats'),
                  _menuButton(context, 'Shop & Support', Icons.store, '/shop'),
                  _menuButton(
                      context, 'Settings', Icons.settings, '/settings'),
                  _menuButton(context, 'About & Privacy', Icons.info, '/about'),
                  const SizedBox(height: 16),
                  Text('v1.0.0 · by QAVEX · offline',
                      style: TextStyle(color: t.subText, fontSize: 12)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _menuButton(BuildContext context, String label, IconData icon,
      String route,
      {bool primary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 6),
      child: SizedBox(
        width: double.infinity,
        child: GoldButton(
          label: label,
          icon: icon,
          small: !primary,
          onTap: () {
            AudioManager.instance.button();
            Navigator.of(context).pushNamed(route);
          },
        ),
      ),
    );
  }
}
