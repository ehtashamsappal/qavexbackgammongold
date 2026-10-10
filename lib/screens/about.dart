import 'package:flutter/material.dart';
import '../widgets/common.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const QavScaffold(
      title: 'About & Privacy',
      body: _AboutBody(),
    );
  }
}

class _AboutBody extends StatelessWidget {
  const _AboutBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SectionCard(
          title: 'Qavex Backgammon Gold',
          child: ThemedText(
              'Version 1.0.0. A premium, fully offline backgammon game.\n\n'
              'Developer: muhammad ehtasham\n'
              'Company: QAVEX\n'
              'Website: https://www.qavex.company/\n'
              'Email: games@qavex.company\n'
              'Phone: +923375621550',
              size: 14),
        ),
        SectionCard(
          title: 'Privacy policy',
          child: ThemedText(
              'Qavex Backgammon Gold collects no personal data. There are no '
              'accounts, no ads, no analytics, and no trackers. All game '
              'progress, statistics, achievements, themes and settings are '
              'stored locally on your device only, using on-device storage. '
              'The game requests no network permissions and works fully '
              'offline.\n\n'
              'The optional "Buy Me a Coffee" purchase is processed entirely '
              'by the Google Play Store / Apple App Store; QAVEX never sees '
              'or stores your payment details.\n\n'
              'Questions: games@qavex.company',
              size: 14),
        ),
        SectionCard(
          title: 'Credits',
          child: ThemedText(
              'All artwork, board designs, music and sound effects were '
              'created originally for this game. Dice physics-free fun '
              'guaranteed.',
              size: 14),
        ),
      ],
    );
  }
}
