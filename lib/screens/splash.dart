import 'package:flutter/material.dart';
import '../widgets/common.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeState.instance,
      builder: (context, _) {
        final t = AppThemeState.instance.theme;
        return Scaffold(
          backgroundColor: t.background,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/splash.png',
                    width: 200, height: 200, errorBuilder: (_, __, ___) {
                  return Icon(Icons.casino,
                      size: 120, color: t.accent);
                }),
                const SizedBox(height: 24),
                Text('QAVEX BACKGAMMON',
                    style: TextStyle(
                        color: t.accent,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3)),
                const SizedBox(height: 6),
                Text('G O L D   E D I T I O N',
                    style: TextStyle(
                        color: t.subText, fontSize: 14, letterSpacing: 6)),
                const SizedBox(height: 32),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(color: t.accent),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
