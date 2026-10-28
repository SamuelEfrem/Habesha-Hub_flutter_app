import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles the two one-time purchases used by Life Tools:
///   theory_pro → extra driving theory questions
///   lang_pro   → extra language topics
/// Create products with exactly these IDs (non-consumable / "managed product")
/// in Google Play Console and App Store Connect.
class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  static const Set<String> productIds = {'theory_pro', 'lang_pro'};
  static const _prefsKey = 'owned_products';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final Map<String, ProductDetails> _products = {};
  final Set<String> _owned = {};

  /// Called when a product becomes owned (bought or restored).
  void Function(String productId)? onUnlocked;

  /// Called with a short message when something goes wrong.
  void Function(String message)? onError;

  Set<String> get owned => Set.unmodifiable(_owned);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _owned.addAll(prefs.getStringList(_prefsKey) ?? const []);

    if (!await _iap.isAvailable()) return;
    _sub ??= _iap.purchaseStream.listen(_onPurchases, onError: (e) => onError?.call('$e'));

    final resp = await _iap.queryProductDetails(productIds);
    for (final p in resp.productDetails) {
      _products[p.id] = p;
    }
  }

  /// Price as shown by the store (for example "49,00 kr"), or null if unknown.
  String? priceOf(String id) => _products[id]?.price;

  Future<void> buy(String id) async {
    if (_owned.contains(id)) {
      onUnlocked?.call(id);
      return;
    }
    final product = _products[id];
    if (product == null) {
      onError?.call('Product not available yet. Check the product ID in the store.');
      return;
    }
    await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  /// Required by Apple: give users a "Restore purchases" button somewhere in the app.
  Future<void> restore() => _iap.restorePurchases();

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
        // NOTE: for real protection, verify p.verificationData on your server
        // (for example a Firebase Cloud Function) before unlocking.
        await _markOwned(p.productID);
        onUnlocked?.call(p.productID);
      } else if (p.status == PurchaseStatus.error) {
        onError?.call(p.error?.message ?? 'Purchase failed');
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }

  Future<void> _markOwned(String id) async {
    _owned.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _owned.toList());
  }

  void dispose() => _sub?.cancel();
}
