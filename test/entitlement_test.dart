import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elapsa/data/purchase_controller.dart';
import 'package:elapsa/data/settings_repository.dart';
import 'package:elapsa/domain/entitlement.dart';
import 'package:elapsa/services/store_gateway.dart';

void main() {
  group('free-tier limit', () {
    test('allows up to three documents', () {
      expect(kFreeDocumentLimit, 3);
      for (var existing = 0; existing < 3; existing++) {
        expect(canAddDocuments(existing: existing, unlocked: false), isTrue);
      }
    });

    test('stops the fourth', () {
      expect(canAddDocuments(existing: 3, unlocked: false), isFalse);
      expect(canAddDocuments(existing: 7, unlocked: false), isFalse);
    });

    test('lifts the limit once unlocked', () {
      expect(canAddDocuments(existing: 3, unlocked: true), isTrue);
      expect(canAddDocuments(existing: 500, unlocked: true), isTrue);
    });

    test('several at once must all fit', () {
      expect(canAddDocuments(existing: 1, adding: 2, unlocked: false), isTrue);
      expect(canAddDocuments(existing: 1, adding: 3, unlocked: false), isFalse);
    });

    test('adding nothing is always fine, even over the limit', () {
      expect(canAddDocuments(existing: 5, adding: 0, unlocked: false), isTrue);
    });
  });

  group('imports', () {
    test('an incoming document already here does not count twice', () {
      expect(
        countAfterImport(
          existingIds: {'a', 'b', 'c'},
          incomingIds: ['a', 'b'],
        ),
        3,
      );
      expect(
        canImport(
          existingIds: {'a', 'b', 'c'},
          incomingIds: ['a', 'b', 'c'],
          unlocked: false,
        ),
        isTrue,
      );
    });

    test('a merge past the limit is refused', () {
      expect(
        canImport(
          existingIds: {'a', 'b'},
          incomingIds: ['c', 'd'],
          unlocked: false,
        ),
        isFalse,
      );
    });

    test('replace counts only what arrives', () {
      expect(
        countAfterImport(
          existingIds: {'a', 'b', 'c'},
          incomingIds: ['x', 'y'],
          replace: true,
        ),
        2,
      );
      expect(
        canImport(
          existingIds: {'a', 'b', 'c'},
          incomingIds: ['w', 'x', 'y', 'z'],
          unlocked: false,
          replace: true,
        ),
        isFalse,
      );
    });

    test('refreshing a wallet already over the limit is allowed', () {
      // Someone refunded with five documents still re-imports their backup.
      expect(
        canImport(
          existingIds: {'a', 'b', 'c', 'd', 'e'},
          incomingIds: ['a', 'b', 'c', 'd', 'e'],
          unlocked: false,
        ),
        isTrue,
      );
    });

    test('anything goes once unlocked', () {
      expect(
        canImport(
          existingIds: {'a', 'b', 'c'},
          incomingIds: List.generate(40, (i) => '$i'),
          unlocked: true,
        ),
        isTrue,
      );
    });
  });

  group('purchase controller', () {
    late _FakeStore store;
    late SettingsRepository settings;

    Future<PurchaseController> make({bool cached = false}) async {
      SharedPreferences.setMockInitialValues(
        cached ? {'unlimited_unlocked': true} : {},
      );
      settings = SettingsRepository(await SharedPreferences.getInstance());
      final controller = PurchaseController(store, settings);
      await controller.start();
      return controller;
    }

    setUp(() => store = _FakeStore());

    test('starts locked and loads the store price', () async {
      final c = await make();
      expect(c.state.unlocked, isFalse);
      expect(c.state.product?.price, r'$9.99');
    });

    test('a purchase unlocks, persists and is finished', () async {
      final c = await make();
      await c.buy();
      store.owned = true;
      await store.emit(PurchaseStatus.purchased);

      expect(c.state.unlocked, isTrue);
      expect(c.state.notice, PurchaseNotice.purchased);
      expect(settings.unlimitedUnlocked, isTrue);
      expect(store.completed, 1);
    });

    test('a cancelled purchase leaves it locked', () async {
      final c = await make();
      await c.buy();
      await store.emit(PurchaseStatus.canceled);

      expect(c.state.unlocked, isFalse);
      expect(c.state.activity, PurchaseActivity.idle);
      expect(c.state.notice, PurchaseNotice.cancelled);
    });

    test('a failed purchase leaves it locked and says so', () async {
      final c = await make();
      await c.buy();
      await store.emit(PurchaseStatus.error);

      expect(c.state.unlocked, isFalse);
      expect(c.state.notice, PurchaseNotice.failed);
      expect(store.completed, 1);
    });

    test('a pending purchase waits, then unlocks when approved', () async {
      final c = await make();
      await c.buy();
      await store.emit(PurchaseStatus.pending);
      expect(c.state.pending, isTrue);
      expect(c.state.unlocked, isFalse);
      expect(c.state.busy, isFalse);

      store.owned = true;
      await store.emit(PurchaseStatus.purchased);
      expect(c.state.unlocked, isTrue);
      expect(c.state.pending, isFalse);
    });

    test('a purchase StoreKit cannot verify is not trusted', () async {
      final c = await make();
      await c.buy();
      store.owned = false;
      await store.emit(PurchaseStatus.purchased);
      expect(c.state.unlocked, isFalse);
      expect(c.state.notice, PurchaseNotice.failed);
    });

    test('offline: no price, and buying says the store is unreachable',
        () async {
      store.product = null;
      final c = await make();
      expect(c.state.product, isNull);
      await c.buy();
      expect(c.state.notice, PurchaseNotice.storeUnavailable);
      expect(store.buys, 0);
    });

    test('offline: a cached unlock survives StoreKit being unreachable',
        () async {
      store.ownsThrows = true;
      final c = await make(cached: true);
      expect(c.state.unlocked, isTrue);
    });

    test('launch corrects the cache from StoreKit entitlements', () async {
      store.owned = false; // refunded
      final c = await make(cached: true);
      expect(c.state.unlocked, isFalse);
      expect(settings.unlimitedUnlocked, isFalse);
    });

    test('restore unlocks when the account owns it', () async {
      final c = await make();
      store.owned = true;
      await c.restore();
      expect(c.state.unlocked, isTrue);
      expect(c.state.notice, PurchaseNotice.restored);
    });

    test('restore with nothing to restore says so', () async {
      final c = await make();
      await c.restore();
      expect(c.state.unlocked, isFalse);
      expect(c.state.notice, PurchaseNotice.nothingToRestore);
      expect(c.state.activity, PurchaseActivity.idle);
    });
  });
}

