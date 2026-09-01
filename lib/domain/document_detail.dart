import 'package:elapsa/domain/document_type.dart';

/// An extra field that only some kinds of document have.
///
/// A bank card has a security code and a cardholder name; a vehicle
/// registration has a plate and a VIN; a passport has a nationality. Showing
/// every one of those on every document would bury the few that matter, so
/// each type declares its own.
enum DocumentDetail {
  cardholderName,
  securityCode,
  nationality,
  placeOfIssue,
  issuingAuthority,
  licenceClass,
  policyNumber,
  plateNumber,
  vehicleIdentification,
  membershipLevel;

  /// Whether the value should be hidden on screen until the user asks for it.
  ///
  /// A security code is the one field here that is worth something to someone
  /// reading over a shoulder — the card number alone cannot be used online
  /// without it. It stays masked by default and never appears on a card face.
  bool get isSensitive => this == DocumentDetail.securityCode;

  /// Short values that should not wrap or be spell-checked.
  bool get isShort => switch (this) {
    DocumentDetail.securityCode ||
    DocumentDetail.licenceClass ||
    DocumentDetail.nationality => true,
    _ => false,
  };
}

extension DocumentTypeDetails on DocumentType {
  /// The extra fields worth keeping for this kind of document, in the order
  /// they should be shown.
  List<DocumentDetail> get details => switch (this) {
    DocumentType.bankCard => const [
      DocumentDetail.cardholderName,
      DocumentDetail.securityCode,
    ],
    DocumentType.passport => const [
      DocumentDetail.nationality,
      DocumentDetail.placeOfIssue,
    ],
    DocumentType.nationalId => const [DocumentDetail.issuingAuthority],
    DocumentType.driversLicence => const [
      DocumentDetail.licenceClass,
      DocumentDetail.issuingAuthority,
    ],
    DocumentType.visa => const [
      DocumentDetail.nationality,
      DocumentDetail.placeOfIssue,
    ],
    DocumentType.residencePermit => const [DocumentDetail.issuingAuthority],
    DocumentType.vehicleRegistration => const [
      DocumentDetail.plateNumber,
      DocumentDetail.vehicleIdentification,
    ],
    DocumentType.insurance => const [DocumentDetail.policyNumber],
    DocumentType.professionalLicence => const [DocumentDetail.issuingAuthority],
    DocumentType.membership => const [DocumentDetail.membershipLevel],
    DocumentType.other => const [],
  };
}
