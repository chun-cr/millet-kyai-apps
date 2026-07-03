// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '맥 AI 건강';

  @override
  String get appBrandPrefix => '맥 ';

  @override
  String get appBrandSuffix => ' 건강';

  @override
  String seasonalSolarTermTag(String solarTerm, String element) {
    return '$solarTerm · $element';
  }

  @override
  String get solarTermMinorCold => '소한';

  @override
  String get solarTermMajorCold => '대한';

  @override
  String get solarTermStartOfSpring => '입춘';

  @override
  String get solarTermRainWater => '우수';

  @override
  String get solarTermAwakeningOfInsects => '경칩';

  @override
  String get solarTermSpringEquinox => '춘분';

  @override
  String get solarTermClearAndBright => '청명';

  @override
  String get solarTermGrainRain => '곡우';

  @override
  String get solarTermStartOfSummer => '입하';

  @override
  String get solarTermGrainFull => '소만';

  @override
  String get solarTermGrainInEar => '망종';

  @override
  String get solarTermSummerSolstice => '하지';

  @override
  String get solarTermMinorHeat => '소서';

  @override
  String get solarTermMajorHeat => '대서';

  @override
  String get solarTermStartOfAutumn => '입추';

  @override
  String get solarTermEndOfHeat => '처서';

  @override
  String get solarTermWhiteDew => '백로';

  @override
  String get solarTermAutumnEquinox => '추분';

  @override
  String get solarTermColdDew => '한로';

  @override
  String get solarTermFrostDescent => '상강';

  @override
  String get solarTermStartOfWinter => '입동';

  @override
  String get solarTermMinorSnow => '소설';

  @override
  String get solarTermMajorSnow => '대설';

  @override
  String get solarTermWinterSolstice => '동지';

  @override
  String get authInspectionMotto => '망 · 문 · 문 · 절';

  @override
  String get authPhoneLogin => '手机号登录';

  @override
  String get authEmailLogin => '邮箱登录';

  @override
  String get authPhoneLabel => '전화번호';

  @override
  String get authPhoneHint => '전화번호를 입력해 주세요';

  @override
  String get authPhoneFormatError => '올바른 전화번호를 입력해 주세요';

  @override
  String get authEmailLabel => '邮箱';

  @override
  String get authEmailHint => '请输入邮箱';

  @override
  String get authEmailFormatError => '请输入正确的邮箱';

  @override
  String get authNameLabel => '닉네임';

  @override
  String get authNameHint => '닉네임을 입력해 주세요';

  @override
  String get authPasswordLabel => '비밀번호';

  @override
  String get authPasswordHint => '비밀번호를 입력해 주세요';

  @override
  String get authPasswordMin6 => '비밀번호는 6자 이상이어야 합니다';

  @override
  String get authPasswordMin8 => '비밀번호는 8자 이상이어야 합니다';

  @override
  String get authConfirmPasswordLabel => '비밀번호 확인';

  @override
  String get authConfirmPasswordHint => '비밀번호를 다시 입력해 주세요';

  @override
  String get authPasswordMismatch => '비밀번호가 일치하지 않습니다';

  @override
  String get authForgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get authLoginButton => '로그인';

  @override
  String get authLoginFailed => '로그인에 실패했어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get authOtherMethods => '다른 방법';

  @override
  String get authWechatLogin => 'WeChat';

  @override
  String get authAppleLogin => 'Apple로 로그인';

  @override
  String get authVerificationCodeLabel => '인증코드';

  @override
  String get authVerificationCodeHint => '인증코드를 입력해 주세요';

  @override
  String get authSendCode => '코드 보내기';

  @override
  String authResendCode(int seconds) {
    return '${seconds}s 후 재전송';
  }

  @override
  String get authPasswordLogin => '비밀번호 로그인';

  @override
  String get authCodeLogin => '인증코드 로그인';

  @override
  String get authLoggingIn => '로그인 중…';

  @override
  String get authSendCodeFailed => '인증코드 전송에 실패했어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get authCodeSent => '인증코드를 보냈어요. 메시지를 확인해 주세요.';

  @override
  String authCodeSentToReceiver(String receiver) {
    return '인증코드를 $receiver(으)로 보냈어요';
  }

  @override
  String get authWechatUnsupported => 'WeChat 미니프로그램 인증은 아직 연결되지 않았습니다.';

  @override
  String get authWechatCodeMissing => 'WeChat 인증 코드를 받아오지 못했어요.';

  @override
  String get authWechatCompletedWithoutToken =>
      'WeChat 인증은 완료됐지만 로그인 토큰이 반환되지 않았어요.';

  @override
  String authWechatStatusPendingBinding(String status) {
    return 'WeChat 인증에서 상태 \"$status\" 가 반환됐어요. 후속 연결 플로우는 아직 미구현 상태예요.';
  }

  @override
  String get authSendCodeFirst => '먼저 인증코드를 받아 주세요.';

  @override
  String get commonContinue => '계속';

  @override
  String get authCaptchaTitle => '캡차 인증';

  @override
  String authCaptchaManualPrompt(String provider) {
    return '먼저 $provider 인증을 완료한 뒤 provider 가 반환한 JSON 결과를 붙여 넣어 계속해 주세요.';
  }

  @override
  String get authCaptchaInitPayloadLabel => '초기화 파라미터';

  @override
  String get authCaptchaResultJsonLabel => '검증 결과 JSON';

  @override
  String get authCaptchaManualResultHint => '예: ticket=ticket-001';

  @override
  String get authCaptchaInvalidJson => '올바른 JSON 객체를 입력해 주세요.';

  @override
  String get authCaptchaFailed => '캡차 인증에 실패했어요. 다시 시도해 주세요.';

  @override
  String get authCaptchaLoadingPage => '캡차 페이지를 불러오는 중이에요...';

  @override
  String get authCaptchaReady => '캡차가 준비되었어요. 인증을 완료해 주세요.';

  @override
  String get authCaptchaPageLoadFailed => '캡차 페이지를 불러오지 못했어요. 닫은 뒤 다시 시도해 주세요.';

  @override
  String get authCaptchaInitFailed => '캡차 초기화에 실패했어요. 닫은 뒤 다시 시도해 주세요.';

  @override
  String get authCaptchaRequiredUnsupported =>
      '현재 환경에서는 캡차 인증을 지원하지 않아요. 잠시 후 다시 시도해 주세요.';

  @override
  String get authForgotPasswordTip => '가입한 전화번호로 비밀번호를 재설정하거나 고객센터로 문의해 주세요.';

  @override
  String get commonConfirm => '알겠어요';

  @override
  String get authNoAccount => '아직 계정이 없으신가요?';

  @override
  String get authRegisterNow => '지금 가입하기';

  @override
  String get registerGoLogin => '로그인으로 이동';

  @override
  String get registerCreateAccountTitle => '계정 만들기';

  @override
  String get registerCreateAccountSubtitle =>
      '전화번호와 인증 코드로 계정을 만들고 빠르게 시작해 보세요';

  @override
  String get registerCreateAccountAction => '계정 만들기';

  @override
  String get registerCreateFailed => '계정 생성에 실패했어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get registerPasswordSetupPrompt =>
      '가입이 완료되었어요. 나중에 \'내 정보 - 설정 - 계정 및 보안\'에서 로그인 비밀번호를 설정할 수 있어요.';

  @override
  String get registerPhoneMode => '휴대폰 가입';

  @override
  String get registerEmailMode => '이메일 가입';

  @override
  String get registerAlreadyHaveAccount => '이미 계정이 있으신가요? ';

  @override
  String get registerLoginNow => '바로 로그인';

  @override
  String get registerGenderOptional => '성별';

  @override
  String get registerGenderRequired => '성별을 선택해 주세요';

  @override
  String get completeProfileTitle => '프로필 완성';

  @override
  String get completeProfileSubtitle =>
      '아바타, 닉네임, 성별을 보완하면 이후 맞춤형 관리 제안이 더 정교해져요.';

  @override
  String get completeProfileSkip => '건너뛰기';

  @override
  String get completeProfileStart => '체험 시작';

  @override
  String get registerGenderMale => '남성';

  @override
  String get registerGenderFemale => '여성';

  @override
  String get registerGenderOther => '선택 안 함';

  @override
  String get registerPasswordHint => '8자 이상, 영문과 숫자를 포함해 주세요';

  @override
  String get registerAgreeTermsFirst => '먼저 이용약관과 개인정보처리방침에 동의해 주세요';

  @override
  String get registerReadAndAgree => '다음 내용에 동의합니다';

  @override
  String get registerUserAgreement => '이용약관';

  @override
  String get registerAnd => '및';

  @override
  String get registerPrivacyPolicy => '개인정보처리방침';

  @override
  String get registerHealthDataClause => '(건강 데이터 수집 및 이용 안내 포함)';

  @override
  String get registerPrivacyTip =>
      '건강 데이터는 AI 분석에만 사용되며 암호화 저장됩니다. 상업적 용도로 사용하거나 제3자와 공유하지 않습니다.';

  @override
  String get passwordStrengthWeak => '약함';

  @override
  String get passwordStrengthMedium => '보통';

  @override
  String get passwordStrengthStrong => '강함';

  @override
  String get passwordStrengthVeryStrong => '매우 강함';

  @override
  String get bottomNavHome => '홈';

  @override
  String get bottomNavScan => '스캔';

  @override
  String get bottomNavReport => '리포트';

  @override
  String get bottomNavProfile => '프로필';

  @override
  String get commonCancel => '취소';

  @override
  String get commonSave => '저장';

  @override
  String get commonRetry => '重试';

  @override
  String get commonLoading => '불러오는 중';

  @override
  String get commonViewAll => '전체 보기';

  @override
  String get commonFeatureInDevelopment => '기능 개발 중입니다';

  @override
  String get commonPleaseEnterName => '이름을 입력해 주세요';

  @override
  String get unitTimes => '회';

  @override
  String get unitPoints => '점';

  @override
  String get unitStage => '단계';

  @override
  String get statusUnlocked => '잠금 해제됨';

  @override
  String get statusLocked => '잠금 상태';

  @override
  String get actionUnlockNow => '지금 열기';

  @override
  String get historyReportTitle => '체질 평가 리포트';

  @override
  String get historyPastReports => '지난 리포트';

  @override
  String get historyHealthTrend => '건강 추이';

  @override
  String get historyHealthIndex => '건강 지수';

  @override
  String get historyRiskTrend => '위험 지수 추이';

  @override
  String homeGreetingMorning(String name) {
    return '좋은 아침입니다, $name님';
  }

  @override
  String get homeGreetingQuestion => '오늘 안색은 어떠신가요?';

  @override
  String homeStatusSummary(String constitution, int days) {
    return '$constitution · 마지막 검사 $days일 전';
  }

  @override
  String get homeSuggestion => '제안: 물을 충분히 마시고 규칙적인 생활을 유지하세요.';

  @override
  String get homeQuickScanTitle => 'AI 망진 체크';

  @override
  String get homeQuickScanTag => '망 · 문 · 문 · 절';

  @override
  String get homeQuickScanFaceTitle => '안면 관찰';

  @override
  String get homeQuickScanFaceSub => '안색 확인';

  @override
  String get homeQuickScanTongueTitle => '설진 확인';

  @override
  String get homeQuickScanTongueSub => '설태 보기';

  @override
  String get homeQuickScanPalmTitle => '손바닥 경락';

  @override
  String get homeQuickScanPalmSub => '손금 보기';

  @override
  String get homeFunctionNavTitle => '기능 바로가기';

  @override
  String get homeFunctionConstitution => '체질 분석';

  @override
  String get homeFunctionMeridianTherapy => '경락 관리';

  @override
  String get homeFunctionDietAdvice => '식이 제안';

  @override
  String get homeFunctionMentalWellness => '정신 양생';

  @override
  String get homeFunctionSeasonalCare => '사계절 관리';

  @override
  String get homeFunctionHistory => '기록 보기';

  @override
  String get homeTodayCareTitle => '오늘의 건강 팁';

  @override
  String get homeTodayCareCount => '추천 2개';

  @override
  String get homeTipDietTag => '식이';

  @override
  String get homeTipDietWuxing => '토';

  @override
  String get homeTipDietBody =>
      '오늘 절기에는 담백한 식사가 좋습니다. 마와 백합은 폐를 윤택하게 하고 비위를 도와 기허 경향이 있는 분들에게 적합합니다.';

  @override
  String get homeTipRoutineTag => '생활';

  @override
  String get homeTipRoutineWuxing => '수';

  @override
  String get homeTipRoutineBody =>
      '자시(23시 이전)에 잠들면 간담 회복에 도움이 됩니다. 밤늦은 화면 사용 시간을 줄여 보세요.';

  @override
  String get homeCollapsedTitle => '맥 AI 건강';

  @override
  String get homeHealthScoreLabel => '건강 점수';

  @override
  String get homeBalancedConstitution => '평화 체질';

  @override
  String get homeBalanceState => '음양 균형이 비교적 안정적입니다';

  @override
  String get homeStartFullScan => '전체 스마트 진단 시작';

  @override
  String get homeLastReportInsight => '기허 경향 · 비위 허약';

  @override
  String get homeLastReportSummary =>
      '비기(脾氣)가 부족하고 운화 기능이 다소 저하되어 있습니다. 얼굴빛이 약간 누렇고, 혀는 담하며 백태가 보입니다. 비기를 보하고 규칙적인 생활을 유지해 주세요.';

  @override
  String get profileTitle => '프로필';

  @override
  String get profileBadgeBalanced => '평화질';

  @override
  String get profileDisplayName => '샤오밍';

  @override
  String get profileStatusStable => '오늘 상태는 안정적입니다. 균형 잡힌 양생을 유지해 보세요.';

  @override
  String get profileBalancedType => '평화 체질';

  @override
  String get profileMetricConsultCount => '상담 횟수';

  @override
  String get profileMetricHealthScore => '현재 건강력';

  @override
  String get profileMetricConstitutionStages => '체질 변화';

  @override
  String get profileSectionFoundation => '건강의 기반';

  @override
  String get profileHeight => '키';

  @override
  String get profileWeight => '체중';

  @override
  String get profileInnateBase => '선천 체질';

  @override
  String get profileInnateBaseValue => '비위 허약 가족 경향';

  @override
  String get profileInnateBaseNote => '부모 모두 비위 허약 경향이 있어 중기가 약한 체질 기반이 시사됩니다.';

  @override
  String get profileCurrentBias => '현재 편향';

  @override
  String get profileCurrentBiasValue => '기허와 습체';

  @override
  String get profileCurrentBiasNote =>
      '최근에는 기허와 습곤 경향이 두드러지며 수면과 식사의 영향을 쉽게 받는 상태입니다.';

  @override
  String get profileHealthScore30Days => '최근 30일 건강 점수';

  @override
  String get profileHealthScoreTrendNote => '전체적으로 안정적이며 최근 1주일은 가벼운 변동이 있습니다.';

  @override
  String get profileSectionCabin => '나의 케어 허브';

  @override
  String get profileCabinAcupoints => '저장한 혈자리';

  @override
  String get profileCabinAcupointsValue => '족삼리 · 기해 · 관원';

  @override
  String get profileCabinDiet => '맞춤 식이요법';

  @override
  String get profileCabinDietValue => '산약과 율무죽 · 당삼과 복령 닭조림';

  @override
  String get profileCabinFollowup => '재평가 알림';

  @override
  String get profileCabinFollowupValue => '다음 조리 평가까지 3일 남음';

  @override
  String get profileSectionServices => '건강 지원';

  @override
  String get profileMenuAccount => '계정 및 가족 프로필';

  @override
  String get profileMenuAccountSub => '개인 정보, 가족 정보, 건강 기록을 관리합니다';

  @override
  String get profileMenuShippingAddress => '배송지 주소';

  @override
  String get profileMenuShippingAddressSub => '배송지 주소를 추가, 수정, 관리합니다';

  @override
  String get profileMenuPoints => '포인트 센터';

  @override
  String get profileMenuPointsSub => '출석으로 포인트를 받고 내역을 확인합니다';

  @override
  String get profileMenuSettings => '설정';

  @override
  String get profileMenuSettingsSub => '계정 보안, 로그인 방식, 일반 설정을 관리합니다';

  @override
  String get profileMenuReminder => '절기 건강 알림';

  @override
  String get profileMenuReminderSub => '알림, 생활 리듬, 절기 양생 제안';

  @override
  String get profileMenuAdvisor => '전담 상담사에게 문의';

  @override
  String get profileMenuAdvisorSub => '양생 상담, 재진 연락, 건강 문의';

  @override
  String get profileMenuLanguage => '언어 설정';

  @override
  String get profileMenuLanguageSub => '앱 표시 언어를 변경합니다';

  @override
  String get profileMenuAbout => '맥 AI 소개';

  @override
  String get profileMenuAboutSub => '서비스 안내 및 현재 버전 v1.0.0';

  @override
  String get profileAddressTitle => '배송지 주소';

  @override
  String get profileAddressAdd => '주소 추가';

  @override
  String get profileAddressEmptyTitle => '배송지 주소가 아직 없습니다';

  @override
  String get profileAddressEmptyBody =>
      '자주 쓰는 주소를 추가하면 주문 시 배송 정보를 더 빠르게 입력할 수 있습니다.';

  @override
  String get profileAddressReceiver => '받는 사람';

  @override
  String get profileAddressPhone => '휴대폰 번호';

  @override
  String get profileAddressProvinceName => '省份名称';

  @override
  String get profileAddressProvinceCode => '省份编码';

  @override
  String get profileAddressCityName => '城市名称';

  @override
  String get profileAddressCityCode => '城市编码';

  @override
  String get profileAddressDistrictName => '区县名称';

  @override
  String get profileAddressDistrictCode => '区县编码';

  @override
  String get profileAddressStreetName => '街道名称';

  @override
  String get profileAddressStreetCode => '街道编码';

  @override
  String get profileAddressRegion => '지역';

  @override
  String get profileAddressDetail => '상세 주소';

  @override
  String get profileAddressTag => '주소 태그';

  @override
  String get profileAddressSetDefault => '기본으로 설정';

  @override
  String get profileAddressDefault => '기본';

  @override
  String get profileAddressEdit => '수정';

  @override
  String get profileAddressDelete => '삭제';

  @override
  String get profileAddressDeleteTitle => '배송지 주소 삭제';

  @override
  String get profileAddressDeleteBody => '삭제하면 복구할 수 없습니다. 계속하시겠습니까?';

  @override
  String get profileAddressDeleteAction => '삭제';

  @override
  String get profileAddressFormAddTitle => '배송지 주소 추가';

  @override
  String get profileAddressFormEditTitle => '배송지 주소 수정';

  @override
  String get profileAddressValidationReceiver => '받는 사람 이름을 입력해 주세요';

  @override
  String get profileAddressValidationPhone => '올바른 휴대폰 번호를 입력해 주세요';

  @override
  String get profileAddressValidationProvinceName => '请输入省份名称';

  @override
  String get profileAddressValidationProvinceCode => '请输入省份编码';

  @override
  String get profileAddressValidationCityName => '请输入城市名称';

  @override
  String get profileAddressValidationCityCode => '请输入城市编码';

  @override
  String get profileAddressValidationDistrictName => '请输入区县名称';

  @override
  String get profileAddressValidationDistrictCode => '请输入区县编码';

  @override
  String get profileAddressValidationRegion => '지역을 입력해 주세요';

  @override
  String get profileAddressValidationDetail => '상세 주소를 입력해 주세요';

  @override
  String get profileAddressValidationCodeFormat => '编码仅支持字母、数字、下划线和短横线';

  @override
  String get profileAddressValidationStreetPair => '街道名称与街道编码需要同时填写或同时留空';

  @override
  String get profileAddressDefaultToggle => '기본 배송지 주소로 사용';

  @override
  String get profileAddressSaveFailed => '保存收货地址失败，请稍后重试';

  @override
  String get profileAddressLoadFailed => '加载收货地址失败，请稍后重试';

  @override
  String get profileAddressDeleteFailed => '删除收货地址失败，请稍后重试';

  @override
  String get profileAddressDefaultFailed => '设置默认收货地址失败，请稍后重试';

  @override
  String get profilePointsTitle => '포인트 센터';

  @override
  String get profilePointsBalance => '현재 포인트';

  @override
  String get profilePointsTodayGain => '今日获得';

  @override
  String get profilePointsWeekGain => '本周获得';

  @override
  String get profilePointsHisTotal => '累计获得';

  @override
  String get profilePointsMonthlyEarned => '이번 달 적립';

  @override
  String get profilePointsMonthlySpent => '이번 달 사용';

  @override
  String get profilePointsCheckIn => '매일 출석 +5';

  @override
  String get profilePointsCheckInDone => '오늘 출석 완료';

  @override
  String get profilePointsCheckInHint =>
      '매일 출석하면 이후 혜택 교환에 사용할 수 있는 포인트를 받을 수 있습니다.';

  @override
  String get profilePointsCheckInFailed => '签到失败，请稍后重试';

  @override
  String profilePointsCheckInSuccess(int points) {
    return '출석 완료. $points포인트를 받았습니다.';
  }

  @override
  String get profilePointsHistory => '포인트 내역';

  @override
  String get profilePointsTasks => '积分任务';

  @override
  String get profilePointsRegisterTask => '新手任务';

  @override
  String get profilePointsTaskEmpty => '暂无可领取积分任务';

  @override
  String get profilePointsEmpty => '포인트 내역이 아직 없습니다';

  @override
  String get profilePointsLoadFailed => '加载积分信息失败，请稍后重试';

  @override
  String get profilePointsLoadMore => '加载更多';

  @override
  String get profilePointsLoadMoreFailed => '加载更多积分记录失败，请稍后重试';

  @override
  String profilePointsTaskActionUnsupported(String action) {
    return '任务入口“$action”暂不可用';
  }

  @override
  String get profilePointsEntryDailyCheckIn => '매일 출석';

  @override
  String get profilePointsEntryDailyCheckInSub => '오늘 출석 보상이 적립되었습니다';

  @override
  String get profilePointsEntryWelcome => '신규 회원 웰컴 포인트';

  @override
  String get profilePointsEntryWelcomeSub => '신규 회원 활성화 완료 후 지급';

  @override
  String get profilePointsEntryAssessment => '체질 평가 보너스';

  @override
  String get profilePointsEntryAssessmentSub => '개인 맞춤 체질 평가 완료 후 지급';

  @override
  String get profilePointsEntryCoupon => '상담 쿠폰 교환';

  @override
  String get profilePointsEntryCouponSub => '포인트를 사용해 할인 혜택으로 교환했습니다';

  @override
  String get profileLogout => '로그아웃';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsSectionAccount => '계정';

  @override
  String get settingsAccountSecurity => '계정 및 보안';

  @override
  String get settingsAccountSecuritySub => '로그인 방식, 전화번호, 비밀번호 보안을 관리합니다';

  @override
  String get accountSecurityTitle => '계정 및 보안';

  @override
  String get accountSecurityPhoneCodeTip =>
      '현재 가입은 휴대폰 인증 코드 로그인이 기본입니다. 필요하면 나중에 로그인 비밀번호를 추가할 수 있어요.';

  @override
  String get accountSecurityLoginPassword => '로그인 비밀번호 설정';

  @override
  String get accountSecurityLoginPasswordSub =>
      '설정 후에는 전화번호와 비밀번호로 로그인할 수 있습니다. 설정하지 않으면 인증 코드 로그인을 계속 사용합니다.';

  @override
  String get accountSecurityPasswordSet => '설정됨';

  @override
  String get accountSecurityPasswordUnset => '미설정';

  @override
  String get setLoginPasswordTitle => '로그인 비밀번호 설정';

  @override
  String get setLoginPasswordSubtitle =>
      '설정 후에는 전화번호와 비밀번호로 로그인할 수 있습니다. 지금 설정하지 않아도 인증 코드 로그인은 계속 사용할 수 있어요.';

  @override
  String get setLoginPasswordAction => '비밀번호 저장';

  @override
  String get setLoginPasswordSuccess => '로그인 비밀번호가 설정되었어요';

  @override
  String get localeSheetTitle => '언어 선택';

  @override
  String get localeFollowSystem => '시스템 설정 따르기';

  @override
  String get localeChineseSimplified => '간체 중국어';

  @override
  String get localeEnglish => 'English';

  @override
  String get localeJapanese => '日本語';

  @override
  String get localeKorean => '한국어';

  @override
  String get commonViewDetails => '자세히 보기';

  @override
  String get commonFiveElements => '오행';

  @override
  String get profileBmiNormal => '정상';

  @override
  String get scanStepFace => '얼굴';

  @override
  String get scanStepTongue => '혀';

  @override
  String get scanStepPalm => '손바닥';

  @override
  String get scanSkipThisStep => '이 단계 건너뛰기';

  @override
  String get scanProgressLabel => '진행 상황';

  @override
  String scanAnalyzingProgress(int progress) {
    return '분석 중 $progress%';
  }

  @override
  String scanCameraPreviewUnsupported(String platform) {
    return '$platform에서는 아직 카메라 미리보기를 지원하지 않습니다.';
  }

  @override
  String get scanGuideHeaderTitle => '건강 스캔 가이드';

  @override
  String get scanGuideHeroTitle => '3단계 가이드 스캔 완료하기';

  @override
  String get scanGuideHeroSubtitle => '얼굴, 혀, 손바닥 스캔을 통해 AI 건강 리포트를 생성합니다.';

  @override
  String get scanGuideStep1Title => '얼굴 스캔';

  @override
  String get scanGuideStep1Desc => '안색과 표정을 확인합니다';

  @override
  String get scanGuideStep1Detail => '얼굴색, 표정, 전체적인 얼굴 상태를 확인합니다.';

  @override
  String get scanGuideStep2Title => '혀 스캔';

  @override
  String get scanGuideStep2Desc => '혀의 색, 형태, 설태를 확인합니다';

  @override
  String get scanGuideStep2Detail => '혀의 색, 설태, 모양을 통해 체질 경향을 살펴봅니다.';

  @override
  String get scanGuideStep3Title => '손바닥 스캔';

  @override
  String get scanGuideStep3Desc => '손금, 색, 손 상태를 확인합니다';

  @override
  String get scanGuideStep3Detail => '손바닥의 선, 색, 전체 상태를 확인합니다.';

  @override
  String scanGuideStepLabel(int step, String title) {
    return '단계 $step · $title';
  }

  @override
  String get scanGuideWarmPromptTitle => '시작 전 안내';

  @override
  String get scanGuideWarmPromptContent =>
      '밝고 안정된 환경에서 진행해 주세요. 모자, 안경, 액세서리를 벗고 편안한 상태를 유지해 주세요.';

  @override
  String get scanGuideEstimate => '약 2분 · 밝은 곳에서 진행해 주세요';

  @override
  String get scanGuideStartButton => '스캔 시작';

  @override
  String get scanGuidePrivacyNote => '스캔 이미지는 이번 건강 평가에만 사용되며 제3자와 공유되지 않습니다.';

  @override
  String get scanFaceDetectionPermissionRequired => '얼굴 인식을 위해 카메라 권한이 필요합니다.';

  @override
  String get scanCameraPermissionRequired => '계속하려면 카메라 권한이 필요합니다.';

  @override
  String get scanKeepStill => '움직이지 말아 주세요';

  @override
  String get scanMoveLeft => '왼쪽으로 이동해 주세요';

  @override
  String get scanMoveRight => '오른쪽으로 이동해 주세요';

  @override
  String get scanMoveUp => '위로 이동해 주세요';

  @override
  String get scanMoveDown => '아래로 이동해 주세요';

  @override
  String get scanTipBrightLight => '밝고 고른 조명에서 진행해 주세요';

  @override
  String get scanTipKeepSteady => '스캔 중에는 자세를 안정적으로 유지해 주세요';

  @override
  String get scanScanning => '스캔 중';

  @override
  String get scanFaceAlignInFrame => '얼굴을 프레임 안에 맞춰 주세요';

  @override
  String get scanFaceDetectedReady => '얼굴을 인식했습니다 ✓';

  @override
  String get scanFaceTitle => '얼굴 스캔';

  @override
  String get scanFaceTag => '면진';

  @override
  String get scanFaceSubtitle => '얼굴을 프레임 안에 넣고 정면을 바라보며 자연스러운 표정을 유지해 주세요.';

  @override
  String get scanFaceDetail => '얼굴색, 표정, 전체적인 얼굴 상태를 확인합니다.';

  @override
  String get scanFaceTipNoMakeup => '짙은 메이크업은 피해주세요';

  @override
  String get scanFaceTipLookForward => '정면을 바라봐 주세요';

  @override
  String get scanFaceStartButton => '开始面部扫描';

  @override
  String get scanTongueCompleted => '혀 스캔 완료 ✓';

  @override
  String get scanTongueTapToStart => '아래 버튼으로 혀 스캔을 시작해 주세요';

  @override
  String get scanTongueDetectedHold => '혀를 인식했습니다. 2초간 유지해 주세요.';

  @override
  String get scanTongueMouthDetected => '입 주변을 인식했습니다. 자연스럽게 혀를 내밀어 주세요.';

  @override
  String get scanTongueAlignHint => '혀를 내밀고 프레임 안에 맞춰 주세요.';

  @override
  String get scanTongueTitle => '혀 스캔';

  @override
  String get scanTongueTag => '설진';

  @override
  String get scanTongueSubtitle => '자연스럽게 혀를 내밀고 평평하게 유지한 채 2초 정도 멈춰 주세요.';

  @override
  String get scanTongueDetail => '혀의 색, 설태, 모양을 통해 체질 경향을 확인합니다.';

  @override
  String get scanTongueTipNoColoredFood => '색이 강한 음식은 미리 피해주세요';

  @override
  String get scanTongueTipTongueFlat => '혀를 최대한 평평하게 유지해 주세요';

  @override
  String get scanTongueStartButton => '혀 스캔 시작';

  @override
  String get scanTongueNextPalm => '손바닥 스캔으로 이동';

  @override
  String get scanPalmMoveCloser => '손바닥이 너무 멉니다. 조금 더 가까이 가져와 주세요.';

  @override
  String get scanPalmMoveFarther => '손바닥이 너무 가깝습니다. 조금 뒤로 물려 주세요.';

  @override
  String get scanPalmWaitingPermission => '카메라 권한을 기다리는 중입니다';

  @override
  String get scanPalmCompleted => '손바닥 스캔 완료 ✓';

  @override
  String get scanPalmReadyHold => '손바닥을 인식했습니다. 2초간 유지해 주세요.';

  @override
  String get scanPalmOpenDetectedStraighten => '펴진 손을 인식했습니다. 손바닥을 곧게 펴 주세요.';

  @override
  String scanPalmDetectedGesture(String gesture) {
    return '인식된 제스처: $gesture';
  }

  @override
  String get scanPalmStretchOpen => '손바닥을 자연스럽게 펴고 곧게 유지해 주세요.';

  @override
  String get scanPalmAlignHint => '손바닥을 프레임 안에 맞춰 주세요.';

  @override
  String get scanGestureOpenPalm => '손바닥 펼치기';

  @override
  String get scanGestureClosedFist => '주먹 쥐기';

  @override
  String get scanGestureVictory => '브이';

  @override
  String get scanGestureThumbUp => '엄지 올리기';

  @override
  String get scanGestureThumbDown => '엄지 내리기';

  @override
  String get scanGesturePointingUp => '검지 위로';

  @override
  String get scanGestureILoveYou => 'I Love You 제스처';

  @override
  String get scanPalmTitle => '손바닥 스캔';

  @override
  String get scanPalmTag => '장진';

  @override
  String get scanPalmSubtitle => '손바닥을 카메라 쪽으로 향하게 하고 윤곽에 맞춰 자연스럽게 손가락을 펴 주세요.';

  @override
  String get scanPalmDetail => '손바닥의 선, 색, 전체 상태를 확인합니다.';

  @override
  String get scanPalmTipFlatten => '손바닥을 평평하게 유지해 주세요';

  @override
  String get scanPalmViewingReportSoon => '리포트를 여는 중...';

  @override
  String get scanPalmHoldButton => '손바닥을 2초간 유지';

  @override
  String get scanQuestionTitle => '추가 질문';

  @override
  String get scanQuestionSubtitle =>
      '몇 가지 질문에 더 답하면 체질 분석과 최종 리포트를 더 완성도 있게 만들 수 있습니다. 현재 스캔 결과로 바로 리포트를 볼 수도 있습니다.';

  @override
  String get scanQuestionSkipDirectReport => '건너뛰고 리포트 보기';

  @override
  String scanQuestionAnsweredCount(int count) {
    return '$count개 답변 완료';
  }

  @override
  String get scanQuestionOptionalTag => '선택 사항';

  @override
  String get scanQuestionLoadingTitle => '추가 질문을 준비하는 중';

  @override
  String get scanQuestionLoadingBody => '다음 질문을 불러오고 답변 컨텍스트를 정리하고 있습니다.';

  @override
  String get scanQuestionLoadFailed => '질문을 불러오지 못했습니다';

  @override
  String get scanQuestionRetry => '다시 시도';

  @override
  String get scanQuestionMissingQuestion =>
      '지금 표시할 질문이 없습니다. 다시 시도하거나 바로 리포트로 이동하세요.';

  @override
  String get scanQuestionFooterHint =>
      '답변 내용은 체질 분석 보완에만 사용되며, 이미 업로드된 스캔 이미지에는 영향을 주지 않습니다.';

  @override
  String scanQuestionProgressTitle(int current, int total) {
    return '$current/$total번째 질문';
  }

  @override
  String get scanQuestionSectionTitle => '추가 질문';

  @override
  String get scanQuestionSubmitAndReport => '답변 제출 후 리포트 생성';

  @override
  String get scanQuestionNextButton => '다음 질문';

  @override
  String get reportTabOverview => '개요';

  @override
  String get reportTabConstitution => '체질';

  @override
  String get reportTabTherapy => '케어';

  @override
  String get reportTabAdvice => '추천';

  @override
  String get reportHeaderCollapsedTitle => 'AI 건강 리포트';

  @override
  String get reportHeroMeta => '2025.03.14 · AI 사진 평가';

  @override
  String reportHeroTitle(String name) {
    return '$name님의 건강 리포트';
  }

  @override
  String get reportHeroSecondaryBias => '기허 경향';

  @override
  String get reportHeroSummary =>
      '비기가 부족하고 운화 기능이 다소 저하되어 있습니다. 얼굴빛이 약간 누렇고, 혀는 담하며 백태가 보입니다.';

  @override
  String get reportHealthScoreLabel => '건강 점수';

  @override
  String get reportHealthStatus => '체질 상태 · 양호';

  @override
  String get reportOverviewFaceDiagnosisDesc => '안색이 약간 누르며 기력은 비교적 무난합니다';

  @override
  String get reportOverviewTongueDiagnosisDesc => '혀는 담색이며 약간 두꺼운 백태가 보입니다';

  @override
  String get reportOverviewPalmDiagnosisDesc => '손금은 비교적 가늘고 손바닥 색은 안정적입니다';

  @override
  String get reportOverviewDiagScoresTitle => '삼진 점수';

  @override
  String get reportOverviewFeatureDetailsTitle => '소견 상세';

  @override
  String get reportOverviewTongueTitle => '설상';

  @override
  String get reportOverviewTongueImagePlaceholder => '설상 이미지';

  @override
  String get reportOverviewTongueColorLabel => '혀 색';

  @override
  String get reportOverviewTongueColorValue => '담홍';

  @override
  String get reportOverviewTongueCoatingLabel => '설태';

  @override
  String get reportOverviewTongueCoatingValue => '백태 · 약간 두꺼움';

  @override
  String get reportOverviewTongueShapeLabel => '혀 형태';

  @override
  String get reportOverviewTongueShapeValue => '정상';

  @override
  String get reportOverviewWuxingTitle => '오행 · 목왕';

  @override
  String get reportOverviewDiagnosisSummaryTitle => '변증 요약';

  @override
  String get reportOverviewDiagnosisSummaryBody =>
      '이번 소견은 비기허로 인해 운화 기능이 다소 약해진 상태를 보여줍니다. 얼굴빛은 약간 누렇고, 혀는 담색에 백태가 있으며, 맥은 비교적 가늘고 완만한 편입니다. 숨이 차고 쉽게 피로하며 식욕이 떨어지는 경향이 있어, 비기허에 습이 더해진 상태로 볼 수 있습니다.';

  @override
  String get reportOverviewDiagnosisTagSpleenWeak => '비위 허약';

  @override
  String get reportOverviewModuleConstitutionTitle => '체질 상세';

  @override
  String get reportOverviewModuleConstitutionSubtitle => '나의 체질을 확인합니다';

  @override
  String get reportOverviewModuleAcupointTitle => '추천 혈자리';

  @override
  String get reportOverviewModuleAcupointSubtitle => '혈자리 관리 플랜';

  @override
  String get reportOverviewModuleDietTitle => '식이 제안';

  @override
  String get reportOverviewModuleDietSubtitle => '식양생 제안';

  @override
  String get reportOverviewModuleSeasonalTitle => '사계절 양생';

  @override
  String get reportOverviewModuleSeasonalSubtitle => '계절에 맞춘 양생';

  @override
  String get reportOverviewModuleNavTitle => '기능 안내';

  @override
  String get reportOverviewScanMetaDisclaimer =>
      '본 리포트는 AI 사진 평가를 기반으로 한 건강 참고 정보이며 의료 진단이 아닙니다. 필요 시 전문의와 상담해 주세요.';

  @override
  String get reportConstitutionDetailTitle => '체질 상세';

  @override
  String get reportConstitutionCoreConclusionLabel => '핵심 소견';

  @override
  String get reportConstitutionCoreConclusionValue => '주된 체질 경향: 기허질';

  @override
  String get reportConstitutionCoreConclusionBody =>
      '전체적으로는 평화 체질을 바탕으로 하면서도 기허 경향이 비교적 뚜렷합니다. 레이더 차트에서 평화질과 기허질이 두드러지며, 기본적인 체력은 유지되고 있지만 피로, 식사 불균형, 수면 부족이 겹치면 쉽게 권태감과 비위 기능 저하가 나타날 수 있습니다.';

  @override
  String get reportConstitutionYangDeficiency => '양허질';

  @override
  String get reportConstitutionYinDeficiency => '음허질';

  @override
  String get reportConstitutionDampHeat => '습열질';

  @override
  String get reportConstitutionBloodStasis => '혈어질';

  @override
  String get reportConstitutionQiStagnation => '기울질';

  @override
  String get reportConstitutionSpecial => '특품질';

  @override
  String get reportCausalAnalysisTitle => '원인 분석';

  @override
  String get reportCauseRoutine => '생활 리듬';

  @override
  String get reportCauseRoutineBody =>
      '늦게까지 깨어 있는 생활이 반복되면 간과 신장의 정기를 손상시켜 기혈이 부족해지기 쉬워집니다.';

  @override
  String get reportCauseDiet => '식사';

  @override
  String get reportCauseDietBody =>
      '차갑거나 생것 위주의 식사는 비양을 손상시켜 소화와 흡수 기능을 떨어뜨릴 수 있습니다.';

  @override
  String get reportCauseEmotion => '정서';

  @override
  String get reportCauseEmotionBody =>
      '걱정과 생각이 지나치게 많아지면 비를 손상시키고 기의 흐름을 막아 운화 기능을 약하게 만듭니다.';

  @override
  String get reportCauseExercise => '운동';

  @override
  String get reportCauseExerciseBody =>
      '오랫동안 앉아 지내거나 운동이 부족하면 기혈 순환이 둔해지고 중기가 점차 약해질 수 있습니다.';

  @override
  String get reportDiseaseTendencyTitle => '발생하기 쉬운 불편 증상';

  @override
  String get reportDiseaseSpleenWeak => '비위 허약';

  @override
  String get reportDiseaseSpleenWeakBody => '소화불량, 복부 팽만, 묽은 변';

  @override
  String get reportDiseaseQiBloodDeficiency => '기혈 양허';

  @override
  String get reportDiseaseQiBloodDeficiencyBody => '어지러움, 피로감, 안색 저하';

  @override
  String get reportDiseaseLowImmunity => '면역 저하';

  @override
  String get reportDiseaseLowImmunityBody => '감기에 자주 걸림, 쉽게 피로함';

  @override
  String get reportDiseaseEmotional => '정서 불균형';

  @override
  String get reportDiseaseEmotionalBody => '불안, 불면, 기분 저하 경향';

  @override
  String get reportBadHabitsTitle => '피해야 할 습관';

  @override
  String get reportBadHabitOverwork => '과로';

  @override
  String get reportBadHabitOverworkBody => '기를 소모하고 비를 손상시켜 기허를 악화시킵니다';

  @override
  String get reportBadHabitColdFood => '찬 음식 과다 섭취';

  @override
  String get reportBadHabitColdFoodBody => '한사가 양기를 손상시키고 비위를 약화시킵니다';

  @override
  String get reportBadHabitLateSleep => '늦은 취침';

  @override
  String get reportBadHabitLateSleepBody => '음기가 충분히 수렴되지 못해 정기 소모를 일으킵니다';

  @override
  String get reportBadHabitDieting => '과도한 식사 제한';

  @override
  String get reportBadHabitDietingBody => '기혈 생성의 원천이 부족해져 중기를 더 약하게 만듭니다';

  @override
  String get reportBadHabitBinge => '폭식';

  @override
  String get reportBadHabitBingeBody => '비위에 부담을 주고 운화 기능을 흐트러뜨립니다';

  @override
  String get reportTherapyAcupointsTitle => '추천 혈자리';

  @override
  String get reportTherapyAcupointsIntro =>
      '비기허 증형에 따라 아래 혈자리에 뜸 또는 지압을 권장합니다. 하루 10~15분 정도를 기준으로 진행해 주세요.';

  @override
  String get reportTherapyAcuPointZusanli => '족삼리';

  @override
  String get reportTherapyAcuPointZusanliLocation => '외슬안 아래 3촌, 경골 바깥 1횡지';

  @override
  String get reportTherapyAcuPointZusanliEffect =>
      '비위를 조화시키고 기혈을 보하는 대표적 강장혈입니다';

  @override
  String get reportTherapyAcuPointZusanliMeridian => '족양명위경';

  @override
  String get reportTherapyAcuPointPishu => '비수';

  @override
  String get reportTherapyAcuPointPishuLocation => '제11흉추 극돌기 아래, 바깥 1.5촌';

  @override
  String get reportTherapyAcuPointPishuEffect => '건비화습과 보기를 도와 비위 기능을 조절합니다';

  @override
  String get reportTherapyAcuPointPishuMeridian => '족태양방광경';

  @override
  String get reportTherapyAcuPointQihai => '기해';

  @override
  String get reportTherapyAcuPointQihaiLocation => '배꼽 아래 1.5촌, 복부 정중선 위';

  @override
  String get reportTherapyAcuPointQihaiEffect =>
      '원기를 보하고 양기를 덥혀 기허로 인한 피로감을 완화합니다';

  @override
  String get reportTherapyAcuPointQihaiMeridian => '임맥';

  @override
  String get reportTherapyAcuPointGuanyuan => '관원';

  @override
  String get reportTherapyAcuPointGuanyuanLocation => '배꼽 아래 3촌, 복부 정중선 위';

  @override
  String get reportTherapyAcuPointGuanyuanEffect =>
      '원기를 기르고 양기와 기를 보하여 체질 강화를 돕습니다';

  @override
  String get reportTherapyAcuPointGuanyuanMeridian => '임맥';

  @override
  String get reportTherapyAcupointsWarning =>
      '임신 중, 피부 손상 부위, 생리 기간에는 뜸을 피해주세요. 화상 방지를 위해 온도 조절에 주의해 주세요.';

  @override
  String get reportMentalWellnessTitle => '정신 양생';

  @override
  String get reportMentalTipCalm => '마음을 고요히 유지하기';

  @override
  String get reportMentalTipCalmBody =>
      '지나친 생각을 줄이고 마음을 차분히 유지해 보세요. 중의학에서는 과도한 사려가 비를 손상시키고 비기를 소모시키기 쉽다고 봅니다.';

  @override
  String get reportMentalTipNature => '자연의 리듬에 맞추기';

  @override
  String get reportMentalTipNatureBody =>
      '낮과 밤의 리듬에 맞춰 생활하고, 가능하면 자정 전에 잠자리에 들며 아침에는 가볍게 몸을 움직여 양기의 순환을 도와주세요.';

  @override
  String get reportMentalTipEmotion => '감정 조절';

  @override
  String get reportMentalTipEmotionBody =>
      '긍정적인 마음을 유지하고 감정의 기복을 지나치게 키우지 않는 것이 중요합니다. 적절히 마음을 환기하며 기의 울체를 쌓아두지 않도록 해보세요.';

  @override
  String get reportMentalTipMeditation => '정좌 명상';

  @override
  String get reportMentalTipMeditationBody =>
      '매일 10분 정도 조용히 앉아 호흡에 집중하면 비위의 기기를 조절하고 정기를 돕는 데 도움이 됩니다.';

  @override
  String get reportSeasonalCareTitle => '사계절 양생';

  @override
  String get reportSeasonSpring => '봄';

  @override
  String get reportSeasonSpringAdvice =>
      '봄에는 간을 돌보고 적당한 신맛을 더해 보세요. 부추와 시금치를 먹고 몸을 가볍게 펴며 아침 산책으로 양기의 순환을 돕는 것이 좋습니다.';

  @override
  String get reportSeasonSpringAvoid => '과로와 지나치게 매운 발산성 음식은 피하세요';

  @override
  String get reportSeasonSummer => '여름';

  @override
  String get reportSeasonSummerAdvice =>
      '여름에는 심을 돌보고 열이 과하게 쌓이지 않도록 하는 것이 중요합니다. 연자육과 율무를 적당히 섭취하고 낮에 잠시 쉬며 과도한 발한은 피하세요.';

  @override
  String get reportSeasonSummerAvoid => '찬 음식과 격한 운동으로 인한 과도한 발한은 피하세요';

  @override
  String get reportSeasonAutumn => '가을';

  @override
  String get reportSeasonAutumnAdvice =>
      '가을에는 폐를 윤택하게 하는 데 집중해 보세요. 배, 백합, 흰목이버섯 등을 섭취하고 일찍 자고 일찍 일어나 정기를 보호합니다.';

  @override
  String get reportSeasonAutumnAvoid => '지나친 슬픔과 맵고 건조한 음식은 피하세요';

  @override
  String get reportSeasonWinter => '겨울';

  @override
  String get reportSeasonWinterAdvice =>
      '겨울에는 신을 기르고 에너지를 잘 저장하는 것이 중요합니다. 검은깨, 호두, 양고기를 적당히 섭취하고 일찍 자고 조금 늦게 일어나 신양을 보호해 주세요.';

  @override
  String get reportSeasonWinterAvoid => '과로와 과도한 발한으로 양기를 흩뜨리는 행동은 피하세요';

  @override
  String get reportAdviceTongueAnalysisTitle => '설상 상세';

  @override
  String get reportAdviceTongueScoreLabel => '설상 종합 점수';

  @override
  String get reportAdviceTongueScoreSummary => '비허습성 · 기혈이 다소 부족함';

  @override
  String get reportAdviceTongueFeatureColor => '혀 색';

  @override
  String get reportAdviceTongueFeatureColorValue => '담홍';

  @override
  String get reportAdviceTongueFeatureColorDesc =>
      '담홍은 대체로 정상이며, 지나치게 담하면 기혈 부족을 시사할 수 있습니다.';

  @override
  String get reportAdviceTongueFeatureShape => '혀 형태';

  @override
  String get reportAdviceTongueFeatureShapeValue => '약간 비대함';

  @override
  String get reportAdviceTongueFeatureShapeDesc =>
      '혀가 약간 비대하고 치흔이 있으면 비허와 습체를 시사할 수 있습니다.';

  @override
  String get reportAdviceTongueFeatureCoatingColor => '설태 색';

  @override
  String get reportAdviceTongueFeatureCoatingColorValue => '백색';

  @override
  String get reportAdviceTongueFeatureCoatingColorDesc =>
      '백태는 한증이나 표증 경향을 나타내며, 양기 부족의 신호가 될 수 있습니다.';

  @override
  String get reportAdviceTongueFeatureTexture => '설태 성상';

  @override
  String get reportAdviceTongueFeatureTextureValue => '두껍고 약간 끈적함';

  @override
  String get reportAdviceTongueFeatureTextureDesc =>
      '두껍고 끈적한 설태는 습이 비교적 많고 비의 운화가 약함을 시사합니다.';

  @override
  String get reportAdviceTongueFeatureTeethMarks => '치흔';

  @override
  String get reportAdviceTongueFeatureTeethMarksValue => '있음';

  @override
  String get reportAdviceTongueFeatureTeethMarksDesc =>
      '혀 가장자리의 치흔은 비허로 인한 운화력 저하의 전형적 소견입니다.';

  @override
  String get reportAdviceDietTitle => '식이 제안';

  @override
  String get reportAdviceDietIntro =>
      '비기허에는 비를 보하고 위를 편안하게 하는, 약간 따뜻한 성질의 보기 식재료가 잘 맞습니다. 찬 음식, 생식, 소화에 부담이 되는 음식은 가급적 피하세요.';

  @override
  String get reportAdviceDietRecommendedTitle => '추천';

  @override
  String get reportAdviceDietAvoidTitle => '피해야 할 것';

  @override
  String get reportAdviceDietRecipeTitle => '추천 레시피';

  @override
  String get reportAdviceDietRecipeBody =>
      '산약과 율무죽: 산약 50g, 율무 30g, 대추 5개를 함께 끓여 아침에 먹으면 비기를 든든하게 보할 수 있습니다.\n\n당삼과 복령 닭조림: 중기를 보하고 기허 체질의 일상 양생에 적합합니다.';

  @override
  String get reportAdviceFoodShanyao => '산약';

  @override
  String get reportAdviceFoodShanyaoDesc => '비신을 보하고 보기·양음을 돕습니다';

  @override
  String get reportAdviceFoodYiyiren => '율무';

  @override
  String get reportAdviceFoodYiyirenDesc => '습을 제거하고 비를 도우며 설사를 완화합니다';

  @override
  String get reportAdviceFoodHongzao => '대추';

  @override
  String get reportAdviceFoodHongzaoDesc => '기혈을 보하고 비위를 조화시키며 마음을 안정시킵니다';

  @override
  String get reportAdviceFoodBiandou => '백편두';

  @override
  String get reportAdviceFoodBiandouDesc => '비를 돕고 습을 제거하며 여름철 권태를 완화합니다';

  @override
  String get reportAdviceFoodDangshen => '당삼';

  @override
  String get reportAdviceFoodDangshenDesc => '중기를 보하고 비위를 돕습니다';

  @override
  String get reportAdviceFoodFuling => '복령';

  @override
  String get reportAdviceFoodFulingDesc => '비를 돕고 중초를 조화시키며 습을 제거합니다';

  @override
  String get reportAdviceAvoidColdFood => '찬 음식';

  @override
  String get reportAdviceAvoidGreasy => '기름지고 무거운 음식';

  @override
  String get reportAdviceAvoidSpicy => '자극적인 매운맛';

  @override
  String get reportAdviceAvoidSweet => '달고 무거운 음식';

  @override
  String get reportAdviceAvoidAlcohol => '술 · 담배';

  @override
  String get reportAdviceProjectsTitle => '추천 케어 프로젝트';

  @override
  String get reportAdviceProjectsSubtitle => '리포트 결과에 맞춘 방문 서비스';

  @override
  String get reportAdviceProjectsEmpty => '현재 이 리포트에 맞는 케어 프로젝트 추천이 없습니다.';

  @override
  String get reportAdviceProjectsDisclaimer =>
      '서비스 추천은 체질 분석을 바탕으로 한 참고 정보입니다. 실제 서비스 내용과 예약 가능 여부는 매장 안내를 따릅니다.';

  @override
  String get reportAdviceProjectDetailButton => '프로젝트 보기 >';

  @override
  String get reportAdviceProductsTitle => '추천 상품';

  @override
  String get reportAdviceProductsSubtitle => '리포트 결과에 맞춘 배송 상품';

  @override
  String get reportAdviceProductsEmpty => '현재 이 리포트에 맞는 상품 추천이 없습니다.';

  @override
  String get reportAdviceProductsDisclaimer =>
      '상품 추천은 체질 분석을 바탕으로 한 참고 정보입니다. 실제 재고, 규격, 배송 범위는 매장 안내를 따릅니다.';

  @override
  String get reportProductCommonShipping => '영업일 기준 48시간 이내 출고되며 배송 추적을 지원합니다.';

  @override
  String get reportProjectCommonServiceNote => '구체적인 서비스 내용은 매장 상담 후 확정됩니다.';

  @override
  String get reportProjectCommonConsultNote =>
      '매장 상담과 예약이 가능하며 실제 일정은 매장 배정에 따릅니다.';

  @override
  String get reportProjectWarmMoxibustion => '온열 뜸 케어';

  @override
  String get reportProjectWarmMoxibustionType => '방문 온보 프로젝트';

  @override
  String get reportProjectWarmMoxibustionDesc =>
      '냉습과 기허 경향이 보일 때 부드러운 뜸과 온열 케어를 우선 제안합니다.';

  @override
  String get reportProjectWarmMoxibustionTag => '매장 추천';

  @override
  String get reportProjectWarmMoxibustionDuration => '1회 약 45분';

  @override
  String get reportProjectMeridianRelief => '경락 릴리프 케어';

  @override
  String get reportProjectMeridianReliefType => '경락 조리 프로젝트';

  @override
  String get reportProjectMeridianReliefDesc =>
      '피로감, 수면 리듬, 기혈 순환을 중심으로 한 완화형 경락 케어입니다.';

  @override
  String get reportProjectMeridianReliefTag => '첫 방문 추천';

  @override
  String get reportProjectMeridianReliefDuration => '1회 약 60분';

  @override
  String get reportProductJianpiwanPack =>
      '1병 / 200환 구성으로, 일상적인 비위 관리 루틴에 적합합니다.';

  @override
  String get reportProductShenlingPack =>
      '10포 / 1박스 구성으로, 가벼운 비위 보조와 기운 관리에 적합합니다.';

  @override
  String get reportProductAijiuPack =>
      '20매 / 1박스 구성으로, 집에서 부드럽게 활용하는 뜸 케어에 적합합니다.';

  @override
  String get reportProductFoodPackPack =>
      '7일 식양생 구성으로 산약, 율무, 복령 등 식양 재료를 포함합니다.';

  @override
  String get reportProductDetailTitle => '상품 상세';

  @override
  String get reportProductDetailHeroBadge => '리포트 연동 추천';

  @override
  String get reportProductDetailRecommendationTitle => '추천 이유';

  @override
  String get reportProductDetailPackageTitle => '구성 및 규격';

  @override
  String get reportProductDetailShippingTitle => '배송 안내';

  @override
  String get reportProductDetailServiceTitle => '서비스 안내';

  @override
  String get reportProductDetailServiceBody =>
      '현재 버전은 상품 표시와 모의 주문 흐름만 제공합니다. 실제 주문 시스템과 Apple Pay / Google Pay는 이후 연결할 수 있습니다.';

  @override
  String get reportProductDetailQuantityTitle => '구매 수량';

  @override
  String reportProductDetailQuantitySummary(int count) {
    return '$count개 선택됨';
  }

  @override
  String get reportProductDetailFinalPrice => '예상 결제 금액';

  @override
  String get reportProductDetailCheckoutButton => '결제로 이동';

  @override
  String get reportProductDetailReportLinked => '리포트 제안과 연동';

  @override
  String get reportProjectDetailTitle => '프로젝트 상세';

  @override
  String get reportProjectDetailHeroBadge => '리포트 연동 프로젝트';

  @override
  String get reportProjectDetailRecommendationTitle => '추천 이유';

  @override
  String get reportProjectDetailDurationTitle => '서비스 시간';

  @override
  String get reportProjectDetailServiceTitle => '서비스 안내';

  @override
  String get reportProjectDetailConsultTitle => '상담 및 예약';

  @override
  String get reportProjectDetailActionButton => '상담 예약하기';

  @override
  String get reportProjectDetailReportLinked => '리포트 제안과 연동';

  @override
  String get reportProductCheckoutTitle => '주문 확인';

  @override
  String get reportProductCheckoutSectionAddress => '배송 정보';

  @override
  String get reportProductCheckoutRecipient => '수령인';

  @override
  String get reportProductCheckoutPhone => '연락처';

  @override
  String get reportProductCheckoutAddress => '배송 주소';

  @override
  String get reportProductCheckoutOrderSummary => '주문 내역';

  @override
  String get reportProductCheckoutQuantityLabel => '수량';

  @override
  String get reportProductCheckoutSubtotal => '상품 금액';

  @override
  String get reportProductCheckoutShippingFee => '배송비';

  @override
  String get reportProductCheckoutServiceFee => '서비스 수수료';

  @override
  String get reportProductCheckoutTotal => '합계';

  @override
  String get reportProductCheckoutPaymentTitle => '결제 수단';

  @override
  String get reportProductCheckoutApplePayTitle => 'Apple Pay';

  @override
  String get reportProductCheckoutApplePaySubtitle =>
      '향후 Apple Pay 연동을 위한 자리표시자입니다.';

  @override
  String get reportProductCheckoutApplePayDialogBody =>
      '이 빌드에는 아직 실제 Apple Pay가 연결되어 있지 않습니다. 향후 결제 진입 위치를 보여주기 위한 버튼이므로, 화면 검증은 모의 주문 흐름으로 진행해 주세요.';

  @override
  String get reportProductCheckoutGooglePayTitle => 'Google Pay';

  @override
  String get reportProductCheckoutGooglePaySubtitle =>
      '향후 Google Pay 연동을 위한 자리표시자입니다.';

  @override
  String get reportProductCheckoutGooglePayDialogBody =>
      '이 빌드에는 아직 실제 Google Pay가 연결되어 있지 않습니다. 향후 결제 진입 위치를 보여주기 위한 버튼이므로, 화면 검증은 모의 주문 흐름으로 진행해 주세요.';

  @override
  String get reportProductCheckoutMockSubmit => '모의 주문 생성';

  @override
  String get reportProductCheckoutSubmitting => '주문을 생성하는 중…';

  @override
  String get reportProductCheckoutSuccessTitle => '모의 주문이 생성되었습니다';

  @override
  String get reportProductCheckoutSuccessBody =>
      '현재는 프런트엔드 주문 경험 데모까지만 완료됩니다. 이후 실제 주문 처리 및 Apple Pay / Google Pay 흐름으로 교체될 예정입니다.';

  @override
  String get reportUnlockTitle => '전체 리포트 잠금 해제';

  @override
  String get reportUnlockDescription =>
      '체질 분석, 케어 플랜, 맞춤형 제안의 전체 내용을 확인할 수 있습니다.';

  @override
  String get reportUnlockButton => '리포트 잠금 해제';

  @override
  String get reportUnlockSheetTitle => '전체 리포트 잠금 해제';

  @override
  String get reportUnlockSheetBody =>
      '잠금 해제 후에는 체질 상세 분석, 케어 플랜, 맞춤형 제안을 모두 확인할 수 있습니다.';

  @override
  String get reportUnlockInvitationTag => '프리미엄 건강 인사이트';

  @override
  String get reportUnlockInvitationSubtitle =>
      '전체 리포트를 열면 더 깊은 체질 인사이트, 맞춤 케어 경로, 개인화된 양생 가이드를 이어서 확인할 수 있습니다.';

  @override
  String get reportUnlockBenefitConstitution =>
      '체질 원인, 위험 경향, 상세 해석을 전체로 확인할 수 있습니다';

  @override
  String get reportUnlockBenefitTherapy =>
      '맞춤 혈자리 제안, 정신 양생, 사계절 케어 가이드를 받을 수 있습니다';

  @override
  String get reportUnlockBenefitAdvice => '설상 상세 해석, 식이 방향, 관련 상품 추천을 잠금 해제합니다';

  @override
  String get reportUnlockSheetPrice => '모의 가격: ¥29.90';

  @override
  String get reportUnlockSheetPriceFallback => 'App Store 가격을 불러오는 중';

  @override
  String get reportUnlockSheetConfirm => 'Apple IAP로 잠금 해제';

  @override
  String get reportUnlockSheetPurchasing => '구매를 시작하는 중…';

  @override
  String get reportUnlockSheetRestoring => '구매 내역을 복원하는 중…';

  @override
  String get reportUnlockRestoreButton => '구매 복원';

  @override
  String get reportUnlockSheetStoreHint =>
      'Apple App Store의 안전한 결제를 사용하며, 이 비소모성 구매는 복원을 지원합니다.';

  @override
  String get reportUnlockStatusStoreUnavailable =>
      '현재 App Store에 연결할 수 없습니다. 네트워크 연결 후 다시 시도해 주세요.';

  @override
  String get reportUnlockStatusProductUnavailable =>
      '구매 가능한 상품을 찾지 못했습니다. 상품 ID를 확인하거나 잠시 후 다시 시도해 주세요.';

  @override
  String get reportUnlockStatusPurchaseFailed =>
      '구매가 완료되지 않았습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get reportUnlockStatusPurchaseCancelled => '이번 구매를 취소했습니다.';

  @override
  String get reportUnlockStatusRestoreNotFound =>
      '이 Apple ID로 복원할 수 있는 구매 내역을 찾지 못했습니다.';

  @override
  String get reportUnlockStatusPurchasing => 'App Store 구매 결과를 기다리는 중입니다.';

  @override
  String get reportUnlockStatusRestoring => 'App Store에서 구매 기록을 복원하는 중입니다.';

  @override
  String get reportUnlockSheetMockHint =>
      '현재는 로컬 모의 구매 흐름이며, 이후 Apple IAP로 교체할 수 있습니다.';

  @override
  String get reportUnlockCausalAnalysisTitle => '원인 심층 분석 잠금 해제';

  @override
  String get reportUnlockCausalAnalysisSubtitle => '查看体质成因与关键诱因。';

  @override
  String get reportUnlockDiseaseTendencyTitle => '질환 경향 알림 잠금 해제';

  @override
  String get reportUnlockDiseaseTendencySubtitle => '查看易发问题与预警重点。';

  @override
  String get reportUnlockBadHabitsTitle => '주의해야 할 행동 안내 잠금 해제';

  @override
  String get reportUnlockBadHabitsSubtitle => '查看需要调整的日常习惯。';

  @override
  String get reportUnlockAcupuncturePointsTitle => '맞춤 혈자리 플랜 잠금 해제';

  @override
  String get reportUnlockAcupuncturePointsSubtitle => '查看专属穴位与调理重点。';

  @override
  String get reportUnlockMentalWellnessTitle => '정신 양생 조언 잠금 해제';

  @override
  String get reportUnlockMentalWellnessSubtitle => '查看情绪调养与舒缓建议。';

  @override
  String get reportUnlockSeasonalCareTitle => '사계절 양생 플랜 잠금 해제';

  @override
  String reportSeasonalCareCurrentTitle(String solarTerm) {
    return '현재 절기: $solarTerm';
  }

  @override
  String get reportSeasonalCareCurrentSubtitle =>
      '현재 시령을 기준으로, 해당 양생 가이드를 먼저 확인할 수 있어요.';

  @override
  String get reportUnlockSeasonalCareSubtitle => '查看本季作息与养护重点。';

  @override
  String get reportUnlockTongueAnalysisTitle => '설상 상세 해석 잠금 해제';

  @override
  String get reportUnlockTongueAnalysisSubtitle => '查看舌象评分与细项解读。';

  @override
  String get reportUnlockDietAdviceTitle => '맞춤 식이 플랜 잠금 해제';

  @override
  String get reportUnlockDietAdviceSubtitle => '查看适宜食材与饮食方向。';

  @override
  String get reportPremiumConstitutionSubtitle =>
      '체질의 원인과 위험 경향을 포함한 상세 분석을 확인할 수 있습니다.';

  @override
  String get reportPremiumConstitutionPreview1 => '주요 경향: 기허질';

  @override
  String get reportPremiumConstitutionPreview2 => '체질과 위험 경향의 상세 해석을 해제';

  @override
  String get reportPremiumTherapySubtitle =>
      '추천 혈자리, 정신 양생, 사계절 케어 제안을 확인할 수 있습니다.';

  @override
  String get reportPremiumTherapyPreview1 => '추천 포인트: 족삼리 · 기해';

  @override
  String get reportPremiumTherapyPreview2 => '구체적인 케어 흐름과 실행 제안을 해제';

  @override
  String get reportPremiumAdviceSubtitle => '식양생, 설상 상세, 관련 상품 제안을 확인할 수 있습니다.';

  @override
  String get reportPremiumAdvicePreview1 => '식이 방향: 건비거습';

  @override
  String get reportPremiumAdvicePreview2 => '식이·설상·상품 제안 전체를 해제';

  @override
  String get reportProductJianpiwan => '건비익기환';

  @override
  String get reportProductJianpiwanType => '중성약';

  @override
  String get reportProductJianpiwanDesc =>
      '중기를 보하고 비를 튼튼하게 하며 위를 조화시킵니다. 피로감과 식욕 저하가 있는 기허 체질에 적합합니다.';

  @override
  String get reportProductJianpiwanTag => '인기';

  @override
  String get reportProductShenling => '삼령백출산';

  @override
  String get reportProductShenlingType => '전통 방제';

  @override
  String get reportProductShenlingDesc =>
      '비기를 보하고 습을 제거하며 설사를 완화합니다. 비허로 인한 식욕 저하, 묽은 변, 피로감에 사용됩니다.';

  @override
  String get reportProductShenlingTag => '기본';

  @override
  String get reportProductAijiu => '뜸 세트';

  @override
  String get reportProductAijiuType => '양생 도구';

  @override
  String get reportProductAijiuDesc =>
      '부드러운 뜸쑥과 혈자리 가이드가 포함되어 족삼리, 기해, 관원의 가정 양생에 적합합니다.';

  @override
  String get reportProductAijiuTag => '추천';

  @override
  String get reportProductFoodPack => '중의 식양생 세트';

  @override
  String get reportProductFoodPackType => '양생 식재료';

  @override
  String get reportProductFoodPackDesc =>
      '산약, 율무, 당삼, 복령, 대추를 조합한 1주일 분량의 식양생 세트입니다.';

  @override
  String get reportProductFoodPackTag => '신규';

  @override
  String get reportWuxingWood => '목';

  @override
  String get reportWuxingFire => '화';

  @override
  String get reportWuxingEarth => '토';

  @override
  String get reportWuxingMetal => '금';

  @override
  String get reportWuxingWater => '수';

  @override
  String get reportAdviceProductDetailButton => '상품 보기 >';

  @override
  String get metricFaceDiagnosis => '면진';

  @override
  String get metricTongueDiagnosis => '설진';

  @override
  String get metricPalmDiagnosis => '장진';

  @override
  String get scanGuideTitle => 'AI 건강 스캔';

  @override
  String get constitutionBalanced => '평화질';

  @override
  String get constitutionQiDeficiency => '기허질';

  @override
  String get constitutionDampness => '담습질';

  @override
  String get riskSpleenStomach => '비위';

  @override
  String get riskQiDeficiency => '기허';

  @override
  String get riskDampness => '습곤';

  @override
  String daysAgo(int days) {
    return '$days일 전';
  }

  @override
  String scoreWithUnit(num score) {
    return '$score점';
  }

  @override
  String percentValue(num value) {
    return '$value%';
  }

  @override
  String get reportConstitutionPhlegmDampness => '담습질';

  @override
  String get reportConstitutionInheritedSpecial => '특품질';

  @override
  String get reportConstitutionCausalTitle => '원인 분석';

  @override
  String get reportConstitutionCauseRoutineTitle => '생활 리듬';

  @override
  String get reportConstitutionCauseRoutineDesc =>
      '만성적인 야간 활동과 늦은 취침은 간신의 정기를 손상시켜 기혈 생성 부족으로 이어질 수 있습니다.';

  @override
  String get reportConstitutionCauseDietTitle => '식사';

  @override
  String get reportConstitutionCauseDietDesc =>
      '차갑고 생식 위주의 식사는 비양을 손상시켜 운화 기능을 떨어뜨릴 수 있습니다.';

  @override
  String get reportConstitutionCauseEmotionTitle => '정서';

  @override
  String get reportConstitutionCauseEmotionDesc =>
      '과도한 걱정과 생각은 비를 손상시키고 기의 흐름을 막아 운화를 약화시킵니다.';

  @override
  String get reportConstitutionCauseExerciseTitle => '운동';

  @override
  String get reportConstitutionCauseExerciseDesc =>
      '장시간 앉아 있는 생활과 운동 부족은 기혈 순환을 둔화시키고 중기를 약화시킵니다.';

  @override
  String get reportConstitutionDiseaseTitle => '발생하기 쉬운 불편 증상';

  @override
  String get reportConstitutionDiseaseSpleenWeakTitle => '비위 허약';

  @override
  String get reportConstitutionDiseaseSpleenWeakDesc => '소화불량, 복부 팽만, 묽은 변';

  @override
  String get reportConstitutionDiseaseQiBloodTitle => '기혈 양허';

  @override
  String get reportConstitutionDiseaseQiBloodDesc => '어지러움, 피로감, 안색 저하';

  @override
  String get reportConstitutionDiseaseLowImmunityTitle => '면역 저하';

  @override
  String get reportConstitutionDiseaseLowImmunityDesc => '감기에 자주 걸리고 쉽게 피로함';

  @override
  String get reportConstitutionDiseaseEmotionTitle => '정서 불균형';

  @override
  String get reportConstitutionDiseaseEmotionDesc => '불안, 불면, 기분 저하 경향';

  @override
  String get reportConstitutionBadHabitsTitle => '피해야 할 습관';

  @override
  String get reportConstitutionHabitOverworkTitle => '과로';

  @override
  String get reportConstitutionHabitOverworkDesc =>
      '기를 소모하고 비를 손상시켜 기허를 악화시킵니다';

  @override
  String get reportConstitutionHabitColdFoodTitle => '찬 음식 과다 섭취';

  @override
  String get reportConstitutionHabitColdFoodDesc => '한사가 양기를 손상시키고 비위를 약화시킵니다';

  @override
  String get reportConstitutionHabitLateSleepTitle => '늦은 취침';

  @override
  String get reportConstitutionHabitLateSleepDesc =>
      '음기가 충분히 수렴되지 못해 정기 소모를 일으킵니다';

  @override
  String get reportConstitutionHabitDietingTitle => '과도한 식사 제한';

  @override
  String get reportConstitutionHabitDietingDesc =>
      '기혈 생성의 원천이 부족해져 중기를 더 약하게 만듭니다';

  @override
  String get reportConstitutionHabitBingeTitle => '폭식';

  @override
  String get reportConstitutionHabitBingeDesc => '비위에 부담을 주고 운화 기능을 흐트러뜨립니다';

  @override
  String get reportTherapyAcupointTitle => '추천 혈자리';

  @override
  String get reportTherapyAcupointIntro =>
      '비기허 증형에 따라 아래 혈자리에 뜸 또는 지압을 권장합니다. 하루 10~15분 정도를 기준으로 진행해 주세요.';

  @override
  String get reportTherapyPointZusanliName => '족삼리';

  @override
  String get reportTherapyPointZusanliLocation => '외슬안 아래 3촌, 경골 바깥 1횡지';

  @override
  String get reportTherapyPointZusanliEffect => '비위를 조화시키고 기혈을 보하는 대표적 강장혈입니다';

  @override
  String get reportTherapyPointZusanliMeridian => '족양명위경';

  @override
  String get reportTherapyPointPishuName => '비수';

  @override
  String get reportTherapyPointPishuLocation => '제11흉추 극돌기 아래, 바깥 1.5촌';

  @override
  String get reportTherapyPointPishuEffect => '건비화습과 보기를 도와 비위 기능을 조절합니다';

  @override
  String get reportTherapyPointPishuMeridian => '족태양방광경';

  @override
  String get reportTherapyPointQihaiName => '기해';

  @override
  String get reportTherapyPointQihaiLocation => '배꼽 아래 1.5촌, 복부 정중선 위';

  @override
  String get reportTherapyPointQihaiEffect =>
      '원기를 보하고 양기를 덥혀 기허로 인한 피로감을 완화합니다';

  @override
  String get reportTherapyPointQihaiMeridian => '임맥';

  @override
  String get reportTherapyPointGuanyuanName => '관원';

  @override
  String get reportTherapyPointGuanyuanLocation => '배꼽 아래 3촌, 복부 정중선 위';

  @override
  String get reportTherapyPointGuanyuanEffect =>
      '원기를 기르고 양기와 기를 보하여 체질 강화를 돕습니다';

  @override
  String get reportTherapyPointGuanyuanMeridian => '임맥';

  @override
  String get reportTherapyAcupointWarning =>
      '임신 중, 피부 손상 부위, 생리 기간에는 뜸을 피해주세요. 화상 방지를 위해 온도 조절에 주의해 주세요.';

  @override
  String get reportTherapyMentalTitle => '정신 양생';

  @override
  String get reportTherapyMentalCalmTitle => '마음을 고요히 유지하기';

  @override
  String get reportTherapyMentalCalmDesc =>
      '지나친 생각을 줄이고 마음을 차분히 유지해 보세요. 중의학에서는 과도한 사려가 비를 손상시키고 비기를 소모시키기 쉽다고 봅니다.';

  @override
  String get reportTherapyMentalNatureTitle => '자연의 리듬에 맞추기';

  @override
  String get reportTherapyMentalNatureDesc =>
      '낮과 밤의 리듬에 맞춰 생활하고, 자정 전에는 잠자리에 들며 아침에는 가볍게 몸을 풀어 양기의 순환을 도와주세요.';

  @override
  String get reportTherapyMentalEmotionTitle => '감정 조절';

  @override
  String get reportTherapyMentalEmotionDesc =>
      '긍정적인 마음을 유지하고 감정의 기복을 지나치게 키우지 않는 것이 중요합니다. 적절한 해소로 기의 울체를 완화해 주세요.';

  @override
  String get reportTherapyMentalMeditationTitle => '정좌 명상';

  @override
  String get reportTherapyMentalMeditationDesc =>
      '매일 10분 정도 조용히 앉아 호흡에 집중하면 비위의 기기를 조절하고 정기를 돕는 데 도움이 됩니다.';

  @override
  String get reportTherapySeasonalTitle => '사계절 양생';

  @override
  String get reportTherapySeasonSpringName => '봄';

  @override
  String get reportTherapySeasonSpringAdvice =>
      '봄에는 간을 기르고 적당한 신맛을 더해 보세요. 부추와 시금치를 먹고 몸을 펴며 아침 산책으로 양기의 발산을 돕습니다.';

  @override
  String get reportTherapySeasonSpringAvoid => '과로와 지나치게 매운 발산성 음식은 피하세요';

  @override
  String get reportTherapySeasonSummerName => '여름';

  @override
  String get reportTherapySeasonSummerAdvice =>
      '여름에는 심을 기르고 열을 과도하게 쌓지 않도록 하세요. 연자육과 율무를 적당히 섭취하고 낮에 잠깐 쉬며 과도한 발한을 피합니다.';

  @override
  String get reportTherapySeasonSummerAvoid => '찬 음식과 격한 운동으로 인한 과도한 발한은 피하세요';

  @override
  String get reportTherapySeasonAutumnName => '가을';

  @override
  String get reportTherapySeasonAutumnAdvice =>
      '가을에는 폐를 윤택하게 하고 배, 백합, 흰목이버섯 등을 섭취해 보세요. 일찍 자고 일찍 일어나 정기를 보호합니다.';

  @override
  String get reportTherapySeasonAutumnAvoid => '지나친 슬픔과 맵고 건조한 음식은 피하세요';

  @override
  String get reportTherapySeasonWinterName => '겨울';

  @override
  String get reportTherapySeasonWinterAdvice =>
      '겨울에는 신을 기르고 저장을 중시하세요. 검은깨, 호두, 양고기를 적당히 섭취하고 일찍 자고 조금 늦게 일어나 신양을 보호합니다.';

  @override
  String get reportTherapySeasonWinterAvoid => '과로와 과도한 발한으로 양기를 흩뜨리는 행동은 피하세요';

  @override
  String get reportAdviceTongueFeatureColorLabel => '혀 색';

  @override
  String get scanToggleCamera => '카메라 전환';

  @override
  String get reportAdviceTongueFeatureShapeLabel => '혀 형태';

  @override
  String get reportAdviceTongueFeatureCoatingColorLabel => '설태 색';

  @override
  String get reportAdviceTongueFeatureCoatingTextureLabel => '설태 성상';

  @override
  String get reportAdviceTongueFeatureCoatingTextureValue => '두껍고 약간 끈적함';

  @override
  String get reportAdviceTongueFeatureCoatingTextureDesc =>
      '두껍고 끈적한 설태는 습이 비교적 많고 비의 운화가 약함을 시사합니다.';

  @override
  String get reportAdviceTongueFeatureTeethMarksLabel => '치흔';

  @override
  String get reportAdviceDietRecommendedLabel => '추천';

  @override
  String get reportAdviceDietFoodYamName => '산약';

  @override
  String get reportAdviceDietFoodYamDesc => '비신을 보하고 보기·양음을 돕습니다';

  @override
  String get reportAdviceDietFoodCoixName => '율무';

  @override
  String get reportAdviceDietFoodCoixDesc => '습을 제거하고 비를 도우며 설사를 완화합니다';

  @override
  String get reportAdviceDietFoodJujubeName => '대추';

  @override
  String get reportAdviceDietFoodJujubeDesc => '기혈을 보하고 비위를 조화시키며 마음을 안정시킵니다';

  @override
  String get reportAdviceDietFoodLablabName => '백편두';

  @override
  String get reportAdviceDietFoodLablabDesc => '비를 돕고 습을 제거하며 여름철 권태를 완화합니다';

  @override
  String get reportAdviceDietFoodCodonopsisName => '당삼';

  @override
  String get reportAdviceDietFoodCodonopsisDesc => '중기를 보하고 비위를 돕습니다';

  @override
  String get reportAdviceDietFoodPoriaName => '복령';

  @override
  String get reportAdviceDietFoodPoriaDesc => '비를 돕고 중초를 조화시키며 습을 제거합니다';

  @override
  String get reportAdviceDietAvoidLabel => '피해야 할 것';

  @override
  String get reportAdviceDietAvoidColdFoods => '찬 음식 및 생식';

  @override
  String get reportAdviceDietAvoidGreasy => '기름지고 무거운 음식';

  @override
  String get reportAdviceDietAvoidSpicy => '자극적인 매운맛';

  @override
  String get reportAdviceDietAvoidSweetRich => '달고 진한 음식';

  @override
  String get reportAdviceDietAvoidAlcoholTobacco => '술 · 담배';

  @override
  String get reportAdviceProductTitle => '추천 상품';

  @override
  String get reportAdviceProductSubtitle => '체질에 맞춘 추천';

  @override
  String get reportAdviceProductOneName => '건비익기환';

  @override
  String get reportAdviceProductOneType => '중성약';

  @override
  String get reportAdviceProductOneDesc =>
      '중기를 보하고 비를 튼튼하게 하며 위를 조화시킵니다. 피로감과 식욕 저하가 있는 기허 체질에 적합합니다.';

  @override
  String get reportAdviceProductOneTag => '인기';

  @override
  String get reportAdviceProductTwoName => '삼령백출산';

  @override
  String get reportAdviceProductTwoType => '전통 방제';

  @override
  String get reportAdviceProductTwoDesc =>
      '비기를 보하고 습을 제거하며 설사를 완화합니다. 비허로 인한 식욕 저하, 묽은 변, 피로감에 사용됩니다.';

  @override
  String get reportAdviceProductTwoTag => '기본';

  @override
  String get reportAdviceProductThreeName => '뜸 세트';

  @override
  String get reportAdviceProductThreeType => '양생 도구';

  @override
  String get reportAdviceProductThreeDesc =>
      '부드러운 뜸쑥과 혈자리 가이드가 포함되어 족삼리, 기해, 관원의 가정 양생에 적합합니다.';

  @override
  String get reportAdviceProductThreeTag => '추천';

  @override
  String get reportAdviceProductFourName => '중의 식양생 세트';

  @override
  String get reportAdviceProductFourType => '양생 식재료';

  @override
  String get reportAdviceProductFourDesc =>
      '산약, 율무, 당삼, 복령, 대추를 조합한 1주일 분량의 식양생 세트입니다.';

  @override
  String get reportAdviceProductFourTag => '신규';

  @override
  String get reportAdviceProductDisclaimer =>
      '이 추천은 체질 분석에 기반한 참고 정보입니다. 중성약은 의사 또는 약사의 지도 아래 사용해 주세요.';

  @override
  String get scanFaceFrameRetryMessage =>
      '얼굴 랜드마크 이미지가 생성되지 않았습니다. 다시 스캔해 주세요.';

  @override
  String get scanFaceUploadFailedTitle => '얼굴 업로드에 실패했습니다';

  @override
  String get scanTongueUploadFailedTitle => '설진 업로드에 실패했습니다';
}
