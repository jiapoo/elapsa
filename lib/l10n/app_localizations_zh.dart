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
  String get fieldRemindMe => '提前多久提醒';

  @override
  String get fieldOptional => '选填';

  @override
  String get fieldHolderHint => '持有人';

  @override
  String get fieldNumberHint => '证件号码';

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
  String get fieldRemindMe => '提前多久提醒';

  @override
  String get fieldOptional => '選填';

  @override
  String get fieldHolderHint => '持有人';

  @override
  String get fieldNumberHint => '證件號碼';

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
}
