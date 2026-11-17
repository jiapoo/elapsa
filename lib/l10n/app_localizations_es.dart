// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class LEs extends L {
  LEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Elapsa';

  @override
  String get homeNeedsAttention => 'Requiere atención';

  @override
  String get homeEverythingElse => 'Todo lo demás';

  @override
  String get homeEmptyTitle => 'Nada por caducar';

  @override
  String get homeEmptyBody =>
      'Añade un pasaporte, DNI o carné y Elapsa te dirá cuándo empezar a renovarlo, no cuando ya sea demasiado tarde.';

  @override
  String get actionAdd => 'Añadir documento';

  @override
  String get actionScan => 'Escanear documento';

  @override
  String get actionSettings => 'Ajustes';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get actionDone => 'Listo';

  @override
  String get actionRetake => 'Repetir';

  @override
  String get actionSaveToPhotos => 'Guardar en Fotos';

  @override
  String get actionSaveToFiles => 'Guardar en Archivos';

  @override
  String get photoSavedToPhotos => 'Guardado en Fotos';

  @override
  String get photoSavedToFiles => 'Guardado en Archivos';

  @override
  String get photoSaveFailed => 'No se pudo guardar la imagen.';

  @override
  String get photoPhotosDenied =>
      'Elapsa no tiene permiso para añadir a Fotos. Puedes permitirlo en Ajustes.';

  @override
  String get photoExportNote =>
      'Una copia guardada fuera de Elapsa no está cifrada.';

  @override
  String get attachmentsTitle => 'Adjuntos';

  @override
  String get attachmentsAdd => 'Añadir adjunto';

  @override
  String get attachmentsAddFile => 'Archivo';

  @override
  String get attachmentsAddFileHint =>
      'PDF, documento o cualquier otro archivo';

  @override
  String get attachmentsAddLink => 'Enlace';

  @override
  String get attachmentsAddLinkHint =>
      'Una página web, como el formulario de renovación';

  @override
  String get attachmentsLinkTitle => 'Añadir un enlace';

  @override
  String get attachmentsLinkUrl => 'Dirección web';

  @override
  String get attachmentsLinkName => 'Nombre (opcional)';

  @override
  String get attachmentsLinkInvalid => 'Eso no parece una dirección web.';

  @override
  String get attachmentsTooLarge =>
      'Ese archivo supera los 50 MB y es demasiado grande para adjuntarlo.';

  @override
  String attachmentsSkippedTooLarge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos superan los 50 MB y se han omitido.',
      one: '1 archivo supera los 50 MB y se ha omitido.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentsCannotOpen => 'No se pudo abrir este adjunto.';

  @override
  String get attachmentsRemoveTitle => '¿Quitar este adjunto?';

  @override
  String get attachmentsRemoveBody =>
      'Se eliminará la copia guardada en Elapsa. No se puede deshacer.';

  @override
  String get actionRemove => 'Quitar';

  @override
  String get actionAddShort => 'Añadir';

  @override
  String get statusExpired => 'Caducado';

  @override
  String get statusExpiring => 'Por caducar';

  @override
  String get statusRenewNow => 'Renueva ya';

  @override
  String get statusValid => 'Vigente';

  @override
  String daysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'quedan $days días',
      one: 'queda 1 día',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'hace $days días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get startRenewingNow => 'empieza a renovar ya';

  @override
  String get travelRuleBadge => 'Por debajo de la regla de 6 meses para viajar';

  @override
  String remindersTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recordatorios programados',
      one: '1 recordatorio programado',
      zero: 'Ningún recordatorio programado',
    );
    return '$_temp0';
  }

  @override
  String get remindersEmptyBody =>
      'Añade un documento y Elapsa programará sus recordatorios.';

  @override
  String get remindersBody => 'Llegan aunque nunca abras la app.';

  @override
  String get editAddTitle => 'Añadir documento';

  @override
  String get editEditTitle => 'Editar documento';

  @override
  String get editScanHelp => 'Lee el código de un pasaporte, DNI o visado';

  @override
  String get editFromScanNote =>
      'Rellenado a partir del código del documento. Puedes cambiar cualquier campo.';

  @override
  String get editScanNothingRead =>
      'Foto guardada. No hay nada legible en esta cara: rellena los datos abajo.';

  @override
  String get editScanRepaired =>
      'Escaneado: el código estaba algo borroso, revisa los datos.';

  @override
  String get scanExpiredTitle => 'Este documento ya ha caducado';

  @override
  String scanExpiredBody(String date) {
    return 'La fecha de caducidad es el $date y ya ha pasado. Empieza a renovarlo ahora o, si la fecha se leyó mal, corrígela abajo.';
  }

  @override
  String get scanExpiredOk => 'Entendido';

  @override
  String get fieldType => 'Tipo';

  @override
  String get fieldName => 'Nombre';

  @override
  String fieldNameHint(String type) {
    return 'Mi $type';
  }

  @override
  String get fieldNameRequired => 'Ponle un nombre';

  @override
  String get fieldExpiry => 'Fecha de caducidad';

  @override
  String get fieldExpiryEmpty => 'Elige una fecha';

  @override
  String get fieldExpiryRequired => 'Elige una fecha de caducidad';

  @override
  String get fieldIssueDate => 'Válido desde';

  @override
  String get fieldRemindMe => 'Empezar a recordarme';

  @override
  String get fieldOptional => 'Opcional';

  @override
  String get fieldHolderHint => 'De quién es';

  @override
  String get fieldNumberHint => 'Número de documento';

  @override
  String get fieldNumberLabel => 'Número de tarjeta';

  @override
  String get imageOptionsTitle => '¿Repetir o eliminar esta foto?';

  @override
  String get fieldImages => 'Fotos';

  @override
  String get editSave => 'Guardar';

  @override
  String get editDeleteTitle => '¿Eliminar este documento?';

  @override
  String get editDeleteBody =>
      'También se eliminarán sus recordatorios y fotos.';

  @override
  String leadExplainNoDate(String lead) {
    return 'Elapsa te avisará $lead antes de que caduque, y de nuevo a medida que se acerque la fecha.';
  }

  @override
  String leadExplainFirst(String date) {
    return 'Primer recordatorio el $date, y de nuevo a medida que se acerque la fecha.';
  }

  @override
  String get leadExplainPassed =>
      'Ese plazo ya ha pasado: deberías empezar ahora.';

  @override
  String leadWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks semanas',
      one: '1 semana',
    );
    return '$_temp0';
  }

  @override
  String leadMonths(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months meses',
      one: '1 mes',
    );
    return '$_temp0';
  }

  @override
  String leadYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years años',
      one: '1 año',
    );
    return '$_temp0';
  }

  @override
  String get sixMonthRuleNote =>
      'Muchos países exigen seis meses de validez desde la fecha de entrada, así que este documento deja de servir para viajar unos seis meses antes de caducar.';

  @override
  String get typePassport => 'Pasaporte';

  @override
  String get typeNationalId => 'Documento de identidad';

  @override
  String get typeDriversLicence => 'Carné de conducir';

  @override
  String get typeVisa => 'Visado';

  @override
  String get typeResidencePermit => 'Permiso de residencia';

  @override
  String get typeVehicleRegistration => 'Permiso de circulación';

  @override
  String get typeInsurance => 'Seguro';

  @override
  String get typeProfessionalLicence => 'Licencia profesional';

  @override
  String get typeMembership => 'Membresía';

  @override
  String get typeBankCard => 'Tarjeta bancaria';

  @override
  String get typeOther => 'Otro';

  @override
  String get scanTitle => 'Escanear documento';

  @override
  String get scanHintSearching => 'Apunta al documento y mantenlo plano';

  @override
  String get scanHintFound => 'No te muevas';

  @override
  String get scanHintNoCamera =>
      'Este dispositivo no tiene cámara: lee el código desde una foto';

  @override
  String get scanChoosePhoto => 'Elegir una foto';

  @override
  String get scanEnterByHand => 'Introducir a mano';

  @override
  String get scanNoCameraTitle => 'Escanear desde una foto';

  @override
  String get scanNoCameraBody =>
      'Elapsa puede leer el código de una foto de un documento que ya tengas.';

  @override
  String get scanFailedNoCode =>
      'No se encontró ningún código. Llena el marco con la tarjeta y asegúrate de que las líneas de código de abajo se vean nítidas.';

  @override
  String get scanFailedUnreadable =>
      'Se encontró el código, pero no se pudo leer bien. Prueba con menos reflejos o introduce los datos a mano.';

  @override
  String get scanFailedPhoto => 'No se pudo leer esa foto.';

  @override
  String get scanFailedCapture =>
      'No se pudo hacer la foto. Inténtalo de nuevo.';

  @override
  String scanPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotos',
      one: '1 foto',
    );
    return '$_temp0';
  }

  @override
  String get scanAddAnother => 'Añadir la otra cara';

  @override
  String get scanSideFront => 'Anverso';

  @override
  String get scanSideBack => 'Reverso';

  @override
  String get detailCardholderName => 'Nombre en la tarjeta';

  @override
  String get detailSecurityCode => 'Código de seguridad';

  @override
  String get detailNationality => 'Nacionalidad';

  @override
  String get detailPlaceOfIssue => 'Lugar de expedición';

  @override
  String get detailIssuingAuthority => 'Expedido por';

  @override
  String get detailLicenceClass => 'Clase';

  @override
  String get detailPolicyNumber => 'Número de póliza';

  @override
  String get detailPlateNumber => 'Matrícula';

  @override
  String get detailVehicleIdentification => 'Número de bastidor';

  @override
  String get detailMembershipLevel => 'Nivel';

  @override
  String get detailSensitiveNote =>
      'Oculto por defecto, cifrado en este dispositivo, nunca se sube.';

  @override
  String get detailReveal => 'Mostrar';

  @override
  String get detailHide => 'Ocultar';

  @override
  String get sortTitle => 'Ordenar';

  @override
  String get sortExpiry => 'Fecha de caducidad';

  @override
  String get sortAdded => 'Añadidos recientemente';

  @override
  String get sortName => 'Nombre';

  @override
  String get sortType => 'Tipo';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Idioma del sistema';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsPrivacyTitle => 'Todo se queda en este dispositivo';

  @override
  String get settingsPrivacyBody =>
      'Tus documentos, sus fotos y sus números se cifran y se guardan solo en este teléfono. Elapsa no tiene cuenta ni servidor, y nunca se sube nada.';

  @override
  String settingsVersion(String version) {
    return 'Versión $version';
  }

  @override
  String notifyRenewTitle(String type) {
    return 'Hora de renovar: $type';
  }

  @override
  String notifyExpiresTitle(String label, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    return '$label caduca en $_temp0';
  }

  @override
  String notifyRenewBody(String date) {
    return 'Caduca el $date. Hay margen para renovarlo sin prisas: empieza ahora y estará listo a tiempo.';
  }

  @override
  String notifyTravelBody(String date) {
    return 'Caduca el $date. Muchos países exigen seis meses de validez, así que puede que ya no sirva para viajar.';
  }

  @override
  String notifyPlainBody(String date) {
    return 'Caduca el $date.';
  }

  @override
  String get notifyChannelName => 'Recordatorios de renovación';

  @override
  String get notifyChannelDescription =>
      'Te dice cuándo empezar a renovar un documento, no cuando ya es tarde.';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Igual que el dispositivo';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get settingsWallet => 'Pantalla de inicio';

  @override
  String get settingsWalletDisplay => 'Mostrar cada tarjeta como';

  @override
  String get displayNameOnly => 'Solo nombre';

  @override
  String get displayImageOnly => 'Solo foto';

  @override
  String get displayNameAndImage => 'Nombre y foto';

  @override
  String get displayNameOnlyBody =>
      'Una lista compacta. Nada en pantalla que alguien pueda leer por encima de tu hombro.';

  @override
  String get displayImageOnlyBody =>
      'Tus propias fotos, como una cartera abierta.';

  @override
  String get displayNameAndImageBody =>
      'La foto con el nombre y la caducidad debajo.';

  @override
  String get settingsRemindersTitle => 'Recordatorios';

  @override
  String get settingsRemindersLead => 'Recordar por defecto';

  @override
  String get settingsRemindersBody =>
      'Se aplica a los documentos nuevos. Cada uno se puede cambiar por separado.';

  @override
  String get settingsRemindersAuto => 'Elegir para cada documento';

  @override
  String get settingsScheduled => 'Recordatorios programados';

  @override
  String get settingsResync => 'Rehacer la programación';

  @override
  String get settingsResyncDone => 'Programación de recordatorios rehecha.';

  @override
  String get settingsDiagnostics => 'Diagnóstico';

  @override
  String get settingsLastScan => 'Último escaneo';

  @override
  String get settingsLastScanBody =>
      'Exactamente lo que leyó la cámara, antes de que Elapsa lo interpretara. Útil cuando un campo sale vacío.';

  @override
  String get settingsLastScanEmpty =>
      'Aún no se ha escaneado nada en esta sesión.';

  @override
  String get actionCopy => 'Copiar';

  @override
  String get settingsCopied => 'Copiado.';

  @override
  String countYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years años',
      one: '1 año',
    );
    return '$_temp0';
  }

  @override
  String countDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String durationLeft(String duration) {
    return 'quedan $duration';
  }

  @override
  String durationAgo(String duration) {
    return 'hace $duration';
  }

  @override
  String get settingsTransfer => 'Transferir';

  @override
  String get transferExport => 'Exportar todo';

  @override
  String get transferExportBody =>
      'Todos los documentos y fotos en un solo archivo cifrado. Envíalo a tu otro teléfono como quieras: AirDrop, Archivos, un cable. También es la única copia de seguridad de Elapsa: nada se guarda fuera de este dispositivo.';

  @override
  String get transferImport => 'Importar desde un archivo';

  @override
  String get transferImportBody =>
      'Abre un archivo exportado desde otro dispositivo.';

  @override
  String get transferPassphrase => 'Frase de contraseña';

  @override
  String get transferPassphraseNew => 'Elige una frase de contraseña';

  @override
  String get transferPassphraseNewBody =>
      'Necesitarás exactamente esta frase para abrir el archivo en el otro teléfono. Nadie puede recuperarla por ti, ni siquiera Elapsa, y eso es lo que protege el archivo si se extravía.';

  @override
  String get transferPassphraseAsk =>
      'Introduce la frase de contraseña con la que se creó este archivo.';

  @override
  String get transferPassphraseShort => 'Al menos 8 caracteres.';

  @override
  String transferExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documentos archivados.',
      one: '1 documento archivado.',
    );
    return '$_temp0';
  }

  @override
  String transferImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documentos importados.',
      one: '1 documento importado.',
    );
    return '$_temp0';
  }

  @override
  String get transferNothing => 'Aún no hay nada que exportar.';

  @override
  String get transferMergeTitle => '¿Cómo importar?';

  @override
  String get transferMerge => 'Combinar';

  @override
  String get transferMergeBody =>
      'Conservar lo que hay aquí y añadir lo del archivo.';

  @override
  String get transferReplace => 'Reemplazar todo';

  @override
  String get transferReplaceBody =>
      'Eliminar antes todos los documentos de este teléfono.';

  @override
  String get transferFailedFile => 'No es un archivo de Elapsa.';

  @override
  String get transferFailedNew =>
      'Este archivo se creó con una versión más reciente de Elapsa.';

  @override
  String get transferFailedKey =>
      'Frase de contraseña incorrecta, o el archivo está dañado.';

  @override
  String get actionContinue => 'Continuar';

  @override
  String shortYears(int years) {
    return '$years a';
  }

  @override
  String shortDays(int days) {
    return '$days d';
  }

  @override
  String get shortExpired => 'CAD';

  @override
  String get transferProtect => 'Proteger con frase de contraseña';

  @override
  String get transferProtectBody =>
      'Se deja activado para un archivo, que sobrevive al traspaso: después queda en Archivos en ambos lados. Desactívalo solo para un archivo que vayas a importar y borrar enseguida.';

  @override
  String get transferChoose => 'Elige qué enviar';

  @override
  String get transferAll => 'Todos';

  @override
  String get transferNone => 'Ninguno';

  @override
  String transferSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documentos',
      one: '1 documento',
      zero: 'Nada seleccionado',
    );
    return '$_temp0';
  }

  @override
  String get cropTitle => 'Arrastra las esquinas';

  @override
  String get cropBody => 'Pon una esquina en cada esquina del documento.';

  @override
  String get cropReset => 'Restablecer';

  @override
  String get scanAdjust => 'Ajustar el recorte';

  @override
  String get scanAutoOn => 'Detección automática activada';

  @override
  String get scanAutoOff => 'Detección automática desactivada';

  @override
  String get scanAutoStuck => '¿No encuentra el documento?';

  @override
  String get scanAutoStuckAction => 'Pasar a manual';

  @override
  String get nearbyTitle => 'Transferir con un dispositivo cercano';

  @override
  String get nearbyBody =>
      'Abre Elapsa en el otro teléfono y ve a esta pantalla. Sin archivo ni contraseña: el otro lado tiene que aceptar.';

  @override
  String get nearbySearching => 'Buscando dispositivos…';

  @override
  String get nearbyNone =>
      'Aún no se ha encontrado nada. Los dos teléfonos necesitan esta pantalla abierta y la Wi-Fi activada.';

  @override
  String get nearbySend => 'Enviar';

  @override
  String nearbyWaiting(String name) {
    return 'Esperando a que $name acepte…';
  }

  @override
  String nearbySendingTo(String name) {
    return 'Enviando a $name…';
  }

  @override
  String get nearbySentTo => 'Enviado.';

  @override
  String get nearbyDeclined => 'Lo ha rechazado.';

  @override
  String nearbyInvite(String name) {
    return '$name quiere enviarte documentos.';
  }

  @override
  String get nearbyAccept => 'Aceptar';

  @override
  String get nearbyDecline => 'Rechazar';

  @override
  String get nearbyReceiving => 'Recibiendo…';

  @override
  String get nearbyUnavailable =>
      'El envío a dispositivos cercanos aún no está disponible en este dispositivo. Exporta un archivo.';

  @override
  String get nearbyName => 'Este dispositivo aparece como';

  @override
  String get actionCrop => 'Recortar';

  @override
  String get leadCustom => 'Elegir una fecha';

  @override
  String get leadDailyTitle => 'Cada día durante el último mes';

  @override
  String get leadDailyBody =>
      'Cuando a un documento le queda un mes, Elapsa te lo recuerda a diario. Ese no es opcional.';

  @override
  String leadOnDate(String date) {
    return 'El $date';
  }

  @override
  String get editUnsavedTitle => '¿Conservar los cambios?';

  @override
  String get editUnsavedBody => 'Este documento tiene cambios sin guardar.';

  @override
  String get editDiscard => 'Descartar';

  @override
  String get nearbyRoleTitle => '¿Enviar o recibir?';

  @override
  String get nearbyRoleSend => 'Enviar desde este teléfono';

  @override
  String get nearbyRoleSendBody =>
      'Elige documentos y pásalos a otro dispositivo.';

  @override
  String get nearbyRoleReceive => 'Recibir en este teléfono';

  @override
  String get nearbyRoleReceiveBody =>
      'Espera a que otro dispositivo envíe. Se te preguntará antes de que llegue nada.';

  @override
  String get nearbyWaitingToReceive => 'Esperando a que un dispositivo envíe…';

  @override
  String get nearbyWantsToSend => 'quiere enviarte documentos';

  @override
  String get actionShare => 'Compartir';

  @override
  String get homeArrange => 'Organizar';

  @override
  String get homeSortBy => 'Ordenar por';

  @override
  String get homeShowAs => 'Mostrar cada tarjeta como';

  @override
  String get detailTitle => 'Documento';

  @override
  String get actionEdit => 'Editar';

  @override
  String get detailReminders => 'Recordatorios';

  @override
  String detailNextReminder(String date) {
    return 'Próximo recordatorio el $date';
  }

  @override
  String get detailNoReminders => 'Ningún recordatorio programado.';

  @override
  String detailPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotos',
      one: '1 foto',
    );
    return '$_temp0';
  }

  @override
  String get settingsTypes => 'Tus propios tipos';

  @override
  String get typesBody =>
      'Elapsa trae once tipos de documento y nunca traerá los once adecuados. Ponle nombre a los tuyos: viajan con las tarjetas archivadas en ellos.';

  @override
  String get typesAdd => 'Añadir un tipo';

  @override
  String get typesName => 'Nombre';

  @override
  String get typesLead => 'Empezar a recordar';

  @override
  String get typesEmpty => 'Ninguno todavía.';

  @override
  String typesInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Usado por $count documentos',
      one: 'Usado por 1 documento',
    );
    return '$_temp0';
  }

  @override
  String get typesRemove => 'Quitar';

  @override
  String get editLastScan => 'Lo que leyó la cámara';

  @override
  String get extrasTitle => 'Tus propios campos';

  @override
  String get extrasAdd => 'Añadir un campo';

  @override
  String get extrasName => 'Nombre del campo';

  @override
  String get extrasValue => 'Valor';

  @override
  String get fieldNeverExpires => 'No caduca';

  @override
  String get fieldNoExpiry => 'Este no caduca';

  @override
  String get homeSearch => 'Buscar';

  @override
  String get homeSearchHint => 'Nombre, tipo, número…';

  @override
  String get homeNoMatches => 'No hay coincidencias.';

  @override
  String get detailIssuedBy => 'País de expedición';

  @override
  String get fieldNumberPassport => 'Número de pasaporte';

  @override
  String get fieldNumberGeneric => 'Número de documento';

  @override
  String get paywallTitle => 'Todos tus documentos en un solo lugar';

  @override
  String paywallBody(int limit) {
    return 'La versión gratuita guarda $limit documentos. Desbloquea documentos ilimitados con una sola compra.';
  }

  @override
  String get paywallPointUnlimited => 'Documentos y recordatorios ilimitados';

  @override
  String get paywallPointOnce =>
      'Pagas una vez. Sin suscripción, nada se renueva.';

  @override
  String get paywallPointPrivate =>
      'Sigue sin cuenta, y nada sale de tu teléfono.';

  @override
  String paywallBuy(String price) {
    return 'Desbloquear por $price';
  }

  @override
  String get paywallLoadingPrice => 'Obteniendo el precio…';

  @override
  String get paywallRestore => 'Restaurar compra';

  @override
  String get paywallNotNow => 'Ahora no';

  @override
  String get paywallPending =>
      'Pendiente de aprobación. El desbloqueo aparecerá en cuanto se apruebe la compra.';

  @override
  String get paywallFailed => 'La compra no se completó. Inténtalo de nuevo.';

  @override
  String get paywallNothingToRestore =>
      'No se encontró ninguna compra anterior para esta cuenta.';

  @override
  String get paywallStoreUnavailable =>
      'No se puede conectar con la tienda ahora mismo. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get paywallRetry => 'Reintentar';

  @override
  String get paywallThanks =>
      'Ilimitado está desbloqueado. Gracias por apoyar Elapsa.';

  @override
  String get paywallRestored =>
      'Bienvenido de nuevo: Ilimitado vuelve a estar desbloqueado.';

  @override
  String paywallImportBlocked(int limit) {
    return 'No se importó. La versión gratuita guarda $limit documentos.';
  }

  @override
  String get settingsUnlimited => 'Elapsa Ilimitado';

  @override
  String get settingsUnlimitedOn =>
      'Desbloqueado. Añade todos los documentos que quieras.';

  @override
  String settingsUnlimitedUsage(int count, int limit) {
    return '$count de $limit documentos gratuitos usados';
  }

  @override
  String get settingsUnlimitedUnlock => 'Desbloquear Ilimitado';
}
