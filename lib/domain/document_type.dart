import 'package:flutter/material.dart';

/// The kinds of document Elapsa tracks.
///
/// Each type carries a *renewal lead time* — how long the renewal process
/// actually takes — which is separate from the expiry date itself. This is the
/// distinction the app is built around: telling someone their passport expires
/// in three weeks is useless if renewing it takes eight. We warn when it is
/// time to *start*, not when it is time to panic.
enum DocumentType {
  passport,
  nationalId,
  driversLicence,
  visa,
  residencePermit,
  vehicleRegistration,
  insurance,
  professionalLicence,
  membership,
  bankCard,
  other;

  /// Days before expiry at which renewal should realistically begin.
  ///
  /// These are deliberately conservative. Processing times vary by country and
  /// by season, and a user who starts early loses nothing, while a user who
  /// starts late may be unable to travel.
  int get defaultRenewalLeadDays => switch (this) {
    // Nine months. Renewal itself takes 6-10 weeks in most countries, but
    // the binding constraint is the six-month rule below: the passport
    // becomes useless for travel long before it expires.
    DocumentType.passport => 270,
    // Residence permits and long-stay visas involve appointments,
    // biometrics and third-party processing. They are the slowest.
    DocumentType.residencePermit => 120,
    DocumentType.visa => 90,
    DocumentType.professionalLicence => 90,
    DocumentType.driversLicence => 60,
    DocumentType.nationalId => 60,
    DocumentType.vehicleRegistration => 45,
    DocumentType.insurance => 30,
    DocumentType.membership => 30,
    DocumentType.bankCard => 30,
    DocumentType.other => 30,
  };

  /// Whether most destinations require this document to stay valid for six
  /// months beyond the date of entry.
  ///
  /// A passport that expires in five months cannot be used to enter much of
  /// Asia, the Middle East and Latin America, so its *effective* expiry is six
  /// months earlier than the date printed on it. Elapsa surfaces that gap.
  bool get hasSixMonthTravelRule => this == DocumentType.passport;

  /// Whether this document type carries a machine-readable zone we can scan.
  bool get hasMachineReadableZone => switch (this) {
    DocumentType.passport ||
    DocumentType.nationalId ||
    DocumentType.residencePermit ||
    DocumentType.visa => true,
    _ => false,
  };

  /// The mark that stands for this kind of document.
  ///
  /// Rounded throughout, and chosen for what the thing *is* rather than for
  /// the nearest available noun: a passport is somewhere you go, not a globe;
  /// a vehicle registration is a car's papers, not a shopping receipt.
  IconData get icon => switch (this) {
    DocumentType.passport => Icons.auto_stories_rounded,
    DocumentType.nationalId => Icons.badge_rounded,
    DocumentType.driversLicence => Icons.directions_car_rounded,
    DocumentType.visa => Icons.approval_rounded,
    DocumentType.residencePermit => Icons.house_rounded,
    DocumentType.vehicleRegistration => Icons.article_rounded,
    DocumentType.insurance => Icons.verified_user_rounded,
    DocumentType.professionalLicence => Icons.workspace_premium_rounded,
    DocumentType.membership => Icons.card_membership_rounded,
    DocumentType.bankCard => Icons.credit_card_rounded,
    DocumentType.other => Icons.folder_rounded,
  };
}