class _FakeStore implements StoreGateway {
  final _updates = StreamController<List<PurchaseDetails>>.broadcast();

  ProductDetails? product = ProductDetails(
    id: kUnlimitedProductId,
    title: 'Elapsa Unlimited',
    description: '',
    price: r'$9.99',
    rawPrice: 9.99,
    currencyCode: 'USD',
  );
  bool owned = false;
  bool ownsThrows = false;
  int buys = 0;
  int completed = 0;

  Future<void> emit(PurchaseStatus status) async {
    final details = PurchaseDetails(
      purchaseID: '1',
      productID: kUnlimitedProductId,
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: '',
        source: 'test',
      ),
      transactionDate: null,
      status: status,
    )..pendingCompletePurchase = status != PurchaseStatus.pending;
    _updates.add([details]);
    // Let the controller's async handler run to completion.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseUpdates => _updates.stream;

  @override
  Future<ProductDetails?> loadProduct(String id) async => product;

  @override
  Future<void> buy(ProductDetails product) async => buys++;

  @override
  Future<void> complete(PurchaseDetails purchase) async => completed++;

  @override
  Future<bool?> ownsProduct(String id) async {
    if (ownsThrows) throw Exception('offline');
    return owned;
  }

  @override
  Future<bool?> restore(String id) => ownsProduct(id);
}
