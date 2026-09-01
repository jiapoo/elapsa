import 'package:elapsa/data/settings_repository.dart';
import 'package:elapsa/domain/document.dart';
import 'package:elapsa/domain/document_detail.dart';
import 'package:elapsa/domain/document_type.dart';
import 'package:elapsa/l10n/app_localizations.dart';

/// Localised names for the domain enums.
///
/// These live outside the enums themselves so the domain layer stays free of
/// anything Flutter, and so the notification service — which has no
/// BuildContext — can look strings up from a locale it loads directly.
extension DocumentTypeLabel on DocumentType {
  String label(L l) => switch (this) {
    DocumentType.passport => l.typePassport,
    DocumentType.nationalId => l.typeNationalId,
    DocumentType.driversLicence => l.typeDriversLicence,
    DocumentType.visa => l.typeVisa,
    DocumentType.residencePermit => l.typeResidencePermit,
    DocumentType.vehicleRegistration => l.typeVehicleRegistration,
    DocumentType.insurance => l.typeInsurance,
    DocumentType.professionalLicence => l.typeProfessionalLicence,
    DocumentType.membership => l.typeMembership,
    DocumentType.bankCard => l.typeBankCard,
    DocumentType.other => l.typeOther,
  };
}

extension DocumentSortLabel on DocumentSort {
  String label(L l) => switch (this) {
    DocumentSort.expiry => l.sortExpiry,
    DocumentSort.added => l.sortAdded,
    DocumentSort.name => l.sortName,
    DocumentSort.type => l.sortType,
  };
}

extension DocumentTypeName on TrackedDocument {
  /// What this document is called a kind of.
  ///
  /// The user's own name for it when they gave it one, and the built-in name
  /// otherwise — so a wallet sorted by type files "Gym pass" under Gym pass
  /// rather than burying it in Other with everything else nobody had a word
  /// for.
  String typeLabel(L l) => customType ?? type.label(l);
}

extension WalletDisplayLabel on WalletDisplay {
  String label(L l) => switch (this) {
    WalletDisplay.nameOnly => l.displayNameOnly,
    WalletDisplay.imageOnly => l.displayImageOnly,
    WalletDisplay.nameAndImage => l.displayNameAndImage,
  };

  String description(L l) => switch (this) {
    WalletDisplay.nameOnly => l.displayNameOnlyBody,
    WalletDisplay.imageOnly => l.displayImageOnlyBody,
    WalletDisplay.nameAndImage => l.displayNameAndImageBody,
  };
}

extension AppThemeLabel on AppTheme {
  String label(L l) => switch (this) {
    AppTheme.system => l.themeSystem,
    AppTheme.light => l.themeLight,
    AppTheme.dark => l.themeDark,
  };
}

extension DocumentDetailLabel on DocumentDetail {
  String label(L l) => switch (this) {
    DocumentDetail.cardholderName => l.detailCardholderName,
    DocumentDetail.securityCode => l.detailSecurityCode,
    DocumentDetail.nationality => l.detailNationality,
    DocumentDetail.placeOfIssue => l.detailPlaceOfIssue,
    DocumentDetail.issuingAuthority => l.detailIssuingAuthority,
    DocumentDetail.licenceClass => l.detailLicenceClass,
    DocumentDetail.policyNumber => l.detailPolicyNumber,
    DocumentDetail.plateNumber => l.detailPlateNumber,
    DocumentDetail.vehicleIdentification => l.detailVehicleIdentification,
    DocumentDetail.membershipLevel => l.detailMembershipLevel,
  };
}

extension DocumentStatusLabel on DocumentStatus {
  String label(L l) => switch (this) {
    DocumentStatus.expired => l.statusExpired,
    DocumentStatus.critical => l.statusExpiring,
    DocumentStatus.actionNeeded => l.statusRenewNow,
    DocumentStatus.valid => l.statusValid,
  };
}

/// Human phrasing for a lead time expressed in days.
///
/// Used everywhere a lead time is shown — chips, explanations, notification
/// copy — so the app never says "9 months" in one place and "39 weeks" in
/// another.
String leadTimeLabel(L l, int days) {
  if (days < 28) return l.leadWeeks((days / 7).round().clamp(1, 3));
  if (days >= 365) return l.leadYears(days ~/ 365);
  final months = (days / 30).round();
  return l.leadMonths(months < 1 ? 1 : months);
}

/// A span written the way people plan in: "2 years 34 days".
///
/// Days alone stop meaning anything past a few hundred of them. Nobody reads
/// "3,412 days left" as three trips round the sun; they read it as a large
/// number and move on, which is the opposite of what a countdown is for.
///
/// Whole calendar years, not 365-day blocks. A ten-year passport should say
/// ten years on the day it is issued, and dividing by 365 makes that nine
/// years and three hundred and sixty-odd days — arithmetically defensible and
/// obviously wrong to anyone holding the passport.
String durationLabel(DateTime from, DateTime to, L l) {
  final start = DateTime(from.year, from.month, from.day);
  final end = DateTime(to.year, to.month, to.day);
  if (!end.isAfter(start)) return l.countDays(0);

  var years = end.year - start.year;
  var anniversary = DateTime(start.year + years, start.month, start.day);
  if (anniversary.isAfter(end)) {
    years -= 1;
    anniversary = DateTime(start.year + years, start.month, start.day);
  }

  final days = end.difference(anniversary).inDays;
  if (years <= 0) return l.countDays(days);
  if (days == 0) return l.countYears(years);
  return '${l.countYears(years)} ${l.countDays(days)}';
}

/// The same span with the words taken out: "3y20d".
///
/// For the picture-only wallet, where a card carries its countdown in a pill
/// the width of a fingernail and there is no room to write it out. Days alone
/// were no use there either — "1204" on the corner of a passport says nothing
/// anybody can act on.
String compactDuration(DateTime from, DateTime to, L l) {
  final start = DateTime(from.year, from.month, from.day);
  final end = DateTime(to.year, to.month, to.day);
  if (!end.isAfter(start)) return l.shortDays(0);

  var years = end.year - start.year;
  var anniversary = DateTime(start.year + years, start.month, start.day);
  if (anniversary.isAfter(end)) {
    years -= 1;
    anniversary = DateTime(start.year + years, start.month, start.day);
  }

  final days = end.difference(anniversary).inDays;
  if (years <= 0) return l.shortDays(days);
  if (days == 0) return l.shortYears(years);
  return '${l.shortYears(years)}${l.shortDays(days)}';
}
