import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../theme/game_themes.dart';
import '../state/save_data.dart';
import '../audio/audio_manager.dart';

class ThemesScreen extends StatefulWidget {
  const ThemesScreen({super.key});

  @override
  State<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends State<ThemesScreen> {
  final tried = <String>{};

  @override
  void initState() {
    super.initState();
    tried.add(SaveData.instance.themeId);
  }

  @override
  Widget build(BuildContext context) {
    return QavScaffold(
      title: 'Themes',
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 0.78, crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemCount: GameThemes.all.length,
        itemBuilder: (ctx, i) {
          final theme = GameThemes.all[i];
          final active = SaveData.instance.themeId == theme.id;
          return GestureDetector(
            onTap: () async {
              await SaveData.instance.setThemeId(theme.id);
              AppThemeState.instance.refresh();
              AudioManager.instance.button();
              tried.add(theme.id);
              await SaveData.instance.unlock('theme_changer');
              if (tried.length >= GameThemes.all.length) {
                await SaveData.instance.unlock('all_themes');
              }
              setState(() {});
            },
            child: Container(
              decoration: BoxDecoration(
                color: theme.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: active ? theme.accent : Colors.grey.shade600,
                    width: active ? 3 : 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _swatch(theme),
                  const SizedBox(height: 10),
                  Text(theme.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w800)),
                  if (active)
                    Text('ACTIVE',
                        style: TextStyle(
                            color: theme.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _swatch(GameTheme theme) {
    return SizedBox(
      width: 120,
      height: 74,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(painter: _MiniBoardPainter(theme)),
      ),
    );
  }
}

class _MiniBoardPainter extends CustomPainter {
  final GameTheme theme;
  _MiniBoardPainter(this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = theme.felt);
    final pw = size.width / 12;
    for (int i = 0; i < 12; i++) {
      final path = Path()
        ..moveTo(i * pw, 0)
        ..lineTo((i + 1) * pw, 0)
        ..lineTo((i + 0.5) * pw, size.height * 0.45)
        ..close();
      canvas.drawPath(path,
          Paint()..color = i % 2 == 0 ? theme.pointA : theme.pointB);
    }
    // mini checkers
    canvas.drawCircle(Offset(pw * 1.5, size.height * 0.8), pw * 0.42,
        Paint()..color = theme.checkerLight);
    canvas.drawCircle(Offset(pw * 9.5, size.height * 0.2), pw * 0.42,
        Paint()..color = theme.checkerDark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
