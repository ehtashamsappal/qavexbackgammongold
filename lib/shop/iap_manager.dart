/// In-app purchase: exactly ONE consumable — "Buy Me a Coffee" ($0.99).
/// Product ID: qavexbackgammongoldcoffee. Never gates gameplay.
library;

import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../state/save_data.dart';

class CoffeeIap {
  static const String productId = 'qavexbackgammongoldcoffee';
  static final CoffeeIap instance = CoffeeIap._();
  CoffeeIap._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  ProductDetails? product;
  bool available = false;
  bool _started = false;
  void Function(String message)? onEvent;

  Future<void> init() async {
    if (_started) return;
    _started = true;
    try {
      available = await _iap.isAvailable();
      if (!available) return;
      final resp = await _iap.queryProductDetails({productId});
      if (resp.productDetails.isNotEmpty) {
        product = resp.productDetails.first;
      }
      _sub = _iap.purchaseStream.listen(_onPurchases,
          onError: (_) {}, onDone: () {});
    } catch (_) {
      available = false;
    }
  }

  Future<void> buyCoffee() async {
    if (!available || product == null) {
      onEvent?.call('Store is unavailable right now.');
      return;
    }
    try {
      await _iap.buyConsumable(
          purchaseParam: PurchaseParam(productDetails: product!));
    } catch (_) {
      onEvent?.call('Purchase could not be started.');
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      if (p.productID != productId) continue;
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        await SaveData.instance.unlock('supporter');
        await SaveData.instance.addCoins(250); // thank-you bonus
        onEvent?.call('Thank you! Enjoy 250 bonus Doubloon Coins.');
      } else if (p.status == PurchaseStatus.error) {
        onEvent?.call('Purchase was not completed.');
      }
      if (p.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(p);
        } catch (_) {}
      }
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
