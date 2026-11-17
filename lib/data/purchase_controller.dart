import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:elapsa/data/settings_repository.dart';
import 'package:elapsa/domain/entitlement.dart';
import 'package:elapsa/services/store_gateway.dart';

/// What the paywall is doing right now.
enum PurchaseActivity { idle, loadingProduct, buying, restoring }

/// Something worth telling the user once, after it happened.
enum PurchaseNotice {
  purchased,
  restored,
  cancelled,
  failed,
  nothingToRestore,
  storeUnavailable,
}

@immutable
class PurchaseState {
  const PurchaseState({
    required this.unlocked,
    this.product,
    this.activity = PurchaseActivity.idle,
    this.pending = false,
    this.notice,
  });

  /// Whether the free-tier limit is lifted.
  final bool unlocked;

  /// The product as the store describes it — the only source of its price.
  /// Null until loaded, and when the store cannot be reached.
  final ProductDetails? product;

  final PurchaseActivity activity;

  /// A purchase waiting on someone else, such as Ask to Buy.
  final bool pending;

  final PurchaseNotice? notice;

  bool get busy =>
      activity == PurchaseActivity.buying ||
      activity == PurchaseActivity.restoring;

  PurchaseState copyWith({
    bool? unlocked,
    ProductDetails? product,
    PurchaseActivity? activity,
    bool? pending,
    PurchaseNotice? notice,
    bool clearNotice = false,
  }) => PurchaseState(
    unlocked: unlocked ?? this.unlocked,
    product: product ?? this.product,
    activity: activity ?? this.activity,
    pending: pending ?? this.pending,
    notice: clearNotice ? null : (notice ?? this.notice),
  );
}

/// Owns the one-time unlock: buying it, restoring it, and remembering it.
class PurchaseController extends StateNotifier<PurchaseState> {
  PurchaseController(this._store, this._settings)
    : super(PurchaseState(unlocked: _settings.unlimitedUnlocked));

  final StoreGateway _store;
  final SettingsRepository _settings;
  StreamSubscription<List<PurchaseDetails>>? _updates;

  /// Called once at launch. Listens before anything else so a purchase that
  /// finished while the app was closed is delivered, not lost.
  Future<void> start() async {
    _updates ??= _store.purchaseUpdates.listen(
      _onUpdates,
      onError: (Object _) => _settle(PurchaseNotice.failed),
    );
    await _checkEntitlement();
    await loadProduct();
  }

  /// Fetches the product and its price. Safe to call again to retry.
  Future<void> loadProduct() async {
    if (state.product != null) return;
    if (state.activity == PurchaseActivity.idle) {
      state = state.copyWith(activity: PurchaseActivity.loadingProduct);
    }
    ProductDetails? product;
    try {
      product = await _store.loadProduct(kUnlimitedProductId);
    } catch (_) {
      product = null;
    }
    if (!mounted) return;
    state = PurchaseState(
      unlocked: state.unlocked,
      product: product ?? state.product,
      activity: state.activity == PurchaseActivity.loadingProduct
          ? PurchaseActivity.idle
          : state.activity,
      pending: state.pending,
      notice: state.notice,
    );
  }

  Future<void> buy() async {
    if (state.unlocked || state.busy) return;
    state = state.copyWith(clearNotice: true);

    if (state.product == null) await loadProduct();
    final product = state.product;
    if (product == null) {
      state = state.copyWith(notice: PurchaseNotice.storeUnavailable);
      return;
    }

    state = state.copyWith(activity: PurchaseActivity.buying);
    try {
      await _store.buy(product);
      // The result comes through [_onUpdates].
    } catch (_) {
      _settle(PurchaseNotice.failed);
    }
  }

