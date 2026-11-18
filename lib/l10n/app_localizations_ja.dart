// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class LJa extends L {
  LJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Elapsa';

  @override
  String get homeNeedsAttention => '要対応';

  @override
  String get homeEverythingElse => 'その他';

  @override
  String get homeEmptyTitle => '期限が近いものはありません';

  @override
  String get homeEmptyBody =>
      'パスポートや身分証、免許証を追加すると、手遅れになる前に「更新を始める時期」をElapsaがお知らせします。';

  @override
  String get actionAdd => '書類を追加';

  @override
  String get actionScan => '書類をスキャン';

  @override
  String get actionSettings => '設定';

  @override
  String get actionCancel => 'キャンセル';

  @override
  String get actionDelete => '削除';

  @override
  String get actionDone => '完了';

  @override
  String get actionRetake => '撮り直す';

  @override
  String get actionOpen => '開く';

  @override
  String get shareFailed => '共有できませんでした。';

  @override
  String get actionSaveToPhotos => '写真に保存';

  @override
  String get actionSaveToFiles => 'ファイルに保存';

  @override
  String get photoSavedToPhotos => '写真に保存しました';

  @override
  String get photoSavedToFiles => 'ファイルに保存しました';

  @override
  String get photoSaveFailed => '画像を保存できませんでした。';

  @override
  String get photoPhotosDenied => 'Elapsa に写真への追加が許可されていません。設定で許可できます。';

  @override
  String get photoExportNote => 'Elapsa の外に保存したコピーは暗号化されません。';

  @override
  String get attachmentsTitle => '添付ファイル';

  @override
  String get attachmentsAdd => '添付を追加';

  @override
  String get attachmentsAddFile => 'ファイル';

  @override
  String get attachmentsAddFileHint => 'PDF、書類、その他のファイル';

  @override
  String get attachmentsAddLink => 'リンク';

  @override
  String get attachmentsAddLinkHint => '更新手続きのページなどのウェブページ';

  @override
  String get attachmentsLinkTitle => 'リンクを追加';

  @override
  String get attachmentsLinkUrl => 'ウェブアドレス';

  @override
  String get attachmentsLinkName => '名前（任意）';

  @override
  String get attachmentsLinkInvalid => 'ウェブアドレスではないようです。';

  @override
  String get attachmentsTooLarge => 'このファイルは 50 MB を超えているため添付できません。';

  @override
  String attachmentsSkippedTooLarge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のファイルが 50 MB を超えているため除外しました。',
      one: '1 件のファイルが 50 MB を超えているため除外しました。',
    );
    return '$_temp0';
  }

  @override
  String get attachmentsCannotOpen => 'この添付ファイルを開けませんでした。';

  @override
  String get attachmentsRemoveTitle => 'この添付ファイルを削除しますか？';

  @override
  String get attachmentsRemoveBody => 'Elapsa 内のコピーが削除されます。この操作は取り消せません。';

  @override
  String get actionRemove => '削除';

  @override
  String get actionAddShort => '追加';

  @override
  String get statusExpired => '期限切れ';

  @override
  String get statusExpiring => '期限間近';

  @override
  String get statusRenewNow => '今すぐ更新';

  @override
  String get statusValid => '有効';

  @override
  String daysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '残り$days日',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days日前',
    );
    return '$_temp0';
  }

  @override
  String get startRenewingNow => '今すぐ更新を始めましょう';

  @override
  String get travelRuleBadge => '渡航に必要な残存期間6か月を切っています';

  @override
  String remindersTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'リマインダー$count件を予定',
      zero: '予定されたリマインダーはありません',
    );
    return '$_temp0';
  }

  @override
  String get remindersEmptyBody => '書類を追加すると、Elapsaがリマインダーを設定します。';

  @override
  String get remindersBody => 'アプリを開かなくても通知されます。';

  @override
  String get editAddTitle => '書類を追加';

  @override
  String get editEditTitle => '書類を編集';

  @override
  String get editScanHelp => 'パスポート、身分証、ビザのコードを読み取ります';

  @override
  String get editFromScanNote => '書類のコードから入力しました。どの項目も自由に変更できます。';

  @override
  String get editScanNothingRead => '写真を保存しました。この面には読み取れる情報がないので、下に入力してください。';

  @override
  String get editScanRepaired => 'スキャンしました。コードが少しぼやけていたので、内容を確認してください。';

  @override
  String get scanExpiredTitle => 'この書類はすでに期限切れです';

  @override
  String scanExpiredBody(String date) {
    return '有効期限は$dateで、すでに過ぎています。今すぐ更新を始めましょう。日付の読み取りが間違っている場合は、下で修正してください。';
  }

  @override
  String get scanExpiredOk => 'OK';

  @override
  String get fieldType => '種類';

  @override
  String get fieldName => '名前';

  @override
  String fieldNameHint(String type) {
    return '私の$type';
  }

  @override
  String get fieldNameRequired => '名前を付けてください';

  @override
  String get fieldExpiry => '有効期限';

  @override
  String get fieldExpiryEmpty => '日付を選択';

  @override
  String get fieldExpiryRequired => '有効期限を選んでください';

  @override
  String get fieldIssueDate => '有効開始日';

  @override
  String get fieldRemindMe => '通知を始める時期';

  @override
  String get fieldOptional => '任意';

  @override
  String get fieldHolderHint => '所有者';

  @override
  String get fieldNumberHint => '書類番号';

  @override
  String get fieldNumberLabel => 'カード番号';

  @override
  String get imageOptionsTitle => 'この写真を撮り直すか削除しますか？';

  @override
  String get fieldImages => '写真';

  @override
  String get editSave => '保存';

  @override
  String get editDeleteTitle => 'この書類を削除しますか？';

  @override
  String get editDeleteBody => 'リマインダーと写真も削除されます。';

  @override
  String leadExplainNoDate(String lead) {
    return '期限の$lead前に通知し、期限が近づくと再度お知らせします。';
  }

  @override
  String leadExplainFirst(String date) {
    return '最初の通知は$date。期限が近づくと再度お知らせします。';
  }

  @override
  String get leadExplainPassed => 'その時期はもう過ぎています。今すぐ始めましょう。';

  @override
  String leadWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks週間',
    );
    return '$_temp0';
  }

  @override
  String leadMonths(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$monthsか月',
    );
    return '$_temp0';
  }

  @override
  String leadYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years年',
    );
    return '$_temp0';
  }

  @override
  String get sixMonthRuleNote =>
      '多くの国では入国日から6か月以上の残存期間が必要です。そのため、この書類は期限の約6か月前から渡航に使えなくなります。';

  @override
  String get typePassport => 'パスポート';

  @override
  String get typeNationalId => '身分証明書';

  @override
  String get typeDriversLicence => '運転免許証';

  @override
  String get typeVisa => 'ビザ';

  @override
  String get typeResidencePermit => '在留カード';

  @override
  String get typeVehicleRegistration => '車検証';

  @override
  String get typeInsurance => '保険';

  @override
  String get typeProfessionalLicence => '資格・免許';

  @override
  String get typeMembership => '会員証';

  @override
  String get typeBankCard => '銀行カード';

  @override
  String get typeOther => 'その他';

  @override
  String get scanTitle => '書類をスキャン';

  @override
  String get scanHintSearching => '書類を平らに置いてカメラを向けてください';

  @override
  String get scanHintFound => 'そのまま動かさないで';

  @override
  String get scanHintNoCamera => 'この端末にはカメラがありません。写真から読み取ってください';

  @override
  String get scanChoosePhoto => '写真を選ぶ';

  @override
  String get scanEnterByHand => '手入力する';

  @override
  String get scanNoCameraTitle => '写真からスキャン';

  @override
  String get scanNoCameraBody => '手元にある書類の写真からコードを読み取れます。';

  @override
  String get scanFailedNoCode =>
      '書類のコードが見つかりません。カードを枠いっぱいに収め、下部のコードがはっきり写るようにしてください。';

  @override
  String get scanFailedUnreadable =>
      'コードは見つかりましたが、きれいに読み取れませんでした。反射を減らしてもう一度試すか、手入力してください。';

  @override
  String get scanFailedPhoto => 'その写真は読み取れませんでした。';

  @override
  String get scanFailedCapture => '撮影できませんでした。もう一度お試しください。';

  @override
  String scanPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '写真$count枚',
    );
    return '$_temp0';
  }

  @override
  String get scanAddAnother => '反対の面を追加';

  @override
  String get scanSideFront => '表面';

  @override
  String get scanSideBack => '裏面';

  @override
  String get detailCardholderName => 'カード名義';

  @override
  String get detailSecurityCode => 'セキュリティコード';

  @override
  String get detailNationality => '国籍';

  @override
  String get detailPlaceOfIssue => '発行地';

  @override
  String get detailIssuingAuthority => '発行機関';

  @override
  String get detailLicenceClass => '種別';

  @override
  String get detailPolicyNumber => '証券番号';

  @override
  String get detailPlateNumber => 'ナンバー';

  @override
  String get detailVehicleIdentification => '車台番号';

  @override
  String get detailMembershipLevel => 'ランク';

  @override
  String get detailSensitiveNote => '通常は非表示。この端末上で暗号化され、アップロードされることはありません。';

  @override
  String get detailReveal => '表示';

  @override
  String get detailHide => '隠す';

  @override
  String get sortTitle => '並べ替え';

  @override
  String get sortExpiry => '有効期限';

  @override
  String get sortAdded => '追加が新しい順';

  @override
  String get sortName => '名前';

  @override
  String get sortType => '種類';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsLanguageSystem => '端末の設定に従う';

  @override
  String get settingsAbout => 'このアプリについて';

  @override
  String get settingsPrivacyTitle => 'すべてこの端末の中だけに';

  @override
  String get settingsPrivacyBody =>
      '書類、写真、番号は暗号化され、このスマートフォンにだけ保存されます。Elapsaにはアカウントもサーバーもなく、何もアップロードされません。';

  @override
  String settingsVersion(String version) {
    return 'バージョン $version';
  }

  @override
  String notifyRenewTitle(String type) {
    return '$typeの更新時期です';
  }

  @override
  String notifyExpiresTitle(String label, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'あと$days日',
    );
    return '$labelの期限まで$_temp0';
  }

  @override
  String notifyRenewBody(String date) {
    return '期限は$dateです。慌てずに更新できる余裕があります。今始めれば十分間に合います。';
  }

  @override
  String notifyTravelBody(String date) {
    return '期限は$dateです。多くの国では6か月の残存期間が必要なため、すでに渡航に使えない可能性があります。';
  }

  @override
  String notifyPlainBody(String date) {
    return '期限は$dateです。';
  }

  @override
  String get notifyChannelName => '更新リマインダー';

  @override
  String get notifyChannelDescription => '手遅れになってからではなく、更新を始める時期をお知らせします。';

  @override
  String get settingsAppearance => '表示';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get themeSystem => '端末に合わせる';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get settingsWallet => 'ホーム画面';

  @override
  String get settingsWalletDisplay => 'カードの表示方法';

  @override
  String get displayNameOnly => '名前のみ';

  @override
  String get displayImageOnly => '写真のみ';

  @override
  String get displayNameAndImage => '名前と写真';

  @override
  String get displayNameOnlyBody => 'コンパクトな一覧。肩越しに読まれる情報は表示されません。';

  @override
  String get displayImageOnlyBody => '自分で撮った写真で、開いた財布のように表示します。';

  @override
  String get displayNameAndImageBody => '写真の下に名前と期限を表示します。';

  @override
  String get settingsRemindersTitle => 'リマインダー';

  @override
  String get settingsRemindersLead => '通知の初期設定';

  @override
  String get settingsRemindersBody => '新しい書類に適用されます。書類ごとに個別に変更できます。';

  @override
  String get settingsRemindersAuto => '書類ごとに選ぶ';

  @override
  String get settingsScheduled => '予定されたリマインダー';

  @override
  String get settingsResync => 'スケジュールを再作成';

  @override
  String get settingsResyncDone => 'リマインダーのスケジュールを再作成しました。';

  @override
  String get settingsDiagnostics => '診断';

  @override
  String get settingsLastScan => '直近のスキャン';

  @override
  String get settingsLastScanBody =>
      'Elapsaが解釈する前に、カメラが読み取った内容そのままです。項目が空になったときに役立ちます。';

  @override
  String get settingsLastScanEmpty => 'このセッションではまだスキャンしていません。';

  @override
  String get actionCopy => 'コピー';

  @override
  String get settingsCopied => 'コピーしました。';

  @override
  String countYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years年',
    );
    return '$_temp0';
  }

  @override
  String countDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days日',
    );
    return '$_temp0';
  }

  @override
  String durationLeft(String duration) {
    return '残り$duration';
  }

  @override
  String durationAgo(String duration) {
    return '$duration前';
  }

  @override
  String get settingsTransfer => 'データの移行';

  @override
  String get transferExport => 'すべて書き出す';

  @override
  String get transferExportBody =>
      'すべての書類と写真を1つの暗号化ファイルにまとめます。AirDrop、ファイル、ケーブルなど、好きな方法でもう1台に送れます。Elapsaのバックアップはこれだけです。この端末以外にはどこにも保存されていません。';

  @override
  String get transferImport => 'ファイルから読み込む';

  @override
  String get transferImportBody => '別の端末で書き出したアーカイブを開きます。';

  @override
  String get transferPassphrase => 'パスフレーズ';

  @override
  String get transferPassphraseNew => 'パスフレーズを決める';

  @override
  String get transferPassphraseNewBody =>
      'もう1台でアーカイブを開くときに、まったく同じパスフレーズが必要です。誰にも復元できません。Elapsaにもできないからこそ、ファイルが他人の手に渡っても安全です。';

  @override
  String get transferPassphraseAsk => 'このアーカイブを作成したときのパスフレーズを入力してください。';

  @override
  String get transferPassphraseShort => '8文字以上にしてください。';

  @override
  String transferExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の書類を書き出しました。',
    );
    return '$_temp0';
  }

  @override
  String transferImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の書類を読み込みました。',
    );
    return '$_temp0';
  }

  @override
  String get transferNothing => '書き出す書類がまだありません。';

  @override
  String get transferMergeTitle => '読み込み方法';

  @override
  String get transferMerge => '統合する';

  @override
  String get transferMergeBody => '今ある書類を残し、ファイルの内容を追加します。';

  @override
  String get transferReplace => 'すべて置き換える';

  @override
  String get transferReplaceBody => '先にこの端末の書類をすべて削除します。';

  @override
  String get transferFailedFile => 'Elapsaのアーカイブではありません。';

  @override
  String get transferFailedNew => 'このアーカイブは新しいバージョンのElapsaで作成されています。';

  @override
  String get transferFailedKey => 'パスフレーズが違うか、ファイルが破損しています。';

  @override
  String get actionContinue => '続ける';

  @override
  String shortYears(int years) {
    return '$years年';
  }

  @override
  String shortDays(int days) {
    return '$days日';
  }

  @override
  String get shortExpired => '期限切れ';

  @override
  String get transferProtect => 'パスフレーズで保護';

  @override
  String get transferProtectBody =>
      'ファイルは受け渡しの後も両方の「ファイル」に残るため、オンにしておきます。すぐに読み込んで削除するアーカイブの場合だけオフにしてください。';

  @override
  String get transferChoose => '送るものを選ぶ';

  @override
  String get transferAll => 'すべて';

  @override
  String get transferNone => 'なし';

  @override
  String transferSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の書類',
      zero: '選択されていません',
    );
    return '$_temp0';
  }

  @override
  String get cropTitle => '角をドラッグ';

  @override
  String get cropBody => '書類の四隅にそれぞれ角を合わせてください。';

  @override
  String get cropReset => 'リセット';

  @override
  String get scanAdjust => '切り抜きを調整';

  @override
  String get scanAutoOn => '自動検出オン';

  @override
  String get scanAutoOff => '自動検出オフ';

  @override
  String get scanAutoStuck => '書類が見つかりませんか？';

  @override
  String get scanAutoStuckAction => '手動に切り替える';

  @override
  String get nearbyTitle => '近くの端末と受け渡し';

  @override
  String get nearbyBody =>
      'もう1台でElapsaを開き、この画面を表示してください。ファイルもパスフレーズも不要です。相手側の承認が必要です。';

  @override
  String get nearbySearching => '端末を探しています…';

  @override
  String get nearbyNone => 'まだ見つかりません。両方の端末でこの画面を開き、Wi-Fiをオンにしてください。';

  @override
  String get nearbySend => '送信';

  @override
  String nearbyWaiting(String name) {
    return '$nameの承認を待っています…';
  }

  @override
  String nearbySendingTo(String name) {
    return '$nameに送信中…';
  }

  @override
  String get nearbySentTo => '送信しました。';

  @override
  String get nearbyDeclined => '拒否されました。';

  @override
  String nearbyInvite(String name) {
    return '$nameが書類を送ろうとしています。';
  }

  @override
  String get nearbyAccept => '受け入れる';

  @override
  String get nearbyDecline => '拒否';

  @override
  String get nearbyReceiving => '受信中…';

  @override
  String get nearbyUnavailable => 'この端末ではまだ近くの端末への送信を利用できません。ファイルを書き出してください。';

  @override
  String get nearbyName => 'この端末の表示名';

  @override
  String get actionCrop => '切り抜く';

  @override
  String get leadCustom => '日付を選ぶ';

  @override
  String get leadDailyTitle => '最後の1か月は毎日';

  @override
  String get leadDailyBody => '期限まで1か月を切ると、Elapsaは毎日お知らせします。これはオフにできません。';

  @override
  String leadOnDate(String date) {
    return '$date';
  }

  @override
  String get editUnsavedTitle => '変更を保存しますか？';

  @override
  String get editUnsavedBody => 'この書類には保存されていない変更があります。';

  @override
  String get editDiscard => '破棄';

  @override
  String get nearbyRoleTitle => '送信しますか、受信しますか？';

  @override
  String get nearbyRoleSend => 'この端末から送る';

  @override
  String get nearbyRoleSendBody => '書類を選んで別の端末に渡します。';

  @override
  String get nearbyRoleReceive => 'この端末で受け取る';

  @override
  String get nearbyRoleReceiveBody => '別の端末からの送信を待ちます。受け取る前に確認があります。';

  @override
  String get nearbyWaitingToReceive => '送信を待っています…';

  @override
  String get nearbyWantsToSend => 'が書類を送ろうとしています';

  @override
  String get actionShare => '共有';

  @override
  String get homeArrange => '並べ方';

  @override
  String get homeSortBy => '並べ替え';

  @override
  String get homeShowAs => 'カードの表示方法';

  @override
  String get detailTitle => '書類';

  @override
  String get actionEdit => '編集';

  @override
  String get detailReminders => 'リマインダー';

  @override
  String detailNextReminder(String date) {
    return '次の通知：$date';
  }

  @override
  String get detailNoReminders => '予定されたリマインダーはありません。';

  @override
  String detailPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '写真$count枚',
    );
    return '$_temp0';
  }

  @override
  String get settingsTypes => '自分で作った種類';

  @override
  String get typesBody =>
      'Elapsaには11種類の書類が用意されていますが、それで全部を網羅することはできません。自分で名前を付けた種類は、その種類のカードと一緒に移行されます。';

  @override
  String get typesAdd => '種類を追加';

  @override
  String get typesName => '名前';

  @override
  String get typesLead => '通知を始める時期';

  @override
  String get typesEmpty => 'まだありません。';

  @override
  String typesInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の書類で使用中',
    );
    return '$_temp0';
  }

  @override
  String get typesRemove => '削除';

  @override
  String get editLastScan => 'カメラが読み取った内容';

  @override
  String get extrasTitle => '自分で作った項目';

  @override
  String get extrasAdd => '項目を追加';

  @override
  String get extrasName => '項目名';

  @override
  String get extrasValue => '内容';

  @override
  String get fieldNeverExpires => '有効期限なし';

  @override
  String get fieldNoExpiry => 'この書類には期限がありません';

  @override
  String get homeSearch => '検索';

  @override
  String get homeSearchHint => '名前、種類、番号…';

  @override
  String get homeNoMatches => '一致するものはありません。';

  @override
  String get detailIssuedBy => '発行国';

  @override
  String get fieldNumberPassport => '旅券番号';

  @override
  String get fieldNumberGeneric => '書類番号';

  @override
  String get paywallTitle => 'すべての書類をひとつの場所に';

  @override
  String paywallBody(int limit) {
    return '無料版で保存できる書類は$limit件までです。一度の購入で無制限に追加できます。';
  }

  @override
  String get paywallPointUnlimited => '書類もリマインダーも無制限';

  @override
  String get paywallPointOnce => '支払いは一度だけ。サブスクリプションではなく、自動更新もありません。';

  @override
  String get paywallPointPrivate => 'これまでどおりアカウント不要。データは端末の外に出ません。';

  @override
  String paywallBuy(String price) {
    return '$priceでアンロック';
  }

  @override
  String get paywallLoadingPrice => '価格を取得中…';

  @override
  String get paywallRestore => '購入を復元';

  @override
  String get paywallNotNow => '今はしない';

  @override
  String get paywallPending => '承認待ちです。購入が承認されるとすぐにアンロックされます。';

  @override
  String get paywallFailed => '購入が完了しませんでした。もう一度お試しください。';

  @override
  String get paywallNothingToRestore => 'このアカウントでの過去の購入は見つかりませんでした。';

  @override
  String get paywallStoreUnavailable => '現在ストアに接続できません。接続を確認して、もう一度お試しください。';

  @override
  String get paywallRetry => '再試行';

  @override
  String get paywallThanks => '無制限版をアンロックしました。Elapsaを応援していただきありがとうございます。';

  @override
  String get paywallRestored => 'おかえりなさい。無制限版が再びアンロックされました。';

  @override
  String paywallImportBlocked(int limit) {
    return '読み込みませんでした。無料版で保存できる書類は$limit件までです。';
  }

  @override
  String get settingsUnlimited => 'Elapsa 無制限版';

  @override
  String get settingsUnlimitedOn => 'アンロック済み。書類をいくつでも追加できます。';

  @override
  String settingsUnlimitedUsage(int count, int limit) {
    return '無料枠 $limit件中$count件を使用';
  }

  @override
  String get settingsUnlimitedUnlock => '無制限版をアンロック';
}
