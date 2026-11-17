// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class LFr extends L {
  LFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Elapsa';

  @override
  String get homeNeedsAttention => 'À traiter';

  @override
  String get homeEverythingElse => 'Tout le reste';

  @override
  String get homeEmptyTitle => 'Rien n\'expire';

  @override
  String get homeEmptyBody =>
      'Ajoutez un passeport, une carte d\'identité ou un permis, et Elapsa vous dira quand commencer le renouvellement — pas quand il sera trop tard.';

  @override
  String get actionAdd => 'Ajouter un document';

  @override
  String get actionScan => 'Scanner un document';

  @override
  String get actionSettings => 'Réglages';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionDone => 'OK';

  @override
  String get actionRetake => 'Reprendre';

  @override
  String get statusExpired => 'Expiré';

  @override
  String get statusExpiring => 'Expire bientôt';

  @override
  String get statusRenewNow => 'À renouveler';

  @override
  String get statusValid => 'Valide';

  @override
  String daysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours restants',
      one: '1 jour restant',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'il y a $days jours',
      one: 'il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get startRenewingNow => 'commencez le renouvellement maintenant';

  @override
  String get travelRuleBadge => 'Sous la règle des 6 mois pour voyager';

  @override
  String remindersTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rappels programmés',
      one: '1 rappel programmé',
      zero: 'Aucun rappel programmé',
    );
    return '$_temp0';
  }

  @override
  String get remindersEmptyBody =>
      'Ajoutez un document et Elapsa programmera ses rappels.';

  @override
  String get remindersBody =>
      'Ils arrivent même si l\'app n\'est jamais ouverte.';

  @override
  String get editAddTitle => 'Ajouter un document';

  @override
  String get editEditTitle => 'Modifier le document';

  @override
  String get editScanHelp =>
      'Lit le code d\'un passeport, d\'une carte d\'identité ou d\'un visa';

  @override
  String get editFromScanNote =>
      'Rempli à partir du code du document. Chaque champ reste modifiable.';

  @override
  String get editScanNothingRead =>
      'Photo enregistrée. Rien de lisible sur cette face — saisissez les informations ci-dessous.';

  @override
  String get editScanRepaired =>
      'Scanné — le code était un peu flou, vérifiez les informations.';

  @override
  String get scanExpiredTitle => 'Ce document a déjà expiré';

  @override
  String scanExpiredBody(String date) {
    return 'Sa date d’expiration est le $date, et elle est passée. Lancez le renouvellement dès maintenant, ou corrigez la date ci-dessous si elle a été mal lue.';
  }

  @override
  String get scanExpiredOk => 'Compris';

  @override
  String get fieldType => 'Type';

  @override
  String get fieldName => 'Nom';

  @override
  String fieldNameHint(String type) {
    return 'Ex. : $type';
  }

  @override
  String get fieldNameRequired => 'Donnez-lui un nom';

  @override
  String get fieldExpiry => 'Date d\'expiration';

  @override
  String get fieldExpiryEmpty => 'Choisir une date';

  @override
  String get fieldExpiryRequired => 'Choisissez une date d\'expiration';

  @override
  String get fieldIssueDate => 'Valable à partir du';

  @override
  String get fieldRemindMe => 'Me rappeler';

  @override
  String get fieldOptional => 'Facultatif';

  @override
  String get fieldHolderHint => 'À qui il appartient';

  @override
  String get fieldNumberHint => 'Numéro du document';

  @override
  String get fieldNumberLabel => 'Numéro de carte';

  @override
  String get imageOptionsTitle => 'Reprendre ou supprimer cette photo ?';

  @override
  String get fieldImages => 'Photos';

  @override
  String get editSave => 'Enregistrer';

  @override
  String get editDeleteTitle => 'Supprimer ce document ?';

  @override
  String get editDeleteBody =>
      'Ses rappels et ses photos seront aussi supprimés.';

  @override
  String leadExplainNoDate(String lead) {
    return 'Elapsa vous préviendra $lead avant l\'expiration, puis à nouveau à l\'approche de la date.';
  }

  @override
  String leadExplainFirst(String date) {
    return 'Premier rappel le $date, puis à nouveau à l\'approche de la date.';
  }

  @override
  String get leadExplainPassed =>
      'Ce délai est déjà passé — mieux vaut commencer maintenant.';

  @override
  String leadWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks semaines',
      one: '1 semaine',
    );
    return '$_temp0';
  }

  @override
  String leadMonths(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months mois',
    );
    return '$_temp0';
  }

  @override
  String leadYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years ans',
      one: '1 an',
    );
    return '$_temp0';
  }

  @override
  String get sixMonthRuleNote =>
      'De nombreux pays exigent six mois de validité après la date d\'entrée : ce document cesse donc d\'être utilisable pour voyager environ six mois avant son expiration.';

  @override
  String get typePassport => 'Passeport';

  @override
  String get typeNationalId => 'Carte d\'identité';

  @override
  String get typeDriversLicence => 'Permis de conduire';

  @override
  String get typeVisa => 'Visa';

  @override
  String get typeResidencePermit => 'Titre de séjour';

  @override
  String get typeVehicleRegistration => 'Carte grise';

  @override
  String get typeInsurance => 'Assurance';

  @override
  String get typeProfessionalLicence => 'Licence professionnelle';

  @override
  String get typeMembership => 'Adhésion';

  @override
  String get typeBankCard => 'Carte bancaire';

  @override
  String get typeOther => 'Autre';

  @override
  String get scanTitle => 'Scanner un document';

  @override
  String get scanHintSearching => 'Visez le document, bien à plat';

  @override
  String get scanHintFound => 'Ne bougez plus';

  @override
  String get scanHintNoCamera =>
      'Pas d\'appareil photo sur cet appareil — lisez plutôt le code depuis une photo';

  @override
  String get scanChoosePhoto => 'Choisir une photo';

  @override
  String get scanEnterByHand => 'Saisir à la main';

  @override
  String get scanNoCameraTitle => 'Scanner depuis une photo';

  @override
  String get scanNoCameraBody =>
      'Elapsa peut lire le code sur une photo d\'un document que vous avez déjà.';

  @override
  String get scanFailedNoCode =>
      'Aucun code trouvé. Remplissez le cadre avec la carte et vérifiez que les lignes de code en bas sont nettes.';

  @override
  String get scanFailedUnreadable =>
      'Code trouvé, mais illisible. Réessayez avec moins de reflets, ou saisissez les informations à la main.';

  @override
  String get scanFailedPhoto => 'Impossible de lire cette photo.';

  @override
  String get scanFailedCapture => 'Impossible de prendre la photo. Réessayez.';

  @override
  String scanPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String get scanAddAnother => 'Ajouter l\'autre face';

  @override
  String get scanSideFront => 'Recto';

  @override
  String get scanSideBack => 'Verso';

  @override
  String get detailCardholderName => 'Nom sur la carte';

  @override
  String get detailSecurityCode => 'Code de sécurité';

  @override
  String get detailNationality => 'Nationalité';

  @override
  String get detailPlaceOfIssue => 'Lieu de délivrance';

  @override
  String get detailIssuingAuthority => 'Délivré par';

  @override
  String get detailLicenceClass => 'Catégorie';

  @override
  String get detailPolicyNumber => 'Numéro de contrat';

  @override
  String get detailPlateNumber => 'Immatriculation';

  @override
  String get detailVehicleIdentification => 'VIN';

  @override
  String get detailMembershipLevel => 'Niveau';

  @override
  String get detailSensitiveNote =>
      'Masqué par défaut, chiffré sur cet appareil, jamais envoyé.';

  @override
  String get detailReveal => 'Afficher';

  @override
  String get detailHide => 'Masquer';

  @override
  String get sortTitle => 'Trier';

  @override
  String get sortExpiry => 'Date d\'expiration';

  @override
  String get sortAdded => 'Ajout récent';

  @override
  String get sortName => 'Nom';

  @override
  String get sortType => 'Type';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Langue du système';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsPrivacyTitle => 'Tout reste sur cet appareil';

  @override
  String get settingsPrivacyBody =>
      'Vos documents, leurs photos et leurs numéros sont chiffrés et stockés uniquement sur ce téléphone. Elapsa n\'a ni compte ni serveur, et rien n\'est jamais envoyé.';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String notifyRenewTitle(String type) {
    return 'Pensez à renouveler : $type';
  }

  @override
  String notifyExpiresTitle(String label, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
    );
    return '$label expire dans $_temp0';
  }

  @override
  String notifyRenewBody(String date) {
    return 'Il expire le $date. C\'est assez tôt pour renouveler sans vous presser — commencez maintenant et ce sera fait à temps.';
  }

  @override
  String notifyTravelBody(String date) {
    return 'Expire le $date. De nombreux pays exigent six mois de validité : il est peut-être déjà inutilisable pour voyager.';
  }

  @override
  String notifyPlainBody(String date) {
    return 'Expire le $date.';
  }

  @override
  String get notifyChannelName => 'Rappels de renouvellement';

  @override
  String get notifyChannelDescription =>
      'Vous dit quand commencer à renouveler un document, pas quand il est trop tard.';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get themeSystem => 'Comme l\'appareil';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get settingsWallet => 'Écran d\'accueil';

  @override
  String get settingsWalletDisplay => 'Afficher chaque carte';

  @override
  String get displayNameOnly => 'Nom seul';

  @override
  String get displayImageOnly => 'Photo seule';

  @override
  String get displayNameAndImage => 'Nom et photo';

  @override
  String get displayNameOnlyBody =>
      'Une liste compacte. Rien à l\'écran que quelqu\'un pourrait lire par-dessus votre épaule.';

  @override
  String get displayImageOnlyBody =>
      'Vos propres photos, comme un portefeuille ouvert.';

  @override
  String get displayNameAndImageBody =>
      'La photo, avec le nom et l\'échéance en dessous.';

  @override
  String get settingsRemindersTitle => 'Rappels';

  @override
  String get settingsRemindersLead => 'Rappels par défaut';

  @override
  String get settingsRemindersBody =>
      'S\'applique aux nouveaux documents. Chacun reste modifiable séparément.';

  @override
  String get settingsRemindersAuto => 'Choisir pour chaque document';

  @override
  String get settingsScheduled => 'Rappels programmés';

  @override
  String get settingsResync => 'Reconstruire le calendrier';

  @override
  String get settingsResyncDone => 'Calendrier des rappels reconstruit.';

  @override
  String get settingsDiagnostics => 'Diagnostic';

  @override
  String get settingsLastScan => 'Dernier scan';

  @override
  String get settingsLastScanBody =>
      'Exactement ce que l\'appareil photo a lu, avant qu\'Elapsa ne l\'interprète. Utile quand un champ reste vide.';

  @override
  String get settingsLastScanEmpty =>
      'Rien n\'a encore été scanné pendant cette session.';

  @override
  String get actionCopy => 'Copier';

  @override
  String get settingsCopied => 'Copié.';

  @override
  String countYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years ans',
      one: '1 an',
    );
    return '$_temp0';
  }

  @override
  String countDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String durationLeft(String duration) {
    return 'encore $duration';
  }

  @override
  String durationAgo(String duration) {
    return 'il y a $duration';
  }

  @override
  String get settingsTransfer => 'Transfert';

  @override
  String get transferExport => 'Tout exporter';

  @override
  String get transferExportBody =>
      'Tous les documents et photos dans un seul fichier chiffré. Envoyez-le sur votre autre téléphone comme vous voulez — AirDrop, Fichiers, un câble. C\'est aussi la seule sauvegarde d\'Elapsa : rien n\'est stocké ailleurs que sur cet appareil.';

  @override
  String get transferImport => 'Importer un fichier';

  @override
  String get transferImportBody =>
      'Ouvrir une archive exportée depuis un autre appareil.';

  @override
  String get transferPassphrase => 'Phrase secrète';

  @override
  String get transferPassphraseNew => 'Choisissez une phrase secrète';

  @override
  String get transferPassphraseNewBody =>
      'Il vous faudra exactement cette phrase secrète pour ouvrir l\'archive sur l\'autre téléphone. Personne ne peut la retrouver pour vous — pas même Elapsa, et c\'est ce qui protège le fichier s\'il se perd.';

  @override
  String get transferPassphraseAsk =>
      'Saisissez la phrase secrète utilisée pour créer cette archive.';

  @override
  String get transferPassphraseShort => 'Au moins 8 caractères.';

  @override
  String transferExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents archivés.',
      one: '1 document archivé.',
    );
    return '$_temp0';
  }

  @override
  String transferImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents importés.',
      one: '1 document importé.',
    );
    return '$_temp0';
  }

  @override
  String get transferNothing => 'Rien à exporter pour l\'instant.';

  @override
  String get transferMergeTitle => 'Comment importer ?';

  @override
  String get transferMerge => 'Fusionner';

  @override
  String get transferMergeBody =>
      'Garder ce qui est ici et ajouter le contenu du fichier.';

  @override
  String get transferReplace => 'Tout remplacer';

  @override
  String get transferReplaceBody =>
      'Supprimer d\'abord tous les documents de ce téléphone.';

  @override
  String get transferFailedFile => 'Ce n\'est pas une archive Elapsa.';

  @override
  String get transferFailedNew =>
      'Cette archive a été créée par une version plus récente d\'Elapsa.';

  @override
  String get transferFailedKey =>
      'Phrase secrète incorrecte, ou fichier endommagé.';

  @override
  String get actionContinue => 'Continuer';

  @override
  String shortYears(int years) {
    return '$years a';
  }

  @override
  String shortDays(int days) {
    return '$days j';
  }

  @override
  String get shortExpired => 'EXP';

  @override
  String get transferProtect => 'Protéger par une phrase secrète';

  @override
  String get transferProtectBody =>
      'Laissé activé pour un fichier, qui survit à l\'échange — il reste ensuite dans Fichiers des deux côtés. Désactivez-le seulement pour une archive que vous allez importer puis supprimer.';

  @override
  String get transferChoose => 'Choisir quoi envoyer';

  @override
  String get transferAll => 'Tout';

  @override
  String get transferNone => 'Aucun';

  @override
  String transferSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents',
      one: '1 document',
      zero: 'Aucune sélection',
    );
    return '$_temp0';
  }

  @override
  String get cropTitle => 'Faites glisser les coins';

  @override
  String get cropBody => 'Placez un coin sur chaque coin du document.';

  @override
  String get cropReset => 'Réinitialiser';

  @override
  String get scanAdjust => 'Ajuster le recadrage';

  @override
  String get scanAutoOn => 'Détection automatique activée';

  @override
  String get scanAutoOff => 'Détection automatique désactivée';

  @override
  String get scanAutoStuck => 'Document introuvable ?';

  @override
  String get scanAutoStuckAction => 'Passer en manuel';

  @override
  String get nearbyTitle => 'Transférer avec un appareil à proximité';

  @override
  String get nearbyBody =>
      'Ouvrez Elapsa sur l\'autre téléphone et allez sur cet écran. Ni fichier, ni phrase secrète — l\'autre côté doit accepter.';

  @override
  String get nearbySearching => 'Recherche d\'appareils…';

  @override
  String get nearbyNone =>
      'Rien trouvé pour l\'instant. Les deux téléphones doivent avoir cet écran ouvert et le Wi-Fi activé.';

  @override
  String get nearbySend => 'Envoyer';

  @override
  String nearbyWaiting(String name) {
    return 'En attente de l\'accord de $name…';
  }

  @override
  String nearbySendingTo(String name) {
    return 'Envoi à $name…';
  }

  @override
  String get nearbySentTo => 'Envoyé.';

  @override
  String get nearbyDeclined => 'Refusé.';

  @override
  String nearbyInvite(String name) {
    return '$name veut vous envoyer des documents.';
  }

  @override
  String get nearbyAccept => 'Accepter';

  @override
  String get nearbyDecline => 'Refuser';

  @override
  String get nearbyReceiving => 'Réception…';

  @override
  String get nearbyUnavailable =>
      'L\'envoi à proximité n\'est pas encore disponible sur cet appareil. Exportez plutôt un fichier.';

  @override
  String get nearbyName => 'Cet appareil apparaît sous le nom';

  @override
  String get actionCrop => 'Recadrer';

  @override
  String get leadCustom => 'Choisir une date';

  @override
  String get leadDailyTitle => 'Chaque jour le dernier mois';

  @override
  String get leadDailyBody =>
      'Quand un document expire dans un mois, Elapsa vous le rappelle chaque jour. Ce rappel-là n\'est pas facultatif.';

  @override
  String leadOnDate(String date) {
    return 'Le $date';
  }

  @override
  String get editUnsavedTitle => 'Garder vos modifications ?';

  @override
  String get editUnsavedBody =>
      'Ce document a des modifications non enregistrées.';

  @override
  String get editDiscard => 'Abandonner';

  @override
  String get nearbyRoleTitle => 'Envoyer ou recevoir ?';

  @override
  String get nearbyRoleSend => 'Envoyer depuis ce téléphone';

  @override
  String get nearbyRoleSendBody =>
      'Choisissez des documents et transmettez-les à un autre appareil.';

  @override
  String get nearbyRoleReceive => 'Recevoir sur ce téléphone';

  @override
  String get nearbyRoleReceiveBody =>
      'Attendre qu\'un autre appareil envoie. On vous demandera avant que quoi que ce soit n\'arrive.';

  @override
  String get nearbyWaitingToReceive => 'En attente d\'un appareil qui envoie…';

  @override
  String get nearbyWantsToSend => 'veut vous envoyer des documents';

  @override
  String get actionShare => 'Partager';

  @override
  String get homeArrange => 'Organiser';

  @override
  String get homeSortBy => 'Trier par';

  @override
  String get homeShowAs => 'Afficher chaque carte';

  @override
  String get detailTitle => 'Document';

  @override
  String get actionEdit => 'Modifier';

  @override
  String get detailReminders => 'Rappels';

  @override
  String detailNextReminder(String date) {
    return 'Prochain rappel le $date';
  }

  @override
  String get detailNoReminders => 'Aucun rappel programmé.';

  @override
  String detailPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String get settingsTypes => 'Vos propres types';

  @override
  String get typesBody =>
      'Elapsa propose onze types de documents et ne proposera jamais les onze bons. Nommez les vôtres : ils voyagent avec les cartes qui y sont classées.';

  @override
  String get typesAdd => 'Ajouter un type';

  @override
  String get typesName => 'Nom';

  @override
  String get typesLead => 'Rappeler';

  @override
  String get typesEmpty => 'Aucun pour l\'instant.';

  @override
  String typesInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Utilisé par $count documents',
      one: 'Utilisé par 1 document',
    );
    return '$_temp0';
  }

  @override
  String get typesRemove => 'Retirer';

  @override
  String get editLastScan => 'Ce que l\'appareil photo a lu';

  @override
  String get extrasTitle => 'Vos propres champs';

  @override
  String get extrasAdd => 'Ajouter un champ';

  @override
  String get extrasName => 'Nom du champ';

  @override
  String get extrasValue => 'Valeur';

  @override
  String get fieldNeverExpires => 'N\'expire jamais';

  @override
  String get fieldNoExpiry => 'Celui-ci n\'expire pas';

  @override
  String get homeSearch => 'Rechercher';

  @override
  String get homeSearchHint => 'Nom, type, numéro…';

  @override
  String get homeNoMatches => 'Aucun résultat.';

  @override
  String get detailIssuedBy => 'Pays de délivrance';

  @override
  String get fieldNumberPassport => 'Numéro de passeport';

  @override
  String get fieldNumberGeneric => 'Numéro du document';

  @override
  String get paywallTitle => 'Tous vos documents au même endroit';

  @override
  String paywallBody(int limit) {
    return 'La version gratuite conserve $limit documents. Débloquez un nombre illimité de documents en un seul achat.';
  }

  @override
  String get paywallPointUnlimited => 'Documents et rappels illimités';

  @override
  String get paywallPointOnce =>
      'Un seul paiement. Pas d\'abonnement, rien ne se renouvelle.';

  @override
  String get paywallPointPrivate =>
      'Toujours sans compte, et rien ne quitte votre téléphone.';

  @override
  String paywallBuy(String price) {
    return 'Débloquer pour $price';
  }

  @override
  String get paywallLoadingPrice => 'Récupération du prix…';

  @override
  String get paywallRestore => 'Restaurer l\'achat';

  @override
  String get paywallNotNow => 'Plus tard';

  @override
  String get paywallPending =>
      'En attente d\'approbation. Le déblocage apparaîtra dès que l\'achat sera approuvé.';

  @override
  String get paywallFailed => 'L\'achat n\'a pas abouti. Veuillez réessayer.';

  @override
  String get paywallNothingToRestore =>
      'Aucun achat antérieur trouvé pour ce compte.';

  @override
  String get paywallStoreUnavailable =>
      'Impossible de joindre la boutique pour le moment. Vérifiez votre connexion et réessayez.';

  @override
  String get paywallRetry => 'Réessayer';

  @override
  String get paywallThanks =>
      'Illimité est débloqué. Merci de soutenir Elapsa.';

  @override
  String get paywallRestored =>
      'Bon retour — Illimité est de nouveau débloqué.';

  @override
  String paywallImportBlocked(int limit) {
    return 'Non importé. La version gratuite conserve $limit documents.';
  }

  @override
  String get settingsUnlimited => 'Elapsa Illimité';

  @override
  String get settingsUnlimitedOn =>
      'Débloqué. Ajoutez autant de documents que vous voulez.';

  @override
  String settingsUnlimitedUsage(int count, int limit) {
    return '$count sur $limit documents gratuits utilisés';
  }

  @override
  String get settingsUnlimitedUnlock => 'Débloquer Illimité';
}
