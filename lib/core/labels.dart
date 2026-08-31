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
