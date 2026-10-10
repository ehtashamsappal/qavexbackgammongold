import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../state/save_data.dart';
import '../shop/iap_manager.dart';
import '../audio/audio_manager.dart';

/// Shop: spend soft currency on unlockable skins, and the single
/// "Buy Me a Coffee" IAP (never gates gameplay).
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final save = SaveData.instance;
  String? _message;

  @override
  void initState() {
    super.initState();
    CoffeeIap.instance.onEvent = (m) {
      if (mounted) setState(() => _message = m);
    };
  }

  @override
  Widget build(BuildContext context) {
    return QavScaffold(
      title: 'Shop & Support',
      body: ListView(
        children: [
          SectionCard(
            title: 'Your Doubloons: ${save.coins}',
            child: const ThemedText(
                'Earn gold by playing and winning games, and by unlocking achievements. Spend it on board and checker skins below.',
                size: 13),
          ),
          if (_message != null)
            SectionCard(
                title: 'Notice', child: ThemedText(_message!, size: 13)),
          SectionCard(
            title: 'Board skins',
            child: Column(children: _skinRows(SaveData.boardSkins, true)),
          ),
          SectionCard(
            title: 'Checker skins',
            child: Column(children: _skinRows(SaveData.checkerSkins, false)),
          ),
          SectionCard(
            title: 'Support the developer',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ThemedText(
                    'Qavex Backgammon Gold is free with no ads. If you enjoy it, you can buy the team a coffee — a \$0.99 consumable that never unlocks gameplay advantages (you also get 250 bonus gold as a thank-you).',
                    size: 13),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: GoldButton(
                    label: CoffeeIap.instance.product != null
                        ? 'Buy Me a Coffee — ${CoffeeIap.instance.product!.price}'
                        : 'Buy Me a Coffee — \$0.99',
                    icon: Icons.coffee,
                    onTap: () {
                      AudioManager.instance.button();
                      CoffeeIap.instance.buyCoffee();
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

  List<Widget> _skinRows(List<Map<String, dynamic>> skins, bool isBoard) {
    return skins.map((s) {
      final id = s['id'] as String;
      final owned = isBoard
          ? save.ownsBoardSkin(id)
          : save.ownsCheckerSkin(id);
      final active = isBoard
          ? save.activeBoardSkin == id
          : save.activeCheckerSkin == id;
      final price = s['price'] as int;
      return ListTile(
        title: ThemedText(s['name'] as String,
            weight: FontWeight.w700),
        subtitle: ThemedText(
            owned ? (active ? 'Equipped' : 'Owned') : '$price Doubloons',
            size: 12),
        trailing: owned
            ? (active
                ? const Icon(Icons.check, color: Colors.green)
                : GoldButton(
                    label: 'Equip',
                    small: true,
                    onTap: () async {
                      if (isBoard) {
                        await save.setActiveBoardSkin(id);
                      } else {
                        await save.setActiveCheckerSkin(id);
                      }
                      AudioManager.instance.button();
                      setState(() {});
                    },
                  ))
            : GoldButton(
                label: 'Buy',
                small: true,
                onTap: save.coins >= price
                    ? () async {
                        final ok = isBoard
                            ? await save.buyBoardSkin(id, price)
                            : await save.buyCheckerSkin(id, price);
                        if (ok) {
                          await save.unlock('skin_unlock');
                          final allBoard = SaveData.boardSkins.every(
                              (x) => save.ownsBoardSkin(x['id'] as String));
                          final allCheck = SaveData.checkerSkins.every(
                              (x) => save.ownsCheckerSkin(x['id'] as String));
                          if (allBoard && allCheck) {
                            await save.unlock('skin_all');
                          }
                        }
                        AudioManager.instance.button();
                        setState(() {});
                      }
                    : null,
              ),
      );
    }).toList();
  }
}
