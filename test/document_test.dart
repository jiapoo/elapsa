import 'package:flutter_test/flutter_test.dart';
import 'package:elapsa/domain/document.dart';
import 'package:elapsa/domain/document_type.dart';

final _now = DateTime(2026, 6, 1);

TrackedDocument doc({
  DocumentType type = DocumentType.passport,
  required DateTime expiry,
  int? leadDays,
  List<int>? offsets,
}) {
  return TrackedDocument(
    id: 'test',
    type: type,
    label: 'Test',
    expiryDate: expiry,
    renewalLeadDays: leadDays ?? type.defaultRenewalLeadDays,
    reminderOffsets: offsets,
    createdAt: _now,
    updatedAt: _now,
  );
}

void main() {
  group('daysRemaining', () {
    test('counts whole calendar days', () {
      expect(doc(expiry: DateTime(2026, 6, 11)).daysRemaining(now: _now), 10);
    });

    test('is zero on the expiry date itself', () {
      expect(doc(expiry: DateTime(2026, 6, 1)).daysRemaining(now: _now), 0);
    });

    test('goes negative once past', () {
      expect(doc(expiry: DateTime(2026, 5, 25)).daysRemaining(now: _now), -7);
    });

    test('ignores the time of day', () {
      // A document expiring tomorrow reads "1 day" all day today, rather than
      // flipping to 0 partway through the afternoon.
      final afternoon = DateTime(2026, 6, 1, 16, 30);
      expect(
        doc(expiry: DateTime(2026, 6, 2)).daysRemaining(now: afternoon),
        1,
      );
    });
  });

  group('status', () {
    test('expired once the date has passed', () {
      expect(
        doc(expiry: DateTime(2026, 5, 1)).status(now: _now),
        DocumentStatus.expired,
      );
    });

    test('critical inside 30 days', () {
      expect(
        doc(expiry: DateTime(2026, 6, 20)).status(now: _now),
        DocumentStatus.critical,
      );
    });

    test('action needed inside the renewal lead time', () {
      // A passport 100 days out is fine on paper but renewal takes months.
      expect(
        doc(expiry: DateTime(2026, 9, 9)).status(now: _now),
        DocumentStatus.actionNeeded,
      );
    });

    test('valid beyond the renewal lead time', () {
      expect(
        doc(expiry: DateTime(2030, 1, 1)).status(now: _now),
        DocumentStatus.valid,
      );
    });

    test('lead time is what separates action needed from valid', () {
      // The same date, on two document types with different processing times.
      final expiry = DateTime(2026, 10, 1); // 122 days out
      expect(
        doc(type: DocumentType.passport, expiry: expiry).status(now: _now),
        DocumentStatus.actionNeeded,
        reason: 'passports take months to renew',
      );
      expect(
        doc(type: DocumentType.insurance, expiry: expiry).status(now: _now),
        DocumentStatus.valid,
        reason: 'insurance renews in a day',
      );
    });
  });

  group('six-month travel rule', () {
    test('passport is travel-restricted before it expires', () {
      // Expires in 100 days: still valid, but no longer accepted for entry by
      // countries enforcing the six-month rule.
      final p = doc(expiry: DateTime(2026, 9, 9));
      expect(p.daysRemaining(now: _now), greaterThan(0));
      expect(p.isTravelRestricted(now: _now), isTrue);
    });

    test('passport well inside validity is not restricted', () {
      expect(
        doc(expiry: DateTime(2028, 1, 1)).isTravelRestricted(now: _now),
        isFalse,
      );
    });

    test('an expired passport is not reported as merely restricted', () {
      expect(
        doc(expiry: DateTime(2026, 1, 1)).isTravelRestricted(now: _now),
        isFalse,
      );
    });

    test('the rule does not apply to other document types', () {
      final licence = doc(
        type: DocumentType.driversLicence,
        expiry: DateTime(2026, 9, 9),
      );
      expect(licence.travelValidUntil, isNull);
      expect(licence.isTravelRestricted(now: _now), isFalse);
    });
  });

  group('reminders', () {
    test('always include the renewal lead time', () {
      final p = doc(type: DocumentType.passport, expiry: DateTime(2030, 1, 1));
      expect(p.reminderOffsetDays.first, DocumentType.passport.defaultRenewalLeadDays);
    });

    test('never schedule beyond the lead time', () {
      final ins = doc(type: DocumentType.insurance, expiry: DateTime(2030, 1, 1));
      expect(ins.reminderOffsetDays, [30, 7, 1]);
    });

    test('are ordered longest-first', () {
      final offsets = doc(expiry: DateTime(2030, 1, 1)).reminderOffsetDays;
      expect(offsets, orderedEquals([...offsets]..sort((a, b) => b.compareTo(a))));
    });

    test('drop dates already in the past', () {
      // Expires in 10 days, so the 270 and 90 day reminders are long gone —
      // and every remaining day is one of them, because the last month is
      // reminded on daily whatever was chosen.
      final p = doc(expiry: DateTime(2026, 6, 11));
      final dates = p.reminderDates(now: _now);
      expect(dates, everyElement(predicate<DateTime>((d) => d.isAfter(_now))));
      expect(dates.length, 10);
      expect(dates.first, DateTime(2026, 6, 2));
      expect(dates.last, DateTime(2026, 6, 11));
    });

    test('the final month is reminded on every day, whatever was chosen', () {
      // Not a preference. A single reminder on day thirty that arrives during
      // a meeting is a reminder that never happened, and the last month is
      // when that stops being advice and starts being urgent.
      final p = doc(expiry: DateTime(2027, 1, 1), offsets: const [365]);
      final dates = p.reminderDates(now: DateTime(2026, 12, 20));

      // The 20th through to the 1st, inclusive of the day itself.
      expect(dates.length, 12);
      expect(dates.last, DateTime(2027, 1, 1));
      for (var i = 1; i < dates.length; i++) {
        expect(dates[i].difference(dates[i - 1]).inDays, 1);
      }
    });

    test('a chosen reminder inside the last month is not doubled', () {
      final p = doc(expiry: DateTime(2026, 6, 20), offsets: const [7, 3]);
      final dates = p.reminderDates(now: _now);
      expect(dates.toSet().length, dates.length);
    });

    test('produce no dates for an already-expired document', () {
      expect(doc(expiry: DateTime(2026, 1, 1)).reminderDates(now: _now), isEmpty);
    });
  });

  group('a document that never expires', () {
    TrackedDocument endless() => TrackedDocument(
      id: 'id-card',
      type: DocumentType.nationalId,
      label: '居民身份证',
      // Whatever date it happens to carry is not read while the flag is set.
      expiryDate: DateTime(2020, 1, 1),
      renewalLeadDays: 90,
      neverExpires: true,
      createdAt: _now,
      updatedAt: _now,
    );

    test('is never urgent, however old the date it carries', () {
      // Without the flag this is five years expired.
      expect(endless().status(now: _now), DocumentStatus.valid);
    });

    test('is never reminded about', () {
      // A reminder is a number of days before a date, and there is no date.
      expect(endless().reminderDates(now: _now), isEmpty);
    });

    test('never triggers the travel rule', () {
      expect(endless().isTravelRestricted(now: _now), isFalse);
    });

    test('the flag survives a copyWith', () {
      expect(endless().copyWith(label: 'x').neverExpires, isTrue);
    });
  });
}
