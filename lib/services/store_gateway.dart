import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

/// The narrow slice of the store the app uses, behind an interface so the
/// purchase logic can be tested without StoreKit.
///
/// There is no server here, and there will not be one. Every check goes to
/// StoreKit on the device, which verifies Apple's signature on each
/// transaction itself — that is the whole of the verification, and for a
/// one-time unlock in an app with no account it is the right amount.
abstract class StoreGateway {
  /// Every transaction update, including ones finished on another launch.
  Stream<List<PurchaseDetails>> get purchaseUpdates;

  /// The product, with its price formatted by the store for this storefront.
  /// Null when the store has no such product or cannot be reached.
  Future<ProductDetails?> loadProduct(String id);

  /// Starts a purchase. The outcome arrives on [purchaseUpdates].
  Future<void> buy(ProductDetails product);

  /// Tells the store the app has delivered what was bought.
  Future<void> complete(PurchaseDetails purchase);

  /// Whether the store, on this device, holds a verified entitlement for [id].
  ///
  /// Null when this platform cannot answer directly (the answer then arrives
  /// as a restored purchase on [purchaseUpdates]).
  Future<bool?> ownsProduct(String id);

  /// The Restore Purchases button: asks the store to bring this device up to
  /// date with the account, then answers as [ownsProduct] does.
  Future<bool?> restore(String id);
}

class InAppPurchaseGateway implements StoreGateway {
  InAppPurchaseGateway([InAppPurchase? iap])
    : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  bool get _isApple => Platform.isIOS || Platform.isMacOS;

  @override
  Stream<List<PurchaseDetails>> get purchaseUpdates => _iap.purchaseStream;

  @override
  Future<ProductDetails?> loadProduct(String id) async {
    if (!await _iap.isAvailable()) {
      debugPrint('Elapsa store: StoreKit says the store is unavailable');
      return null;
    }
    final response = await _iap.queryProductDetails({id});
    // Said out loud, because "the store cannot be reached" covers three very
    // different problems — no network, a product App Store Connect is not
    // serving yet, and a typo in the identifier — and only the log can tell
    // them apart.
    if (response.error != null) {
      debugPrint('Elapsa store: product query failed: ${response.error}');
      return null;
    }
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint(
        'Elapsa store: the store does not offer ${response.notFoundIDs} '
        '(not approved, agreement not active, or wrong ID)',
      );
    }
    for (final product in response.productDetails) {
      if (product.id == id) return product;
    }
    return null;
  }

  @override
  Future<void> buy(ProductDetails product) =>
      _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));

  @override
  Future<void> complete(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);

  @override
  Future<bool?> ownsProduct(String id) async {
    if (!_isApple || !InAppPurchaseStoreKitPlatform.isStoreKit2Enabled) {
      return null;
    }
    // Transaction.currentEntitlements: verified by StoreKit, works offline,
    // and drops a purchase that was refunded.
    final owned = await SK2Transaction.currentEntitlements();
    return owned.any((transaction) => transaction.productId == id);
  }

  @override
  Future<bool?> restore(String id) async {
    if (_isApple && InAppPurchaseStoreKitPlatform.isStoreKit2Enabled) {
      try {
        // AppStore.sync() may ask the user to sign in, which is fine here:
        // they pressed Restore. It throws when they cancel or are offline,
        // and the local entitlements are still worth checking after that.
        await AppStore().sync();
      } catch (_) {}
      return ownsProduct(id);
    }
    await _iap.restorePurchases();
    return null;
  }
}
