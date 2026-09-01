// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class LZh extends L {
  LZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Elapsa';

  @override
  String get homeNeedsAttention => '需要处理';

  @override
  String get homeEverythingElse => '其他证件';

  @override
  String get homeEmptyTitle => '没有快到期的证件';

  @override
  String get homeEmptyBody => '添加护照、身份证或驾驶证，Elapsa 会在该动手办理的时候提醒你，而不是等到来不及。';

  @override
  String get actionAdd => '添加证件';

  @override
  String get actionScan => '扫描证件';

  @override
  String get actionSettings => '设置';

  @override
  String get actionCancel => '取消';

  @override
  String get actionDelete => '删除';

  @override
  String get actionDone => '完成';

  @override
  String get actionRetake => '重拍';

  @override
  String get statusExpired => '已过期';

  @override
  String get statusExpiring => '即将到期';

  @override
  String get statusRenewNow => '该办理了';

  @override
  String get statusValid => '有效';

  @override
  String daysLeft(int days) {
    return '还剩 $days 天';
  }

  @override
  String daysAgo(int days) {
    return '已过期 $days 天';
  }

  @override
  String get startRenewingNow => '现在就该开始办';

  @override
  String get travelRuleBadge => '已不足六个月，多数国家不予入境';

  @override
  String remindersTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已安排 $count 条提醒',
      zero: '没有已安排的提醒',
    );
    return '$_temp0';
  }

  @override
  String get remindersEmptyBody => '添加证件后，Elapsa 会自动为它安排提醒。';

  @override
  String get remindersBody => '即使你从不打开这个 App，提醒也会照常发出。';

  @override
  String get editAddTitle => '添加证件';

  @override
  String get editEditTitle => '编辑证件';

  @override
  String get editScanHelp => '识别护照、身份证、签证上的机读码';

  @override
  String get editFromScanNote => '以下内容由机读码自动填入，每一项你都可以修改。';

  @override
  String get editScanNothingRead => '照片已保存。这一面没有读到可用信息，请在下面填写。';

  @override
  String get editScanRepaired => '已扫描 — 机读码有点模糊，请核对一下信息。';

  @override
  String get fieldType => '类型';

  @override
  String get fieldName => '名称';

  @override
  String fieldNameHint(String type) {
    return '我的$type';
  }

  @override
  String get fieldNameRequired => '请起个名字';

  @override
  String get fieldExpiry => '到期日';

  @override
  String get fieldExpiryEmpty => '选择日期';

  @override
  String get fieldExpiryRequired => '请选择到期日';

  @override
  String get fieldIssueDate => '有效期起始';

  @override
  String get fieldRemindMe => '提前多久提醒';

  @override
  String get fieldOptional => '选填';

  @override
  String get fieldHolderHint => '持有人';

  @override
  String get fieldNumberHint => '证件号码';

  @override
  String get fieldNumberLabel => '证件号码';

  @override
  String get imageOptionsTitle => '重拍或删除这张照片？';

  @override
  String get fieldImages => '照片';

  @override
  String get editSave => '保存';

  @override
  String get editDeleteTitle => '删除这个证件？';

  @override
  String get editDeleteBody => '它的提醒和照片也会一并删除。';

  @override
  String leadExplainNoDate(String lead) {
    return 'Elapsa 会在到期前 $lead 提醒你，之后随着日子临近再提醒几次。';
  }

  @override
  String leadExplainFirst(String date) {
    return '第一次提醒：$date，之后随着日子临近再提醒几次。';
  }

  @override
  String get leadExplainPassed => '这个时间点已经过了 — 现在就该开始办。';

  @override
  String leadWeeks(int weeks) {
    return '$weeks 周';
  }

  @override
  String leadMonths(int months) {
    return '$months 个月';
  }

  @override
  String leadYears(int years) {
    return '$years 年';
  }

  @override
  String get sixMonthRuleNote => '很多国家要求入境时护照仍有六个月以上有效期，所以它在到期前约六个月就已经不能用来出行了。';

  @override
  String get typePassport => '护照';

  @override
  String get typeNationalId => '身份证';

  @override
  String get typeDriversLicence => '驾驶证';

  @override
  String get typeVisa => '签证';

  @override
  String get typeResidencePermit => '居留许可';

  @override
  String get typeVehicleRegistration => '行驶证';

  @override
  String get typeInsurance => '保险';

  @override
  String get typeProfessionalLicence => '执业证书';

  @override
  String get typeMembership => '会员卡';

  @override
  String get typeBankCard => '银行卡';

  @override
  String get typeOther => '其他';

  @override
  String get scanTitle => '扫描证件';

  @override
  String get scanHintSearching => '对准证件，尽量放平';

  @override
  String get scanHintFound => '拿稳，别动';

  @override
  String get scanHintNoCamera => '此设备没有摄像头 — 可以从相册里的照片识别';

  @override
  String get scanChoosePhoto => '从相册选择';

  @override
  String get scanEnterByHand => '手动输入';

  @override
  String get scanNoCameraTitle => '从照片识别';

  @override
  String get scanNoCameraBody => 'Elapsa 可以直接读取你已有的证件照片。';

  @override
  String get scanFailedNoCode => '没找到机读码。让证件填满取景框，并确保底部那两行字母数字清晰。';

  @override
  String get scanFailedUnreadable => '找到了机读码但读不清楚。换个角度避开反光再试一次，或者手动输入。';

  @override
  String get scanFailedPhoto => '这张照片读不出来。';

  @override
  String get scanFailedCapture => '拍照失败，请再试一次。';

  @override
  String scanPageCount(int count) {
    return '$count 张照片';
  }

  @override
  String get scanAddAnother => '再拍一面';

  @override
  String get scanSideFront => '正面';

  @override
  String get scanSideBack => '反面';

  @override
  String get detailCardholderName => '持卡人姓名';

  @override
  String get detailSecurityCode => '安全码';

  @override
  String get detailNationality => '国籍';

  @override
  String get detailPlaceOfIssue => '签发地';

  @override
  String get detailIssuingAuthority => '签发机关';

  @override
  String get detailLicenceClass => '准驾车型';

  @override
  String get detailPolicyNumber => '保单号';

  @override
  String get detailPlateNumber => '车牌号';

  @override
  String get detailVehicleIdentification => '车架号';

  @override
  String get detailMembershipLevel => '等级';

  @override
  String get detailSensitiveNote => '默认隐藏，加密保存在这台手机里，绝不上传。';

  @override
  String get detailReveal => '显示';

  @override
  String get detailHide => '隐藏';

  @override
  String get sortTitle => '排序';

  @override
  String get sortExpiry => '按到期日';

  @override
  String get sortAdded => '按添加时间';

  @override
  String get sortName => '按名称';

  @override
  String get sortType => '按类型';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsPrivacyTitle => '所有资料都只留在这台手机上';

  @override
  String get settingsPrivacyBody =>
      '你的证件信息、照片和号码都经过加密，只保存在这台手机里。Elapsa 没有账号，也没有服务器，任何内容都不会被上传。';

  @override
  String settingsVersion(String version) {
    return '版本 $version';
  }

  @override
  String notifyRenewTitle(String type) {
    return '该去办$type了';
  }

  @override
  String notifyExpiresTitle(String label, int days) {
    return '$label 还有 $days 天到期';
  }

  @override
  String notifyRenewBody(String date) {
    return '到期日是 $date。现在时间还宽裕，从容办完刚刚好。';
  }

  @override
  String notifyTravelBody(String date) {
    return '到期日是 $date。很多国家要求剩余有效期满六个月，现在可能已经不能出行了。';
  }

  @override
  String notifyPlainBody(String date) {
    return '到期日：$date。';
  }

  @override
  String get notifyChannelName => '证件到期提醒';

  @override
  String get notifyChannelDescription => '在该动手办理的时候提醒你，而不是等到来不及。';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsTheme => '主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get settingsWallet => '卡包';

  @override
  String get settingsWalletDisplay => '卡片显示方式';

  @override
  String get displayNameOnly => '仅名称';

  @override
  String get displayImageOnly => '仅图片';

  @override
  String get displayNameAndImage => '名称与图片';

  @override
  String get displayNameOnlyBody => '紧凑列表。屏幕上没有旁人能看到的内容。';

  @override
  String get displayImageOnlyBody => '你自己拍的照片，像打开钱包一样。';

  @override
  String get displayNameAndImageBody => '照片下方显示名称与到期日。';

  @override
  String get settingsRemindersTitle => '提醒';

  @override
  String get settingsRemindersLead => '默认提前提醒';

  @override
  String get settingsRemindersBody => '适用于新添加的证件，每张仍可单独调整。';

  @override
  String get settingsRemindersAuto => '由每张证件自行决定';

  @override
  String get settingsScheduled => '已安排的提醒';

  @override
  String get settingsResync => '重建提醒计划';

  @override
  String get settingsResyncDone => '提醒计划已重建。';

  @override
  String get settingsDiagnostics => '诊断';

  @override
  String get settingsLastScan => '最近一次识别';

  @override
  String get settingsLastScanBody => '相机读到的原始文字，尚未经过解析。某个字段为空时可用来排查。';

  @override
  String get settingsLastScanEmpty => '本次启动后还没有扫描过。';

  @override
  String get actionCopy => '复制';

  @override
  String get settingsCopied => '已复制。';

  @override
  String countYears(int years) {
    return '$years 年';
  }

  @override
  String countDays(int days) {
    return '$days 天';
  }

  @override
  String durationLeft(String duration) {
    return '还剩 $duration';
  }

  @override
  String durationAgo(String duration) {
    return '已过期 $duration';
  }

  @override
  String get settingsTransfer => '迁移';

  @override
  String get transferExport => '导出全部';

  @override
  String get transferExportBody =>
      '所有证件和照片打包成一个加密文件。用任何方式传给另一台手机——隔空投送、文件、数据线都行。这也是 Elapsa 唯一的备份：数据只存在这台设备上。';

  @override
  String get transferImport => '从文件导入';

  @override
  String get transferImportBody => '打开从另一台设备导出的存档。';

  @override
  String get transferPassphrase => '密码';

  @override
  String get transferPassphraseNew => '设置密码';

  @override
  String get transferPassphraseNewBody =>
      '在另一台手机上打开存档时需要输入完全相同的密码。没有人能帮你找回——Elapsa 也不能，这正是文件万一遗失仍然安全的原因。';

  @override
  String get transferPassphraseAsk => '请输入创建此存档时使用的密码。';

  @override
  String get transferPassphraseShort => '至少 8 个字符。';

  @override
  String transferExported(int count) {
    return '已归档 $count 份证件。';
  }

  @override
  String transferImported(int count) {
    return '已导入 $count 份证件。';
  }

  @override
  String get transferNothing => '暂无可导出的内容。';

  @override
  String get transferMergeTitle => '如何导入？';

  @override
  String get transferMerge => '合并';

  @override
  String get transferMergeBody => '保留现有内容，并加入文件中的证件。';

  @override
  String get transferReplace => '全部替换';

  @override
  String get transferReplaceBody => '先删除这台手机上的所有证件。';

  @override
  String get transferFailedFile => '这不是 Elapsa 存档文件。';

  @override
  String get transferFailedNew => '此存档由更新版本的 Elapsa 创建。';

  @override
  String get transferFailedKey => '密码错误，或文件已损坏。';

  @override
  String get actionContinue => '继续';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class LZhHant extends LZh {
  LZhHant() : super('zh_Hant');

  @override
  String get appTitle => 'Elapsa';

  @override
  String get homeNeedsAttention => '需要處理';

  @override
  String get homeEverythingElse => '其他證件';

  @override
  String get homeEmptyTitle => '沒有快到期的證件';

  @override
  String get homeEmptyBody => '加入護照、身分證或駕照，Elapsa 會在該動手辦的時候提醒你，而不是等到來不及。';

  @override
  String get actionAdd => '新增證件';

  @override
  String get actionScan => '掃描證件';

  @override
  String get actionSettings => '設定';

  @override
  String get actionCancel => '取消';

  @override
  String get actionDelete => '刪除';

  @override
  String get actionDone => '完成';

  @override
  String get actionRetake => '重拍';

  @override
  String get statusExpired => '已過期';

  @override
  String get statusExpiring => '即將到期';

  @override
  String get statusRenewNow => '該辦了';

  @override
  String get statusValid => '有效';

  @override
  String daysLeft(int days) {
    return '還剩 $days 天';
  }

  @override
  String daysAgo(int days) {
    return '已過期 $days 天';
  }

  @override
  String get startRenewingNow => '現在就該開始辦';

  @override
  String get travelRuleBadge => '已不足六個月，多數國家不予入境';

  @override
  String remindersTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已排定 $count 則提醒',
      zero: '沒有已排定的提醒',
    );
    return '$_temp0';
  }

  @override
  String get remindersEmptyBody => '加入證件後，Elapsa 會自動為它排定提醒。';

  @override
  String get remindersBody => '就算你從來不打開這個 App，提醒也會照常送出。';

  @override
  String get editAddTitle => '新增證件';

  @override
  String get editEditTitle => '編輯證件';

  @override
  String get editScanHelp => '辨識護照、身分證、簽證上的機器可讀區';

  @override
  String get editFromScanNote => '以下內容由機器可讀區自動填入，每一項你都可以修改。';

  @override
  String get editScanNothingRead => '照片已儲存。這一面沒有讀到可用資訊，請在下面填寫。';

  @override
  String get editScanRepaired => '已掃描 — 機讀碼有點模糊，請核對一下資料。';

  @override
  String get fieldType => '類型';

  @override
  String get fieldName => '名稱';

  @override
  String fieldNameHint(String type) {
    return '我的$type';
  }

  @override
  String get fieldNameRequired => '請取個名稱';

  @override
  String get fieldExpiry => '到期日';

  @override
  String get fieldExpiryEmpty => '選擇日期';

  @override
  String get fieldExpiryRequired => '請選擇到期日';

  @override
  String get fieldIssueDate => '有效期起始';

  @override
  String get fieldRemindMe => '提前多久提醒';

  @override
  String get fieldOptional => '選填';

  @override
  String get fieldHolderHint => '持有人';

  @override
  String get fieldNumberHint => '證件號碼';

  @override
  String get fieldNumberLabel => '證件號碼';

  @override
  String get imageOptionsTitle => '重拍或刪除這張照片？';

  @override
  String get fieldImages => '照片';

  @override
  String get editSave => '儲存';

  @override
  String get editDeleteTitle => '刪除這張證件？';

  @override
  String get editDeleteBody => '它的提醒和照片也會一併刪除。';

  @override
  String leadExplainNoDate(String lead) {
    return 'Elapsa 會在到期前 $lead 提醒你，之後隨著日子接近再提醒幾次。';
  }

  @override
  String leadExplainFirst(String date) {
    return '第一次提醒：$date，之後隨著日子接近再提醒幾次。';
  }

  @override
  String get leadExplainPassed => '這個時間點已經過了 — 現在就該開始辦。';

  @override
  String leadWeeks(int weeks) {
    return '$weeks 週';
  }

  @override
  String leadMonths(int months) {
    return '$months 個月';
  }

  @override
  String leadYears(int years) {
    return '$years 年';
  }

  @override
  String get sixMonthRuleNote => '很多國家要求入境時護照仍有六個月以上效期，所以它在到期前約六個月就已經不能用來出國了。';

  @override
  String get typePassport => '護照';

  @override
  String get typeNationalId => '身分證';

  @override
  String get typeDriversLicence => '駕照';

  @override
  String get typeVisa => '簽證';

  @override
  String get typeResidencePermit => '居留證';

  @override
  String get typeVehicleRegistration => '行照';

  @override
  String get typeInsurance => '保險';

  @override
  String get typeProfessionalLicence => '專業證照';

  @override
  String get typeMembership => '會員卡';

  @override
  String get typeBankCard => '銀行卡';

  @override
  String get typeOther => '其他';

  @override
  String get scanTitle => '掃描證件';

  @override
  String get scanHintSearching => '對準證件，盡量放平';

  @override
  String get scanHintFound => '拿穩，別動';

  @override
  String get scanHintNoCamera => '這台裝置沒有相機 — 可以從相簿的照片辨識';

  @override
  String get scanChoosePhoto => '從相簿選擇';

  @override
  String get scanEnterByHand => '手動輸入';

  @override
  String get scanNoCameraTitle => '從照片辨識';

  @override
  String get scanNoCameraBody => 'Elapsa 可以直接讀取你已有的證件照片。';

  @override
  String get scanFailedNoCode => '找不到機讀碼。讓證件填滿取景框，並確認底部那兩行英數字清晰。';

  @override
  String get scanFailedUnreadable => '找到機讀碼但讀不清楚。換個角度避開反光再試一次，或者手動輸入。';

  @override
  String get scanFailedPhoto => '這張照片讀不出來。';

  @override
  String get scanFailedCapture => '拍照失敗，請再試一次。';

  @override
  String scanPageCount(int count) {
    return '$count 張照片';
  }

  @override
  String get scanAddAnother => '再拍一面';

  @override
  String get scanSideFront => '正面';

  @override
  String get scanSideBack => '背面';

  @override
  String get detailCardholderName => '持卡人姓名';

  @override
  String get detailSecurityCode => '安全碼';

  @override
  String get detailNationality => '國籍';

  @override
  String get detailPlaceOfIssue => '簽發地';

  @override
  String get detailIssuingAuthority => '簽發機關';

  @override
  String get detailLicenceClass => '駕駛車型';

  @override
  String get detailPolicyNumber => '保單號碼';

  @override
  String get detailPlateNumber => '車牌號碼';

  @override
  String get detailVehicleIdentification => '車身號碼';

  @override
  String get detailMembershipLevel => '等級';

  @override
  String get detailSensitiveNote => '預設隱藏，加密保存在這台手機裡，絕不上傳。';

  @override
  String get detailReveal => '顯示';

  @override
  String get detailHide => '隱藏';

  @override
  String get sortTitle => '排序';

  @override
  String get sortExpiry => '按到期日';

  @override
  String get sortAdded => '按新增時間';

  @override
  String get sortName => '按名稱';

  @override
  String get sortType => '按類型';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsLanguage => '語言';

  @override
  String get settingsLanguageSystem => '跟隨系統';

  @override
  String get settingsAbout => '關於';

  @override
  String get settingsPrivacyTitle => '所有資料都只留在這台手機上';

  @override
  String get settingsPrivacyBody =>
      '你的證件資料、照片和號碼都經過加密，只保存在這台手機裡。Elapsa 沒有帳號，也沒有伺服器，任何內容都不會被上傳。';

  @override
  String settingsVersion(String version) {
    return '版本 $version';
  }

  @override
  String notifyRenewTitle(String type) {
    return '該去辦$type了';
  }

  @override
  String notifyExpiresTitle(String label, int days) {
    return '$label 還有 $days 天到期';
  }

  @override
  String notifyRenewBody(String date) {
    return '到期日是 $date。現在時間還寬裕，從容辦完剛剛好。';
  }

  @override
  String notifyTravelBody(String date) {
    return '到期日是 $date。很多國家要求剩餘效期滿六個月，現在可能已經不能出國了。';
  }

  @override
  String notifyPlainBody(String date) {
    return '到期日：$date。';
  }

  @override
  String get notifyChannelName => '證件到期提醒';

  @override
  String get notifyChannelDescription => '在該動手辦理的時候提醒你，而不是等到來不及。';

  @override
  String get settingsAppearance => '外觀';

  @override
  String get settingsTheme => '主題';

  @override
  String get themeSystem => '跟隨系統';

  @override
  String get themeLight => '淺色';

  @override
  String get themeDark => '深色';

  @override
  String get settingsWallet => '卡包';

  @override
  String get settingsWalletDisplay => '卡片顯示方式';

  @override
  String get displayNameOnly => '僅名稱';

  @override
  String get displayImageOnly => '僅圖片';

  @override
  String get displayNameAndImage => '名稱與圖片';

  @override
  String get displayNameOnlyBody => '緊湊列表。螢幕上沒有旁人能看到的內容。';

  @override
  String get displayImageOnlyBody => '你自己拍的照片，像打開錢包一樣。';

  @override
  String get displayNameAndImageBody => '照片下方顯示名稱與到期日。';

  @override
  String get settingsRemindersTitle => '提醒';

  @override
  String get settingsRemindersLead => '預設提前提醒';

  @override
  String get settingsRemindersBody => '套用於新加入的證件，每張仍可單獨調整。';

  @override
  String get settingsRemindersAuto => '由每張證件自行決定';

  @override
  String get settingsScheduled => '已排定的提醒';

  @override
  String get settingsResync => '重建提醒排程';

  @override
  String get settingsResyncDone => '提醒排程已重建。';

  @override
  String get settingsDiagnostics => '診斷';

  @override
  String get settingsLastScan => '最近一次辨識';

  @override
  String get settingsLastScanBody => '相機讀到的原始文字，尚未經過解析。某個欄位為空時可用來排查。';

  @override
  String get settingsLastScanEmpty => '本次啟動後尚未掃描過。';

  @override
  String get actionCopy => '複製';

  @override
  String get settingsCopied => '已複製。';

  @override
  String countYears(int years) {
    return '$years 年';
  }

  @override
  String countDays(int days) {
    return '$days 天';
  }

  @override
  String durationLeft(String duration) {
    return '還剩 $duration';
  }

  @override
  String durationAgo(String duration) {
    return '已過期 $duration';
  }

  @override
  String get settingsTransfer => '轉移';

  @override
  String get transferExport => '匯出全部';

  @override
  String get transferExportBody =>
      '所有證件與照片打包成一個加密檔案。用任何方式傳給另一台手機——AirDrop、檔案、傳輸線都行。這也是 Elapsa 唯一的備份：資料只存在這台裝置上。';

  @override
  String get transferImport => '從檔案匯入';

  @override
  String get transferImportBody => '開啟從另一台裝置匯出的封存檔。';

  @override
  String get transferPassphrase => '密碼';

  @override
  String get transferPassphraseNew => '設定密碼';

  @override
  String get transferPassphraseNewBody =>
      '在另一台手機上開啟封存檔時需要輸入完全相同的密碼。沒有人能幫你找回——Elapsa 也不能，這正是檔案萬一遺失仍然安全的原因。';

  @override
  String get transferPassphraseAsk => '請輸入建立此封存檔時使用的密碼。';

  @override
  String get transferPassphraseShort => '至少 8 個字元。';

  @override
  String transferExported(int count) {
    return '已封存 $count 份證件。';
  }

  @override
  String transferImported(int count) {
    return '已匯入 $count 份證件。';
  }

  @override
  String get transferNothing => '暫無可匯出的內容。';

  @override
  String get transferMergeTitle => '如何匯入？';

  @override
  String get transferMerge => '合併';

  @override
  String get transferMergeBody => '保留現有內容，並加入檔案中的證件。';

  @override
  String get transferReplace => '全部取代';

  @override
  String get transferReplaceBody => '先刪除這台手機上的所有證件。';

  @override
  String get transferFailedFile => '這不是 Elapsa 封存檔。';

  @override
  String get transferFailedNew => '此封存檔由更新版本的 Elapsa 建立。';

  @override
  String get transferFailedKey => '密碼錯誤，或檔案已損毀。';

  @override
  String get actionContinue => '繼續';
}
