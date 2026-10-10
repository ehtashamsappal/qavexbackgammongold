/// Shared UI atoms: themed scaffold, gold buttons, section cards.
library;

import 'package:flutter/material.dart';
import '../theme/game_themes.dart';
import '../state/save_data.dart';

class AppThemeState extends ChangeNotifier {
  static final AppThemeState instance = AppThemeState._();
  AppThemeState._();

  GameTheme get theme => GameThemes.byId(SaveData.instance.themeId);

  void refresh() => notifyListeners();
}

class QavScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const QavScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeState.instance,
      builder: (context, _) {
        final t = AppThemeState.instance.theme;
        return Scaffold(
          backgroundColor: t.background,
          appBar: AppBar(
            backgroundColor: t.frame,
            foregroundColor: t.accent,
            title: Text(title,
                style: TextStyle(
                    color: t.accent, fontWeight: FontWeight.w800)),
            actions: actions,
          ),
          body: SafeArea(child: body),
          floatingActionButton: floatingActionButton,
        );
      },
    );
  }
}

class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool small;

  const GoldButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeState.instance,
      builder: (context, _) {
        final t = AppThemeState.instance.theme;
        return ElevatedButton.icon(
          onPressed: onTap,
          icon: icon != null
              ? Icon(icon, size: small ? 16 : 20)
              : const SizedBox.shrink(),
          label: Text(label,
              style: TextStyle(
                  fontSize: small ? 13 : 16, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: t.accent,
            foregroundColor: t.frame,
            disabledBackgroundColor: t.subText.withValues(alpha: 0.3),
            padding: EdgeInsets.symmetric(
                horizontal: small ? 14 : 22, vertical: small ? 8 : 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const SectionCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeState.instance,
      builder: (context, _) {
        final t = AppThemeState.instance.theme;
        return Card(
          color: t.felt.withValues(alpha: 0.35),
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: t.accent,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                child,
              ],
            ),
          ),
        );
      },
    );
  }
}

class ThemedText extends StatelessWidget {
  final String text;
  final double size;
  final FontWeight weight;
  final Color? color;
  const ThemedText(this.text,
      {super.key, this.size = 14, this.weight = FontWeight.normal, this.color});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeState.instance,
      builder: (context, _) {
        final t = AppThemeState.instance.theme;
        return Text(text,
            style: TextStyle(
                color: color ?? t.textColor, fontSize: size, fontWeight: weight));
      },
    );
  }
}
