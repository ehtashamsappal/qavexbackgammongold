import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'state/save_data.dart';
import 'audio/audio_manager.dart';
import 'shop/iap_manager.dart';
import 'widgets/common.dart';
import 'screens/splash.dart';
import 'screens/home.dart';
import 'screens/mode_select.dart';
import 'screens/level_select.dart';
import 'screens/game.dart';
import 'screens/settings.dart';
import 'screens/themes.dart';
import 'screens/profile.dart';
import 'screens/stats.dart';
import 'screens/how_to.dart';
import 'screens/about.dart';
import 'screens/shop.dart';
import 'dart:async';
import 'state/game_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SaveData.instance.init();
  await AudioManager.instance.init();
  // IAP is optional/offline-safe; never blocks startup.
  unawaited(CoffeeIap.instance.init());
  unawaited(AudioManager.instance.startBgm());
  runApp(const QavexBackgammonApp());
}

class QavexBackgammonApp extends StatelessWidget {
  const QavexBackgammonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeState.instance,
      builder: (context, _) {
        final t = AppThemeState.instance.theme;
        return MaterialApp(
          title: 'Qavex Backgammon Gold',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: t.accent,
              brightness: t.dark ? Brightness.dark : Brightness.light,
            ),
            scaffoldBackgroundColor: t.background,
          ),
          initialRoute: '/',
          routes: {
            '/': (_) => const SplashScreen(),
            '/home': (_) => const HomeScreen(),
            '/modes': (_) => const ModeSelectScreen(),
            '/level': (_) => const LevelSelectScreen(),
            '/settings': (_) => const SettingsScreen(),
            '/themes': (_) => const ThemesScreen(),
            '/profile': (_) => const ProfileScreen(),
            '/stats': (_) => const StatsScreen(),
            '/howto': (_) => const HowToScreen(),
            '/about': (_) => const AboutScreen(),
            '/shop': (_) => const ShopScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/game') {
              final config = settings.arguments as GameConfig;
              return MaterialPageRoute(
                  builder: (_) => GameScreen(config: config));
            }
            return null;
          },
        );
      },
    );
  }
}
