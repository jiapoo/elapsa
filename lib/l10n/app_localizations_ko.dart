// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class LKo extends L {
  LKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Elapsa';

  @override
  String get homeNeedsAttention => '확인 필요';

  @override
  String get homeEverythingElse => '그 외';

  @override
  String get homeEmptyTitle => '곧 만료되는 문서가 없습니다';

  @override
  String get homeEmptyBody =>
      '여권, 신분증, 면허증을 추가하면 이미 늦었을 때가 아니라 갱신을 시작해야 할 때 Elapsa가 알려 드립니다.';

  @override
  String get actionAdd => '문서 추가';

  @override
  String get actionScan => '문서 스캔';

  @override
  String get actionSettings => '설정';

  @override
  String get actionCancel => '취소';

  @override
  String get actionDelete => '삭제';

  @override
  String get actionDone => '완료';

  @override
  String get actionRetake => '다시 찍기';

  @override
  String get exportWhereTitle => '아카이브를 어디에 저장할까요?';

  @override
  String get exportToFilesBody =>
      '이 iPhone 또는 iCloud Drive의 폴더를 선택하세요. 나중에 파일 앱에서 찾을 수 있습니다.';

  @override
  String get exportShareTitle => '다른 앱으로 보내기';

  @override
  String get exportShareBody => 'AirDrop, 메시지, Mail 등.';

  @override
  String get exportSavedTitle => '파일에 저장됨';

  @override
  String get exportSavedBody => '파일 앱을 열고 다음 위치로 이동하세요:';

  @override
  String get filesOnMyPhone => '나의 iPhone';

  @override
  String get filesIcloudDrive => 'iCloud Drive';

  @override
  String get typesNew => '새 유형…';

  @override
  String get scanBothSides => '양면을 모두 촬영했습니다.';

  @override
  String get scanKeepGoing => '더 촬영';

  @override
  String get actionOpen => '열기';

  @override
  String get shareFailed => '공유할 수 없습니다.';

  @override
  String get actionSaveToPhotos => '사진에 저장';

  @override
  String get actionSaveToFiles => '파일에 저장';

  @override
  String get photoSavedToPhotos => '사진에 저장됨';

  @override
  String get photoSavedToFiles => '파일에 저장됨';

  @override
  String get photoSaveFailed => '이미지를 저장하지 못했습니다.';

  @override
  String get photoPhotosDenied => 'Elapsa에 사진 추가 권한이 없습니다. 설정에서 허용할 수 있습니다.';

  @override
  String get photoExportNote => 'Elapsa 밖에 저장한 사본은 암호화되지 않습니다.';

  @override
  String get attachmentsTitle => '첨부 파일';

  @override
  String get attachmentsAdd => '첨부 추가';

  @override
  String get attachmentsAddFile => '파일';

  @override
  String get attachmentsAddFileHint => 'PDF, 문서 또는 기타 파일';

  @override
  String get attachmentsAddLink => '링크';

  @override
  String get attachmentsAddLinkHint => '갱신 신청 페이지 같은 웹페이지';

  @override
  String get attachmentsLinkTitle => '링크 추가';

  @override
  String get attachmentsLinkUrl => '웹 주소';

  @override
  String get attachmentsLinkName => '이름(선택)';

  @override
  String get attachmentsLinkInvalid => '웹 주소가 아닌 것 같습니다.';

  @override
  String get attachmentsTooLarge => '이 파일은 50MB를 넘어 첨부할 수 없습니다.';

  @override
  String attachmentsSkippedTooLarge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '50MB를 넘는 파일 $count개가 제외되었습니다.',
      one: '50MB를 넘는 파일 1개가 제외되었습니다.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentsCannotOpen => '이 첨부 파일을 열 수 없습니다.';

  @override
  String get attachmentsRemoveTitle => '이 첨부 파일을 삭제할까요?';

  @override
  String get attachmentsRemoveBody => 'Elapsa에 보관된 사본이 삭제됩니다. 되돌릴 수 없습니다.';

  @override
  String get actionRemove => '삭제';

  @override
  String get actionAddShort => '추가';

  @override
  String get statusExpired => '만료됨';

  @override
  String get statusExpiring => '만료 임박';

  @override
  String get statusRenewNow => '지금 갱신';

  @override
  String get statusValid => '유효';

  @override
  String daysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days일 남음',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days일 전',
    );
    return '$_temp0';
  }

  @override
  String get startRenewingNow => '지금 갱신을 시작하세요';

  @override
  String get travelRuleBadge => '여행에 필요한 6개월 유효기간 미만';

  @override
  String remindersTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '알림 $count개 예약됨',
      zero: '예약된 알림 없음',
    );
    return '$_temp0';
  }

  @override
  String get remindersEmptyBody => '문서를 추가하면 Elapsa가 알림을 예약합니다.';

  @override
  String get remindersBody => '앱을 열지 않아도 알림이 옵니다.';

  @override
  String get editAddTitle => '문서 추가';

  @override
  String get editEditTitle => '문서 편집';

  @override
  String get editScanHelp => '여권, 신분증, 비자의 코드를 읽습니다';

  @override
  String get editFromScanNote => '문서 코드에서 채웠습니다. 모든 항목은 직접 수정할 수 있습니다.';

  @override
  String get editScanNothingRead =>
      '사진을 저장했습니다. 이 면에는 읽을 수 있는 내용이 없으니 아래에 직접 입력해 주세요.';

  @override
  String get editScanRepaired => '스캔했습니다. 코드가 조금 흐릿했으니 내용을 확인해 주세요.';

  @override
  String get scanExpiredTitle => '이미 만료된 문서입니다';

  @override
  String scanExpiredBody(String date) {
    return '유효기간이 $date로 이미 지났습니다. 지금 갱신을 시작하세요. 날짜가 잘못 인식되었다면 아래에서 수정해 주세요.';
  }

  @override
  String get scanExpiredOk => '확인';

  @override
  String get fieldType => '종류';

  @override
  String get fieldName => '이름';

  @override
  String fieldNameHint(String type) {
    return '내 $type';
  }

  @override
  String get fieldNameRequired => '이름을 입력하세요';

  @override
  String get fieldExpiry => '만료일';

  @override
  String get fieldExpiryEmpty => '날짜 선택';

  @override
  String get fieldExpiryRequired => '만료일을 선택하세요';

  @override
  String get fieldIssueDate => '유효 시작일';

  @override
  String get fieldRemindMe => '알림 시작';

  @override
  String get fieldOptional => '선택 사항';

  @override
  String get fieldHolderHint => '소유자';

  @override
  String get fieldNumberHint => '문서 번호';

  @override
  String get fieldNumberLabel => '카드 번호';

  @override
  String get imageOptionsTitle => '이 사진을 다시 찍거나 삭제할까요?';

  @override
  String get fieldImages => '사진';

  @override
  String get editSave => '저장';

  @override
  String get editDeleteTitle => '이 문서를 삭제할까요?';

  @override
  String get editDeleteBody => '알림과 사진도 함께 삭제됩니다.';

  @override
  String leadExplainNoDate(String lead) {
    return '만료 $lead 전에 알려 드리고, 날짜가 다가오면 다시 알려 드립니다.';
  }

  @override
  String leadExplainFirst(String date) {
    return '첫 알림은 $date이며, 날짜가 다가오면 다시 알려 드립니다.';
  }

  @override
  String get leadExplainPassed => '그 시기는 이미 지났습니다. 지금 시작하세요.';

  @override
  String leadWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks주',
    );
    return '$_temp0';
  }

  @override
  String leadMonths(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months개월',
    );
    return '$_temp0';
  }

  @override
  String leadYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years년',
    );
    return '$_temp0';
  }

  @override
  String get sixMonthRuleNote =>
      '많은 나라에서 입국일 기준 6개월 이상의 유효기간을 요구하므로, 이 문서는 만료 약 6개월 전부터 여행에 사용할 수 없게 됩니다.';

  @override
  String get typePassport => '여권';

  @override
  String get typeNationalId => '신분증';

  @override
  String get typeDriversLicence => '운전면허증';

  @override
  String get typeVisa => '비자';

  @override
  String get typeResidencePermit => '체류 허가증';

  @override
  String get typeVehicleRegistration => '자동차 등록증';

  @override
  String get typeInsurance => '보험';

  @override
  String get typeProfessionalLicence => '자격증';

  @override
  String get typeMembership => '멤버십';

  @override
  String get typeBankCard => '은행 카드';

  @override
  String get typeOther => '기타';

  @override
  String get scanTitle => '문서 스캔';

  @override
  String get scanHintSearching => '문서를 평평하게 두고 카메라를 비추세요';

  @override
  String get scanHintFound => '움직이지 마세요';

  @override
  String get scanHintNoCamera => '이 기기에는 카메라가 없습니다. 사진에서 코드를 읽어 주세요';

  @override
  String get scanChoosePhoto => '사진 선택';

  @override
  String get scanEnterByHand => '직접 입력';

  @override
  String get scanNoCameraTitle => '사진에서 스캔';

  @override
  String get scanNoCameraBody => '이미 가지고 있는 문서 사진에서 코드를 읽을 수 있습니다.';

  @override
  String get scanFailedNoCode =>
      '문서 코드를 찾지 못했습니다. 카드를 화면에 가득 채우고 아래쪽 코드 줄이 선명하게 보이도록 해 주세요.';

  @override
  String get scanFailedUnreadable =>
      '코드는 찾았지만 깨끗하게 읽지 못했습니다. 빛 반사를 줄여 다시 시도하거나 직접 입력해 주세요.';

  @override
  String get scanFailedPhoto => '이 사진을 읽을 수 없습니다.';

  @override
  String get scanFailedCapture => '사진을 찍지 못했습니다. 다시 시도해 주세요.';

  @override
  String scanPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '사진 $count장',
    );
    return '$_temp0';
  }

  @override
  String get scanAddAnother => '다른 면 추가';

  @override
  String get scanSideFront => '앞면';

  @override
  String get scanSideBack => '뒷면';

  @override
  String get detailCardholderName => '카드 명의';

  @override
  String get detailSecurityCode => '보안 코드';

  @override
  String get detailNationality => '국적';

  @override
  String get detailPlaceOfIssue => '발급지';

  @override
  String get detailIssuingAuthority => '발급 기관';

  @override
  String get detailLicenceClass => '종류';

  @override
  String get detailPolicyNumber => '증권 번호';

  @override
  String get detailPlateNumber => '차량 번호';

  @override
  String get detailVehicleIdentification => '차대번호';

  @override
  String get detailMembershipLevel => '등급';

  @override
  String get detailSensitiveNote => '기본적으로 숨겨지며, 이 기기에서 암호화되고 업로드되지 않습니다.';

  @override
  String get detailReveal => '보기';

  @override
  String get detailHide => '숨기기';

  @override
  String get sortTitle => '정렬';

  @override
  String get sortExpiry => '만료일';

  @override
  String get sortAdded => '최근 추가';

  @override
  String get sortName => '이름';

  @override
  String get sortType => '종류';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsLanguageSystem => '시스템 기본값';

  @override
  String get settingsAbout => '정보';

  @override
  String get settingsPrivacyTitle => '모든 것이 이 기기에만 남습니다';

  @override
  String get settingsPrivacyBody =>
      '문서와 사진, 번호는 암호화되어 이 휴대폰에만 저장됩니다. Elapsa에는 계정도 서버도 없으며, 어떤 것도 업로드되지 않습니다.';

  @override
  String settingsVersion(String version) {
    return '버전 $version';
  }

  @override
  String notifyRenewTitle(String type) {
    return '$type 갱신할 때입니다';
  }

  @override
  String notifyExpiresTitle(String label, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days일',
    );
    return '$label 만료까지 $_temp0';
  }

  @override
  String notifyRenewBody(String date) {
    return '$date에 만료됩니다. 서두르지 않고 갱신할 수 있는 여유가 있으니, 지금 시작하면 넉넉히 마칠 수 있습니다.';
  }

  @override
  String notifyTravelBody(String date) {
    return '$date에 만료됩니다. 많은 나라에서 6개월 이상의 유효기간을 요구하므로 이미 여행에 사용할 수 없을 수도 있습니다.';
  }

  @override
  String notifyPlainBody(String date) {
    return '$date에 만료됩니다.';
  }

  @override
  String get notifyChannelName => '갱신 알림';

  @override
  String get notifyChannelDescription => '너무 늦었을 때가 아니라 갱신을 시작할 때를 알려 드립니다.';

  @override
  String get settingsAppearance => '화면';

  @override
  String get settingsTheme => '테마';

  @override
  String get themeSystem => '기기 설정 따르기';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get settingsWallet => '홈 화면';

  @override
  String get settingsWalletDisplay => '카드 표시 방식';

  @override
  String get displayNameOnly => '이름만';

  @override
  String get displayImageOnly => '사진만';

  @override
  String get displayNameAndImage => '이름과 사진';

  @override
  String get displayNameOnlyBody => '간결한 목록입니다. 어깨 너머로 읽힐 만한 내용이 화면에 없습니다.';

  @override
  String get displayImageOnlyBody => '직접 찍은 사진으로, 펼친 지갑처럼 보여 줍니다.';

  @override
  String get displayNameAndImageBody => '사진 아래에 이름과 만료일을 보여 줍니다.';

  @override
  String get settingsRemindersTitle => '알림';

  @override
  String get settingsRemindersLead => '기본 알림 시기';

  @override
  String get settingsRemindersBody => '새 문서에 적용됩니다. 문서마다 따로 바꿀 수 있습니다.';

  @override
  String get settingsRemindersAuto => '문서마다 선택';

  @override
  String get settingsScheduled => '예약된 알림';

  @override
  String get settingsResync => '일정 다시 만들기';

  @override
  String get settingsResyncDone => '알림 일정을 다시 만들었습니다.';

  @override
  String get settingsDiagnostics => '진단';

  @override
  String get settingsLastScan => '마지막 스캔';

  @override
  String get settingsLastScanBody =>
      'Elapsa가 해석하기 전, 카메라가 읽은 그대로의 내용입니다. 항목이 비어 있을 때 유용합니다.';

  @override
  String get settingsLastScanEmpty => '이번 세션에서는 아직 스캔하지 않았습니다.';

  @override
  String get actionCopy => '복사';

  @override
  String get settingsCopied => '복사했습니다.';

  @override
  String countYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years년',
    );
    return '$_temp0';
  }

  @override
  String countDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days일',
    );
    return '$_temp0';
  }

  @override
  String durationLeft(String duration) {
    return '$duration 남음';
  }

  @override
  String durationAgo(String duration) {
    return '$duration 전';
  }

  @override
  String get settingsTransfer => '옮기기';

  @override
  String get transferExport => '모두 내보내기';

  @override
  String get transferExportBody =>
      '모든 문서와 사진을 암호화된 파일 하나로 묶습니다. AirDrop, 파일 앱, 케이블 등 원하는 방법으로 다른 휴대폰에 보내세요. Elapsa의 유일한 백업이기도 합니다. 이 기기 외에는 어디에도 저장되지 않습니다.';

  @override
  String get transferImport => '파일에서 가져오기';

  @override
  String get transferImportBody => '다른 기기에서 내보낸 아카이브를 엽니다.';

  @override
  String get transferPassphrase => '암호 문구';

  @override
  String get transferPassphraseNew => '암호 문구 정하기';

  @override
  String get transferPassphraseNewBody =>
      '다른 휴대폰에서 아카이브를 열 때 정확히 같은 암호 문구가 필요합니다. 누구도 복구해 줄 수 없습니다. Elapsa도 할 수 없기에 파일이 엉뚱한 곳에 가도 안전합니다.';

  @override
  String get transferPassphraseAsk => '이 아카이브를 만들 때 사용한 암호 문구를 입력하세요.';

  @override
  String get transferPassphraseShort => '8자 이상이어야 합니다.';

  @override
  String transferExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '문서 $count개를 내보냈습니다.',
    );
    return '$_temp0';
  }

  @override
  String transferImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '문서 $count개를 가져왔습니다.',
    );
    return '$_temp0';
  }

  @override
  String get transferNothing => '아직 내보낼 문서가 없습니다.';

  @override
  String get transferMergeTitle => '어떻게 가져올까요?';

  @override
  String get transferMerge => '합치기';

  @override
  String get transferMergeBody => '지금 있는 문서는 그대로 두고 파일의 내용을 추가합니다.';

  @override
  String get transferReplace => '모두 바꾸기';

  @override
  String get transferReplaceBody => '먼저 이 휴대폰의 모든 문서를 삭제합니다.';

  @override
  String get transferFailedFile => 'Elapsa 아카이브가 아닙니다.';

  @override
  String get transferFailedNew => '더 새로운 버전의 Elapsa에서 만든 아카이브입니다.';

  @override
  String get transferFailedKey => '암호 문구가 틀렸거나 파일이 손상되었습니다.';

  @override
  String get actionContinue => '계속';

  @override
  String shortYears(int years) {
    return '$years년';
  }

  @override
  String shortDays(int days) {
    return '$days일';
  }

  @override
  String get shortExpired => '만료';

  @override
  String get transferProtect => '암호 문구로 보호';

  @override
  String get transferProtectBody =>
      '파일은 전달 후에도 양쪽 파일 앱에 남기 때문에 켜 두는 것이 좋습니다. 바로 가져와서 삭제할 아카이브일 때만 끄세요.';

  @override
  String get transferChoose => '보낼 항목 선택';

  @override
  String get transferAll => '전체';

  @override
  String get transferNone => '없음';

  @override
  String transferSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '문서 $count개',
      zero: '선택된 항목 없음',
    );
    return '$_temp0';
  }

  @override
  String get cropTitle => '모서리를 끌어 맞추세요';

  @override
  String get cropBody => '문서의 네 모서리에 각각 꼭짓점을 맞춰 주세요.';

  @override
  String get cropReset => '초기화';

  @override
  String get scanAdjust => '자르기 조정';

  @override
  String get scanAutoOn => '자동 감지 켬';

  @override
  String get scanAutoOff => '자동 감지 끔';

  @override
  String get scanAutoStuck => '문서를 찾지 못하나요?';

  @override
  String get scanAutoStuckAction => '수동으로 전환';

  @override
  String get nearbyTitle => '가까운 기기와 주고받기';

  @override
  String get nearbyBody =>
      '다른 휴대폰에서 Elapsa를 열고 이 화면으로 오세요. 파일도 암호 문구도 필요 없으며, 상대방이 수락해야 합니다.';

  @override
  String get nearbySearching => '기기를 찾는 중…';

  @override
  String get nearbyNone => '아직 찾지 못했습니다. 두 휴대폰 모두 이 화면을 열고 Wi-Fi를 켜 주세요.';

  @override
  String get nearbySend => '보내기';

  @override
  String nearbyWaiting(String name) {
    return '$name의 수락을 기다리는 중…';
  }

  @override
  String nearbySendingTo(String name) {
    return '$name(으)로 보내는 중…';
  }

  @override
  String get nearbySentTo => '보냈습니다.';

  @override
  String get nearbyDeclined => '상대방이 거절했습니다.';

  @override
  String nearbyInvite(String name) {
    return '$name에서 문서를 보내려고 합니다.';
  }

  @override
  String get nearbyAccept => '수락';

  @override
  String get nearbyDecline => '거절';

  @override
  String get nearbyReceiving => '받는 중…';

  @override
  String get nearbyUnavailable =>
      '이 기기에서는 아직 가까운 기기로 보내기를 사용할 수 없습니다. 대신 파일로 내보내세요.';

  @override
  String get nearbyName => '이 기기의 표시 이름';

  @override
  String get actionCrop => '자르기';

  @override
  String get leadCustom => '날짜 선택';

  @override
  String get leadDailyTitle => '마지막 한 달은 매일';

  @override
  String get leadDailyBody =>
      '만료까지 한 달이 남으면 Elapsa가 매일 알려 드립니다. 이 알림은 끌 수 없습니다.';

  @override
  String leadOnDate(String date) {
    return '$date';
  }

  @override
  String get editUnsavedTitle => '변경 사항을 저장할까요?';

  @override
  String get editUnsavedBody => '이 문서에 저장하지 않은 변경 사항이 있습니다.';

  @override
  String get editDiscard => '버리기';

  @override
  String get nearbyRoleTitle => '보낼까요, 받을까요?';

  @override
  String get nearbyRoleSend => '이 휴대폰에서 보내기';

  @override
  String get nearbyRoleSendBody => '문서를 골라 다른 기기로 넘겨줍니다.';

  @override
  String get nearbyRoleReceive => '이 휴대폰에서 받기';

  @override
  String get nearbyRoleReceiveBody => '다른 기기가 보낼 때까지 기다립니다. 받기 전에 확인을 요청합니다.';

  @override
  String get nearbyWaitingToReceive => '보내는 기기를 기다리는 중…';

  @override
  String get nearbyWantsToSend => '에서 문서를 보내려고 합니다';

  @override
  String get actionShare => '공유';

  @override
  String get homeArrange => '정리';

  @override
  String get homeSortBy => '정렬 기준';

  @override
  String get homeShowAs => '카드 표시 방식';

  @override
  String get detailTitle => '문서';

  @override
  String get actionEdit => '편집';

  @override
  String get detailReminders => '알림';

  @override
  String detailNextReminder(String date) {
    return '다음 알림: $date';
  }

  @override
  String get detailNoReminders => '예약된 알림이 없습니다.';

  @override
  String detailPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '사진 $count장',
    );
    return '$_temp0';
  }

  @override
  String get settingsTypes => '내가 만든 종류';

  @override
  String get typesBody =>
      'Elapsa는 11가지 문서 종류를 제공하지만, 그것으로 모든 경우를 담을 수는 없습니다. 직접 이름을 붙인 종류는 그 종류로 분류된 카드와 함께 옮겨집니다.';

  @override
  String get typesAdd => '종류 추가';

  @override
  String get typesName => '이름';

  @override
  String get typesLead => '알림 시작';

  @override
  String get typesEmpty => '아직 없습니다.';

  @override
  String typesInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '문서 $count개에서 사용 중',
    );
    return '$_temp0';
  }

  @override
  String get typesRemove => '삭제';

  @override
  String get editLastScan => '카메라가 읽은 내용';

  @override
  String get extrasTitle => '내가 만든 항목';

  @override
  String get extrasAdd => '항목 추가';

  @override
  String get extrasName => '항목 이름';

  @override
  String get extrasValue => '값';

  @override
  String get fieldNeverExpires => '만료 없음';

  @override
  String get fieldNoExpiry => '이 문서는 만료일이 없습니다';

  @override
  String get homeSearch => '검색';

  @override
  String get homeSearchHint => '이름, 종류, 번호…';

  @override
  String get homeNoMatches => '일치하는 항목이 없습니다.';

  @override
  String get detailIssuedBy => '발급 국가';

  @override
  String get fieldNumberPassport => '여권 번호';

  @override
  String get fieldNumberGeneric => '문서 번호';

  @override
  String get paywallTitle => '모든 문서를 한곳에';

  @override
  String paywallBody(int limit) {
    return '무료 버전은 문서를 $limit개까지 보관합니다. 한 번 구매로 문서를 무제한 추가하세요.';
  }

  @override
  String get paywallPointUnlimited => '문서와 알림 무제한';

  @override
  String get paywallPointOnce => '한 번만 결제. 구독이 아니며 자동 갱신도 없습니다.';

  @override
  String get paywallPointPrivate => '여전히 계정이 필요 없고, 데이터는 휴대폰 밖으로 나가지 않습니다.';

  @override
  String paywallBuy(String price) {
    return '$price에 잠금 해제';
  }

  @override
  String get paywallLoadingPrice => '가격을 불러오는 중…';

  @override
  String get paywallRestore => '구매 복원';

  @override
  String get paywallNotNow => '나중에';

  @override
  String get paywallPending => '승인을 기다리고 있습니다. 구매가 승인되면 바로 잠금이 해제됩니다.';

  @override
  String get paywallFailed => '구매가 완료되지 않았습니다. 다시 시도해 주세요.';

  @override
  String get paywallNothingToRestore => '이 계정에서 이전 구매를 찾지 못했습니다.';

  @override
  String get paywallStoreUnavailable =>
      '지금은 스토어에 연결할 수 없습니다. 연결 상태를 확인한 후 다시 시도해 주세요.';

  @override
  String get paywallRetry => '다시 시도';

  @override
  String get paywallThanks => '무제한 버전이 잠금 해제되었습니다. Elapsa를 응원해 주셔서 감사합니다.';

  @override
  String get paywallRestored => '다시 오신 것을 환영합니다. 무제한 버전이 다시 잠금 해제되었습니다.';

  @override
  String paywallImportBlocked(int limit) {
    return '가져오지 않았습니다. 무료 버전은 문서를 $limit개까지 보관합니다.';
  }

  @override
  String get settingsUnlimited => 'Elapsa 무제한';

  @override
  String get settingsUnlimitedOn => '잠금 해제됨. 문서를 원하는 만큼 추가할 수 있습니다.';

  @override
  String settingsUnlimitedUsage(int count, int limit) {
    return '무료 문서 $limit개 중 $count개 사용';
  }

  @override
  String get settingsUnlimitedUnlock => '무제한 잠금 해제';
}
