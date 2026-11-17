// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class LIt extends L {
  LIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Elapsa';

  @override
  String get homeNeedsAttention => 'Da controllare';

  @override
  String get homeEverythingElse => 'Tutto il resto';

  @override
  String get homeEmptyTitle => 'Nessuna scadenza';

  @override
  String get homeEmptyBody =>
      'Aggiungi un passaporto, una carta d\'identità o una patente: Elapsa ti dirà quando iniziare il rinnovo, non quando è ormai troppo tardi.';

  @override
  String get actionAdd => 'Aggiungi documento';

  @override
  String get actionScan => 'Scansiona documento';

  @override
  String get actionSettings => 'Impostazioni';

  @override
  String get actionCancel => 'Annulla';

  @override
  String get actionDelete => 'Elimina';

  @override
  String get actionDone => 'Fine';

  @override
  String get actionRetake => 'Rifai';

  @override
  String get statusExpired => 'Scaduto';

  @override
  String get statusExpiring => 'In scadenza';

  @override
  String get statusRenewNow => 'Rinnova ora';

  @override
  String get statusValid => 'Valido';

  @override
  String daysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'mancano $days giorni',
      one: 'manca 1 giorno',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days giorni fa',
      one: '1 giorno fa',
    );
    return '$_temp0';
  }

  @override
  String get startRenewingNow => 'inizia subito il rinnovo';

  @override
  String get travelRuleBadge => 'Sotto la regola dei 6 mesi per viaggiare';

  @override
  String remindersTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count promemoria programmati',
      one: '1 promemoria programmato',
      zero: 'Nessun promemoria programmato',
    );
    return '$_temp0';
  }

  @override
  String get remindersEmptyBody =>
      'Aggiungi un documento ed Elapsa programmerà i promemoria.';

  @override
  String get remindersBody => 'Arrivano anche se l\'app non viene mai aperta.';

  @override
  String get editAddTitle => 'Aggiungi documento';

  @override
  String get editEditTitle => 'Modifica documento';

  @override
  String get editScanHelp =>
      'Legge il codice di passaporto, carta d\'identità o visto';

  @override
  String get editFromScanNote =>
      'Compilato dal codice del documento. Puoi comunque modificare ogni campo.';

  @override
  String get editScanNothingRead =>
      'Foto salvata. Niente di leggibile su questo lato: inserisci i dati qui sotto.';

  @override
  String get editScanRepaired =>
      'Scansionato: il codice era un po\' sfocato, controlla i dati.';

  @override
  String get fieldType => 'Tipo';

  @override
  String get fieldName => 'Nome';

  @override
  String fieldNameHint(String type) {
    return 'Es. $type';
  }

  @override
  String get fieldNameRequired => 'Dagli un nome';

  @override
  String get fieldExpiry => 'Data di scadenza';

  @override
  String get fieldExpiryEmpty => 'Scegli una data';

  @override
  String get fieldExpiryRequired => 'Scegli una data di scadenza';

  @override
  String get fieldIssueDate => 'Valido dal';

  @override
  String get fieldRemindMe => 'Inizia a ricordarmelo';

  @override
  String get fieldOptional => 'Facoltativo';

  @override
  String get fieldHolderHint => 'A chi appartiene';

  @override
  String get fieldNumberHint => 'Numero del documento';

  @override
  String get fieldNumberLabel => 'Numero della carta';

  @override
  String get imageOptionsTitle => 'Rifare o eliminare questa foto?';

  @override
  String get fieldImages => 'Foto';

  @override
  String get editSave => 'Salva';

  @override
  String get editDeleteTitle => 'Eliminare questo documento?';

  @override
  String get editDeleteBody =>
      'Verranno eliminati anche i suoi promemoria e le foto.';

  @override
  String leadExplainNoDate(String lead) {
    return 'Elapsa ti avviserà $lead prima della scadenza, e di nuovo man mano che la data si avvicina.';
  }

  @override
  String leadExplainFirst(String date) {
    return 'Primo promemoria il $date, poi di nuovo man mano che la data si avvicina.';
  }

  @override
  String get leadExplainPassed =>
      'Quel momento è già passato: conviene iniziare adesso.';

  @override
  String leadWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks settimane',
      one: '1 settimana',
    );
    return '$_temp0';
  }

  @override
  String leadMonths(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months mesi',
      one: '1 mese',
    );
    return '$_temp0';
  }

  @override
  String leadYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years anni',
      one: '1 anno',
    );
    return '$_temp0';
  }

  @override
  String get sixMonthRuleNote =>
      'Molti paesi richiedono sei mesi di validità oltre la data d\'ingresso, quindi questo documento non è più utilizzabile per viaggiare circa sei mesi prima della scadenza.';

  @override
  String get typePassport => 'Passaporto';

  @override
  String get typeNationalId => 'Carta d\'identità';

  @override
  String get typeDriversLicence => 'Patente';

  @override
  String get typeVisa => 'Visto';

  @override
  String get typeResidencePermit => 'Permesso di soggiorno';

  @override
  String get typeVehicleRegistration => 'Libretto di circolazione';

  @override
  String get typeInsurance => 'Assicurazione';

  @override
  String get typeProfessionalLicence => 'Abilitazione professionale';

  @override
  String get typeMembership => 'Tessera';

  @override
  String get typeBankCard => 'Carta bancaria';

  @override
  String get typeOther => 'Altro';

  @override
  String get scanTitle => 'Scansiona documento';

  @override
  String get scanHintSearching => 'Inquadra il documento, tienilo piatto';

  @override
  String get scanHintFound => 'Tieni fermo';

  @override
  String get scanHintNoCamera =>
      'Questo dispositivo non ha fotocamera: leggi il codice da una foto';

  @override
  String get scanChoosePhoto => 'Scegli una foto';

  @override
  String get scanEnterByHand => 'Inserisci a mano';

  @override
  String get scanNoCameraTitle => 'Scansiona da una foto';

  @override
  String get scanNoCameraBody =>
      'Elapsa può leggere il codice dalla foto di un documento che hai già.';

  @override
  String get scanFailedNoCode =>
      'Nessun codice trovato. Riempi la cornice con la carta e assicurati che le righe di codice in basso siano nitide.';

  @override
  String get scanFailedUnreadable =>
      'Codice trovato, ma non leggibile bene. Riprova con meno riflessi, oppure inserisci i dati a mano.';

  @override
  String get scanFailedPhoto => 'Impossibile leggere quella foto.';

  @override
  String get scanFailedCapture => 'Impossibile scattare la foto. Riprova.';

  @override
  String scanPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foto',
      one: '1 foto',
    );
    return '$_temp0';
  }

  @override
  String get scanAddAnother => 'Aggiungi l\'altro lato';

  @override
  String get scanSideFront => 'Fronte';

  @override
  String get scanSideBack => 'Retro';

  @override
  String get detailCardholderName => 'Nome sulla carta';

  @override
  String get detailSecurityCode => 'Codice di sicurezza';

  @override
  String get detailNationality => 'Cittadinanza';

  @override
  String get detailPlaceOfIssue => 'Luogo di rilascio';

  @override
  String get detailIssuingAuthority => 'Rilasciato da';

  @override
  String get detailLicenceClass => 'Categoria';

  @override
  String get detailPolicyNumber => 'Numero di polizza';

  @override
  String get detailPlateNumber => 'Targa';

  @override
  String get detailVehicleIdentification => 'Numero di telaio';

  @override
  String get detailMembershipLevel => 'Livello';

  @override
  String get detailSensitiveNote =>
      'Nascosto per impostazione predefinita, cifrato su questo dispositivo, mai caricato.';

  @override
  String get detailReveal => 'Mostra';

  @override
  String get detailHide => 'Nascondi';

  @override
  String get sortTitle => 'Ordina';

  @override
  String get sortExpiry => 'Data di scadenza';

  @override
  String get sortAdded => 'Aggiunti di recente';

  @override
  String get sortName => 'Nome';

  @override
  String get sortType => 'Tipo';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsLanguageSystem => 'Lingua del sistema';

  @override
  String get settingsAbout => 'Informazioni';

  @override
  String get settingsPrivacyTitle => 'Tutto resta su questo dispositivo';

  @override
  String get settingsPrivacyBody =>
      'I tuoi documenti, le foto e i numeri sono cifrati e salvati solo su questo telefono. Elapsa non ha account né server, e niente viene mai caricato.';

  @override
  String settingsVersion(String version) {
    return 'Versione $version';
  }

  @override
  String notifyRenewTitle(String type) {
    return 'È ora di rinnovare: $type';
  }

  @override
  String notifyExpiresTitle(String label, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days giorni',
      one: '1 giorno',
    );
    return '$label scade tra $_temp0';
  }

  @override
  String notifyRenewBody(String date) {
    return 'Scade il $date. C\'è abbastanza tempo per rinnovare senza fretta: inizia ora e sarà pronto in tempo.';
  }

  @override
  String notifyTravelBody(String date) {
    return 'Scade il $date. Molti paesi richiedono sei mesi di validità, quindi potrebbe già non servire per viaggiare.';
  }

  @override
  String notifyPlainBody(String date) {
    return 'Scade il $date.';
  }

  @override
  String get notifyChannelName => 'Promemoria di rinnovo';

  @override
  String get notifyChannelDescription =>
      'Ti dice quando iniziare a rinnovare un documento, non quando è troppo tardi.';

  @override
  String get settingsAppearance => 'Aspetto';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Come il dispositivo';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get settingsWallet => 'Schermata principale';

  @override
  String get settingsWalletDisplay => 'Mostra ogni carta come';

  @override
  String get displayNameOnly => 'Solo nome';

  @override
  String get displayImageOnly => 'Solo foto';

  @override
  String get displayNameAndImage => 'Nome e foto';

  @override
  String get displayNameOnlyBody =>
      'Un elenco compatto. Niente sullo schermo che qualcuno possa leggere da sopra la tua spalla.';

  @override
  String get displayImageOnlyBody => 'Le tue foto, come un portafoglio aperto.';

  @override
  String get displayNameAndImageBody =>
      'La foto con il nome e la scadenza sotto.';

  @override
  String get settingsRemindersTitle => 'Promemoria';

  @override
  String get settingsRemindersLead => 'Promemoria predefiniti';

  @override
  String get settingsRemindersBody =>
      'Valgono per i nuovi documenti. Ognuno si può comunque cambiare singolarmente.';

  @override
  String get settingsRemindersAuto => 'Scegli per ogni documento';

  @override
  String get settingsScheduled => 'Promemoria programmati';

  @override
  String get settingsResync => 'Ricrea il calendario';

  @override
  String get settingsResyncDone => 'Calendario dei promemoria ricreato.';

  @override
  String get settingsDiagnostics => 'Diagnostica';

  @override
  String get settingsLastScan => 'Ultima scansione';

  @override
  String get settingsLastScanBody =>
      'Esattamente ciò che ha letto la fotocamera, prima che Elapsa lo interpretasse. Utile quando un campo resta vuoto.';

  @override
  String get settingsLastScanEmpty =>
      'Ancora nessuna scansione in questa sessione.';

  @override
  String get actionCopy => 'Copia';

  @override
  String get settingsCopied => 'Copiato.';

  @override
  String countYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years anni',
      one: '1 anno',
    );
    return '$_temp0';
  }

  @override
  String countDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String durationLeft(String duration) {
    return 'mancano $duration';
  }

  @override
  String durationAgo(String duration) {
    return '$duration fa';
  }

  @override
  String get settingsTransfer => 'Trasferimento';

  @override
  String get transferExport => 'Esporta tutto';

  @override
  String get transferExportBody =>
      'Tutti i documenti e le foto in un unico file cifrato. Mandalo all\'altro telefono come preferisci: AirDrop, File, un cavo. È anche l\'unico backup di Elapsa: niente è salvato altrove se non su questo dispositivo.';

  @override
  String get transferImport => 'Importa da file';

  @override
  String get transferImportBody =>
      'Apri un archivio esportato da un altro dispositivo.';

  @override
  String get transferPassphrase => 'Passphrase';

  @override
  String get transferPassphraseNew => 'Scegli una passphrase';

  @override
  String get transferPassphraseNewBody =>
      'Ti servirà esattamente questa passphrase per aprire l\'archivio sull\'altro telefono. Nessuno può recuperarla per te, nemmeno Elapsa: è questo che protegge il file se finisce nelle mani sbagliate.';

  @override
  String get transferPassphraseAsk =>
      'Inserisci la passphrase con cui è stato creato questo archivio.';

  @override
  String get transferPassphraseShort => 'Almeno 8 caratteri.';

  @override
  String transferExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documenti archiviati.',
      one: '1 documento archiviato.',
    );
    return '$_temp0';
  }

  @override
  String transferImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documenti importati.',
      one: '1 documento importato.',
    );
    return '$_temp0';
  }

  @override
  String get transferNothing => 'Ancora niente da esportare.';

  @override
  String get transferMergeTitle => 'Come importare?';

  @override
  String get transferMerge => 'Unisci';

  @override
  String get transferMergeBody =>
      'Mantieni ciò che c\'è qui e aggiungi il contenuto del file.';

  @override
  String get transferReplace => 'Sostituisci tutto';

  @override
  String get transferReplaceBody =>
      'Elimina prima tutti i documenti su questo telefono.';

  @override
  String get transferFailedFile => 'Non è un archivio di Elapsa.';

  @override
  String get transferFailedNew =>
      'Questo archivio è stato creato da una versione più recente di Elapsa.';

  @override
  String get transferFailedKey =>
      'Passphrase errata, oppure il file è danneggiato.';

  @override
  String get actionContinue => 'Continua';

  @override
  String shortYears(int years) {
    return '${years}a';
  }

  @override
  String shortDays(int days) {
    return '${days}g';
  }

  @override
  String get shortExpired => 'SCAD';

  @override
  String get transferProtect => 'Proteggi con passphrase';

  @override
  String get transferProtectBody =>
      'Resta attiva per un file, che sopravvive al passaggio: dopo rimane in File su entrambi i lati. Disattivala solo per un archivio che stai per importare ed eliminare.';

  @override
  String get transferChoose => 'Scegli cosa inviare';

  @override
  String get transferAll => 'Tutti';

  @override
  String get transferNone => 'Nessuno';

  @override
  String transferSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documenti',
      one: '1 documento',
      zero: 'Nessuna selezione',
    );
    return '$_temp0';
  }

  @override
  String get cropTitle => 'Trascina gli angoli';

  @override
  String get cropBody => 'Metti un angolo su ciascun angolo del documento.';

  @override
  String get cropReset => 'Ripristina';

  @override
  String get scanAdjust => 'Regola il ritaglio';

  @override
  String get scanAutoOn => 'Rilevamento automatico attivo';

  @override
  String get scanAutoOff => 'Rilevamento automatico disattivo';

  @override
  String get scanAutoStuck => 'Non trova il documento?';

  @override
  String get scanAutoStuckAction => 'Passa al manuale';

  @override
  String get nearbyTitle => 'Trasferisci con un dispositivo vicino';

  @override
  String get nearbyBody =>
      'Apri Elapsa sull\'altro telefono e vai a questa schermata. Niente file, niente passphrase: l\'altra parte deve accettare.';

  @override
  String get nearbySearching => 'Ricerca dei dispositivi…';

  @override
  String get nearbyNone =>
      'Ancora niente. Entrambi i telefoni devono avere questa schermata aperta e il Wi-Fi attivo.';

  @override
  String get nearbySend => 'Invia';

  @override
  String nearbyWaiting(String name) {
    return 'In attesa che $name accetti…';
  }

  @override
  String nearbySendingTo(String name) {
    return 'Invio a $name…';
  }

  @override
  String get nearbySentTo => 'Inviato.';

  @override
  String get nearbyDeclined => 'Rifiutato.';

  @override
  String nearbyInvite(String name) {
    return '$name vuole inviarti dei documenti.';
  }

  @override
  String get nearbyAccept => 'Accetta';

  @override
  String get nearbyDecline => 'Rifiuta';

  @override
  String get nearbyReceiving => 'Ricezione…';

  @override
  String get nearbyUnavailable =>
      'L\'invio ai dispositivi vicini non è ancora disponibile su questo dispositivo. Esporta un file.';

  @override
  String get nearbyName => 'Questo dispositivo appare come';

  @override
  String get actionCrop => 'Ritaglia';

  @override
  String get leadCustom => 'Scegli una data';

  @override
  String get leadDailyTitle => 'Ogni giorno nell\'ultimo mese';

  @override
  String get leadDailyBody =>
      'Quando manca un mese alla scadenza, Elapsa te lo ricorda ogni giorno. Questo non è facoltativo.';

  @override
  String leadOnDate(String date) {
    return 'Il $date';
  }

  @override
  String get editUnsavedTitle => 'Tenere le modifiche?';

  @override
  String get editUnsavedBody => 'Questo documento ha modifiche non salvate.';

  @override
  String get editDiscard => 'Scarta';

  @override
  String get nearbyRoleTitle => 'Inviare o ricevere?';

  @override
  String get nearbyRoleSend => 'Invia da questo telefono';

  @override
  String get nearbyRoleSendBody =>
      'Scegli i documenti e passali a un altro dispositivo.';

  @override
  String get nearbyRoleReceive => 'Ricevi su questo telefono';

  @override
  String get nearbyRoleReceiveBody =>
      'Attendi che un altro dispositivo invii. Ti verrà chiesto prima che arrivi qualcosa.';

  @override
  String get nearbyWaitingToReceive => 'In attesa di un dispositivo che invii…';

  @override
  String get nearbyWantsToSend => 'vuole inviarti dei documenti';

  @override
  String get actionShare => 'Condividi';

  @override
  String get homeArrange => 'Disponi';

  @override
  String get homeSortBy => 'Ordina per';

  @override
  String get homeShowAs => 'Mostra ogni carta come';

  @override
  String get detailTitle => 'Documento';

  @override
  String get actionEdit => 'Modifica';

  @override
  String get detailReminders => 'Promemoria';

  @override
  String detailNextReminder(String date) {
    return 'Prossimo promemoria il $date';
  }

  @override
  String get detailNoReminders => 'Nessun promemoria programmato.';

  @override
  String detailPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foto',
      one: '1 foto',
    );
    return '$_temp0';
  }

  @override
  String get settingsTypes => 'I tuoi tipi';

  @override
  String get typesBody =>
      'Elapsa offre undici tipi di documento e non avrà mai gli undici giusti. Dai un nome ai tuoi: viaggiano insieme alle carte archiviate sotto di essi.';

  @override
  String get typesAdd => 'Aggiungi un tipo';

  @override
  String get typesName => 'Nome';

  @override
  String get typesLead => 'Inizia a ricordare';

  @override
  String get typesEmpty => 'Ancora nessuno.';

  @override
  String typesInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Usato da $count documenti',
      one: 'Usato da 1 documento',
    );
    return '$_temp0';
  }

  @override
  String get typesRemove => 'Rimuovi';

  @override
  String get editLastScan => 'Cosa ha letto la fotocamera';

  @override
  String get extrasTitle => 'I tuoi campi';

  @override
  String get extrasAdd => 'Aggiungi un campo';

  @override
  String get extrasName => 'Nome del campo';

  @override
  String get extrasValue => 'Valore';

  @override
  String get fieldNeverExpires => 'Non scade mai';

  @override
  String get fieldNoExpiry => 'Questo non ha scadenza';

  @override
  String get homeSearch => 'Cerca';

  @override
  String get homeSearchHint => 'Nome, tipo, numero…';

  @override
  String get homeNoMatches => 'Nessun risultato.';

  @override
  String get detailIssuedBy => 'Paese di rilascio';

  @override
  String get fieldNumberPassport => 'Numero di passaporto';

  @override
  String get fieldNumberGeneric => 'Numero del documento';

  @override
  String get paywallTitle => 'Tutti i documenti in un unico posto';

  @override
  String paywallBody(int limit) {
    return 'La versione gratuita conserva $limit documenti. Sblocca documenti illimitati con un solo acquisto.';
  }

  @override
  String get paywallPointUnlimited => 'Documenti e promemoria illimitati';

  @override
  String get paywallPointOnce =>
      'Paghi una volta. Nessun abbonamento, niente si rinnova.';

  @override
  String get paywallPointPrivate =>
      'Sempre senza account, e niente lascia il tuo telefono.';

  @override
  String paywallBuy(String price) {
    return 'Sblocca per $price';
  }

  @override
  String get paywallLoadingPrice => 'Recupero del prezzo…';

  @override
  String get paywallRestore => 'Ripristina acquisto';

  @override
  String get paywallNotNow => 'Non ora';

  @override
  String get paywallPending =>
      'In attesa di approvazione. Lo sblocco comparirà appena l\'acquisto sarà approvato.';

  @override
  String get paywallFailed => 'L\'acquisto non è andato a buon fine. Riprova.';

  @override
  String get paywallNothingToRestore =>
      'Nessun acquisto precedente trovato per questo account.';

  @override
  String get paywallStoreUnavailable =>
      'Impossibile raggiungere lo store in questo momento. Controlla la connessione e riprova.';

  @override
  String get paywallRetry => 'Riprova';

  @override
  String get paywallThanks =>
      'Illimitato è sbloccato. Grazie per sostenere Elapsa.';

  @override
  String get paywallRestored => 'Bentornato: Illimitato è di nuovo sbloccato.';

  @override
  String paywallImportBlocked(int limit) {
    return 'Non importato. La versione gratuita conserva $limit documenti.';
  }

  @override
  String get settingsUnlimited => 'Elapsa Illimitato';

  @override
  String get settingsUnlimitedOn =>
      'Sbloccato. Aggiungi tutti i documenti che vuoi.';

  @override
  String settingsUnlimitedUsage(int count, int limit) {
    return '$count di $limit documenti gratuiti usati';
  }

  @override
  String get settingsUnlimitedUnlock => 'Sblocca Illimitato';
}
