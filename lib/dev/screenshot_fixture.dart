import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elapsa/data/document_repository.dart';
import 'package:elapsa/domain/document_detail.dart';
import 'package:elapsa/domain/document_type.dart';

/// A wallet worth photographing, for App Store screenshots.
///
/// Compiled in only under `--dart-define=DEMO=true`; the constant is false in
/// every ordinary build, so this and everything it reaches is dropped.
///
/// Invented documents, deliberately. Apple's guidance is against showing real
/// identity documents in screenshots, and nobody should have to hand their own
/// passport to a marketing asset. The card numbers are the published test
/// numbers the schemes provide for exactly this: valid to look at, belonging
/// to nobody.
const bool kDemoMode = bool.fromEnvironment('DEMO');

Future<void> seedForScreenshots(ProviderContainer container) async {
  final repo = container.read(documentRepositoryProvider);
  if ((await repo.getAll()).isNotEmpty) return;

  // Names follow the phone's language, so a Chinese screenshot or preview
  // shows a Chinese wallet. Printed fields (numbers, MRZ nationality,
  // cardholder names on cards) stay as they're printed.
  final zh = PlatformDispatcher.instance.locale.languageCode == 'zh';
  String name(String en, String chinese) => zh ? chinese : en;
  final holder = name('Chen Wei', '陈伟');

  final now = DateTime.now();
  DateTime inDays(int days) => DateTime(now.year, now.month, now.day + days);

  // Spread across the statuses on purpose. The wallet is only worth looking at
  // when it is doing what it is for: one thing overdue, one that wants
  // starting on, and a shelf of things that are fine.
  await repo.create(
    type: DocumentType.passport,
    label: name('Passport', '护照'),
    holder: holder,
    documentNumber: 'EM1234567',
    issuingCountry: 'CHN',
    issueDate: inDays(-2430),
    expiryDate: inDays(96),
    details: const {DocumentDetail.nationality: 'CHINESE'},
  );

  await repo.create(
    type: DocumentType.visa,
    label: name('US B1/B2 visa', '美国 B1/B2 签证'),
    holder: holder,
    documentNumber: 'K1234567',
    issuingCountry: 'USA',
    expiryDate: inDays(23),
  );

  await repo.create(
    type: DocumentType.driversLicence,
    label: name("Driver's licence", '驾照'),
    holder: holder,
    documentNumber: 'S9876543',
    expiryDate: inDays(-12),
  );

  await repo.create(
    type: DocumentType.residencePermit,
    label: name('Residence permit', '居留许可'),
    holder: holder,
    expiryDate: inDays(412),
  );

  await repo.create(
    type: DocumentType.bankCard,
    label: name('China Merchants Bank', '招商银行'),
    holder: 'CHEN WEI',
    documentNumber: '4111 1111 1111 1111',
    issueDate: DateTime(now.year - 2, 10),
    expiryDate: DateTime(now.year + 3, 8, 31),
    details: const {DocumentDetail.cardholderName: 'CHEN WEI'},
  );

  await repo.create(
    type: DocumentType.bankCard,
    label: name('China Construction Bank', '建设银行'),
    holder: 'CHEN WEI',
    documentNumber: '5555 5555 5555 4444',
    expiryDate: DateTime(now.year + 1, 6, 30),
  );

  await repo.create(
    type: DocumentType.insurance,
    label: name('Travel insurance', '旅行保险'),
    expiryDate: inDays(268),
  );
}
