import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elapsa/data/purchase_controller.dart';
import 'package:elapsa/domain/entitlement.dart';
import 'package:elapsa/l10n/app_localizations.dart';

/// Shows the paywall. Completes with true once unlimited is unlocked, false
/// if the sheet was dismissed without it.
Future<bool> showPaywall(BuildContext context) async {
  final unlocked = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const PaywallSheet(),
  );
  return unlocked ?? false;
}

/// Lets a change through if it fits in the free version, and otherwise asks
/// for the unlock first.
///
/// [fits] answers for a given entitlement, so the caller's own rule — one
/// more document, or an import of several — decides, not this function.
Future<bool> ensureRoom(
  BuildContext context,
  WidgetRef ref,
  bool Function(bool unlocked) fits,
) async {
  if (fits(ref.read(unlockedProvider))) return true;
  if (!context.mounted) return false;
  final unlocked = await showPaywall(context);
  return unlocked && fits(true);
}

class PaywallSheet extends ConsumerStatefulWidget {
  const PaywallSheet({super.key});

  @override
  ConsumerState<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends ConsumerState<PaywallSheet> {
  @override
  void initState() {
    super.initState();
    // The price may not have loaded at launch — no network then, perhaps.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(purchaseProvider.notifier)..clearNotice();
      controller.loadProduct();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(purchaseProvider);

    ref.listen(purchaseProvider, (previous, next) {
      if (next.unlocked && !(previous?.unlocked ?? false)) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        Navigator.of(context).pop(true);
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              next.notice == PurchaseNotice.restored
                  ? l.paywallRestored
                  : l.paywallThanks,
            ),
          ),
        );
      }
    });

    final message = switch (state.notice) {
      PurchaseNotice.failed => l.paywallFailed,
      PurchaseNotice.nothingToRestore => l.paywallNothingToRestore,
      PurchaseNotice.storeUnavailable => l.paywallStoreUnavailable,
      _ => state.pending ? l.paywallPending : null,
    };

    final product = state.product;
    final loadingPrice =
        product == null && state.activity == PurchaseActivity.loadingProduct;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.all_inclusive_rounded,
                size: 30, color: scheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            l.paywallTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            l.paywallBody(kFreeDocumentLimit),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant, height: 1.45),
          ),
          const SizedBox(height: 20),
          _Point(icon: Icons.folder_copy_rounded, text: l.paywallPointUnlimited),
          _Point(icon: Icons.verified_rounded, text: l.paywallPointOnce),
          _Point(icon: Icons.lock_rounded, text: l.paywallPointPrivate),
          const SizedBox(height: 20),
          if (message != null) ...[
            Text(
              message,
              key: const Key('paywall-message'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: state.pending && state.notice == null
                    ? scheme.onSurfaceVariant
                    : scheme.error,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('paywall-buy'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: state.busy || loadingPrice
                  ? null
                  : product == null
                  ? () => ref.read(purchaseProvider.notifier).loadProduct()
                  : () => ref.read(purchaseProvider.notifier).buy(),
              child: state.activity == PurchaseActivity.buying
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : Text(
                      product != null
                          // Formatted by the store, in the storefront's own
                          // currency. Never typed into the app.
                          ? l.paywallBuy(product.price)
                          : loadingPrice
                          ? l.paywallLoadingPrice
                          : l.paywallRetry,
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            key: const Key('paywall-restore'),
            onPressed: state.busy
                ? null
                : () => ref.read(purchaseProvider.notifier).restore(),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
            child: state.activity == PurchaseActivity.restoring
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.paywallRestore),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              foregroundColor: scheme.onSurfaceVariant,
            ),
            child: Text(l.paywallNotNow),
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
