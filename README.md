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

## Not built yet

- Camera capture + on-device OCR feeding the MRZ parser (parser is done)
- NFC passport chip reading (`flutter_nfc_kit` + `dmrtd`)
- SQLCipher — the database is currently unencrypted; swapping
  `sqlite3_flutter_libs` for `sqlcipher_flutter_libs` encrypts it with no
  schema change
- Biometric lock, document photos, localisation, family accounts