  Future<void> restore() async {
    if (state.busy) return;
    state = state.copyWith(
      activity: PurchaseActivity.restoring,
      clearNotice: true,
    );
    try {
      final owned = await _store.restore(kUnlimitedProductId);
      if (owned == true) {
        await _grant(PurchaseNotice.restored);
      } else if (owned == false) {
        _settle(PurchaseNotice.nothingToRestore);
      } else {
        // This platform answers on the update stream. If nothing has come
        // back after a moment, there was nothing to restore.
        Future<void>.delayed(const Duration(seconds: 6), () {
          if (mounted && state.activity == PurchaseActivity.restoring) {
            _settle(PurchaseNotice.nothingToRestore);
          }
        });
      }
    } catch (_) {
      _settle(PurchaseNotice.storeUnavailable);
    }
  }

  void clearNotice() {
    if (state.notice != null) state = state.copyWith(clearNotice: true);
  }

  Future<void> _checkEntitlement() async {
    bool? owned;
    try {
      owned = await _store.ownsProduct(kUnlimitedProductId);
    } catch (_) {
      // StoreKit unreachable in an unexpected way: keep what was cached.
      return;
    }
    if (owned == null || !mounted || owned == state.unlocked) return;
    // StoreKit's entitlements are the record. A refund removes the unlock;
    // a purchase made on another device of the same account adds it.
    state = state.copyWith(unlocked: owned);
    await _settings.setUnlimitedUnlocked(owned);
  }

  Future<void> _onUpdates(List<PurchaseDetails> updates) async {
    for (final update in updates) {
      if (update.productID == kUnlimitedProductId) {
        await _handle(update);
      }
      // Always finish, whatever it was. A transaction left unfinished is
      // delivered again on every launch and blocks buying the same product.
      if (update.pendingCompletePurchase) {
        try {
          await _store.complete(update);
        } catch (_) {}
      }
    }
  }

  Future<void> _handle(PurchaseDetails update) async {
    switch (update.status) {
      case PurchaseStatus.pending:
        if (mounted) {
          state = state.copyWith(
            activity: PurchaseActivity.idle,
            pending: true,
          );
        }
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // The purchase result carries the transaction before StoreKit's
        // signature check; currentEntitlements only ever holds verified ones.
        // Where the platform can answer, that answer decides.
        bool? verified;
        try {
          verified = await _store.ownsProduct(kUnlimitedProductId);
        } catch (_) {
          verified = null;
        }
        if (verified == false) {
          _settle(PurchaseNotice.failed);
          return;
        }
        await _grant(
          update.status == PurchaseStatus.restored
              ? PurchaseNotice.restored
              : PurchaseNotice.purchased,
        );
      case PurchaseStatus.canceled:
        _settle(PurchaseNotice.cancelled);
      case PurchaseStatus.error:
        _settle(PurchaseNotice.failed);
    }
  }

  Future<void> _grant(PurchaseNotice notice) async {
    await _settings.setUnlimitedUnlocked(true);
    if (!mounted) return;
    state = state.copyWith(
      unlocked: true,
      activity: PurchaseActivity.idle,
      pending: false,
      notice: notice,
    );
  }

  void _settle(PurchaseNotice notice) {
    if (!mounted) return;
    state = state.copyWith(
      activity: PurchaseActivity.idle,
      // A cancelled or failed attempt does not end an Ask to Buy that is
      // still waiting; only an outcome for it does.
      notice: notice,
    );
  }

  @override
  void dispose() {
    _updates?.cancel();
    super.dispose();
  }
}

final storeGatewayProvider = Provider<StoreGateway>(
  (ref) => InAppPurchaseGateway(),
);

final purchaseProvider =
    StateNotifierProvider<PurchaseController, PurchaseState>((ref) {
      return PurchaseController(
        ref.watch(storeGatewayProvider),
        ref.watch(settingsRepositoryProvider),
      );
    });

/// Whether the free-tier limit is lifted. The one thing most screens need.
final unlockedProvider = Provider<bool>(
  (ref) => ref.watch(purchaseProvider.select((s) => s.unlocked)),
);
