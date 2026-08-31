# Elapsa

Never miss a renewal. Tracks passports, IDs, visas and licences — privately, on
the device.

The premise that separates Elapsa from every other expiry tracker: **telling
someone their passport expires in three weeks is useless if renewing it takes
eight.** Elapsa warns when it is time to *start*, not when it is time to panic.

- `cc.elapsa` · Flutter (iOS + Android) · 100% on-device, no account, no upload

## Running it

```bash
flutter run
```

```bash
flutter test
```

Drift generates `lib/data/database.g.dart`. After changing the schema:

```bash
dart run build_runner build
```

## Layout

```
lib/
  domain/       Pure Dart. No Flutter imports except icons. Fully unit-tested.
    mrz.dart            ICAO 9303 parser — TD1/TD2/TD3, check digits, OCR repair
    document.dart       Status, six-month travel rule, reminder scheduling
    document_type.dart  Per-type renewal lead times
  data/         Drift database + repository
  services/     Notification scheduling
  ui/           Home list, add/edit form
  core/         Theme, shared formatting
```

### Why the MRZ parser matters

The machine-readable zone at the bottom of a passport carries a check digit on
every field. A parse that validates is near-certain to be correct, so scanning
the MRZ gives an *answer* where OCR of the printed face gives a *guess*. The
parser also repairs the `0`/`O`, `1`/`I`, `5`/`S`, `8`/`B` confusions OCR makes,
and re-validates — a wrong repair fails the check digits rather than corrupting
data.

It is verified against the published ICAO Doc 9303 specimen documents.

### Two constraints that shaped the design

**iOS caps an app at 64 pending local notifications** and silently drops the
rest. Reminders are therefore never scheduled per-document; every change
rebuilds the whole set, sorted by date, keeping the soonest 56. The schedule is
also rebuilt on app resume and cold start, which additionally recovers the case
where a user declined the permission prompt and later enabled notifications in
Settings.

**Permission must be requested before the first schedule.** iOS discards
notifications requested while unauthorised, so the prompt is shown when the
user saves their first document — late enough to have context, early enough
that the reminders actually register.

Android reminders deliberately use *inexact* alarms. A renewal notice does not
need second accuracy, and requesting `SCHEDULE_EXACT_ALARM` invites a Play
Store policy review for no benefit.

### Why OCR is a platform channel, not a package

ML Kit's iOS SDK ships as legacy fat `.framework` bundles whose arm64 slice is
device-only, which forces `EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64` onto
the whole app and makes it uninstallable on an Apple Silicon simulator. So
text recognition goes over `cc.elapsa/text_recognition` instead: Apple Vision
on iOS, ML Kit via Gradle on Android. Vision is a system framework, costs
nothing in app size, and reads Chinese better than ML Kit's Latin model.

The channel is registered in `didInitializeImplicitFlutterEngine`, not off the
root view controller — this app uses the scene lifecycle, so `window` is nil in
`didFinishLaunchingWithOptions` and registering there silently does nothing.

### Encryption at rest

One AES-256 key in the Keychain / Android Keystore, non-syncing, protects both
the SQLCipher database and the card images (AES-GCM, random nonce per write).
Deleting a document deletes its encrypted image with it.

### Card faces

The scanner shows a card-shaped guide and crops the capture to exactly that
rectangle, so composition is settled at capture time rather than guessed at
render time. A real card image is shown clean, with no overlay — the document
prints its own details, and Elapsa's read on it goes in the status line
underneath. Hand-entered documents get a designed gradient face instead. Elapsa
never synthesises a replica of official document artwork.

## Not built yet

- **Android half of the OCR channel** — the Dart and iOS sides are done
- **Android in general** — no SDK on this machine, nothing built or tested
- **Camera on hardware** — the scanner has only run against the photo library,
  because no simulator has a camera
- NFC passport chip reading (`flutter_nfc_kit` + `dmrtd`)
- Biometric lock, localisation, family accounts
