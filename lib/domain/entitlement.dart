/// What the free version allows, and whether a change fits inside it.
///
/// Kept apart from StoreKit and from any widget so the one rule that decides
/// whether someone sees a paywall can be tested on its own.
library;

/// The product that lifts the limit. A single non-consumable, bought once.
///
/// Must match the product created in App Store Connect and the one in
/// `ios/Runner/Elapsa.storekit` exactly.
const kUnlimitedProductId = 'com.ljworkshop.elapsa.unlimited';

/// How many documents the free version keeps.
///
/// Three is a passport, an ID card and one more — enough to find out whether
/// the reminders are worth paying for, not enough for a family.
const kFreeDocumentLimit = 3;

/// Whether adding [adding] new documents to a wallet of [existing] is allowed.
///
/// Editing a document never adds one, so editing is always allowed — even for
/// someone over the limit, which can happen after a refund. Their documents
/// stay theirs; only growth is gated.
bool canAddDocuments({
  required int existing,
  required bool unlocked,
  int adding = 1,
}) {
  if (unlocked || adding <= 0) return true;
  return existing + adding <= kFreeDocumentLimit;
}

/// How many documents a wallet will hold after an import.
///
/// Imports keep identity — importing the same archive twice updates records
/// rather than doubling them — so an incoming document that is already here
/// does not count again. [replace] clears the wallet first.
int countAfterImport({
  required Set<String> existingIds,
  required Iterable<String> incomingIds,
  bool replace = false,
}) {
  final incoming = incomingIds.toSet();
  if (replace) return incoming.length;
  return existingIds.union(incoming).length;
}

/// Whether an import fits in the free version.
bool canImport({
  required Set<String> existingIds,
  required Iterable<String> incomingIds,
  required bool unlocked,
  bool replace = false,
}) {
  if (unlocked) return true;
  final after = countAfterImport(
    existingIds: existingIds,
    incomingIds: incomingIds,
    replace: replace,
  );
  // An import that does not grow the wallet is always allowed, even above
  // the limit: it only refreshes what is already here.
  final before = replace ? 0 : existingIds.length;
  return after <= kFreeDocumentLimit || after <= before;
}
