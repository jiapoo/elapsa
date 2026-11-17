# In-app purchase: Elapsa Unlimited

One non-consumable product. Free version keeps 3 documents; the unlock lifts
the limit for good. No subscription, no server.

| | |
|---|---|
| Product ID | `com.ljworkshop.elapsa.unlimited` |
| Type | Non-Consumable |
| Free limit | 3 documents (`kFreeDocumentLimit` in `lib/domain/entitlement.dart`) |
| Price | Set in App Store Connect only. The app shows `ProductDetails.price`, formatted by StoreKit for the user's storefront. Never typed into the code. |

## How it works

- **Where the limit applies:** saving a *new* document (`edit_document_screen.dart`),
  importing a file (`transfer_section.dart`) and receiving from a nearby phone
  (`nearby_screen.dart`). Editing is never blocked. Re-importing documents that are
  already on the phone does not count again.
- **Paywall:** `lib/ui/paywall/paywall_sheet.dart`. It is a bottom sheet over the form, so
  "Not now" loses nothing the user typed. Restore Purchase is on the paywall and in
  Settings → Elapsa Unlimited.
- **Store:** `in_app_purchase` with StoreKit 2 (the plugin's default on iOS 15+).
  `lib/services/store_gateway.dart` is the only file that talks to it.
- **Verification, on the device only:** StoreKit 2 checks Apple's signature on each
  transaction itself. After any "purchased" or "restored" event, the app also checks
  `Transaction.currentEntitlements`, which only ever holds verified transactions, and
  refuses the unlock if the product is missing. No receipt leaves the phone.
- **Persistence:** the last known answer is cached in SharedPreferences
  (`unlimited_unlocked`), so the app starts unlocked offline with no wait. On every
  launch it is corrected against `currentEntitlements`. That check works offline, and
  it also removes the unlock after a refund.
- **Outcomes handled:** purchased, restored, pending (Ask to Buy: the unlock arrives
  later, even across launches), cancelled (nothing shown), failed, store unreachable
  or offline (the price button becomes "Try again"), nothing to restore.

## Testing in the simulator (StoreKit configuration)

`ios/Runner/Elapsa.storekit` defines the product locally ($9.99, en / zh-Hans / zh-Hant
names). The shared `Runner` scheme points at it (Edit Scheme → Run → Options →
StoreKit Configuration).

1. Open `ios/Runner.xcworkspace` in Xcode, choose a simulator, and press **Run**.
   `flutter run` does **not** use the StoreKit configuration. It has to be launched
   from Xcode.
   - The shared scheme's Run action uses the **Profile** configuration, which Flutter
     does not support on simulators. For simulator testing, switch it to Debug in
     Edit Scheme → Run → Build Configuration, and don't commit that change.
2. Add three documents, then try to save a fourth. The paywall should show "Unlock for
   $9.99".
3. Buy. StoreKit's own sheet appears; confirm it. The sheet closes, a thank-you
   snackbar shows, and the fourth document saves when you press Save again.
4. In Xcode: **Debug → StoreKit → Manage Transactions**. Here you can:
   - delete the transaction, relaunch the app, and check it is locked again;
   - refund it, relaunch, and check it is locked again;
   - turn on **Ask to Buy** (Editor → Enable Ask to Buy in the .storekit editor), buy,
     check the "Waiting for approval" message, then approve in Manage Transactions.
5. To test failures, open `Elapsa.storekit` → Editor → **Fail Transactions**, or use the
   StoreKit errors list in the file's settings.
6. To test offline, set Load Products to fail in the .storekit settings. The button
   should read "Try again" and the message should say the store can't be reached.

## Sandbox testing on a real iPhone

Needs the App Store Connect setup below to be done first. The product has to exist
there with the same ID, though it does not have to be approved yet.

1. App Store Connect → **Users and Access → Sandbox → Test Accounts** → add a tester.
   Use an email address that is not an existing Apple Account.
2. On the iPhone: **Settings → Developer → Sandbox Apple Account**, and sign in with
   the tester. Developer mode must be on. Do not sign out of your real account.
3. Install a build that does **not** use the local .storekit file. Either:
   - In Xcode, Edit Scheme → Run → Options → StoreKit Configuration: **None**, then
     Run on the device; or
   - upload to TestFlight and install from there. TestFlight always uses the sandbox,
     and purchases there are free.
4. Repeat steps 2–3 of the simulator test. The purchase sheet should say
   "[Environment: Sandbox]".
5. Delete the app, reinstall, and tap **Restore Purchase** in Settings. It should unlock
   without paying again.
6. To test on a fresh state, clear the tester's purchase history in App Store Connect
   (Sandbox → Test Accounts → the tester → Clear Purchase History).

## What you must do in App Store Connect

1. **Agreements, Tax, and Banking:** sign the **Paid Apps** agreement, then fill in the
   bank account and tax forms (W-8BEN or W-9, depending on where the studio is based).
   Until the agreement shows *Active*, StoreKit returns no products and the paywall
   only ever shows "Try again".
2. **App → Monetization → In-App Purchases → +:** type **Non-Consumable**, reference
   name "Unlimited documents", product ID `com.ljworkshop.elapsa.unlimited`. It must
   match exactly, and an ID can never be reused once created.
3. Set the **price**. Pick a tier and let Apple fill in the other storefronts.
4. Add a **localization** for each language you ship. The display name and description
   appear on Apple's purchase sheet. The .storekit file has suggested text.
5. **Review information:** a screenshot of the paywall (640×920 or larger), plus a
   review note, e.g. "Add three documents, then save a fourth to see the purchase.
   Restore is in Settings."
6. **Family Sharing:** decide before submitting. Once it is turned on it cannot be
   turned off. The local .storekit file has it off.
7. On the **1.0 version page**, under *In-App Purchases and Subscriptions*, select the
   product so it is **submitted together with the app**. A first IAP can only be
   reviewed alongside an app version.
8. The privacy label stays **Data Not Collected**. Purchases go through Apple and
   the app sends nothing anywhere.
