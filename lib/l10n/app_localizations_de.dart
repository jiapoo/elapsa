// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class LDe extends L {
  LDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Elapsa';

  @override
  String get homeNeedsAttention => 'Braucht Aufmerksamkeit';

  @override
  String get homeEverythingElse => 'Alles andere';

  @override
  String get homeEmptyTitle => 'Nichts läuft ab';

  @override
  String get homeEmptyBody =>
      'Füge einen Reisepass, Ausweis oder Führerschein hinzu, und Elapsa sagt dir, wann du mit der Verlängerung beginnen solltest – nicht erst, wenn es zu spät ist.';

  @override
  String get actionAdd => 'Dokument hinzufügen';

  @override
  String get actionScan => 'Dokument scannen';

  @override
  String get actionSettings => 'Einstellungen';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionDelete => 'Löschen';

  @override
  String get actionDone => 'Fertig';

  @override
  String get actionRetake => 'Neu aufnehmen';

  @override
  String get exportWhereTitle => 'Wohin soll das Archiv?';

  @override
  String get exportToFilesBody =>
      'Wähle einen Ordner auf diesem iPhone oder in iCloud Drive. Du findest ihn später in der App „Dateien“.';

  @override
  String get exportShareTitle => 'An eine andere App senden';

  @override
  String get exportShareBody => 'AirDrop, Nachrichten, Mail und mehr.';

  @override
  String get exportSavedTitle => 'In „Dateien“ gesichert';

  @override
  String get exportSavedBody => 'Öffne die App „Dateien“ und gehe zu:';

  @override
  String get filesOnMyPhone => 'Auf meinem iPhone';

  @override
  String get filesIcloudDrive => 'iCloud Drive';

  @override
  String get typesNew => 'Neuer Typ …';

  @override
  String get scanBothSides => 'Beide Seiten erfasst.';

  @override
  String get scanKeepGoing => 'Weitere';

  @override
  String get actionOpen => 'Öffnen';

  @override
  String get shareFailed => 'Teilen nicht möglich.';

  @override
  String get actionSaveToPhotos => 'In Fotos sichern';

  @override
  String get actionSaveToFiles => 'In Dateien sichern';

  @override
  String get photoSavedToPhotos => 'In Fotos gesichert';

  @override
  String get photoSavedToFiles => 'In Dateien gesichert';

  @override
  String get photoSaveFailed => 'Das Bild konnte nicht gesichert werden.';

  @override
  String get photoPhotosDenied =>
      'Elapsa darf nichts zu Fotos hinzufügen. Du kannst es in den Einstellungen erlauben.';

  @override
  String get photoExportNote =>
      'Eine außerhalb von Elapsa gesicherte Kopie ist nicht verschlüsselt.';

  @override
  String get attachmentsTitle => 'Anhänge';

  @override
  String get attachmentsAdd => 'Anhang hinzufügen';

  @override
  String get attachmentsAddFile => 'Datei';

  @override
  String get attachmentsAddFileHint => 'PDF, Dokument oder eine andere Datei';

  @override
  String get attachmentsAddLink => 'Link';

  @override
  String get attachmentsAddLinkHint =>
      'Eine Webseite, etwa das Verlängerungsformular';

  @override
  String get attachmentsLinkTitle => 'Link hinzufügen';

  @override
  String get attachmentsLinkUrl => 'Webadresse';

  @override
  String get attachmentsLinkName => 'Name (optional)';

  @override
  String get attachmentsLinkInvalid =>
      'Das sieht nicht nach einer Webadresse aus.';

  @override
  String get attachmentsTooLarge =>
      'Diese Datei ist größer als 50 MB und zu groß zum Anhängen.';

  @override
  String attachmentsSkippedTooLarge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien sind größer als 50 MB und wurden weggelassen.',
      one: '1 Datei ist größer als 50 MB und wurde weggelassen.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentsCannotOpen =>
      'Dieser Anhang konnte nicht geöffnet werden.';

  @override
  String get attachmentsRemoveTitle => 'Diesen Anhang entfernen?';

  @override
  String get attachmentsRemoveBody =>
      'Die in Elapsa gespeicherte Kopie wird gelöscht. Das lässt sich nicht rückgängig machen.';

  @override
  String get actionRemove => 'Entfernen';

  @override
  String get actionAddShort => 'Hinzufügen';

  @override
  String get statusExpired => 'Abgelaufen';

  @override
  String get statusExpiring => 'Läuft ab';

  @override
  String get statusRenewNow => 'Jetzt verlängern';

  @override
  String get statusValid => 'Gültig';

  @override
  String daysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'noch $days Tage',
      one: 'noch 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'vor $days Tagen',
      one: 'vor 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get startRenewingNow => 'jetzt mit der Verlängerung beginnen';

  @override
  String get travelRuleBadge => 'Unter der 6-Monats-Regel für Reisen';

  @override
  String remindersTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Erinnerungen geplant',
      one: '1 Erinnerung geplant',
      zero: 'Keine Erinnerungen geplant',
    );
    return '$_temp0';
  }

  @override
  String get remindersEmptyBody =>
      'Füge ein Dokument hinzu, und Elapsa plant Erinnerungen dafür.';

  @override
  String get remindersBody =>
      'Sie kommen auch, wenn die App nie geöffnet wird.';

  @override
  String get editAddTitle => 'Dokument hinzufügen';

  @override
  String get editEditTitle => 'Dokument bearbeiten';

  @override
  String get editScanHelp => 'Liest den Code auf Reisepass, Ausweis oder Visum';

  @override
  String get editFromScanNote =>
      'Aus dem Dokumentcode ausgefüllt. Jedes Feld kannst du weiterhin ändern.';

  @override
  String get editScanNothingRead =>
      'Bild gespeichert. Auf dieser Seite war nichts lesbar – trag die Angaben unten ein.';

  @override
  String get editScanRepaired =>
      'Gescannt – der Code war etwas unscharf, bitte prüfe die Angaben.';

  @override
  String get scanExpiredTitle => 'Das ist bereits abgelaufen';

  @override
  String scanExpiredBody(String date) {
    return 'Das Ablaufdatum ist der $date – und der ist schon vorbei. Kümmere dich jetzt um die Verlängerung oder korrigiere das Datum unten, falls es falsch gelesen wurde.';
  }

  @override
  String get scanExpiredOk => 'Verstanden';

  @override
  String get fieldType => 'Art';

  @override
  String get fieldName => 'Name';

  @override
  String fieldNameHint(String type) {
    return 'z. B. $type';
  }

  @override
  String get fieldNameRequired => 'Gib ihm einen Namen';

  @override
  String get fieldExpiry => 'Ablaufdatum';

  @override
  String get fieldExpiryEmpty => 'Datum wählen';

  @override
  String get fieldExpiryRequired => 'Wähle ein Ablaufdatum';

  @override
  String get fieldIssueDate => 'Gültig ab';

  @override
  String get fieldRemindMe => 'Erinnern ab';

  @override
  String get fieldOptional => 'Optional';

  @override
  String get fieldHolderHint => 'Wem es gehört';

  @override
  String get fieldNumberHint => 'Dokumentnummer';

  @override
  String get fieldNumberLabel => 'Kartennummer';

  @override
  String get imageOptionsTitle => 'Dieses Bild neu aufnehmen oder löschen?';

  @override
  String get fieldImages => 'Bilder';

  @override
  String get editSave => 'Sichern';

  @override
  String get editDeleteTitle => 'Dieses Dokument löschen?';

  @override
  String get editDeleteBody =>
      'Seine Erinnerungen und Bilder werden ebenfalls gelöscht.';

  @override
  String leadExplainNoDate(String lead) {
    return 'Elapsa erinnert dich $lead vor Ablauf und dann erneut, je näher das Datum rückt.';
  }

  @override
  String leadExplainFirst(String date) {
    return 'Erste Erinnerung am $date, dann erneut, je näher das Datum rückt.';
  }

  @override
  String get leadExplainPassed =>
      'Dieser Zeitpunkt ist schon vorbei – fang am besten jetzt an.';

  @override
  String leadWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks Wochen',
      one: '1 Woche',
    );
    return '$_temp0';
  }

  @override
  String leadMonths(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months Monate',
      one: '1 Monat',
    );
    return '$_temp0';
  }

  @override
  String leadYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years Jahre',
      one: '1 Jahr',
    );
    return '$_temp0';
  }

  @override
  String get sixMonthRuleNote =>
      'Viele Länder verlangen eine Gültigkeit von sechs Monaten über das Einreisedatum hinaus. Für Reisen ist dieses Dokument daher etwa sechs Monate vor Ablauf nicht mehr nutzbar.';

  @override
  String get typePassport => 'Reisepass';

  @override
  String get typeNationalId => 'Personalausweis';

  @override
  String get typeDriversLicence => 'Führerschein';

  @override
  String get typeVisa => 'Visum';

  @override
  String get typeResidencePermit => 'Aufenthaltstitel';

  @override
  String get typeVehicleRegistration => 'Fahrzeugschein';

  @override
  String get typeInsurance => 'Versicherung';

  @override
  String get typeProfessionalLicence => 'Berufszulassung';

  @override
  String get typeMembership => 'Mitgliedschaft';

  @override
  String get typeBankCard => 'Bankkarte';

  @override
  String get typeOther => 'Sonstiges';

  @override
  String get scanTitle => 'Dokument scannen';

  @override
  String get scanHintSearching => 'Auf das Dokument richten, flach halten';

  @override
  String get scanHintFound => 'Ruhig halten';

  @override
  String get scanHintNoCamera =>
      'Dieses Gerät hat keine Kamera – lies den Code stattdessen aus einem Foto';

  @override
  String get scanChoosePhoto => 'Foto auswählen';

  @override
  String get scanEnterByHand => 'Von Hand eingeben';

  @override
  String get scanNoCameraTitle => 'Aus einem Foto scannen';

  @override
  String get scanNoCameraBody =>
      'Elapsa kann den Code aus einem Foto eines Dokuments lesen, das du schon hast.';

  @override
  String get scanFailedNoCode =>
      'Kein Dokumentcode gefunden. Füll den Rahmen mit der Karte und achte darauf, dass die Codezeilen unten scharf sind.';

  @override
  String get scanFailedUnreadable =>
      'Der Code wurde gefunden, ließ sich aber nicht sauber lesen. Versuch es mit weniger Spiegelung noch einmal oder gib die Angaben von Hand ein.';

  @override
  String get scanFailedPhoto => 'Dieses Foto konnte nicht gelesen werden.';

  @override
  String get scanFailedCapture =>
      'Das Foto konnte nicht aufgenommen werden. Versuch es noch einmal.';

  @override
  String scanPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bilder',
      one: '1 Bild',
    );
    return '$_temp0';
  }

  @override
  String get scanAddAnother => 'Weitere Seite hinzufügen';

  @override
  String get scanSideFront => 'Vorderseite';

  @override
  String get scanSideBack => 'Rückseite';

  @override
  String get detailCardholderName => 'Name auf der Karte';

  @override
  String get detailSecurityCode => 'Sicherheitscode';

  @override
  String get detailNationality => 'Staatsangehörigkeit';

  @override
  String get detailPlaceOfIssue => 'Ausstellungsort';

  @override
  String get detailIssuingAuthority => 'Ausgestellt von';

  @override
  String get detailLicenceClass => 'Klasse';

  @override
  String get detailPolicyNumber => 'Policennummer';

  @override
  String get detailPlateNumber => 'Kennzeichen';

  @override
  String get detailVehicleIdentification => 'FIN';

  @override
  String get detailMembershipLevel => 'Stufe';

  @override
  String get detailSensitiveNote =>
      'Standardmäßig verborgen, auf diesem Gerät verschlüsselt, nie hochgeladen.';

  @override
  String get detailReveal => 'Zeigen';

  @override
  String get detailHide => 'Verbergen';

  @override
  String get sortTitle => 'Sortieren';

  @override
  String get sortExpiry => 'Ablaufdatum';

  @override
  String get sortAdded => 'Zuletzt hinzugefügt';

  @override
  String get sortName => 'Name';

  @override
  String get sortType => 'Art';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageSystem => 'Systemstandard';

  @override
  String get settingsAbout => 'Über';

  @override
  String get settingsPrivacyTitle => 'Alles bleibt auf diesem Gerät';

  @override
  String get settingsPrivacyBody =>
      'Deine Dokumente, ihre Bilder und Nummern werden verschlüsselt und nur auf diesem Telefon gespeichert. Elapsa hat kein Konto und keinen Server, und nichts wird jemals hochgeladen.';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String notifyRenewTitle(String type) {
    return 'Zeit zum Verlängern: $type';
  }

  @override
  String notifyExpiresTitle(String label, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tagen',
      one: '1 Tag',
    );
    return '$label läuft in $_temp0 ab';
  }

  @override
  String notifyRenewBody(String date) {
    return 'Läuft am $date ab. Das ist früh genug, um ohne Eile zu verlängern – fang jetzt an, dann ist es rechtzeitig erledigt.';
  }

  @override
  String notifyTravelBody(String date) {
    return 'Läuft am $date ab. Viele Länder verlangen sechs Monate Gültigkeit, für Reisen ist es also womöglich schon unbrauchbar.';
  }

  @override
  String notifyPlainBody(String date) {
    return 'Läuft am $date ab.';
  }

  @override
  String get notifyChannelName => 'Erinnerungen zur Verlängerung';

  @override
  String get notifyChannelDescription =>
      'Sagt dir, wann du mit der Verlängerung beginnen solltest – nicht, wenn es zu spät ist.';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsTheme => 'Design';

  @override
  String get themeSystem => 'Wie Gerät';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get settingsWallet => 'Startbildschirm';

  @override
  String get settingsWalletDisplay => 'Karten anzeigen als';

  @override
  String get displayNameOnly => 'Nur Name';

  @override
  String get displayImageOnly => 'Nur Bild';

  @override
  String get displayNameAndImage => 'Name und Bild';

  @override
  String get displayNameOnlyBody =>
      'Eine kompakte Liste. Nichts auf dem Bildschirm, das jemand über die Schulter mitlesen könnte.';

  @override
  String get displayImageOnlyBody =>
      'Deine eigenen Fotos, so wie eine aufgeklappte Brieftasche aussieht.';

  @override
  String get displayNameAndImageBody =>
      'Das Foto mit Name und Ablaufdatum darunter.';

  @override
  String get settingsRemindersTitle => 'Erinnerungen';

  @override
  String get settingsRemindersLead => 'Standardmäßig erinnern';

  @override
  String get settingsRemindersBody =>
      'Gilt für neue Dokumente. Jedes lässt sich weiterhin einzeln ändern.';

  @override
  String get settingsRemindersAuto => 'Für jedes Dokument wählen';

  @override
  String get settingsScheduled => 'Geplante Erinnerungen';

  @override
  String get settingsResync => 'Zeitplan neu erstellen';

  @override
  String get settingsResyncDone => 'Erinnerungsplan neu erstellt.';

  @override
  String get settingsDiagnostics => 'Diagnose';

  @override
  String get settingsLastScan => 'Letzter Scan';

  @override
  String get settingsLastScanBody =>
      'Genau das, was die Kamera gelesen hat, bevor Elapsa es ausgewertet hat. Nützlich, wenn ein Feld leer bleibt.';

  @override
  String get settingsLastScanEmpty =>
      'In dieser Sitzung wurde noch nichts gescannt.';

  @override
  String get actionCopy => 'Kopieren';

  @override
  String get settingsCopied => 'Kopiert.';

  @override
  String countYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years Jahre',
      one: '1 Jahr',
    );
    return '$_temp0';
  }

  @override
  String countDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String durationLeft(String duration) {
    return 'noch $duration';
  }

  @override
  String durationAgo(String duration) {
    return 'vor $duration';
  }

  @override
  String get settingsTransfer => 'Übertragen';

  @override
  String get transferExport => 'Alles exportieren';

  @override
  String get transferExportBody =>
      'Alle Dokumente und Bilder in einer verschlüsselten Datei. Schick sie auf dein anderes Telefon, wie du willst – AirDrop, Dateien, ein Kabel. Sie ist auch das einzige Backup von Elapsa: Nichts wird irgendwo anders als auf diesem Gerät gespeichert.';

  @override
  String get transferImport => 'Aus Datei importieren';

  @override
  String get transferImportBody =>
      'Ein Archiv öffnen, das auf einem anderen Gerät exportiert wurde.';

  @override
  String get transferPassphrase => 'Passphrase';

  @override
  String get transferPassphraseNew => 'Passphrase wählen';

  @override
  String get transferPassphraseNewBody =>
      'Du brauchst genau diese Passphrase, um das Archiv auf dem anderen Telefon zu öffnen. Niemand kann sie für dich wiederherstellen – auch Elapsa nicht. Genau das schützt die Datei, falls sie in falsche Hände gerät.';

  @override
  String get transferPassphraseAsk =>
      'Gib die Passphrase ein, mit der dieses Archiv erstellt wurde.';

  @override
  String get transferPassphraseShort => 'Mindestens 8 Zeichen.';

  @override
  String transferExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dokumente archiviert.',
      one: '1 Dokument archiviert.',
    );
    return '$_temp0';
  }

  @override
  String transferImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dokumente importiert.',
      one: '1 Dokument importiert.',
    );
    return '$_temp0';
  }

  @override
  String get transferNothing => 'Noch nichts zu exportieren.';

  @override
  String get transferMergeTitle => 'Wie importieren?';

  @override
  String get transferMerge => 'Zusammenführen';

  @override
  String get transferMergeBody =>
      'Vorhandenes behalten und den Inhalt der Datei hinzufügen.';

  @override
  String get transferReplace => 'Alles ersetzen';

  @override
  String get transferReplaceBody =>
      'Zuerst alle Dokumente auf diesem Telefon löschen.';

  @override
  String get transferFailedFile => 'Das ist kein Elapsa-Archiv.';

  @override
  String get transferFailedNew =>
      'Dieses Archiv stammt von einer neueren Elapsa-Version.';

  @override
  String get transferFailedKey =>
      'Falsche Passphrase, oder die Datei ist beschädigt.';

  @override
  String get actionContinue => 'Weiter';

  @override
  String shortYears(int years) {
    return '$years J.';
  }

  @override
  String shortDays(int days) {
    return '$days T.';
  }

  @override
  String get shortExpired => 'ABGEL.';

  @override
  String get transferProtect => 'Mit Passphrase schützen';

  @override
  String get transferProtectBody =>
      'Bei einer Datei bleibt das an, denn sie überdauert die Übergabe – danach liegt sie auf beiden Seiten in Dateien. Schalte es nur für ein Archiv aus, das du gleich importierst und löschst.';

  @override
  String get transferChoose => 'Auswählen, was gesendet wird';

  @override
  String get transferAll => 'Alle';

  @override
  String get transferNone => 'Keine';

  @override
  String transferSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dokumente',
      one: '1 Dokument',
      zero: 'Nichts ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String get cropTitle => 'Ecken ziehen';

  @override
  String get cropBody => 'Setz je eine Ecke auf jede Ecke des Dokuments.';

  @override
  String get cropReset => 'Zurücksetzen';

  @override
  String get scanAdjust => 'Zuschnitt anpassen';

  @override
  String get scanAutoOn => 'Automatische Erkennung an';

  @override
  String get scanAutoOff => 'Automatische Erkennung aus';

  @override
  String get scanAutoStuck => 'Dokument wird nicht erkannt?';

  @override
  String get scanAutoStuckAction => 'Manuell aufnehmen';

  @override
  String get nearbyTitle => 'Mit einem Gerät in der Nähe übertragen';

  @override
  String get nearbyBody =>
      'Öffne Elapsa auf dem anderen Telefon und geh zu diesem Bildschirm. Keine Datei, keine Passphrase – die andere Seite muss annehmen.';

  @override
  String get nearbySearching => 'Suche nach Geräten …';

  @override
  String get nearbyNone =>
      'Noch nichts gefunden. Auf beiden Telefonen muss dieser Bildschirm offen und WLAN an sein.';

  @override
  String get nearbySend => 'Senden';

  @override
  String nearbyWaiting(String name) {
    return 'Warte, bis $name annimmt …';
  }

  @override
  String nearbySendingTo(String name) {
    return 'Wird an $name gesendet …';
  }

  @override
  String get nearbySentTo => 'Gesendet.';

  @override
  String get nearbyDeclined => 'Abgelehnt.';

  @override
  String nearbyInvite(String name) {
    return '$name möchte dir Dokumente senden.';
  }

  @override
  String get nearbyAccept => 'Annehmen';

  @override
  String get nearbyDecline => 'Ablehnen';

  @override
  String get nearbyReceiving => 'Wird empfangen …';

  @override
  String get nearbyUnavailable =>
      'Senden an Geräte in der Nähe ist auf diesem Gerät noch nicht verfügbar. Exportiere stattdessen eine Datei.';

  @override
  String get nearbyName => 'Dieses Gerät erscheint als';

  @override
  String get actionCrop => 'Zuschneiden';

  @override
  String get leadCustom => 'Datum wählen';

  @override
  String get leadDailyTitle => 'Jeden Tag im letzten Monat';

  @override
  String get leadDailyBody =>
      'Läuft ein Dokument in einem Monat ab, erinnert Elapsa dich täglich. Das lässt sich nicht abschalten.';

  @override
  String leadOnDate(String date) {
    return 'Am $date';
  }

  @override
  String get editUnsavedTitle => 'Änderungen behalten?';

  @override
  String get editUnsavedBody =>
      'Dieses Dokument hat Änderungen, die nicht gesichert sind.';

  @override
  String get editDiscard => 'Verwerfen';

  @override
  String get nearbyRoleTitle => 'Senden oder empfangen?';

  @override
  String get nearbyRoleSend => 'Von diesem Telefon senden';

  @override
  String get nearbyRoleSendBody =>
      'Dokumente auswählen und an ein anderes Gerät übergeben.';

  @override
  String get nearbyRoleReceive => 'Auf diesem Telefon empfangen';

  @override
  String get nearbyRoleReceiveBody =>
      'Warten, bis ein anderes Gerät sendet. Du wirst gefragt, bevor etwas ankommt.';

  @override
  String get nearbyWaitingToReceive => 'Warte auf ein sendendes Gerät …';

  @override
  String get nearbyWantsToSend => 'möchte dir Dokumente senden';

  @override
  String get actionShare => 'Teilen';

  @override
  String get homeArrange => 'Anordnen';

  @override
  String get homeSortBy => 'Sortieren nach';

  @override
  String get homeShowAs => 'Karten anzeigen als';

  @override
  String get detailTitle => 'Dokument';

  @override
  String get actionEdit => 'Bearbeiten';

  @override
  String get detailReminders => 'Erinnerungen';

  @override
  String detailNextReminder(String date) {
    return 'Nächste Erinnerung $date';
  }

  @override
  String get detailNoReminders => 'Keine Erinnerungen geplant.';

  @override
  String detailPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bilder',
      one: '1 Bild',
    );
    return '$_temp0';
  }

  @override
  String get settingsTypes => 'Eigene Arten';

  @override
  String get typesBody =>
      'Elapsa bringt elf Dokumentarten mit und wird nie die richtigen elf haben. Benenne deine eigenen – sie reisen mit den Karten, die darunter abgelegt sind.';

  @override
  String get typesAdd => 'Art hinzufügen';

  @override
  String get typesName => 'Name';

  @override
  String get typesLead => 'Erinnern ab';

  @override
  String get typesEmpty => 'Noch keine.';

  @override
  String typesInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Von $count Dokumenten verwendet',
      one: 'Von 1 Dokument verwendet',
    );
    return '$_temp0';
  }

  @override
  String get typesRemove => 'Entfernen';

  @override
  String get editLastScan => 'Was die Kamera gelesen hat';

  @override
  String get extrasTitle => 'Eigene Felder';

  @override
  String get extrasAdd => 'Feld hinzufügen';

  @override
  String get extrasName => 'Feldname';

  @override
  String get extrasValue => 'Wert';

  @override
  String get fieldNeverExpires => 'Läuft nie ab';

  @override
  String get fieldNoExpiry => 'Ohne Ablaufdatum';

  @override
  String get homeSearch => 'Suchen';

  @override
  String get homeSearchHint => 'Name, Art, Nummer …';

  @override
  String get homeNoMatches => 'Keine Treffer.';

  @override
  String get detailIssuedBy => 'Ausstellungsland';

  @override
  String get fieldNumberPassport => 'Passnummer';

  @override
  String get fieldNumberGeneric => 'Dokumentnummer';

  @override
  String get paywallTitle => 'Alle Dokumente an einem Ort';

  @override
  String paywallBody(int limit) {
    return 'Die kostenlose Version speichert $limit Dokumente. Schalte mit einem einzigen Kauf unbegrenzt viele frei.';
  }

  @override
  String get paywallPointUnlimited => 'Unbegrenzt Dokumente und Erinnerungen';

  @override
  String get paywallPointOnce =>
      'Einmal zahlen. Kein Abo, nichts verlängert sich.';

  @override
  String get paywallPointPrivate =>
      'Weiterhin kein Konto, und nichts verlässt dein Telefon.';

  @override
  String paywallBuy(String price) {
    return 'Für $price freischalten';
  }

  @override
  String get paywallLoadingPrice => 'Preis wird geladen …';

  @override
  String get paywallRestore => 'Kauf wiederherstellen';

  @override
  String get paywallNotNow => 'Nicht jetzt';

  @override
  String get paywallPending =>
      'Wartet auf Genehmigung. Die Freischaltung erscheint, sobald der Kauf genehmigt ist.';

  @override
  String get paywallFailed =>
      'Der Kauf wurde nicht abgeschlossen. Bitte versuch es noch einmal.';

  @override
  String get paywallNothingToRestore =>
      'Für dieses Konto wurde kein früherer Kauf gefunden.';

  @override
  String get paywallStoreUnavailable =>
      'Der Store ist gerade nicht erreichbar. Prüfe deine Verbindung und versuch es noch einmal.';

  @override
  String get paywallRetry => 'Erneut versuchen';

  @override
  String get paywallThanks =>
      'Unbegrenzt ist freigeschaltet. Danke, dass du Elapsa unterstützt.';

  @override
  String get paywallRestored =>
      'Willkommen zurück – Unbegrenzt ist wieder freigeschaltet.';

  @override
  String paywallImportBlocked(int limit) {
    return 'Nicht importiert. Die kostenlose Version speichert $limit Dokumente.';
  }

  @override
  String get settingsUnlimited => 'Elapsa Unbegrenzt';

  @override
  String get settingsUnlimitedOn =>
      'Freigeschaltet. Füge so viele Dokumente hinzu, wie du willst.';

  @override
  String settingsUnlimitedUsage(int count, int limit) {
    return '$count von $limit kostenlosen Dokumenten belegt';
  }

  @override
  String get settingsUnlimitedUnlock => 'Unbegrenzt freischalten';
}
