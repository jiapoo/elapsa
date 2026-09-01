// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Elapsa';

  @override
  String get homeNeedsAttention => 'Needs attention';

  @override
  String get homeEverythingElse => 'Everything else';

  @override
  String get homeEmptyTitle => 'Nothing expiring';

  @override
  String get homeEmptyBody =>
      'Add a passport, ID or licence and Elapsa will tell you when to start renewing it — not when it is already too late.';

  @override
  String get actionAdd => 'Add document';

  @override
  String get actionScan => 'Scan document';

  @override
  String get actionSettings => 'Settings';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionDone => 'Done';

  @override
  String get actionRetake => 'Retake';

  @override
  String get statusExpired => 'Expired';

  @override
  String get statusExpiring => 'Expiring';

  @override
  String get statusRenewNow => 'Renew now';

  @override
  String get statusValid => 'Valid';

  @override
  String daysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get startRenewingNow => 'start renewing now';

  @override
  String get travelRuleBadge => 'Below the 6-month travel rule';

  @override
  String remindersTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders scheduled',
      one: '1 reminder scheduled',
      zero: 'No reminders scheduled',
    );
    return '$_temp0';
  }

  @override
  String get remindersEmptyBody =>
      'Add a document and Elapsa will schedule reminders for it.';

  @override
  String get remindersBody => 'These fire even if the app is never opened.';

  @override
  String get editAddTitle => 'Add document';

  @override
  String get editEditTitle => 'Edit document';

  @override
  String get editScanHelp => 'Reads the code on a passport, ID card or visa';

  @override
  String get editFromScanNote =>
      'Filled in from the document code. Every field is still yours to change.';

  @override
  String get editScanNothingRead =>
      'Picture saved. Nothing readable on this side — fill in the details below.';

  @override
  String get editScanRepaired =>
      'Scanned — the code was a little blurry, so please check the details.';

  @override
  String get fieldType => 'Type';

  @override
  String get fieldName => 'Name';

  @override
  String fieldNameHint(String type) {
    return 'My $type';
  }

  @override
  String get fieldNameRequired => 'Give it a name';

  @override
  String get fieldExpiry => 'Expiry date';

  @override
  String get fieldExpiryEmpty => 'Select a date';

  @override
  String get fieldExpiryRequired => 'Pick an expiry date';

  @override
  String get fieldIssueDate => 'Valid from';

  @override
  String get fieldRemindMe => 'Start reminding me';

  @override
  String get fieldOptional => 'Optional';

  @override
  String get fieldHolderHint => 'Who it belongs to';

  @override
  String get fieldNumberHint => 'Document number';

  @override
  String get fieldNumberLabel => 'Card number';

  @override
  String get imageOptionsTitle => 'Retake or delete this picture?';

  @override
  String get fieldImages => 'Pictures';

  @override
  String get editSave => 'Save';

  @override
  String get editDeleteTitle => 'Delete this document?';

  @override
  String get editDeleteBody =>
      'Its reminders and pictures will be deleted too.';

  @override
  String leadExplainNoDate(String lead) {
    return 'Elapsa will remind you $lead before it expires, then again as the date approaches.';
  }

  @override
  String leadExplainFirst(String date) {
    return 'First reminder on $date, then again as the date approaches.';
  }

  @override
  String get leadExplainPassed =>
      'That window has already passed — you should start now.';

  @override
  String leadWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String leadMonths(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String leadYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years years',
      one: '1 year',
    );
    return '$_temp0';
  }

  @override
  String get sixMonthRuleNote =>
      'Many countries require six months of validity beyond your entry date, so this document stops being usable for travel about six months before it expires.';

  @override
  String get typePassport => 'Passport';

  @override
  String get typeNationalId => 'National ID';

  @override
  String get typeDriversLicence => 'Driver\'s licence';

  @override
  String get typeVisa => 'Visa';

  @override
  String get typeResidencePermit => 'Residence permit';

  @override
  String get typeVehicleRegistration => 'Vehicle registration';

  @override
  String get typeInsurance => 'Insurance';

  @override
  String get typeProfessionalLicence => 'Professional licence';

  @override
  String get typeMembership => 'Membership';

  @override
  String get typeBankCard => 'Bank card';

  @override
  String get typeOther => 'Other';

  @override
  String get scanTitle => 'Scan document';

  @override
  String get scanHintSearching => 'Point at the document, keep it flat';

  @override
  String get scanHintFound => 'Hold steady';

  @override
  String get scanHintNoCamera =>
      'No camera on this device — read the code from a photo instead';

  @override
  String get scanChoosePhoto => 'Choose a photo';

  @override
  String get scanEnterByHand => 'Enter details by hand';

  @override
  String get scanNoCameraTitle => 'Scan from a photo';

  @override
  String get scanNoCameraBody =>
      'Elapsa can read the code from a picture of a document you already have.';

  @override
  String get scanFailedNoCode =>
      'No document code found. Fill the frame with the card and make sure the lines of code along the bottom are sharp.';

  @override
  String get scanFailedUnreadable =>
      'Found the code but could not read it cleanly. Try again with less glare, or enter the details by hand.';

  @override
  String get scanFailedPhoto => 'Could not read that photo.';

  @override
  String get scanFailedCapture => 'Could not take that photo. Try again.';

  @override
  String scanPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pictures',
      one: '1 picture',
    );
    return '$_temp0';
  }

  @override
  String get scanAddAnother => 'Add another side';

  @override
  String get scanSideFront => 'Front';

  @override
  String get scanSideBack => 'Back';

  @override
  String get detailCardholderName => 'Name on card';

  @override
  String get detailSecurityCode => 'Security code';

  @override
  String get detailNationality => 'Nationality';

  @override
  String get detailPlaceOfIssue => 'Place of issue';

  @override
  String get detailIssuingAuthority => 'Issued by';

  @override
  String get detailLicenceClass => 'Class';

  @override
  String get detailPolicyNumber => 'Policy number';

  @override
  String get detailPlateNumber => 'Plate number';

  @override
  String get detailVehicleIdentification => 'VIN';

  @override
  String get detailMembershipLevel => 'Level';

  @override
  String get detailSensitiveNote =>
      'Hidden by default, encrypted on this device, never uploaded.';

  @override
  String get detailReveal => 'Show';

  @override
  String get detailHide => 'Hide';

  @override
  String get sortTitle => 'Sort';

  @override
  String get sortExpiry => 'Expiry date';

  @override
  String get sortAdded => 'Recently added';

  @override
  String get sortName => 'Name';

  @override
  String get sortType => 'Type';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsPrivacyTitle => 'Everything stays on this device';

  @override
  String get settingsPrivacyBody =>
      'Your documents, their pictures and their numbers are encrypted and stored only on this phone. Elapsa has no account and no server, and nothing is ever uploaded.';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String notifyRenewTitle(String type) {
    return 'Time to renew your $type';
  }

  @override
  String notifyExpiresTitle(String label, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$label expires in $_temp0';
  }

  @override
  String notifyRenewBody(String date) {
    return 'It expires on $date. That is far enough ahead to renew without rushing — start now and it will be done in good time.';
  }

  @override
  String notifyTravelBody(String date) {
    return 'Expires on $date. Many countries require six months of validity, so it may already be unusable for travel.';
  }

  @override
  String notifyPlainBody(String date) {
    return 'Expires on $date.';
  }

  @override
  String get notifyChannelName => 'Renewal reminders';

  @override
  String get notifyChannelDescription =>
      'Tells you when to start renewing a document, not when it is too late.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'Follow device';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsWallet => 'Home screen';

  @override
  String get settingsWalletDisplay => 'Show each card as';

  @override
  String get displayNameOnly => 'Name only';

  @override
  String get displayImageOnly => 'Picture only';

  @override
  String get displayNameAndImage => 'Name and picture';

  @override
  String get displayNameOnlyBody =>
      'A compact list. Nothing on screen anyone could read over your shoulder.';

  @override
  String get displayImageOnlyBody =>
      'Your own photographs, the way a wallet looks when it is open.';

  @override
  String get displayNameAndImageBody =>
      'The photograph with its name and expiry underneath.';

  @override
  String get settingsRemindersTitle => 'Reminders';

  @override
  String get settingsRemindersLead => 'Remind me by default';

  @override
  String get settingsRemindersBody =>
      'Applied to new documents. Each one can still be changed on its own.';

  @override
  String get settingsRemindersAuto => 'Choose for each document';

  @override
  String get settingsScheduled => 'Scheduled reminders';

  @override
  String get settingsResync => 'Rebuild the schedule';

  @override
  String get settingsResyncDone => 'Reminder schedule rebuilt.';

  @override
  String get settingsDiagnostics => 'Diagnostics';

  @override
  String get settingsLastScan => 'Last scan';

  @override
  String get settingsLastScanBody =>
      'Exactly what the camera read, before Elapsa made sense of it. Useful when a field comes back empty.';

  @override
  String get settingsLastScanEmpty => 'Nothing scanned yet in this session.';

  @override
  String get actionCopy => 'Copy';

  @override
  String get settingsCopied => 'Copied.';

  @override
  String countYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years years',
      one: '1 year',
    );
    return '$_temp0';
  }

  @override
  String countDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String durationLeft(String duration) {
    return '$duration left';
  }

  @override
  String durationAgo(String duration) {
    return '$duration ago';
  }

  @override
  String get settingsTransfer => 'Transfer';

  @override
  String get transferExport => 'Export everything';

  @override
  String get transferExportBody =>
      'Every document and picture in one encrypted file. Send it to your other phone however you like — AirDrop, Files, a cable. It is also the only backup Elapsa has: nothing is stored anywhere but this device.';

  @override
  String get transferImport => 'Import from a file';

  @override
  String get transferImportBody =>
      'Open an archive exported from another device.';

  @override
  String get transferPassphrase => 'Passphrase';

  @override
  String get transferPassphraseNew => 'Choose a passphrase';

  @override
  String get transferPassphraseNewBody =>
      'You will need this exact passphrase to open the archive on the other phone. Nobody can recover it for you — not even Elapsa, which is what keeps the file safe if it goes astray.';

  @override
  String get transferPassphraseAsk =>
      'Enter the passphrase this archive was made with.';

  @override
  String get transferPassphraseShort => 'At least 8 characters.';

  @override
  String transferExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents',
      one: '1 document',
    );
    return 'Archived $_temp0.';
  }

  @override
  String transferImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents',
      one: '1 document',
    );
    return 'Imported $_temp0.';
  }

  @override
  String get transferNothing => 'Nothing to export yet.';

  @override
  String get transferMergeTitle => 'Import how?';

  @override
  String get transferMerge => 'Merge';

  @override
  String get transferMergeBody =>
      'Keep what is here and add what is in the file.';

  @override
  String get transferReplace => 'Replace everything';

  @override
  String get transferReplaceBody =>
      'Delete every document on this phone first.';

  @override
  String get transferFailedFile => 'That is not an Elapsa archive.';

  @override
  String get transferFailedNew =>
      'That archive was made by a newer version of Elapsa.';

  @override
  String get transferFailedKey =>
      'Wrong passphrase, or the file has been damaged.';

  @override
  String get actionContinue => 'Continue';

  @override
  String shortYears(int years) {
    return '${years}y';
  }

  @override
  String shortDays(int days) {
    return '${days}d';
  }

  @override
  String get shortExpired => 'EXP';

  @override
  String get transferProtect => 'Protect with a passphrase';

  @override
  String get transferProtectBody =>
      'Kept on for a file, which outlives the handover — it sits in Files at both ends afterwards. Turn it off only for an archive you are about to import and delete.';

  @override
  String get transferChoose => 'Choose what to send';

  @override
  String get transferAll => 'All';

  @override
  String get transferNone => 'None';

  @override
  String transferSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents',
      one: '1 document',
      zero: 'Nothing selected',
    );
    return '$_temp0';
  }

  @override
  String get cropTitle => 'Drag the corners';

  @override
  String get cropBody => 'Put a corner on each corner of the document.';

  @override
  String get cropReset => 'Reset';

  @override
  String get scanAdjust => 'Adjust the crop';

  @override
  String get scanAutoOn => 'Automatic detection on';

  @override
  String get scanAutoOff => 'Automatic detection off';

  @override
  String get scanAutoStuck => 'Can\'t find the document?';

  @override
  String get scanAutoStuckAction => 'Take it yourself';

  @override
  String get nearbyTitle => 'Transfer with a nearby device';

  @override
  String get nearbyBody =>
      'Open Elapsa on the other phone and come to this screen. No file, no passphrase — the other side has to accept.';

  @override
  String get nearbySearching => 'Looking for devices…';

  @override
  String get nearbyNone =>
      'Nothing found yet. Both phones need this screen open, and Wi-Fi on.';

  @override
  String get nearbySend => 'Send';

  @override
  String nearbyWaiting(String name) {
    return 'Waiting for $name to accept…';
  }

  @override
  String nearbySendingTo(String name) {
    return 'Sending to $name…';
  }

  @override
  String get nearbySentTo => 'Sent.';

  @override
  String get nearbyDeclined => 'They declined.';

  @override
  String nearbyInvite(String name) {
    return '$name wants to send you documents.';
  }

  @override
  String get nearbyAccept => 'Accept';

  @override
  String get nearbyDecline => 'Decline';

  @override
  String get nearbyReceiving => 'Receiving…';

  @override
  String get nearbyUnavailable =>
      'Nearby sending is not available on this device yet. Export a file instead.';

  @override
  String get nearbyName => 'This device appears as';

  @override
  String get actionCrop => 'Crop';

  @override
  String get leadCustom => 'Pick a date';

  @override
  String get leadDailyTitle => 'Every day in the final month';

  @override
  String get leadDailyBody =>
      'Once a document is a month from expiring, Elapsa reminds you daily. That one is not optional.';

  @override
  String leadOnDate(String date) {
    return 'On $date';
  }
}
