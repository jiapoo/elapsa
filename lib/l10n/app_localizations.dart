import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Elapsa'**
  String get appTitle;

  /// No description provided for @homeNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get homeNeedsAttention;

  /// No description provided for @homeEverythingElse.
  ///
  /// In en, this message translates to:
  /// **'Everything else'**
  String get homeEverythingElse;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing expiring'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add a passport, ID or licence and Elapsa will tell you when to start renewing it — not when it is already too late.'**
  String get homeEmptyBody;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add document'**
  String get actionAdd;

  /// No description provided for @actionScan.
  ///
  /// In en, this message translates to:
  /// **'Scan document'**
  String get actionScan;

  /// No description provided for @actionSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get actionSettings;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get actionRetake;

  /// Save to Photos
  ///
  /// In en, this message translates to:
  /// **'Save to Photos'**
  String get actionSaveToPhotos;

  /// Save to Files
  ///
  /// In en, this message translates to:
  /// **'Save to Files'**
  String get actionSaveToFiles;

  /// Saved to Photos
  ///
  /// In en, this message translates to:
  /// **'Saved to Photos'**
  String get photoSavedToPhotos;

  /// Saved to Files
  ///
  /// In en, this message translates to:
  /// **'Saved to Files'**
  String get photoSavedToFiles;

  /// Couldn't save the picture.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the picture.'**
  String get photoSaveFailed;

  /// Elapsa isn't allowed to add to Photos. You can allow it in Settings.
  ///
  /// In en, this message translates to:
  /// **'Elapsa isn\'t allowed to add to Photos. You can allow it in Settings.'**
  String get photoPhotosDenied;

  /// A copy saved outside Elapsa isn't encrypted.
  ///
  /// In en, this message translates to:
  /// **'A copy saved outside Elapsa isn\'t encrypted.'**
  String get photoExportNote;

  /// Attachments
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachmentsTitle;

  /// Add attachment
  ///
  /// In en, this message translates to:
  /// **'Add attachment'**
  String get attachmentsAdd;

  /// File
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get attachmentsAddFile;

  /// PDF, document or any other file
  ///
  /// In en, this message translates to:
  /// **'PDF, document or any other file'**
  String get attachmentsAddFileHint;

  /// Link
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get attachmentsAddLink;

  /// A web page, such as the renewal form
  ///
  /// In en, this message translates to:
  /// **'A web page, such as the renewal form'**
  String get attachmentsAddLinkHint;

  /// Add a link
  ///
  /// In en, this message translates to:
  /// **'Add a link'**
  String get attachmentsLinkTitle;

  /// Web address
  ///
  /// In en, this message translates to:
  /// **'Web address'**
  String get attachmentsLinkUrl;

  /// Name (optional)
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get attachmentsLinkName;

  /// That doesn't look like a web address.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a web address.'**
  String get attachmentsLinkInvalid;

  /// That file is over 50 MB, too large to attach.
  ///
  /// In en, this message translates to:
  /// **'That file is over 50 MB, too large to attach.'**
  String get attachmentsTooLarge;

  /// Some chosen files were too large
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file is over 50 MB and was left out.} other{{count} files are over 50 MB and were left out.}}'**
  String attachmentsSkippedTooLarge(int count);

  /// Couldn't open this attachment.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this attachment.'**
  String get attachmentsCannotOpen;

  /// Remove this attachment?
  ///
  /// In en, this message translates to:
  /// **'Remove this attachment?'**
  String get attachmentsRemoveTitle;

  /// The copy kept in Elapsa is deleted. This can't be undone.
  ///
  /// In en, this message translates to:
  /// **'The copy kept in Elapsa is deleted. This can\'t be undone.'**
  String get attachmentsRemoveBody;

  /// Remove
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// Add
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAddShort;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @statusExpiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get statusExpiring;

  /// No description provided for @statusRenewNow.
  ///
  /// In en, this message translates to:
  /// **'Renew now'**
  String get statusRenewNow;

  /// No description provided for @statusValid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get statusValid;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day left} other{{days} days left}}'**
  String daysLeft(int days);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day ago} other{{days} days ago}}'**
  String daysAgo(int days);

  /// No description provided for @startRenewingNow.
  ///
  /// In en, this message translates to:
  /// **'start renewing now'**
  String get startRenewingNow;

  /// No description provided for @travelRuleBadge.
  ///
  /// In en, this message translates to:
  /// **'Below the 6-month travel rule'**
  String get travelRuleBadge;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No reminders scheduled} =1{1 reminder scheduled} other{{count} reminders scheduled}}'**
  String remindersTitle(int count);

  /// No description provided for @remindersEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add a document and Elapsa will schedule reminders for it.'**
  String get remindersEmptyBody;

  /// No description provided for @remindersBody.
  ///
  /// In en, this message translates to:
  /// **'These fire even if the app is never opened.'**
  String get remindersBody;

  /// No description provided for @editAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add document'**
  String get editAddTitle;

  /// No description provided for @editEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit document'**
  String get editEditTitle;

  /// No description provided for @editScanHelp.
  ///
  /// In en, this message translates to:
  /// **'Reads the code on a passport, ID card or visa'**
  String get editScanHelp;

  /// No description provided for @editFromScanNote.
  ///
  /// In en, this message translates to:
  /// **'Filled in from the document code. Every field is still yours to change.'**
  String get editFromScanNote;

  /// No description provided for @editScanNothingRead.
  ///
  /// In en, this message translates to:
  /// **'Picture saved. Nothing readable on this side — fill in the details below.'**
  String get editScanNothingRead;

  /// No description provided for @editScanRepaired.
  ///
  /// In en, this message translates to:
  /// **'Scanned — the code was a little blurry, so please check the details.'**
  String get editScanRepaired;

  /// No description provided for @scanExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'This one has already expired'**
  String get scanExpiredTitle;

  /// No description provided for @scanExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'The expiry date on it is {date}, which has passed. Start renewing it now — or, if the date was misread, correct it below.'**
  String scanExpiredBody(String date);

  /// No description provided for @scanExpiredOk.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get scanExpiredOk;

  /// No description provided for @fieldType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get fieldType;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldNameHint.
  ///
  /// In en, this message translates to:
  /// **'My {type}'**
  String fieldNameHint(String type);

  /// No description provided for @fieldNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give it a name'**
  String get fieldNameRequired;

  /// No description provided for @fieldExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get fieldExpiry;

  /// No description provided for @fieldExpiryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get fieldExpiryEmpty;

  /// No description provided for @fieldExpiryRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick an expiry date'**
  String get fieldExpiryRequired;

  /// No description provided for @fieldIssueDate.
  ///
  /// In en, this message translates to:
  /// **'Valid from'**
  String get fieldIssueDate;

  /// No description provided for @fieldRemindMe.
  ///
  /// In en, this message translates to:
  /// **'Start reminding me'**
  String get fieldRemindMe;

  /// No description provided for @fieldOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get fieldOptional;

  /// No description provided for @fieldHolderHint.
  ///
  /// In en, this message translates to:
  /// **'Who it belongs to'**
  String get fieldHolderHint;

  /// No description provided for @fieldNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Document number'**
  String get fieldNumberHint;

  /// No description provided for @fieldNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Card number'**
  String get fieldNumberLabel;

  /// No description provided for @imageOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Retake or delete this picture?'**
  String get imageOptionsTitle;

  /// No description provided for @fieldImages.
  ///
  /// In en, this message translates to:
  /// **'Pictures'**
  String get fieldImages;

  /// No description provided for @editSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get editSave;

  /// No description provided for @editDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this document?'**
  String get editDeleteTitle;

  /// No description provided for @editDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Its reminders and pictures will be deleted too.'**
  String get editDeleteBody;

  /// No description provided for @leadExplainNoDate.
  ///
  /// In en, this message translates to:
  /// **'Elapsa will remind you {lead} before it expires, then again as the date approaches.'**
  String leadExplainNoDate(String lead);

  /// No description provided for @leadExplainFirst.
  ///
  /// In en, this message translates to:
  /// **'First reminder on {date}, then again as the date approaches.'**
  String leadExplainFirst(String date);

  /// No description provided for @leadExplainPassed.
  ///
  /// In en, this message translates to:
  /// **'That window has already passed — you should start now.'**
  String get leadExplainPassed;

  /// No description provided for @leadWeeks.
  ///
  /// In en, this message translates to:
  /// **'{weeks, plural, =1{1 week} other{{weeks} weeks}}'**
  String leadWeeks(int weeks);

  /// No description provided for @leadMonths.
  ///
  /// In en, this message translates to:
  /// **'{months, plural, =1{1 month} other{{months} months}}'**
  String leadMonths(int months);

  /// No description provided for @leadYears.
  ///
  /// In en, this message translates to:
  /// **'{years, plural, =1{1 year} other{{years} years}}'**
  String leadYears(int years);

  /// No description provided for @sixMonthRuleNote.
  ///
  /// In en, this message translates to:
  /// **'Many countries require six months of validity beyond your entry date, so this document stops being usable for travel about six months before it expires.'**
  String get sixMonthRuleNote;

  /// No description provided for @typePassport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get typePassport;

  /// No description provided for @typeNationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get typeNationalId;

  /// No description provided for @typeDriversLicence.
  ///
  /// In en, this message translates to:
  /// **'Driver\'s licence'**
  String get typeDriversLicence;

  /// No description provided for @typeVisa.
  ///
  /// In en, this message translates to:
  /// **'Visa'**
  String get typeVisa;

  /// No description provided for @typeResidencePermit.
  ///
  /// In en, this message translates to:
  /// **'Residence permit'**
  String get typeResidencePermit;

  /// No description provided for @typeVehicleRegistration.
  ///
  /// In en, this message translates to:
  /// **'Vehicle registration'**
  String get typeVehicleRegistration;

  /// No description provided for @typeInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get typeInsurance;

  /// No description provided for @typeProfessionalLicence.
  ///
  /// In en, this message translates to:
  /// **'Professional licence'**
  String get typeProfessionalLicence;

  /// No description provided for @typeMembership.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get typeMembership;

  /// No description provided for @typeBankCard.
  ///
  /// In en, this message translates to:
  /// **'Bank card'**
  String get typeBankCard;

  /// No description provided for @typeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get typeOther;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan document'**
  String get scanTitle;

  /// No description provided for @scanHintSearching.
  ///
  /// In en, this message translates to:
  /// **'Point at the document, keep it flat'**
  String get scanHintSearching;

  /// No description provided for @scanHintFound.
  ///
  /// In en, this message translates to:
  /// **'Hold steady'**
  String get scanHintFound;

  /// No description provided for @scanHintNoCamera.
  ///
  /// In en, this message translates to:
  /// **'No camera on this device — read the code from a photo instead'**
  String get scanHintNoCamera;

  /// No description provided for @scanChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo'**
  String get scanChoosePhoto;

  /// No description provided for @scanEnterByHand.
  ///
  /// In en, this message translates to:
  /// **'Enter details by hand'**
  String get scanEnterByHand;

  /// No description provided for @scanNoCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan from a photo'**
  String get scanNoCameraTitle;

  /// No description provided for @scanNoCameraBody.
  ///
  /// In en, this message translates to:
  /// **'Elapsa can read the code from a picture of a document you already have.'**
  String get scanNoCameraBody;

  /// No description provided for @scanFailedNoCode.
  ///
  /// In en, this message translates to:
  /// **'No document code found. Fill the frame with the card and make sure the lines of code along the bottom are sharp.'**
  String get scanFailedNoCode;

  /// No description provided for @scanFailedUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Found the code but could not read it cleanly. Try again with less glare, or enter the details by hand.'**
  String get scanFailedUnreadable;

  /// No description provided for @scanFailedPhoto.
  ///
  /// In en, this message translates to:
  /// **'Could not read that photo.'**
  String get scanFailedPhoto;

  /// No description provided for @scanFailedCapture.
  ///
  /// In en, this message translates to:
  /// **'Could not take that photo. Try again.'**
  String get scanFailedCapture;

  /// No description provided for @scanPageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 picture} other{{count} pictures}}'**
  String scanPageCount(int count);

  /// No description provided for @scanAddAnother.
  ///
  /// In en, this message translates to:
  /// **'Add another side'**
  String get scanAddAnother;

  /// No description provided for @scanSideFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get scanSideFront;

  /// No description provided for @scanSideBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get scanSideBack;

  /// No description provided for @detailCardholderName.
  ///
  /// In en, this message translates to:
  /// **'Name on card'**
  String get detailCardholderName;

  /// No description provided for @detailSecurityCode.
  ///
  /// In en, this message translates to:
  /// **'Security code'**
  String get detailSecurityCode;

  /// No description provided for @detailNationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get detailNationality;

  /// No description provided for @detailPlaceOfIssue.
  ///
  /// In en, this message translates to:
  /// **'Place of issue'**
  String get detailPlaceOfIssue;

  /// No description provided for @detailIssuingAuthority.
  ///
  /// In en, this message translates to:
  /// **'Issued by'**
  String get detailIssuingAuthority;

  /// No description provided for @detailLicenceClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get detailLicenceClass;

  /// No description provided for @detailPolicyNumber.
  ///
  /// In en, this message translates to:
  /// **'Policy number'**
  String get detailPolicyNumber;

  /// No description provided for @detailPlateNumber.
  ///
  /// In en, this message translates to:
  /// **'Plate number'**
  String get detailPlateNumber;

  /// No description provided for @detailVehicleIdentification.
  ///
  /// In en, this message translates to:
  /// **'VIN'**
  String get detailVehicleIdentification;

  /// No description provided for @detailMembershipLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get detailMembershipLevel;

  /// No description provided for @detailSensitiveNote.
  ///
  /// In en, this message translates to:
  /// **'Hidden by default, encrypted on this device, never uploaded.'**
  String get detailSensitiveNote;

  /// No description provided for @detailReveal.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get detailReveal;

  /// No description provided for @detailHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get detailHide;

  /// No description provided for @sortTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortTitle;

  /// No description provided for @sortExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get sortExpiry;

  /// No description provided for @sortAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get sortAdded;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortName;

  /// No description provided for @sortType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get sortType;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Everything stays on this device'**
  String get settingsPrivacyTitle;

  /// No description provided for @settingsPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Your documents, their pictures and their numbers are encrypted and stored only on this phone. Elapsa has no account and no server, and nothing is ever uploaded.'**
  String get settingsPrivacyBody;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @notifyRenewTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to renew your {type}'**
  String notifyRenewTitle(String type);

  /// No description provided for @notifyExpiresTitle.
  ///
  /// In en, this message translates to:
  /// **'{label} expires in {days, plural, =1{1 day} other{{days} days}}'**
  String notifyExpiresTitle(String label, int days);

  /// No description provided for @notifyRenewBody.
  ///
  /// In en, this message translates to:
  /// **'It expires on {date}. That is far enough ahead to renew without rushing — start now and it will be done in good time.'**
  String notifyRenewBody(String date);

  /// No description provided for @notifyTravelBody.
  ///
  /// In en, this message translates to:
  /// **'Expires on {date}. Many countries require six months of validity, so it may already be unusable for travel.'**
  String notifyTravelBody(String date);

  /// No description provided for @notifyPlainBody.
  ///
  /// In en, this message translates to:
  /// **'Expires on {date}.'**
  String notifyPlainBody(String date);

  /// No description provided for @notifyChannelName.
  ///
  /// In en, this message translates to:
  /// **'Renewal reminders'**
  String get notifyChannelName;

  /// No description provided for @notifyChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Tells you when to start renewing a document, not when it is too late.'**
  String get notifyChannelDescription;

  /// Appearance
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Theme
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Follow device
  ///
  /// In en, this message translates to:
  /// **'Follow device'**
  String get themeSystem;

  /// Light
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Dark
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Home screen
  ///
  /// In en, this message translates to:
  /// **'Home screen'**
  String get settingsWallet;

  /// Show each card as
  ///
  /// In en, this message translates to:
  /// **'Show each card as'**
  String get settingsWalletDisplay;

  /// Name only
  ///
  /// In en, this message translates to:
  /// **'Name only'**
  String get displayNameOnly;

  /// Picture only
  ///
  /// In en, this message translates to:
  /// **'Picture only'**
  String get displayImageOnly;

  /// Name and picture
  ///
  /// In en, this message translates to:
  /// **'Name and picture'**
  String get displayNameAndImage;

  /// A compact list. Nothing on screen anyone could read over your shoulder.
  ///
  /// In en, this message translates to:
  /// **'A compact list. Nothing on screen anyone could read over your shoulder.'**
  String get displayNameOnlyBody;

  /// Your own photographs, the way a wallet looks when it is open.
  ///
  /// In en, this message translates to:
  /// **'Your own photographs, the way a wallet looks when it is open.'**
  String get displayImageOnlyBody;

  /// The photograph with its name and expiry underneath.
  ///
  /// In en, this message translates to:
  /// **'The photograph with its name and expiry underneath.'**
  String get displayNameAndImageBody;

  /// Reminders
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get settingsRemindersTitle;

  /// Remind me by default
  ///
  /// In en, this message translates to:
  /// **'Remind me by default'**
  String get settingsRemindersLead;

  /// Applied to new documents. Each one can still be changed on its own.
  ///
  /// In en, this message translates to:
  /// **'Applied to new documents. Each one can still be changed on its own.'**
  String get settingsRemindersBody;

  /// Choose for each document
  ///
  /// In en, this message translates to:
  /// **'Choose for each document'**
  String get settingsRemindersAuto;

  /// Scheduled reminders
  ///
  /// In en, this message translates to:
  /// **'Scheduled reminders'**
  String get settingsScheduled;

  /// Rebuild the schedule
  ///
  /// In en, this message translates to:
  /// **'Rebuild the schedule'**
  String get settingsResync;

  /// Reminder schedule rebuilt.
  ///
  /// In en, this message translates to:
  /// **'Reminder schedule rebuilt.'**
  String get settingsResyncDone;

  /// Diagnostics
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get settingsDiagnostics;

  /// Last scan
  ///
  /// In en, this message translates to:
  /// **'Last scan'**
  String get settingsLastScan;

  /// Exactly what the camera read, before Elapsa made sense of it. Useful when a field comes back empty.
  ///
  /// In en, this message translates to:
  /// **'Exactly what the camera read, before Elapsa made sense of it. Useful when a field comes back empty.'**
  String get settingsLastScanBody;

  /// Nothing scanned yet in this session.
  ///
  /// In en, this message translates to:
  /// **'Nothing scanned yet in this session.'**
  String get settingsLastScanEmpty;

  /// Copy
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// Copied.
  ///
  /// In en, this message translates to:
  /// **'Copied.'**
  String get settingsCopied;

  /// Duration fragment
  ///
  /// In en, this message translates to:
  /// **'{years, plural, =1{1 year} other{{years} years}}'**
  String countYears(int years);

  /// Duration fragment
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}}'**
  String countDays(int days);

  /// Duration fragment
  ///
  /// In en, this message translates to:
  /// **'{duration} left'**
  String durationLeft(String duration);

  /// Duration fragment
  ///
  /// In en, this message translates to:
  /// **'{duration} ago'**
  String durationAgo(String duration);

  /// Transfer
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get settingsTransfer;

  /// Export everything
  ///
  /// In en, this message translates to:
  /// **'Export everything'**
  String get transferExport;

  /// Every document and picture in one encrypted file. Send it to
  ///
  /// In en, this message translates to:
  /// **'Every document and picture in one encrypted file. Send it to your other phone however you like — AirDrop, Files, a cable. It is also the only backup Elapsa has: nothing is stored anywhere but this device.'**
  String get transferExportBody;

  /// Import from a file
  ///
  /// In en, this message translates to:
  /// **'Import from a file'**
  String get transferImport;

  /// Open an archive exported from another device.
  ///
  /// In en, this message translates to:
  /// **'Open an archive exported from another device.'**
  String get transferImportBody;

  /// Passphrase
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get transferPassphrase;

  /// Choose a passphrase
  ///
  /// In en, this message translates to:
  /// **'Choose a passphrase'**
  String get transferPassphraseNew;

  /// You will need this exact passphrase to open the archive on t
  ///
  /// In en, this message translates to:
  /// **'You will need this exact passphrase to open the archive on the other phone. Nobody can recover it for you — not even Elapsa, which is what keeps the file safe if it goes astray.'**
  String get transferPassphraseNewBody;

  /// Enter the passphrase this archive was made with.
  ///
  /// In en, this message translates to:
  /// **'Enter the passphrase this archive was made with.'**
  String get transferPassphraseAsk;

  /// At least 8 characters.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters.'**
  String get transferPassphraseShort;

  /// Archived {count, plural, =1{1 document} other{{count} docume
  ///
  /// In en, this message translates to:
  /// **'Archived {count, plural, =1{1 document} other{{count} documents}}.'**
  String transferExported(int count);

  /// Imported {count, plural, =1{1 document} other{{count} docume
  ///
  /// In en, this message translates to:
  /// **'Imported {count, plural, =1{1 document} other{{count} documents}}.'**
  String transferImported(int count);

  /// Nothing to export yet.
  ///
  /// In en, this message translates to:
  /// **'Nothing to export yet.'**
  String get transferNothing;

  /// Import how?
  ///
  /// In en, this message translates to:
  /// **'Import how?'**
  String get transferMergeTitle;

  /// Merge
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get transferMerge;

  /// Keep what is here and add what is in the file.
  ///
  /// In en, this message translates to:
  /// **'Keep what is here and add what is in the file.'**
  String get transferMergeBody;

  /// Replace everything
  ///
  /// In en, this message translates to:
  /// **'Replace everything'**
  String get transferReplace;

  /// Delete every document on this phone first.
  ///
  /// In en, this message translates to:
  /// **'Delete every document on this phone first.'**
  String get transferReplaceBody;

  /// That is not an Elapsa archive.
  ///
  /// In en, this message translates to:
  /// **'That is not an Elapsa archive.'**
  String get transferFailedFile;

  /// That archive was made by a newer version of Elapsa.
  ///
  /// In en, this message translates to:
  /// **'That archive was made by a newer version of Elapsa.'**
  String get transferFailedNew;

  /// Wrong passphrase, or the file has been damaged.
  ///
  /// In en, this message translates to:
  /// **'Wrong passphrase, or the file has been damaged.'**
  String get transferFailedKey;

  /// Continue
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// {years}y
  ///
  /// In en, this message translates to:
  /// **'{years}y'**
  String shortYears(int years);

  /// {days}d
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String shortDays(int days);

  /// EXP
  ///
  /// In en, this message translates to:
  /// **'EXP'**
  String get shortExpired;

  /// Protect with a passphrase
  ///
  /// In en, this message translates to:
  /// **'Protect with a passphrase'**
  String get transferProtect;

  /// Off, the archive is a plain readable file wherever it lands
  ///
  /// In en, this message translates to:
  /// **'Kept on for a file, which outlives the handover — it sits in Files at both ends afterwards. Turn it off only for an archive you are about to import and delete.'**
  String get transferProtectBody;

  /// Choose what to send
  ///
  /// In en, this message translates to:
  /// **'Choose what to send'**
  String get transferChoose;

  /// All
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get transferAll;

  /// None
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get transferNone;

  /// {count, plural, =0{Nothing selected} =1{1 document} other{{c
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing selected} =1{1 document} other{{count} documents}}'**
  String transferSelected(int count);

  /// Drag the corners
  ///
  /// In en, this message translates to:
  /// **'Drag the corners'**
  String get cropTitle;

  /// Put a corner on each corner of the document.
  ///
  /// In en, this message translates to:
  /// **'Put a corner on each corner of the document.'**
  String get cropBody;

  /// Reset
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get cropReset;

  /// Adjust the crop
  ///
  /// In en, this message translates to:
  /// **'Adjust the crop'**
  String get scanAdjust;

  /// Automatic detection on
  ///
  /// In en, this message translates to:
  /// **'Automatic detection on'**
  String get scanAutoOn;

  /// Automatic detection off
  ///
  /// In en, this message translates to:
  /// **'Automatic detection off'**
  String get scanAutoOff;

  /// Can't find the document?
  ///
  /// In en, this message translates to:
  /// **'Can\'t find the document?'**
  String get scanAutoStuck;

  /// Take it yourself
  ///
  /// In en, this message translates to:
  /// **'Switch to manual'**
  String get scanAutoStuckAction;

  /// Transfer with a nearby device
  ///
  /// In en, this message translates to:
  /// **'Transfer with a nearby device'**
  String get nearbyTitle;

  /// Open Elapsa on the other phone and come to this screen. No f
  ///
  /// In en, this message translates to:
  /// **'Open Elapsa on the other phone and come to this screen. No file, no passphrase — the other side has to accept.'**
  String get nearbyBody;

  /// Looking for devices…
  ///
  /// In en, this message translates to:
  /// **'Looking for devices…'**
  String get nearbySearching;

  /// Nothing found yet. Both phones need this screen open, and Wi
  ///
  /// In en, this message translates to:
  /// **'Nothing found yet. Both phones need this screen open, and Wi-Fi on.'**
  String get nearbyNone;

  /// Send
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get nearbySend;

  /// Waiting for {name} to accept…
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to accept…'**
  String nearbyWaiting(String name);

  /// Sending to {name}…
  ///
  /// In en, this message translates to:
  /// **'Sending to {name}…'**
  String nearbySendingTo(String name);

  /// Sent.
  ///
  /// In en, this message translates to:
  /// **'Sent.'**
  String get nearbySentTo;

  /// They declined.
  ///
  /// In en, this message translates to:
  /// **'They declined.'**
  String get nearbyDeclined;

  /// {name} wants to send you documents.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to send you documents.'**
  String nearbyInvite(String name);

  /// Accept
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get nearbyAccept;

  /// Decline
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get nearbyDecline;

  /// Receiving…
  ///
  /// In en, this message translates to:
  /// **'Receiving…'**
  String get nearbyReceiving;

  /// Nearby sending is not available on this device yet. Export a
  ///
  /// In en, this message translates to:
  /// **'Nearby sending is not available on this device yet. Export a file instead.'**
  String get nearbyUnavailable;

  /// This device appears as
  ///
  /// In en, this message translates to:
  /// **'This device appears as'**
  String get nearbyName;

  /// Crop a picture
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get actionCrop;

  /// Pick a date
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get leadCustom;

  /// Every day in the final month
  ///
  /// In en, this message translates to:
  /// **'Every day in the final month'**
  String get leadDailyTitle;

  /// Once a document is a month from expiring, Elapsa reminds you
  ///
  /// In en, this message translates to:
  /// **'Once a document is a month from expiring, Elapsa reminds you daily. That one is not optional.'**
  String get leadDailyBody;

  /// On {date}
  ///
  /// In en, this message translates to:
  /// **'On {date}'**
  String leadOnDate(String date);

  /// Keep your changes?
  ///
  /// In en, this message translates to:
  /// **'Keep your changes?'**
  String get editUnsavedTitle;

  /// This document has edits that have not been saved.
  ///
  /// In en, this message translates to:
  /// **'This document has edits that have not been saved.'**
  String get editUnsavedBody;

  /// Discard
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get editDiscard;

  /// Send or receive?
  ///
  /// In en, this message translates to:
  /// **'Send or receive?'**
  String get nearbyRoleTitle;

  /// Send from this phone
  ///
  /// In en, this message translates to:
  /// **'Send from this phone'**
  String get nearbyRoleSend;

  /// Choose documents and hand them to another device.
  ///
  /// In en, this message translates to:
  /// **'Choose documents and hand them to another device.'**
  String get nearbyRoleSendBody;

  /// Receive on this phone
  ///
  /// In en, this message translates to:
  /// **'Receive on this phone'**
  String get nearbyRoleReceive;

  /// Wait for another device to send. You will be asked before an
  ///
  /// In en, this message translates to:
  /// **'Wait for another device to send. You will be asked before anything arrives.'**
  String get nearbyRoleReceiveBody;

  /// Waiting for a device to send…
  ///
  /// In en, this message translates to:
  /// **'Waiting for a device to send…'**
  String get nearbyWaitingToReceive;

  /// wants to send you documents
  ///
  /// In en, this message translates to:
  /// **'wants to send you documents'**
  String get nearbyWantsToSend;

  /// Share
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// Arrange
  ///
  /// In en, this message translates to:
  /// **'Arrange'**
  String get homeArrange;

  /// Sort by
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get homeSortBy;

  /// Show each card as
  ///
  /// In en, this message translates to:
  /// **'Show each card as'**
  String get homeShowAs;

  /// Document
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get detailTitle;

  /// Edit
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// Reminders
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get detailReminders;

  /// Next reminder {date}
  ///
  /// In en, this message translates to:
  /// **'Next reminder {date}'**
  String detailNextReminder(String date);

  /// No reminders scheduled.
  ///
  /// In en, this message translates to:
  /// **'No reminders scheduled.'**
  String get detailNoReminders;

  /// {count, plural, =1{1 picture} other{{count} pictures}}
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 picture} other{{count} pictures}}'**
  String detailPages(int count);

  /// Your own types
  ///
  /// In en, this message translates to:
  /// **'Your own types'**
  String get settingsTypes;

  /// Elapsa ships eleven kinds of document and will never ship th
  ///
  /// In en, this message translates to:
  /// **'Elapsa ships eleven kinds of document and will never ship the right eleven. Name your own, and they travel with the cards filed under them.'**
  String get typesBody;

  /// Add a type
  ///
  /// In en, this message translates to:
  /// **'Add a type'**
  String get typesAdd;

  /// Name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get typesName;

  /// Start reminding
  ///
  /// In en, this message translates to:
  /// **'Start reminding'**
  String get typesLead;

  /// None yet.
  ///
  /// In en, this message translates to:
  /// **'None yet.'**
  String get typesEmpty;

  /// In use by {count, plural, =1{1 document} other{{count} docum
  ///
  /// In en, this message translates to:
  /// **'In use by {count, plural, =1{1 document} other{{count} documents}}'**
  String typesInUse(int count);

  /// Remove
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get typesRemove;

  /// What the camera read
  ///
  /// In en, this message translates to:
  /// **'What the camera read'**
  String get editLastScan;

  /// Your own fields
  ///
  /// In en, this message translates to:
  /// **'Your own fields'**
  String get extrasTitle;

  /// Add a field
  ///
  /// In en, this message translates to:
  /// **'Add a field'**
  String get extrasAdd;

  /// Field name
  ///
  /// In en, this message translates to:
  /// **'Field name'**
  String get extrasName;

  /// Value
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get extrasValue;

  /// Never expires
  ///
  /// In en, this message translates to:
  /// **'Never expires'**
  String get fieldNeverExpires;

  /// This one has no expiry
  ///
  /// In en, this message translates to:
  /// **'This one has no expiry'**
  String get fieldNoExpiry;

  /// Search
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get homeSearch;

  /// Name, type, number…
  ///
  /// In en, this message translates to:
  /// **'Name, type, number…'**
  String get homeSearchHint;

  /// Nothing matches that.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches that.'**
  String get homeNoMatches;

  /// Issuing country
  ///
  /// In en, this message translates to:
  /// **'Issuing country'**
  String get detailIssuedBy;

  /// Passport number
  ///
  /// In en, this message translates to:
  /// **'Passport number'**
  String get fieldNumberPassport;

  /// Document number
  ///
  /// In en, this message translates to:
  /// **'Document number'**
  String get fieldNumberGeneric;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return LZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return LEn();
    case 'zh':
      return LZh();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
