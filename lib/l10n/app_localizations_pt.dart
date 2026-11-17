// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class LPt extends L {
  LPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Elapsa';

  @override
  String get homeNeedsAttention => 'Precisa de atenção';

  @override
  String get homeEverythingElse => 'Todo o resto';

  @override
  String get homeEmptyTitle => 'Nada vencendo';

  @override
  String get homeEmptyBody =>
      'Adicione um passaporte, RG ou CNH e o Elapsa avisará quando começar a renovar — não quando já for tarde demais.';

  @override
  String get actionAdd => 'Adicionar documento';

  @override
  String get actionScan => 'Escanear documento';

  @override
  String get actionSettings => 'Ajustes';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionDelete => 'Apagar';

  @override
  String get actionDone => 'OK';

  @override
  String get actionRetake => 'Refazer';

  @override
  String get statusExpired => 'Vencido';

  @override
  String get statusExpiring => 'Vencendo';

  @override
  String get statusRenewNow => 'Renove já';

  @override
  String get statusValid => 'Válido';

  @override
  String daysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'faltam $days dias',
      one: 'falta 1 dia',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'há $days dias',
      one: 'há 1 dia',
    );
    return '$_temp0';
  }

  @override
  String get startRenewingNow => 'comece a renovar agora';

  @override
  String get travelRuleBadge => 'Abaixo da regra de 6 meses para viagem';

  @override
  String remindersTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lembretes agendados',
      one: '1 lembrete agendado',
      zero: 'Nenhum lembrete agendado',
    );
    return '$_temp0';
  }

  @override
  String get remindersEmptyBody =>
      'Adicione um documento e o Elapsa agendará os lembretes.';

  @override
  String get remindersBody => 'Eles chegam mesmo que o app nunca seja aberto.';

  @override
  String get editAddTitle => 'Adicionar documento';

  @override
  String get editEditTitle => 'Editar documento';

  @override
  String get editScanHelp => 'Lê o código de passaporte, RG ou visto';

  @override
  String get editFromScanNote =>
      'Preenchido pelo código do documento. Você ainda pode alterar qualquer campo.';

  @override
  String get editScanNothingRead =>
      'Foto salva. Não há nada legível deste lado — preencha os dados abaixo.';

  @override
  String get editScanRepaired =>
      'Escaneado — o código estava um pouco borrado, confira os dados.';

  @override
  String get fieldType => 'Tipo';

  @override
  String get fieldName => 'Nome';

  @override
  String fieldNameHint(String type) {
    return 'Ex.: $type';
  }

  @override
  String get fieldNameRequired => 'Dê um nome';

  @override
  String get fieldExpiry => 'Data de validade';

  @override
  String get fieldExpiryEmpty => 'Selecione uma data';

  @override
  String get fieldExpiryRequired => 'Escolha a data de validade';

  @override
  String get fieldIssueDate => 'Válido a partir de';

  @override
  String get fieldRemindMe => 'Começar a lembrar';

  @override
  String get fieldOptional => 'Opcional';

  @override
  String get fieldHolderHint => 'De quem é';

  @override
  String get fieldNumberHint => 'Número do documento';

  @override
  String get fieldNumberLabel => 'Número do cartão';

  @override
  String get imageOptionsTitle => 'Refazer ou apagar esta foto?';

  @override
  String get fieldImages => 'Fotos';

  @override
  String get editSave => 'Salvar';

  @override
  String get editDeleteTitle => 'Apagar este documento?';

  @override
  String get editDeleteBody =>
      'Os lembretes e as fotos dele também serão apagados.';

  @override
  String leadExplainNoDate(String lead) {
    return 'O Elapsa vai lembrar você $lead antes do vencimento e de novo conforme a data se aproxima.';
  }

  @override
  String leadExplainFirst(String date) {
    return 'Primeiro lembrete em $date, e de novo conforme a data se aproxima.';
  }

  @override
  String get leadExplainPassed =>
      'Esse prazo já passou — é melhor começar agora.';

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
      one: '1 mês',
    );
    return '$_temp0';
  }

  @override
  String leadYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years anos',
      one: '1 ano',
    );
    return '$_temp0';
  }

  @override
  String get sixMonthRuleNote =>
      'Muitos países exigem seis meses de validade além da data de entrada, então este documento deixa de servir para viagens cerca de seis meses antes de vencer.';

  @override
  String get typePassport => 'Passaporte';

  @override
  String get typeNationalId => 'RG';

  @override
  String get typeDriversLicence => 'CNH';

  @override
  String get typeVisa => 'Visto';

  @override
  String get typeResidencePermit => 'Autorização de residência';

  @override
  String get typeVehicleRegistration => 'Documento do veículo';

  @override
  String get typeInsurance => 'Seguro';

  @override
  String get typeProfessionalLicence => 'Registro profissional';

  @override
  String get typeMembership => 'Associação';

  @override
  String get typeBankCard => 'Cartão bancário';

  @override
  String get typeOther => 'Outro';

  @override
  String get scanTitle => 'Escanear documento';

  @override
  String get scanHintSearching => 'Aponte para o documento, mantenha-o reto';

  @override
  String get scanHintFound => 'Segure firme';

  @override
  String get scanHintNoCamera =>
      'Este aparelho não tem câmera — leia o código a partir de uma foto';

  @override
  String get scanChoosePhoto => 'Escolher uma foto';

  @override
  String get scanEnterByHand => 'Digitar os dados';

  @override
  String get scanNoCameraTitle => 'Escanear de uma foto';

  @override
  String get scanNoCameraBody =>
      'O Elapsa consegue ler o código a partir da foto de um documento que você já tem.';

  @override
  String get scanFailedNoCode =>
      'Nenhum código encontrado. Preencha o quadro com o cartão e garanta que as linhas de código na parte de baixo estejam nítidas.';

  @override
  String get scanFailedUnreadable =>
      'O código foi encontrado, mas não deu para ler direito. Tente de novo com menos reflexo ou digite os dados.';

  @override
  String get scanFailedPhoto => 'Não foi possível ler essa foto.';

  @override
  String get scanFailedCapture =>
      'Não foi possível tirar a foto. Tente de novo.';

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
  String get scanAddAnother => 'Adicionar o outro lado';

  @override
  String get scanSideFront => 'Frente';

  @override
  String get scanSideBack => 'Verso';

  @override
  String get detailCardholderName => 'Nome no cartão';

  @override
  String get detailSecurityCode => 'Código de segurança';

  @override
  String get detailNationality => 'Nacionalidade';

  @override
  String get detailPlaceOfIssue => 'Local de emissão';

  @override
  String get detailIssuingAuthority => 'Emitido por';

  @override
  String get detailLicenceClass => 'Categoria';

  @override
  String get detailPolicyNumber => 'Número da apólice';

  @override
  String get detailPlateNumber => 'Placa';

  @override
  String get detailVehicleIdentification => 'Chassi';

  @override
  String get detailMembershipLevel => 'Nível';

  @override
  String get detailSensitiveNote =>
      'Oculto por padrão, criptografado neste aparelho, nunca enviado.';

  @override
  String get detailReveal => 'Mostrar';

  @override
  String get detailHide => 'Ocultar';

  @override
  String get sortTitle => 'Ordenar';

  @override
  String get sortExpiry => 'Data de validade';

  @override
  String get sortAdded => 'Adicionados recentemente';

  @override
  String get sortName => 'Nome';

  @override
  String get sortType => 'Tipo';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Padrão do sistema';

  @override
  String get settingsAbout => 'Sobre';

  @override
  String get settingsPrivacyTitle => 'Tudo fica neste aparelho';

  @override
  String get settingsPrivacyBody =>
      'Seus documentos, fotos e números são criptografados e guardados só neste celular. O Elapsa não tem conta nem servidor, e nada é enviado.';

  @override
  String settingsVersion(String version) {
    return 'Versão $version';
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
      other: '$days dias',
      one: '1 dia',
    );
    return '$label vence em $_temp0';
  }

  @override
  String notifyRenewBody(String date) {
    return 'Vence em $date. Dá tempo de renovar sem pressa — comece agora e fica pronto a tempo.';
  }

  @override
  String notifyTravelBody(String date) {
    return 'Vence em $date. Muitos países exigem seis meses de validade, então talvez já não sirva para viagens.';
  }

  @override
  String notifyPlainBody(String date) {
    return 'Vence em $date.';
  }

  @override
  String get notifyChannelName => 'Lembretes de renovação';

  @override
  String get notifyChannelDescription =>
      'Avisa quando começar a renovar um documento, não quando já é tarde.';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Igual ao aparelho';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get settingsWallet => 'Tela inicial';

  @override
  String get settingsWalletDisplay => 'Mostrar cada cartão como';

  @override
  String get displayNameOnly => 'Só o nome';

  @override
  String get displayImageOnly => 'Só a foto';

  @override
  String get displayNameAndImage => 'Nome e foto';

  @override
  String get displayNameOnlyBody =>
      'Uma lista compacta. Nada na tela que alguém possa ler por cima do seu ombro.';

  @override
  String get displayImageOnlyBody =>
      'Suas próprias fotos, como uma carteira aberta.';

  @override
  String get displayNameAndImageBody =>
      'A foto com o nome e a validade embaixo.';

  @override
  String get settingsRemindersTitle => 'Lembretes';

  @override
  String get settingsRemindersLead => 'Lembrar por padrão';

  @override
  String get settingsRemindersBody =>
      'Vale para documentos novos. Cada um ainda pode ser alterado separadamente.';

  @override
  String get settingsRemindersAuto => 'Escolher para cada documento';

  @override
  String get settingsScheduled => 'Lembretes agendados';

  @override
  String get settingsResync => 'Refazer a agenda';

  @override
  String get settingsResyncDone => 'Agenda de lembretes refeita.';

  @override
  String get settingsDiagnostics => 'Diagnóstico';

  @override
  String get settingsLastScan => 'Último escaneamento';

  @override
  String get settingsLastScanBody =>
      'Exatamente o que a câmera leu, antes de o Elapsa interpretar. Útil quando um campo volta vazio.';

  @override
  String get settingsLastScanEmpty => 'Nada escaneado nesta sessão ainda.';

  @override
  String get actionCopy => 'Copiar';

  @override
  String get settingsCopied => 'Copiado.';

  @override
  String countYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years anos',
      one: '1 ano',
    );
    return '$_temp0';
  }

  @override
  String countDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String durationLeft(String duration) {
    return 'faltam $duration';
  }

  @override
  String durationAgo(String duration) {
    return 'há $duration';
  }

  @override
  String get settingsTransfer => 'Transferir';

  @override
  String get transferExport => 'Exportar tudo';

  @override
  String get transferExportBody =>
      'Todos os documentos e fotos em um único arquivo criptografado. Envie para o seu outro celular como preferir — AirDrop, Arquivos, um cabo. É também o único backup do Elapsa: nada fica guardado em outro lugar além deste aparelho.';

  @override
  String get transferImport => 'Importar de um arquivo';

  @override
  String get transferImportBody =>
      'Abrir um arquivo exportado de outro aparelho.';

  @override
  String get transferPassphrase => 'Frase-senha';

  @override
  String get transferPassphraseNew => 'Escolha uma frase-senha';

  @override
  String get transferPassphraseNewBody =>
      'Você vai precisar exatamente desta frase-senha para abrir o arquivo no outro celular. Ninguém consegue recuperá-la — nem o Elapsa, e é isso que protege o arquivo se ele se perder.';

  @override
  String get transferPassphraseAsk =>
      'Digite a frase-senha usada para criar este arquivo.';

  @override
  String get transferPassphraseShort => 'Pelo menos 8 caracteres.';

  @override
  String transferExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documentos arquivados.',
      one: '1 documento arquivado.',
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
  String get transferNothing => 'Nada para exportar ainda.';

  @override
  String get transferMergeTitle => 'Como importar?';

  @override
  String get transferMerge => 'Mesclar';

  @override
  String get transferMergeBody =>
      'Manter o que já está aqui e adicionar o que está no arquivo.';

  @override
  String get transferReplace => 'Substituir tudo';

  @override
  String get transferReplaceBody =>
      'Apagar antes todos os documentos deste celular.';

  @override
  String get transferFailedFile => 'Isso não é um arquivo do Elapsa.';

  @override
  String get transferFailedNew =>
      'Este arquivo foi criado por uma versão mais nova do Elapsa.';

  @override
  String get transferFailedKey =>
      'Frase-senha errada, ou o arquivo está danificado.';

  @override
  String get actionContinue => 'Continuar';

  @override
  String shortYears(int years) {
    return '${years}a';
  }

  @override
  String shortDays(int days) {
    return '${days}d';
  }

  @override
  String get shortExpired => 'VENC';

  @override
  String get transferProtect => 'Proteger com frase-senha';

  @override
  String get transferProtectBody =>
      'Fica ligado para um arquivo, que continua existindo depois da troca — fica em Arquivos nos dois lados. Desligue só para um arquivo que você vai importar e apagar em seguida.';

  @override
  String get transferChoose => 'Escolher o que enviar';

  @override
  String get transferAll => 'Todos';

  @override
  String get transferNone => 'Nenhum';

  @override
  String transferSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documentos',
      one: '1 documento',
      zero: 'Nada selecionado',
    );
    return '$_temp0';
  }

  @override
  String get cropTitle => 'Arraste os cantos';

  @override
  String get cropBody => 'Coloque um canto em cada canto do documento.';

  @override
  String get cropReset => 'Redefinir';

  @override
  String get scanAdjust => 'Ajustar o corte';

  @override
  String get scanAutoOn => 'Detecção automática ligada';

  @override
  String get scanAutoOff => 'Detecção automática desligada';

  @override
  String get scanAutoStuck => 'Não encontra o documento?';

  @override
  String get scanAutoStuckAction => 'Mudar para manual';

  @override
  String get nearbyTitle => 'Transferir com um aparelho próximo';

  @override
  String get nearbyBody =>
      'Abra o Elapsa no outro celular e venha para esta tela. Sem arquivo, sem frase-senha — o outro lado precisa aceitar.';

  @override
  String get nearbySearching => 'Procurando aparelhos…';

  @override
  String get nearbyNone =>
      'Nada encontrado ainda. Os dois celulares precisam estar nesta tela e com o Wi-Fi ligado.';

  @override
  String get nearbySend => 'Enviar';

  @override
  String nearbyWaiting(String name) {
    return 'Aguardando $name aceitar…';
  }

  @override
  String nearbySendingTo(String name) {
    return 'Enviando para $name…';
  }

  @override
  String get nearbySentTo => 'Enviado.';

  @override
  String get nearbyDeclined => 'Recusado.';

  @override
  String nearbyInvite(String name) {
    return '$name quer enviar documentos para você.';
  }

  @override
  String get nearbyAccept => 'Aceitar';

  @override
  String get nearbyDecline => 'Recusar';

  @override
  String get nearbyReceiving => 'Recebendo…';

  @override
  String get nearbyUnavailable =>
      'O envio por proximidade ainda não está disponível neste aparelho. Exporte um arquivo.';

  @override
  String get nearbyName => 'Este aparelho aparece como';

  @override
  String get actionCrop => 'Cortar';

  @override
  String get leadCustom => 'Escolher uma data';

  @override
  String get leadDailyTitle => 'Todos os dias no último mês';

  @override
  String get leadDailyBody =>
      'Quando faltar um mês para o vencimento, o Elapsa lembra você todo dia. Esse não é opcional.';

  @override
  String leadOnDate(String date) {
    return 'Em $date';
  }

  @override
  String get editUnsavedTitle => 'Manter as alterações?';

  @override
  String get editUnsavedBody =>
      'Este documento tem alterações que não foram salvas.';

  @override
  String get editDiscard => 'Descartar';

  @override
  String get nearbyRoleTitle => 'Enviar ou receber?';

  @override
  String get nearbyRoleSend => 'Enviar deste celular';

  @override
  String get nearbyRoleSendBody =>
      'Escolha documentos e entregue a outro aparelho.';

  @override
  String get nearbyRoleReceive => 'Receber neste celular';

  @override
  String get nearbyRoleReceiveBody =>
      'Aguardar outro aparelho enviar. Você será consultado antes de qualquer coisa chegar.';

  @override
  String get nearbyWaitingToReceive => 'Aguardando um aparelho enviar…';

  @override
  String get nearbyWantsToSend => 'quer enviar documentos para você';

  @override
  String get actionShare => 'Compartilhar';

  @override
  String get homeArrange => 'Organizar';

  @override
  String get homeSortBy => 'Ordenar por';

  @override
  String get homeShowAs => 'Mostrar cada cartão como';

  @override
  String get detailTitle => 'Documento';

  @override
  String get actionEdit => 'Editar';

  @override
  String get detailReminders => 'Lembretes';

  @override
  String detailNextReminder(String date) {
    return 'Próximo lembrete em $date';
  }

  @override
  String get detailNoReminders => 'Nenhum lembrete agendado.';

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
  String get settingsTypes => 'Seus próprios tipos';

  @override
  String get typesBody =>
      'O Elapsa traz onze tipos de documento e nunca vai acertar os onze certos. Dê nome aos seus — eles viajam junto com os cartões guardados neles.';

  @override
  String get typesAdd => 'Adicionar tipo';

  @override
  String get typesName => 'Nome';

  @override
  String get typesLead => 'Começar a lembrar';

  @override
  String get typesEmpty => 'Nenhum ainda.';

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
  String get typesRemove => 'Remover';

  @override
  String get editLastScan => 'O que a câmera leu';

  @override
  String get extrasTitle => 'Seus próprios campos';

  @override
  String get extrasAdd => 'Adicionar campo';

  @override
  String get extrasName => 'Nome do campo';

  @override
  String get extrasValue => 'Valor';

  @override
  String get fieldNeverExpires => 'Não vence';

  @override
  String get fieldNoExpiry => 'Este não tem validade';

  @override
  String get homeSearch => 'Buscar';

  @override
  String get homeSearchHint => 'Nome, tipo, número…';

  @override
  String get homeNoMatches => 'Nenhum resultado.';

  @override
  String get detailIssuedBy => 'País emissor';

  @override
  String get fieldNumberPassport => 'Número do passaporte';

  @override
  String get fieldNumberGeneric => 'Número do documento';

  @override
  String get paywallTitle => 'Todos os documentos num só lugar';

  @override
  String paywallBody(int limit) {
    return 'A versão gratuita guarda $limit documentos. Desbloqueie documentos ilimitados com uma única compra.';
  }

  @override
  String get paywallPointUnlimited => 'Documentos e lembretes ilimitados';

  @override
  String get paywallPointOnce =>
      'Pague uma vez. Sem assinatura, nada é renovado.';

  @override
  String get paywallPointPrivate =>
      'Continua sem conta, e nada sai do seu celular.';

  @override
  String paywallBuy(String price) {
    return 'Desbloquear por $price';
  }

  @override
  String get paywallLoadingPrice => 'Buscando o preço…';

  @override
  String get paywallRestore => 'Restaurar compra';

  @override
  String get paywallNotNow => 'Agora não';

  @override
  String get paywallPending =>
      'Aguardando aprovação. O desbloqueio aparece assim que a compra for aprovada.';

  @override
  String get paywallFailed => 'A compra não foi concluída. Tente de novo.';

  @override
  String get paywallNothingToRestore =>
      'Nenhuma compra anterior encontrada para esta conta.';

  @override
  String get paywallStoreUnavailable =>
      'Não foi possível acessar a loja agora. Verifique sua conexão e tente de novo.';

  @override
  String get paywallRetry => 'Tentar de novo';

  @override
  String get paywallThanks =>
      'Ilimitado desbloqueado. Obrigado por apoiar o Elapsa.';

  @override
  String get paywallRestored =>
      'Que bom ter você de volta — Ilimitado desbloqueado de novo.';

  @override
  String paywallImportBlocked(int limit) {
    return 'Não importado. A versão gratuita guarda $limit documentos.';
  }

  @override
  String get settingsUnlimited => 'Elapsa Ilimitado';

  @override
  String get settingsUnlimitedOn =>
      'Desbloqueado. Adicione quantos documentos quiser.';

  @override
  String settingsUnlimitedUsage(int count, int limit) {
    return '$count de $limit documentos gratuitos usados';
  }

  @override
  String get settingsUnlimitedUnlock => 'Desbloquear Ilimitado';
}
