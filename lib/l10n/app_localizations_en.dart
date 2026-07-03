// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mai AI Health';

  @override
  String get appBrandPrefix => 'Mai ';

  @override
  String get appBrandSuffix => ' Health';

  @override
  String seasonalSolarTermTag(String solarTerm, String element) {
    return '$solarTerm · $element';
  }

  @override
  String get solarTermMinorCold => 'Minor Cold';

  @override
  String get solarTermMajorCold => 'Major Cold';

  @override
  String get solarTermStartOfSpring => 'Start of Spring';

  @override
  String get solarTermRainWater => 'Rain Water';

  @override
  String get solarTermAwakeningOfInsects => 'Awakening of Insects';

  @override
  String get solarTermSpringEquinox => 'Spring Equinox';

  @override
  String get solarTermClearAndBright => 'Clear and Bright';

  @override
  String get solarTermGrainRain => 'Grain Rain';

  @override
  String get solarTermStartOfSummer => 'Start of Summer';

  @override
  String get solarTermGrainFull => 'Grain Full';

  @override
  String get solarTermGrainInEar => 'Grain in Ear';

  @override
  String get solarTermSummerSolstice => 'Summer Solstice';

  @override
  String get solarTermMinorHeat => 'Minor Heat';

  @override
  String get solarTermMajorHeat => 'Major Heat';

  @override
  String get solarTermStartOfAutumn => 'Start of Autumn';

  @override
  String get solarTermEndOfHeat => 'End of Heat';

  @override
  String get solarTermWhiteDew => 'White Dew';

  @override
  String get solarTermAutumnEquinox => 'Autumn Equinox';

  @override
  String get solarTermColdDew => 'Cold Dew';

  @override
  String get solarTermFrostDescent => 'Frost Descent';

  @override
  String get solarTermStartOfWinter => 'Start of Winter';

  @override
  String get solarTermMinorSnow => 'Minor Snow';

  @override
  String get solarTermMajorSnow => 'Major Snow';

  @override
  String get solarTermWinterSolstice => 'Winter Solstice';

  @override
  String get authInspectionMotto => 'Inspect · Listen · Ask · Feel';

  @override
  String get authPhoneLogin => 'Phone Login';

  @override
  String get authEmailLogin => 'Email Login';

  @override
  String get authPhoneLabel => 'Phone';

  @override
  String get authPhoneHint => 'Enter phone number';

  @override
  String get authPhoneFormatError => 'Please enter a valid phone number';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailHint => 'Enter email address';

  @override
  String get authEmailFormatError => 'Please enter a valid email address';

  @override
  String get authNameLabel => 'Nickname';

  @override
  String get authNameHint => 'Enter your nickname';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordHint => 'Enter password';

  @override
  String get authPasswordMin6 => 'Password must be at least 6 characters';

  @override
  String get authPasswordMin8 => 'Password must be at least 8 characters';

  @override
  String get authConfirmPasswordLabel => 'Confirm Password';

  @override
  String get authConfirmPasswordHint => 'Enter password again';

  @override
  String get authPasswordMismatch => 'Passwords do not match';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authLoginButton => 'Log In';

  @override
  String get authLoginFailed => 'Login failed. Please try again later.';

  @override
  String get authOtherMethods => 'Other methods';

  @override
  String get authWechatLogin => 'WeChat Mini Program';

  @override
  String get authAppleLogin => 'Continue with Apple';

  @override
  String get authVerificationCodeLabel => 'Verification Code';

  @override
  String get authVerificationCodeHint => 'Enter code';

  @override
  String get authSendCode => 'Send Code';

  @override
  String authResendCode(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get authPasswordLogin => 'Password Login';

  @override
  String get authCodeLogin => 'Code Login';

  @override
  String get authLoggingIn => 'Logging in…';

  @override
  String get authSendCodeFailed =>
      'Failed to send verification code. Please try again later.';

  @override
  String get authCodeSent =>
      'Verification code sent. Please check your messages.';

  @override
  String authCodeSentToReceiver(String receiver) {
    return 'Code sent to $receiver';
  }

  @override
  String get authWechatUnsupported =>
      'WeChat Mini Program authorization is not wired yet.';

  @override
  String get authWechatCodeMissing =>
      'WeChat authorization code was not acquired.';

  @override
  String get authWechatCompletedWithoutToken =>
      'WeChat authorization completed without a login token.';

  @override
  String authWechatStatusPendingBinding(String status) {
    return 'WeChat authorization returned status \"$status\". Follow-up binding is not wired yet.';
  }

  @override
  String get authSendCodeFirst => 'Please request a verification code first.';

  @override
  String get commonContinue => 'Continue';

  @override
  String get authCaptchaTitle => 'Captcha verification';

  @override
  String authCaptchaManualPrompt(String provider) {
    return 'Complete the $provider verification first, then paste the JSON result returned by the provider to continue.';
  }

  @override
  String get authCaptchaInitPayloadLabel => 'Initialization parameters';

  @override
  String get authCaptchaResultJsonLabel => 'Verification result JSON';

  @override
  String get authCaptchaManualResultHint => 'Example: ticket=ticket-001';

  @override
  String get authCaptchaInvalidJson => 'Please enter a valid JSON object.';

  @override
  String get authCaptchaFailed =>
      'Captcha verification failed. Please try again.';

  @override
  String get authCaptchaLoadingPage => 'Loading captcha page...';

  @override
  String get authCaptchaReady =>
      'Captcha is ready. Please complete the verification.';

  @override
  String get authCaptchaPageLoadFailed =>
      'Failed to load the captcha page. Please close it and try again.';

  @override
  String get authCaptchaInitFailed =>
      'Failed to initialize captcha. Please close it and try again.';

  @override
  String get authCaptchaRequiredUnsupported =>
      'This environment does not support captcha verification yet. Please try again later.';

  @override
  String get authForgotPasswordTip =>
      'Please reset your password using your registered phone number, or contact support.';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get authNoAccount => 'No account yet? ';

  @override
  String get authRegisterNow => 'Sign up now';

  @override
  String get registerGoLogin => 'Go to login';

  @override
  String get registerCreateAccountTitle => 'Create your account';

  @override
  String get registerCreateAccountSubtitle =>
      'Create your account with your phone number and verification code to get started quickly';

  @override
  String get registerCreateAccountAction => 'Create account';

  @override
  String get registerCreateFailed =>
      'Account creation failed. Please try again later.';

  @override
  String get registerPasswordSetupPrompt =>
      'Registration succeeded. You can set a login password later in Me - Settings - Account & Security.';

  @override
  String get registerPhoneMode => 'Phone Sign Up';

  @override
  String get registerEmailMode => 'Email Sign Up';

  @override
  String get registerAlreadyHaveAccount => 'Already have an account? ';

  @override
  String get registerLoginNow => 'Log in now';

  @override
  String get registerGenderOptional => 'Gender';

  @override
  String get registerGenderRequired => 'Please select a gender';

  @override
  String get completeProfileTitle => 'Complete your profile';

  @override
  String get completeProfileSubtitle =>
      'Add your avatar, nickname, and gender so future therapy suggestions can fit you better.';

  @override
  String get completeProfileSkip => 'Skip';

  @override
  String get completeProfileStart => 'Start now';

  @override
  String get registerGenderMale => 'Male';

  @override
  String get registerGenderFemale => 'Female';

  @override
  String get registerGenderOther => 'Prefer not to say';

  @override
  String get registerPasswordHint =>
      'At least 8 characters, including letters and numbers';

  @override
  String get registerAgreeTermsFirst =>
      'Please agree to the User Agreement and Privacy Policy first';

  @override
  String get registerReadAndAgree => 'I have read and agree to the ';

  @override
  String get registerUserAgreement => 'User Agreement';

  @override
  String get registerAnd => ' and ';

  @override
  String get registerPrivacyPolicy => 'Privacy Policy';

  @override
  String get registerHealthDataClause =>
      ', including the collection and use of health data.';

  @override
  String get registerPrivacyTip =>
      'Your health data is used only for AI diagnostic analysis, stored in encrypted form, and will not be used commercially or shared with third parties.';

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordStrengthMedium => 'Medium';

  @override
  String get passwordStrengthStrong => 'Strong';

  @override
  String get passwordStrengthVeryStrong => 'Very strong';

  @override
  String get bottomNavHome => 'Home';

  @override
  String get bottomNavScan => 'Scan';

  @override
  String get bottomNavReport => 'Report';

  @override
  String get bottomNavProfile => 'Profile';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonLoading => 'Loading';

  @override
  String get commonViewAll => 'View all';

  @override
  String get commonFeatureInDevelopment => 'Feature in development';

  @override
  String get commonPleaseEnterName => 'Please enter your name';

  @override
  String get unitTimes => 'x';

  @override
  String get unitPoints => 'pts';

  @override
  String get unitStage => 'stages';

  @override
  String get statusUnlocked => 'Unlocked';

  @override
  String get statusLocked => 'Locked';

  @override
  String get actionUnlockNow => 'Unlock now';

  @override
  String get historyReportTitle => 'Constitution Assessment Report';

  @override
  String get historyPastReports => 'Past Reports';

  @override
  String get historyHealthTrend => 'Health Trend';

  @override
  String get historyHealthIndex => 'Health Index';

  @override
  String get historyRiskTrend => 'Risk Index Trend';

  @override
  String homeGreetingMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String get homeGreetingQuestion => 'How is your complexion today?';

  @override
  String homeStatusSummary(String constitution, int days) {
    return '$constitution · Last checked $days days ago';
  }

  @override
  String get homeSuggestion =>
      'Suggestion: drink more water and keep a regular routine.';

  @override
  String get homeQuickScanTitle => 'AI Visual Check-In';

  @override
  String get homeQuickScanTag => 'Inspect · Listen · Ask · Feel';

  @override
  String get homeQuickScanFaceTitle => 'Face Check';

  @override
  String get homeQuickScanFaceSub => 'Check complexion';

  @override
  String get homeQuickScanTongueTitle => 'Tongue Review';

  @override
  String get homeQuickScanTongueSub => 'Observe coating';

  @override
  String get homeQuickScanPalmTitle => 'Palm Reading';

  @override
  String get homeQuickScanPalmSub => 'Review palm lines';

  @override
  String get homeFunctionNavTitle => 'Feature Navigation';

  @override
  String get homeFunctionConstitution => 'Constitution Analysis';

  @override
  String get homeFunctionMeridianTherapy => 'Meridian Therapy';

  @override
  String get homeFunctionDietAdvice => 'Dietary Advice';

  @override
  String get homeFunctionMentalWellness => 'Mental Wellness';

  @override
  String get homeFunctionSeasonalCare => 'Seasonal Care';

  @override
  String get homeFunctionHistory => 'History';

  @override
  String get homeTodayCareTitle => 'Today’s Wellness';

  @override
  String get homeTodayCareCount => 'Two tips';

  @override
  String get homeTipDietTag => 'Diet';

  @override
  String get homeTipDietWuxing => 'Earth';

  @override
  String get homeTipDietBody =>
      'Today’s seasonal guidance favors lighter meals. Chinese yam and lily bulbs can help support the lungs and spleen, especially for people with qi deficiency tendencies.';

  @override
  String get homeTipRoutineTag => 'Routine';

  @override
  String get homeTipRoutineWuxing => 'Water';

  @override
  String get homeTipRoutineBody =>
      'Sleeping before 11:00 PM helps the liver and gallbladder recover. Try to reduce screen time late at night.';

  @override
  String get homeCollapsedTitle => 'Mai AI Health';

  @override
  String get homeHealthScoreLabel => 'Health Score';

  @override
  String get homeBalancedConstitution => 'Balanced Constitution';

  @override
  String get homeBalanceState => 'Yin and yang are relatively balanced';

  @override
  String get homeStartFullScan => 'Start Full Smart Scan';

  @override
  String get homeLastReportInsight =>
      'Qi Deficiency Tendency · Weak Spleen and Stomach';

  @override
  String get homeLastReportSummary =>
      'Spleen qi is weak and transport function is reduced. The complexion appears slightly yellow, and the tongue is pale with a white coating. Focus on strengthening spleen qi and maintaining a regular routine.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileBadgeBalanced => 'Balanced';

  @override
  String get profileDisplayName => 'Xiaoming';

  @override
  String get profileStatusStable =>
      'You’re stable today. Focus on balanced nourishment.';

  @override
  String get profileBalancedType => 'Balanced Constitution';

  @override
  String get profileMetricConsultCount => 'Consultations';

  @override
  String get profileMetricHealthScore => 'Health Score';

  @override
  String get profileMetricConstitutionStages => 'Constitution Changes';

  @override
  String get profileSectionFoundation => 'Health Foundation';

  @override
  String get profileHeight => 'Height';

  @override
  String get profileWeight => 'Weight';

  @override
  String get profileInnateBase => 'Innate Constitution';

  @override
  String get profileInnateBaseValue =>
      'Family tendency toward weak spleen and stomach';

  @override
  String get profileInnateBaseNote =>
      'Both parents have a history of weak spleen and stomach, suggesting a naturally weaker middle-qi foundation.';

  @override
  String get profileCurrentBias => 'Current Imbalance';

  @override
  String get profileCurrentBiasValue => 'Qi Deficiency with Dampness';

  @override
  String get profileCurrentBiasNote =>
      'Recent imbalance is centered on qi deficiency and dampness, and is easily affected by sleep and diet.';

  @override
  String get profileHealthScore30Days => 'Health Score in the Last 30 Days';

  @override
  String get profileHealthScoreTrendNote =>
      'Overall stable, with mild fluctuations over the past week.';

  @override
  String get profileSectionCabin => 'My Care Hub';

  @override
  String get profileCabinAcupoints => 'Saved Acupoints';

  @override
  String get profileCabinAcupointsValue => 'Zusanli · Qihai · Guanyuan';

  @override
  String get profileCabinDiet => 'Personalized Food Therapy';

  @override
  String get profileCabinDietValue =>
      'Yam and coix porridge · Codonopsis and poria chicken stew';

  @override
  String get profileCabinFollowup => 'Follow-up Reminder';

  @override
  String get profileCabinFollowupValue =>
      '3 days until the next therapy assessment';

  @override
  String get profileSectionServices => 'Health Services';

  @override
  String get profileMenuAccount => 'Account & Family Profiles';

  @override
  String get profileMenuAccountSub =>
      'Personal details, family information, and health records';

  @override
  String get profileMenuShippingAddress => 'Shipping Addresses';

  @override
  String get profileMenuShippingAddressSub =>
      'Add, edit, and manage delivery addresses';

  @override
  String get profileMenuPoints => 'Points Center';

  @override
  String get profileMenuPointsSub =>
      'Check in for points and view your history';

  @override
  String get profileMenuSettings => 'Settings';

  @override
  String get profileMenuSettingsSub =>
      'Account security, sign-in options, and general preferences';

  @override
  String get profileMenuReminder => 'Seasonal Health Reminders';

  @override
  String get profileMenuReminderSub =>
      'Notifications, routines, and seasonal care guidance';

  @override
  String get profileMenuAdvisor => 'Contact Your Health Advisor';

  @override
  String get profileMenuAdvisorSub =>
      'Care questions, follow-up communication, and health consultation';

  @override
  String get profileMenuLanguage => 'Language';

  @override
  String get profileMenuLanguageSub => 'Change the app display language';

  @override
  String get profileMenuAbout => 'About Mai AI';

  @override
  String get profileMenuAboutSub =>
      'Learn about the service and current version v1.0.0';

  @override
  String get profileAddressTitle => 'Shipping Addresses';

  @override
  String get profileAddressAdd => 'Add Address';

  @override
  String get profileAddressEmptyTitle => 'No shipping address yet';

  @override
  String get profileAddressEmptyBody =>
      'Add a frequently used address to fill in delivery details faster at checkout.';

  @override
  String get profileAddressReceiver => 'Recipient';

  @override
  String get profileAddressPhone => 'Phone Number';

  @override
  String get profileAddressProvinceName => 'Province Name';

  @override
  String get profileAddressProvinceCode => 'Province Code';

  @override
  String get profileAddressCityName => 'City Name';

  @override
  String get profileAddressCityCode => 'City Code';

  @override
  String get profileAddressDistrictName => 'District Name';

  @override
  String get profileAddressDistrictCode => 'District Code';

  @override
  String get profileAddressStreetName => 'Street Name';

  @override
  String get profileAddressStreetCode => 'Street Code';

  @override
  String get profileAddressRegion => 'Region';

  @override
  String get profileAddressDetail => 'Street Address';

  @override
  String get profileAddressTag => 'Address Tag';

  @override
  String get profileAddressSetDefault => 'Set as Default';

  @override
  String get profileAddressDefault => 'Default';

  @override
  String get profileAddressEdit => 'Edit';

  @override
  String get profileAddressDelete => 'Delete';

  @override
  String get profileAddressDeleteTitle => 'Delete address';

  @override
  String get profileAddressDeleteBody =>
      'This address cannot be restored after deletion. Continue?';

  @override
  String get profileAddressDeleteAction => 'Delete';

  @override
  String get profileAddressFormAddTitle => 'Add Shipping Address';

  @override
  String get profileAddressFormEditTitle => 'Edit Shipping Address';

  @override
  String get profileAddressValidationReceiver => 'Enter the recipient name';

  @override
  String get profileAddressValidationPhone => 'Enter a valid phone number';

  @override
  String get profileAddressValidationProvinceName => 'Enter the province name';

  @override
  String get profileAddressValidationProvinceCode => 'Enter the province code';

  @override
  String get profileAddressValidationCityName => 'Enter the city name';

  @override
  String get profileAddressValidationCityCode => 'Enter the city code';

  @override
  String get profileAddressValidationDistrictName => 'Enter the district name';

  @override
  String get profileAddressValidationDistrictCode => 'Enter the district code';

  @override
  String get profileAddressValidationRegion => 'Enter the region';

  @override
  String get profileAddressValidationDetail => 'Enter the street address';

  @override
  String get profileAddressValidationCodeFormat =>
      'Codes can contain only letters, numbers, underscores, and hyphens';

  @override
  String get profileAddressValidationStreetPair =>
      'Street name and street code must either both be filled or both be empty';

  @override
  String get profileAddressDefaultToggle => 'Use as default shipping address';

  @override
  String get profileAddressSaveFailed =>
      'Failed to save the address. Please try again.';

  @override
  String get profileAddressLoadFailed =>
      'Failed to load address information. Please try again.';

  @override
  String get profileAddressDeleteFailed =>
      'Failed to delete the address. Please try again.';

  @override
  String get profileAddressDefaultFailed =>
      'Failed to update the default address. Please try again.';

  @override
  String get profilePointsTitle => 'Points Center';

  @override
  String get profilePointsBalance => 'Available Points';

  @override
  String get profilePointsTodayGain => 'Today';

  @override
  String get profilePointsWeekGain => 'This Week';

  @override
  String get profilePointsHisTotal => 'All-Time';

  @override
  String get profilePointsMonthlyEarned => 'Earned This Month';

  @override
  String get profilePointsMonthlySpent => 'Spent This Month';

  @override
  String get profilePointsCheckIn => 'Daily Check-in +5';

  @override
  String get profilePointsCheckInDone => 'Checked in Today';

  @override
  String get profilePointsCheckInHint =>
      'Check in every day to collect reward points for future perks.';

  @override
  String get profilePointsCheckInFailed =>
      'Failed to check in. Please try again.';

  @override
  String profilePointsCheckInSuccess(int points) {
    return 'Check-in complete. You received $points points.';
  }

  @override
  String get profilePointsHistory => 'Points History';

  @override
  String get profilePointsTasks => 'Points Tasks';

  @override
  String get profilePointsRegisterTask => 'Starter Task';

  @override
  String get profilePointsTaskEmpty => 'No points tasks available right now.';

  @override
  String get profilePointsEmpty => 'No points history yet';

  @override
  String get profilePointsLoadFailed =>
      'Failed to load points information. Please try again.';

  @override
  String get profilePointsLoadMore => 'Load More';

  @override
  String get profilePointsLoadMoreFailed =>
      'Failed to load more points records. Please try again.';

  @override
  String profilePointsTaskActionUnsupported(String action) {
    return 'The task action \"$action\" is not available yet.';
  }

  @override
  String get profilePointsEntryDailyCheckIn => 'Daily Check-in';

  @override
  String get profilePointsEntryDailyCheckInSub =>
      'Today\'s sign-in reward has been credited';

  @override
  String get profilePointsEntryWelcome => 'Welcome Reward';

  @override
  String get profilePointsEntryWelcomeSub =>
      'Granted after completing your new member activation';

  @override
  String get profilePointsEntryAssessment => 'Assessment Bonus';

  @override
  String get profilePointsEntryAssessmentSub =>
      'Granted after finishing a personalized constitution assessment';

  @override
  String get profilePointsEntryCoupon => 'Consultation Coupon Redemption';

  @override
  String get profilePointsEntryCouponSub =>
      'Points were redeemed for a discount benefit';

  @override
  String get profileLogout => 'Log out';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsAccountSecurity => 'Account & Security';

  @override
  String get settingsAccountSecuritySub =>
      'Manage sign-in methods, phone, and password security';

  @override
  String get accountSecurityTitle => 'Account & Security';

  @override
  String get accountSecurityPhoneCodeTip =>
      'Registration currently uses phone verification codes by default. You can add a password later if needed.';

  @override
  String get accountSecurityLoginPassword => 'Set Login Password';

  @override
  String get accountSecurityLoginPasswordSub =>
      'After setting it, you can sign in with your phone number and password. If not set, continue using verification codes.';

  @override
  String get accountSecurityPasswordSet => 'Set';

  @override
  String get accountSecurityPasswordUnset => 'Not set';

  @override
  String get setLoginPasswordTitle => 'Set Login Password';

  @override
  String get setLoginPasswordSubtitle =>
      'After setting it, you can sign in with your phone number and password. If you skip it for now, verification code login stays available.';

  @override
  String get setLoginPasswordAction => 'Save Password';

  @override
  String get setLoginPasswordSuccess => 'Login password set successfully';

  @override
  String get localeSheetTitle => 'Choose Language';

  @override
  String get localeFollowSystem => 'Follow System';

  @override
  String get localeChineseSimplified => 'Simplified Chinese';

  @override
  String get localeEnglish => 'English';

  @override
  String get localeJapanese => '日本語';

  @override
  String get localeKorean => '한국어';

  @override
  String get commonViewDetails => 'View details';

  @override
  String get commonFiveElements => 'Five Elements';

  @override
  String get profileBmiNormal => 'Normal';

  @override
  String get scanStepFace => 'Face';

  @override
  String get scanStepTongue => 'Tongue';

  @override
  String get scanStepPalm => 'Palm';

  @override
  String get scanSkipThisStep => 'Skip this step';

  @override
  String get scanProgressLabel => 'Progress';

  @override
  String scanAnalyzingProgress(int progress) {
    return 'Analyzing $progress%';
  }

  @override
  String scanCameraPreviewUnsupported(String platform) {
    return '$platform is not supported yet for camera preview.';
  }

  @override
  String get scanGuideHeaderTitle => 'Health Scan Guide';

  @override
  String get scanGuideHeroTitle => 'Complete Three Guided Scans';

  @override
  String get scanGuideHeroSubtitle =>
      'Follow the face, tongue, and palm scans to generate your AI health report.';

  @override
  String get scanGuideStep1Title => 'Face Scan';

  @override
  String get scanGuideStep1Desc => 'Check complexion and facial features';

  @override
  String get scanGuideStep1Detail =>
      'This scan reviews facial color, expression, and overall facial condition.';

  @override
  String get scanGuideStep2Title => 'Tongue Scan';

  @override
  String get scanGuideStep2Desc => 'Review tongue color, shape, and coating';

  @override
  String get scanGuideStep2Detail =>
      'This scan reviews tongue color, coating, and shape for constitution assessment.';

  @override
  String get scanGuideStep3Title => 'Palm Scan';

  @override
  String get scanGuideStep3Desc =>
      'Review palm lines, color, and hand condition';

  @override
  String get scanGuideStep3Detail =>
      'This scan reviews palm texture, color, and overall hand condition.';

  @override
  String scanGuideStepLabel(int step, String title) {
    return 'Step $step · $title';
  }

  @override
  String get scanGuideWarmPromptTitle => 'Before You Start';

  @override
  String get scanGuideWarmPromptContent =>
      'Use steady, well-lit surroundings. Clean your face, remove hats, glasses, and accessories, and stay relaxed throughout the scan.';

  @override
  String get scanGuideEstimate => 'About 2 minutes · Best in good lighting';

  @override
  String get scanGuideStartButton => 'Start Scan';

  @override
  String get scanGuidePrivacyNote =>
      'Scan images are used only for this health assessment and are not shared with third parties.';

  @override
  String get scanFaceDetectionPermissionRequired =>
      'Camera permission is required for face detection.';

  @override
  String get scanCameraPermissionRequired =>
      'Camera permission is required to continue.';

  @override
  String get scanKeepStill => 'Please keep still';

  @override
  String get scanMoveLeft => 'Move left';

  @override
  String get scanMoveRight => 'Move right';

  @override
  String get scanMoveUp => 'Move up';

  @override
  String get scanMoveDown => 'Move down';

  @override
  String get scanTipBrightLight => 'Use bright, even lighting';

  @override
  String get scanTipKeepSteady => 'Keep steady during the scan';

  @override
  String get scanScanning => 'Scanning';

  @override
  String get scanFaceAlignInFrame => 'Align your face inside the frame';

  @override
  String get scanFaceDetectedReady => 'Face aligned ✓';

  @override
  String get scanFaceTitle => 'Face Scan';

  @override
  String get scanFaceTag => 'Face';

  @override
  String get scanFaceSubtitle =>
      'Place your face inside the frame, look forward, and keep a relaxed expression.';

  @override
  String get scanFaceDetail =>
      'This scan reviews facial color, expression, and overall facial condition.';

  @override
  String get scanFaceTipNoMakeup => 'Minimal makeup';

  @override
  String get scanFaceTipLookForward => 'Look straight ahead';

  @override
  String get scanFaceStartButton => 'Start Face Scan';

  @override
  String get scanTongueCompleted => 'Tongue scan complete ✓';

  @override
  String get scanTongueTapToStart => 'Tap below to start the tongue scan';

  @override
  String get scanTongueDetectedHold => 'Tongue detected, hold for 2 seconds';

  @override
  String get scanTongueMouthDetected =>
      'Mouth detected. Please extend your tongue naturally.';

  @override
  String get scanTongueAlignHint =>
      'Extend your tongue and align it inside the frame.';

  @override
  String get scanTongueTitle => 'Tongue Scan';

  @override
  String get scanTongueTag => 'Tongue';

  @override
  String get scanTongueSubtitle =>
      'Extend your tongue naturally, keep it flat, and hold for 2 seconds.';

  @override
  String get scanTongueDetail =>
      'This scan reviews tongue color, coating, and shape for constitution assessment.';

  @override
  String get scanTongueTipNoColoredFood => 'Avoid colored foods';

  @override
  String get scanTongueTipTongueFlat => 'Keep your tongue flat';

  @override
  String get scanTongueStartButton => 'Start Tongue Scan';

  @override
  String get scanTongueNextPalm => 'Continue to Palm Scan';

  @override
  String get scanPalmMoveCloser =>
      'Your palm is too far away. Move a little closer.';

  @override
  String get scanPalmMoveFarther =>
      'Your palm is too close. Move a little farther back.';

  @override
  String get scanPalmWaitingPermission => 'Waiting for camera permission';

  @override
  String get scanPalmCompleted => 'Palm scan complete ✓';

  @override
  String get scanPalmReadyHold => 'Palm aligned. Hold for 2 seconds.';

  @override
  String get scanPalmOpenDetectedStraighten =>
      'Open palm detected. Please straighten your palm.';

  @override
  String scanPalmDetectedGesture(String gesture) {
    return 'Detected gesture: $gesture';
  }

  @override
  String get scanPalmStretchOpen =>
      'Straighten your palm and keep it naturally open.';

  @override
  String get scanPalmAlignHint => 'Place your palm inside the frame.';

  @override
  String get scanGestureOpenPalm => 'Open Palm';

  @override
  String get scanGestureClosedFist => 'Closed Fist';

  @override
  String get scanGestureVictory => 'Victory';

  @override
  String get scanGestureThumbUp => 'Thumb Up';

  @override
  String get scanGestureThumbDown => 'Thumb Down';

  @override
  String get scanGesturePointingUp => 'Pointing Up';

  @override
  String get scanGestureILoveYou => 'I Love You';

  @override
  String get scanPalmTitle => 'Palm Scan';

  @override
  String get scanPalmTag => 'Palm';

  @override
  String get scanPalmSubtitle =>
      'Extend your palm toward the camera, match the outline, and spread your fingers naturally.';

  @override
  String get scanPalmDetail =>
      'This scan reviews palm lines, color, and overall hand condition.';

  @override
  String get scanPalmTipFlatten => 'Keep your palm flat';

  @override
  String get scanPalmViewingReportSoon => 'Opening your report...';

  @override
  String get scanPalmHoldButton => 'Hold Your Palm for 2 Seconds';

  @override
  String get scanQuestionTitle => 'Follow-up Questions';

  @override
  String get scanQuestionSubtitle =>
      'A few extra questions can make the constitution analysis and final report more complete. You can also skip and view the report from the current scan results.';

  @override
  String get scanQuestionSkipDirectReport => 'Skip to report';

  @override
  String scanQuestionAnsweredCount(int count) {
    return '$count answered';
  }

  @override
  String get scanQuestionOptionalTag => 'Optional';

  @override
  String get scanQuestionLoadingTitle => 'Preparing follow-up questions';

  @override
  String get scanQuestionLoadingBody =>
      'Fetching the next question and assembling the answer context.';

  @override
  String get scanQuestionLoadFailed => 'Couldn\'t load the questions';

  @override
  String get scanQuestionRetry => 'Retry';

  @override
  String get scanQuestionMissingQuestion =>
      'No question is available right now. Try again or go straight to the report.';

  @override
  String get scanQuestionFooterHint =>
      'These answers are only used to refine the constitution analysis and do not change the uploaded scan images.';

  @override
  String scanQuestionProgressTitle(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get scanQuestionSectionTitle => 'Extra questions';

  @override
  String get scanQuestionSubmitAndReport => 'Submit and build report';

  @override
  String get scanQuestionNextButton => 'Next question';

  @override
  String get reportTabOverview => 'Overview';

  @override
  String get reportTabConstitution => 'Constitution';

  @override
  String get reportTabTherapy => 'Therapy';

  @override
  String get reportTabAdvice => 'Advice';

  @override
  String get reportHeaderCollapsedTitle => 'AI Health Report';

  @override
  String get reportHeroMeta => '2025.03.14 · AI Four-Diagnosis Assessment';

  @override
  String reportHeroTitle(String name) {
    return '$name\'s Health Report';
  }

  @override
  String get reportHeroSecondaryBias => 'Qi Deficiency Tendency';

  @override
  String get reportHeroSummary =>
      'Spleen qi is weak and transport function is reduced. The complexion appears slightly yellow, and the tongue is pale with a white coating.';

  @override
  String get reportHealthScoreLabel => 'Health Score';

  @override
  String get reportHealthStatus => 'Constitution Status · Good';

  @override
  String get reportOverviewFaceDiagnosisDesc =>
      'Slightly yellow complexion with fair vitality';

  @override
  String get reportOverviewTongueDiagnosisDesc =>
      'Pale tongue with a slightly thick white coating';

  @override
  String get reportOverviewPalmDiagnosisDesc =>
      'Fine palm lines with even complexion';

  @override
  String get reportOverviewDiagScoresTitle => 'Three-Diagnosis Scores';

  @override
  String get reportOverviewFeatureDetailsTitle => 'Feature Details';

  @override
  String get reportOverviewTongueTitle => 'Tongue';

  @override
  String get reportOverviewTongueImagePlaceholder => 'Tongue image';

  @override
  String get reportOverviewTongueColorLabel => 'Color';

  @override
  String get reportOverviewTongueColorValue => 'Light red';

  @override
  String get reportOverviewTongueCoatingLabel => 'Coating';

  @override
  String get reportOverviewTongueCoatingValue => 'White · Slightly thick';

  @override
  String get reportOverviewTongueShapeLabel => 'Shape';

  @override
  String get reportOverviewTongueShapeValue => 'Normal';

  @override
  String get reportOverviewWuxingTitle => 'Five Elements · Wood dominant';

  @override
  String get reportOverviewDiagnosisSummaryTitle => 'Diagnosis Summary';

  @override
  String get reportOverviewDiagnosisSummaryBody =>
      'Diagnosis: Spleen qi deficiency with weakened transport function. Yellowish complexion, pale tongue with white coating, fine and moderate pulse, shortness of breath, fatigue, and poor appetite. The pattern belongs to weak spleen qi with internal dampness.';

  @override
  String get reportOverviewDiagnosisTagSpleenWeak => 'Weak spleen and stomach';

  @override
  String get reportOverviewModuleConstitutionTitle => 'Constitution Details';

  @override
  String get reportOverviewModuleConstitutionSubtitle =>
      'Understand your constitution';

  @override
  String get reportOverviewModuleAcupointTitle => 'Recommended Acupoints';

  @override
  String get reportOverviewModuleAcupointSubtitle => 'Acupoint therapy plan';

  @override
  String get reportOverviewModuleDietTitle => 'Dietary Advice';

  @override
  String get reportOverviewModuleDietSubtitle => 'Food therapy plan';

  @override
  String get reportOverviewModuleSeasonalTitle => 'Seasonal Care';

  @override
  String get reportOverviewModuleSeasonalSubtitle => 'Nourish with the seasons';

  @override
  String get reportOverviewModuleNavTitle => 'Module Navigation';

  @override
  String get reportOverviewScanMetaDisclaimer =>
      'This report is generated through AI Four-Diagnosis Assessment and is for wellness reference only. It does not constitute a medical diagnosis. Please consult a qualified physician if needed.';

  @override
  String get reportConstitutionDetailTitle => 'Constitution Details';

  @override
  String get reportConstitutionCoreConclusionLabel => 'Key Finding';

  @override
  String get reportConstitutionCoreConclusionValue =>
      'Primary constitutional tendency: Qi Deficiency';

  @override
  String get reportConstitutionCoreConclusionBody =>
      'Overall, the baseline is a Balanced Constitution with a noticeable Qi Deficiency tendency. The radar chart highlights both traits, suggesting a decent foundation that still becomes more prone to fatigue and weak spleen transport when overworked, poorly nourished, or sleep deprived.';

  @override
  String get reportConstitutionYangDeficiency => 'Yang Deficiency Constitution';

  @override
  String get reportConstitutionYinDeficiency => 'Yin Deficiency Constitution';

  @override
  String get reportConstitutionDampHeat => 'Damp-Heat Constitution';

  @override
  String get reportConstitutionBloodStasis => 'Blood Stasis Constitution';

  @override
  String get reportConstitutionQiStagnation => 'Qi Stagnation Constitution';

  @override
  String get reportConstitutionSpecial => 'Special Constitution';

  @override
  String get reportCausalAnalysisTitle => 'Cause Analysis';

  @override
  String get reportCauseRoutine => 'Routine';

  @override
  String get reportCauseRoutineBody =>
      'Staying up late over time and remaining awake at midnight can damage liver and kidney essence, resulting in insufficient qi and blood generation.';

  @override
  String get reportCauseDiet => 'Diet';

  @override
  String get reportCauseDietBody =>
      'A preference for cold foods and excessive intake of raw or chilled items can injure spleen yang and weaken transport function.';

  @override
  String get reportCauseEmotion => 'Emotion';

  @override
  String get reportCauseEmotionBody =>
      'Excessive worry and overthinking can injure the spleen, cause qi stagnation, and impair transformation and transportation.';

  @override
  String get reportCauseExercise => 'Exercise';

  @override
  String get reportCauseExerciseBody =>
      'Long periods of sitting and insufficient movement slow qi and blood circulation and gradually weaken central qi.';

  @override
  String get reportDiseaseTendencyTitle => 'Likely Triggered Conditions';

  @override
  String get reportDiseaseSpleenWeak => 'Weak Spleen and Stomach';

  @override
  String get reportDiseaseSpleenWeakBody =>
      'Indigestion, bloating, loose stools';

  @override
  String get reportDiseaseQiBloodDeficiency => 'Qi and Blood Deficiency';

  @override
  String get reportDiseaseQiBloodDeficiencyBody =>
      'Dizziness, fatigue, pale-yellow complexion';

  @override
  String get reportDiseaseLowImmunity => 'Low Immunity';

  @override
  String get reportDiseaseLowImmunityBody => 'Frequent colds, easy fatigue';

  @override
  String get reportDiseaseEmotional => 'Emotional Disorders';

  @override
  String get reportDiseaseEmotionalBody =>
      'Anxiety, insomnia, depressive tendency';

  @override
  String get reportBadHabitsTitle => 'Harmful Habits';

  @override
  String get reportBadHabitOverwork => 'Overwork';

  @override
  String get reportBadHabitOverworkBody =>
      'Consumes qi and harms the spleen, worsening qi deficiency';

  @override
  String get reportBadHabitColdFood => 'Excess Cold Food';

  @override
  String get reportBadHabitColdFoodBody =>
      'Cold pathogens damage yang and weaken the spleen and stomach';

  @override
  String get reportBadHabitLateSleep => 'Late Sleep';

  @override
  String get reportBadHabitLateSleepBody =>
      'Yin cannot be gathered, causing essence depletion';

  @override
  String get reportBadHabitDieting => 'Excessive Dieting';

  @override
  String get reportBadHabitDietingBody =>
      'Leaves qi and blood without a source of production and further harms central qi';

  @override
  String get reportBadHabitBinge => 'Binge Eating';

  @override
  String get reportBadHabitBingeBody =>
      'Overburdens the spleen and stomach and disrupts transport function';

  @override
  String get reportTherapyAcupointsTitle => 'Acupoint Therapy';

  @override
  String get reportTherapyAcupointsIntro =>
      'Based on the spleen qi deficiency pattern, the following acupoints are recommended for moxibustion or massage for 10–15 minutes daily.';

  @override
  String get reportTherapyAcuPointZusanli => 'Zusanli';

  @override
  String get reportTherapyAcuPointZusanliLocation =>
      '3 cun below Dubi, one finger-breadth lateral to the tibia';

  @override
  String get reportTherapyAcuPointZusanliEffect =>
      'Strengthens spleen and stomach, supplements qi and blood, a key strengthening point';

  @override
  String get reportTherapyAcuPointZusanliMeridian =>
      'Stomach Meridian of Foot-Yangming';

  @override
  String get reportTherapyAcuPointPishu => 'Pishu';

  @override
  String get reportTherapyAcuPointPishuLocation =>
      '1.5 cun lateral to the lower border of the spinous process of T11';

  @override
  String get reportTherapyAcuPointPishuEffect =>
      'Strengthens spleen, resolves dampness, supplements qi, and regulates spleen-stomach function';

  @override
  String get reportTherapyAcuPointPishuMeridian =>
      'Bladder Meridian of Foot-Taiyang';

  @override
  String get reportTherapyAcuPointQihai => 'Qihai';

  @override
  String get reportTherapyAcuPointQihaiLocation =>
      '1.5 cun below the navel on the anterior midline';

  @override
  String get reportTherapyAcuPointQihaiEffect =>
      'Supplements original qi, warms yang, and improves qi-deficiency fatigue';

  @override
  String get reportTherapyAcuPointQihaiMeridian => 'Ren Meridian';

  @override
  String get reportTherapyAcuPointGuanyuan => 'Guanyuan';

  @override
  String get reportTherapyAcuPointGuanyuanLocation =>
      '3 cun below the navel on the anterior midline';

  @override
  String get reportTherapyAcuPointGuanyuanEffect =>
      'Strengthens original vitality, warms yang, and improves constitution';

  @override
  String get reportTherapyAcuPointGuanyuanMeridian => 'Ren Meridian';

  @override
  String get reportTherapyAcupointsWarning =>
      'Avoid moxibustion during pregnancy, menstruation, or on broken skin. Control heat carefully to prevent burns.';

  @override
  String get reportMentalWellnessTitle => 'Mental Wellness';

  @override
  String get reportMentalTipCalm => 'Calm Emptiness';

  @override
  String get reportMentalTipCalmBody =>
      'Reduce overthinking and keep the mind calm. In TCM, excessive thinking harms the spleen and most easily depletes spleen qi.';

  @override
  String get reportMentalTipNature => 'Follow Nature';

  @override
  String get reportMentalTipNatureBody =>
      'Align sleep and wake with the day-night rhythm. Sleep before midnight to nourish liver qi and stretch in the early morning to support rising yang.';

  @override
  String get reportMentalTipEmotion => 'Regulate Emotions';

  @override
  String get reportMentalTipEmotionBody =>
      'Stay optimistic and avoid emotional extremes. Moderate expression helps relieve stagnant qi.';

  @override
  String get reportMentalTipMeditation => 'Meditation';

  @override
  String get reportMentalTipMeditationBody =>
      'Sit quietly for 10 minutes each day and focus on breathing to regulate spleen-stomach qi and strengthen upright qi.';

  @override
  String get reportSeasonalCareTitle => 'Seasonal Care';

  @override
  String get reportSeasonSpring => 'Spring';

  @override
  String get reportSeasonSpringAdvice =>
      'Nourish the liver in spring and mildly increase sour foods. Eat leeks and spinach, stretch the body, and take morning walks to support rising yang.';

  @override
  String get reportSeasonSpringAvoid =>
      'Avoid overfatigue and overly pungent dispersing foods';

  @override
  String get reportSeasonSummer => 'Summer';

  @override
  String get reportSeasonSummerAdvice =>
      'Nourish the heart in summer and pay attention to clearing heat. Eat lotus seeds and coix seeds moderately, rest at noon, and avoid excessive sweating that drains qi.';

  @override
  String get reportSeasonSummerAvoid =>
      'Avoid cold drinks and intense exercise with heavy sweating';

  @override
  String get reportSeasonAutumn => 'Autumn';

  @override
  String get reportSeasonAutumnAdvice =>
      'Nourish the lungs in autumn with moistening foods. Eat pears, lily bulbs, and tremella, sleep early, and conserve essence.';

  @override
  String get reportSeasonAutumnAvoid =>
      'Avoid excessive sadness and overly spicy, drying foods';

  @override
  String get reportSeasonWinter => 'Winter';

  @override
  String get reportSeasonWinterAdvice =>
      'Nourish the kidneys in winter and focus on storage. Eat black sesame, walnuts, and lamb appropriately; sleep early and rise later to protect kidney yang.';

  @override
  String get reportSeasonWinterAvoid =>
      'Avoid overwork and excessive sweating that disperses yang';

  @override
  String get reportAdviceTongueAnalysisTitle => 'Tongue Analysis';

  @override
  String get reportAdviceTongueScoreLabel => 'Tongue Composite Score';

  @override
  String get reportAdviceTongueScoreSummary =>
      'Spleen deficiency with dampness, weak qi and blood';

  @override
  String get reportAdviceTongueFeatureColor => 'Tongue Color';

  @override
  String get reportAdviceTongueFeatureColorValue => 'Light red';

  @override
  String get reportAdviceTongueFeatureColorDesc =>
      'A light-red tongue is normal; paleness suggests insufficient qi and blood';

  @override
  String get reportAdviceTongueFeatureShape => 'Tongue Shape';

  @override
  String get reportAdviceTongueFeatureShapeValue => 'Slightly puffy';

  @override
  String get reportAdviceTongueFeatureShapeDesc =>
      'A slightly puffy tongue with tooth marks suggests spleen deficiency with dampness';

  @override
  String get reportAdviceTongueFeatureCoatingColor => 'Coating Color';

  @override
  String get reportAdviceTongueFeatureCoatingColorValue => 'White';

  @override
  String get reportAdviceTongueFeatureCoatingColorDesc =>
      'A white coating often indicates cold or an exterior pattern, suggesting mildly insufficient yang qi';

  @override
  String get reportAdviceTongueFeatureTexture => 'Coating Texture';

  @override
  String get reportAdviceTongueFeatureTextureValue => 'Thick and greasy';

  @override
  String get reportAdviceTongueFeatureTextureDesc =>
      'A thick greasy coating indicates relatively heavy dampness and impaired spleen transport';

  @override
  String get reportAdviceTongueFeatureTeethMarks => 'Teeth Marks';

  @override
  String get reportAdviceTongueFeatureTeethMarksValue => 'Present';

  @override
  String get reportAdviceTongueFeatureTeethMarksDesc =>
      'Tooth marks on the tongue edge are a classic sign of spleen deficiency with weak qi transformation';

  @override
  String get reportAdviceDietTitle => 'Dietary Advice';

  @override
  String get reportAdviceDietIntro =>
      'For spleen qi deficiency, favor mildly warm and qi-tonifying foods that strengthen the spleen and harmonize the stomach. Avoid cold, raw, and hard-to-digest foods.';

  @override
  String get reportAdviceDietRecommendedTitle => 'Recommended';

  @override
  String get reportAdviceDietAvoidTitle => 'Avoid';

  @override
  String get reportAdviceDietRecipeTitle => 'Suggested Recipes';

  @override
  String get reportAdviceDietRecipeBody =>
      'Chinese yam and coix porridge: cook 50g yam, 30g coix seed, and 5 red dates together for breakfast to strongly support spleen qi.\n\nCodonopsis and poria chicken stew: tonifies middle qi and suits daily care for qi-deficiency constitutions.';

  @override
  String get reportAdviceFoodShanyao => 'Yam';

  @override
  String get reportAdviceFoodShanyaoDesc =>
      'Strengthens spleen and kidneys, supplements qi, nourishes yin';

  @override
  String get reportAdviceFoodYiyiren => 'Coix Seeds';

  @override
  String get reportAdviceFoodYiyirenDesc =>
      'Drains dampness, strengthens spleen, stops diarrhea';

  @override
  String get reportAdviceFoodHongzao => 'Red Dates';

  @override
  String get reportAdviceFoodHongzaoDesc =>
      'Supplement qi and blood, strengthen spleen and stomach, calm the mind';

  @override
  String get reportAdviceFoodBiandou => 'White Hyacinth Bean';

  @override
  String get reportAdviceFoodBiandouDesc =>
      'Strengthens spleen, transforms dampness, relieves summer heat';

  @override
  String get reportAdviceFoodDangshen => 'Codonopsis';

  @override
  String get reportAdviceFoodDangshenDesc =>
      'Tonifies middle qi, strengthens spleen, nourishes stomach';

  @override
  String get reportAdviceFoodFuling => 'Poria';

  @override
  String get reportAdviceFoodFulingDesc =>
      'Strengthens spleen, harmonizes the middle, drains dampness';

  @override
  String get reportAdviceAvoidColdFood => 'Cold foods';

  @override
  String get reportAdviceAvoidGreasy => 'Greasy heavy foods';

  @override
  String get reportAdviceAvoidSpicy => 'Spicy irritants';

  @override
  String get reportAdviceAvoidSweet => 'Overly sweet rich foods';

  @override
  String get reportAdviceAvoidAlcohol => 'Tobacco and alcohol';

  @override
  String get reportAdviceProjectsTitle => 'Recommended Care Services';

  @override
  String get reportAdviceProjectsSubtitle =>
      'In-clinic service recommendations based on your report';

  @override
  String get reportAdviceProjectsEmpty =>
      'No matching care-service recommendations are available right now.';

  @override
  String get reportAdviceProjectsDisclaimer =>
      'These service recommendations are based on constitution analysis and are for reference only. Final service content and booking availability follow the clinic\'s arrangement.';

  @override
  String get reportAdviceProjectDetailButton => 'View service >';

  @override
  String get reportAdviceProductsTitle => 'Recommended Products';

  @override
  String get reportAdviceProductsSubtitle =>
      'Shippable product recommendations based on your report';

  @override
  String get reportAdviceProductsEmpty =>
      'No matching product recommendations are available right now.';

  @override
  String get reportAdviceProductsDisclaimer =>
      'These product recommendations are based on constitution analysis and are for reference only. Actual inventory, specifications, and delivery coverage follow the clinic\'s arrangement.';

  @override
  String get reportProductCommonShipping =>
      'Orders are prepared within 48 business hours and include shipment tracking.';

  @override
  String get reportProjectCommonServiceNote =>
      'Final service content is arranged after an in-clinic assessment.';

  @override
  String get reportProjectCommonConsultNote =>
      'In-clinic consultation and booking are supported. Final scheduling depends on the clinic.';

  @override
  String get reportProjectWarmMoxibustion => 'Warm Moxibustion Care';

  @override
  String get reportProjectWarmMoxibustionType => 'In-clinic warming session';

  @override
  String get reportProjectWarmMoxibustionDesc =>
      'Recommended when the report suggests cold-damp or qi-deficiency tendencies and gentle warming care is appropriate.';

  @override
  String get reportProjectWarmMoxibustionTag => 'Clinic pick';

  @override
  String get reportProjectWarmMoxibustionDuration =>
      'About 45 minutes per session';

  @override
  String get reportProjectMeridianRelief => 'Meridian Relief Session';

  @override
  String get reportProjectMeridianReliefType => 'Meridian care service';

  @override
  String get reportProjectMeridianReliefDesc =>
      'Focused on fatigue, sleep rhythm, and qi-blood circulation with a lighter, restorative in-clinic treatment plan.';

  @override
  String get reportProjectMeridianReliefTag => 'Good first visit';

  @override
  String get reportProjectMeridianReliefDuration =>
      'About 60 minutes per session';

  @override
  String get reportProductJianpiwanPack =>
      '1 bottle / 200 pills, suitable for daily spleen and stomach care routines.';

  @override
  String get reportProductShenlingPack =>
      '10 sachets per box, suitable for light daily spleen support and qi care.';

  @override
  String get reportProductAijiuPack =>
      '20 patches per box, suitable for gentle at-home moxibustion care.';

  @override
  String get reportProductFoodPackPack =>
      '7-day dietary wellness kit with yam, coix seed, poria, and more.';

  @override
  String get reportProductDetailTitle => 'Product Details';

  @override
  String get reportProductDetailHeroBadge => 'Linked to Your Report';

  @override
  String get reportProductDetailRecommendationTitle => 'Why It Is Recommended';

  @override
  String get reportProductDetailPackageTitle => 'Package & Specification';

  @override
  String get reportProductDetailShippingTitle => 'Shipping Notes';

  @override
  String get reportProductDetailServiceTitle => 'Service Notes';

  @override
  String get reportProductDetailServiceBody =>
      'This version only demonstrates product display and mock checkout. A real order system and Apple Pay / Google Pay can be added later.';

  @override
  String get reportProductDetailQuantityTitle => 'Quantity';

  @override
  String reportProductDetailQuantitySummary(int count) {
    return 'Selected $count item(s)';
  }

  @override
  String get reportProductDetailFinalPrice => 'Estimated Price';

  @override
  String get reportProductDetailCheckoutButton => 'Proceed to Checkout';

  @override
  String get reportProductDetailReportLinked => 'Aligned with report guidance';

  @override
  String get reportProjectDetailTitle => 'Service Details';

  @override
  String get reportProjectDetailHeroBadge => 'Linked to your report';

  @override
  String get reportProjectDetailRecommendationTitle => 'Why it is recommended';

  @override
  String get reportProjectDetailDurationTitle => 'Session length';

  @override
  String get reportProjectDetailServiceTitle => 'Service notes';

  @override
  String get reportProjectDetailConsultTitle => 'Consultation & booking';

  @override
  String get reportProjectDetailActionButton => 'Book a consultation';

  @override
  String get reportProjectDetailReportLinked => 'Aligned with report guidance';

  @override
  String get reportProductCheckoutTitle => 'Confirm Order';

  @override
  String get reportProductCheckoutSectionAddress => 'Shipping Information';

  @override
  String get reportProductCheckoutRecipient => 'Recipient';

  @override
  String get reportProductCheckoutPhone => 'Phone Number';

  @override
  String get reportProductCheckoutAddress => 'Shipping Address';

  @override
  String get reportProductCheckoutOrderSummary => 'Order Summary';

  @override
  String get reportProductCheckoutQuantityLabel => 'Quantity';

  @override
  String get reportProductCheckoutSubtotal => 'Subtotal';

  @override
  String get reportProductCheckoutShippingFee => 'Shipping';

  @override
  String get reportProductCheckoutServiceFee => 'Service Fee';

  @override
  String get reportProductCheckoutTotal => 'Total';

  @override
  String get reportProductCheckoutPaymentTitle => 'Payment Method';

  @override
  String get reportProductCheckoutApplePayTitle => 'Apple Pay';

  @override
  String get reportProductCheckoutApplePaySubtitle =>
      'Reserved for future Apple Pay integration once merchant capabilities are ready.';

  @override
  String get reportProductCheckoutApplePayDialogBody =>
      'Real Apple Pay is not connected in this build yet. This button currently marks the future payment entry, so continue with the mock order flow for page verification.';

  @override
  String get reportProductCheckoutGooglePayTitle => 'Google Pay';

  @override
  String get reportProductCheckoutGooglePaySubtitle =>
      'Reserved for future Google Pay integration once payment capabilities are ready.';

  @override
  String get reportProductCheckoutGooglePayDialogBody =>
      'Real Google Pay is not connected in this build yet. This button currently marks the future payment entry, so continue with the mock order flow for page verification.';

  @override
  String get reportProductCheckoutMockSubmit => 'Create Mock Order';

  @override
  String get reportProductCheckoutSubmitting => 'Creating order…';

  @override
  String get reportProductCheckoutSuccessTitle => 'Mock Order Created';

  @override
  String get reportProductCheckoutSuccessBody =>
      'This currently completes only the frontend order demo flow. It will be replaced by the real checkout and Apple Pay / Google Pay flow later.';

  @override
  String get reportUnlockTitle => 'Unlock Full Report';

  @override
  String get reportUnlockDescription =>
      'View the full constitution analysis, care plan, and personalized recommendations.';

  @override
  String get reportUnlockButton => 'Unlock Report';

  @override
  String get reportUnlockSheetTitle => 'Unlock Full Report';

  @override
  String get reportUnlockSheetBody =>
      'After unlocking, you can view the complete constitution details, care plans, and personalized recommendations.';

  @override
  String get reportUnlockInvitationTag => 'Premium Health Insights';

  @override
  String get reportUnlockInvitationSubtitle =>
      'Unlock the full report to continue with deeper constitution insights, tailored care paths, and personalized wellness guidance.';

  @override
  String get reportUnlockBenefitConstitution =>
      'View the full constitution causes, risk tendencies, and detailed interpretation';

  @override
  String get reportUnlockBenefitTherapy =>
      'Get personalized acupoint guidance, mental wellness support, and seasonal care advice';

  @override
  String get reportUnlockBenefitAdvice =>
      'Unlock detailed tongue analysis, dietary direction, and related product recommendations';

  @override
  String get reportUnlockSheetPrice => 'Mock price: ¥29.90';

  @override
  String get reportUnlockSheetPriceFallback => 'Loading App Store price';

  @override
  String get reportUnlockSheetConfirm => 'Unlock with Apple IAP';

  @override
  String get reportUnlockSheetPurchasing => 'Starting purchase…';

  @override
  String get reportUnlockSheetRestoring => 'Restoring purchases…';

  @override
  String get reportUnlockRestoreButton => 'Restore Purchase';

  @override
  String get reportUnlockSheetStoreHint =>
      'Securely processed through the Apple App Store and supports restoring this non-consumable purchase.';

  @override
  String get reportUnlockStatusStoreUnavailable =>
      'The App Store is currently unavailable. Please try again when online.';

  @override
  String get reportUnlockStatusProductUnavailable =>
      'No purchasable product was found. Please check the product ID or try again later.';

  @override
  String get reportUnlockStatusPurchaseFailed =>
      'The purchase did not complete. Please try again later.';

  @override
  String get reportUnlockStatusPurchaseCancelled =>
      'You cancelled this purchase.';

  @override
  String get reportUnlockStatusRestoreNotFound =>
      'No restorable purchase was found for this Apple ID.';

  @override
  String get reportUnlockStatusPurchasing =>
      'Waiting for the App Store purchase result.';

  @override
  String get reportUnlockStatusRestoring =>
      'Restoring your purchase record from the App Store.';

  @override
  String get reportUnlockSheetMockHint =>
      'This is currently a local mock purchase flow and can be replaced with Apple IAP later.';

  @override
  String get reportUnlockCausalAnalysisTitle => 'Unlock Deep Causal Analysis';

  @override
  String get reportUnlockCausalAnalysisSubtitle => '查看体质成因与关键诱因。';

  @override
  String get reportUnlockDiseaseTendencyTitle =>
      'Unlock Disease Tendency Alerts';

  @override
  String get reportUnlockDiseaseTendencySubtitle => '查看易发问题与预警重点。';

  @override
  String get reportUnlockBadHabitsTitle => 'Unlock Harmful Habit Warnings';

  @override
  String get reportUnlockBadHabitsSubtitle => '查看需要调整的日常习惯。';

  @override
  String get reportUnlockAcupuncturePointsTitle =>
      'Unlock Personalized Acupoint Plan';

  @override
  String get reportUnlockAcupuncturePointsSubtitle => '查看专属穴位与调理重点。';

  @override
  String get reportUnlockMentalWellnessTitle =>
      'Unlock Mental Wellness Guidance';

  @override
  String get reportUnlockMentalWellnessSubtitle => '查看情绪调养与舒缓建议。';

  @override
  String get reportUnlockSeasonalCareTitle => 'Unlock Seasonal Wellness Plan';

  @override
  String reportSeasonalCareCurrentTitle(String solarTerm) {
    return 'Current solar term: $solarTerm';
  }

  @override
  String get reportSeasonalCareCurrentSubtitle =>
      'We’ve highlighted the current seasonal rhythm so you can start with the matching care guidance.';

  @override
  String get reportUnlockSeasonalCareSubtitle => '查看本季作息与养护重点。';

  @override
  String get reportUnlockTongueAnalysisTitle =>
      'Unlock Detailed Tongue Analysis';

  @override
  String get reportUnlockTongueAnalysisSubtitle => '查看舌象评分与细项解读。';

  @override
  String get reportUnlockDietAdviceTitle => 'Unlock Personalized Diet Plan';

  @override
  String get reportUnlockDietAdviceSubtitle => '查看适宜食材与饮食方向。';

  @override
  String get reportPremiumConstitutionSubtitle =>
      'View root causes, risk tendencies, and the full constitution analysis.';

  @override
  String get reportPremiumConstitutionPreview1 =>
      'Primary tendency: Qi Deficiency Constitution';

  @override
  String get reportPremiumConstitutionPreview2 =>
      'Unlock the full constitution and risk interpretation';

  @override
  String get reportPremiumTherapySubtitle =>
      'View recommended acupoints, mental wellness, and seasonal care guidance.';

  @override
  String get reportPremiumTherapyPreview1 =>
      'Recommended focus: Zusanli · Qihai';

  @override
  String get reportPremiumTherapyPreview2 =>
      'Unlock the full care path and action plan';

  @override
  String get reportPremiumAdviceSubtitle =>
      'View food therapy guidance, tongue analysis, and recommended products.';

  @override
  String get reportPremiumAdvicePreview1 =>
      'Diet focus: Strengthen the spleen and clear dampness';

  @override
  String get reportPremiumAdvicePreview2 =>
      'Unlock full diet, tongue, and product guidance';

  @override
  String get reportProductJianpiwan => 'Spleen-Strengthening Qi Pill';

  @override
  String get reportProductJianpiwanType => 'Chinese Patent Medicine';

  @override
  String get reportProductJianpiwanDesc =>
      'Tonifies middle qi, strengthens spleen, harmonizes stomach. Suitable for qi-deficiency constitutions with fatigue and poor appetite.';

  @override
  String get reportProductJianpiwanTag => 'Popular';

  @override
  String get reportProductShenling => 'Shenling Baizhu Powder';

  @override
  String get reportProductShenlingType => 'Traditional Formula';

  @override
  String get reportProductShenlingDesc =>
      'Strengthens spleen, supplements qi, drains dampness, and stops diarrhea. Commonly used for weak spleen qi with loose stools and fatigue.';

  @override
  String get reportProductShenlingTag => 'Classic';

  @override
  String get reportProductAijiu => 'Moxibustion Kit';

  @override
  String get reportProductAijiuType => 'Therapy Device';

  @override
  String get reportProductAijiuDesc =>
      'Mild moxa sticks with an acupoint guide for home moxibustion at Zusanli, Qihai, and Guanyuan.';

  @override
  String get reportProductAijiuTag => 'Recommended';

  @override
  String get reportProductFoodPack => 'TCM Food Therapy Pack';

  @override
  String get reportProductFoodPackType => 'Wellness Ingredients';

  @override
  String get reportProductFoodPackDesc =>
      'A selected weekly food-therapy set including yam, coix seeds, codonopsis, poria, and red dates.';

  @override
  String get reportProductFoodPackTag => 'New';

  @override
  String get reportWuxingWood => 'Wood';

  @override
  String get reportWuxingFire => 'Fire';

  @override
  String get reportWuxingEarth => 'Earth';

  @override
  String get reportWuxingMetal => 'Metal';

  @override
  String get reportWuxingWater => 'Water';

  @override
  String get reportAdviceProductDetailButton => 'View product >';

  @override
  String get metricFaceDiagnosis => 'Face';

  @override
  String get metricTongueDiagnosis => 'Tongue';

  @override
  String get metricPalmDiagnosis => 'Palm';

  @override
  String get scanGuideTitle => 'AI Inspection Entry';

  @override
  String get constitutionBalanced => 'Balanced';

  @override
  String get constitutionQiDeficiency => 'Qi Deficiency';

  @override
  String get constitutionDampness => 'Phlegm-Dampness';

  @override
  String get riskSpleenStomach => 'Spleen/Stomach';

  @override
  String get riskQiDeficiency => 'Qi Deficiency';

  @override
  String get riskDampness => 'Dampness';

  @override
  String daysAgo(int days) {
    return '$days days ago';
  }

  @override
  String scoreWithUnit(num score) {
    return '$score pts';
  }

  @override
  String percentValue(num value) {
    return '$value%';
  }

  @override
  String get reportConstitutionPhlegmDampness => 'Phlegm-Dampness Constitution';

  @override
  String get reportConstitutionInheritedSpecial => 'Special Constitution';

  @override
  String get reportConstitutionCausalTitle => 'Contributing Factors';

  @override
  String get reportConstitutionCauseRoutineTitle => 'Routine';

  @override
  String get reportConstitutionCauseRoutineDesc =>
      'Staying up late over time and remaining awake around midnight can deplete liver and kidney essence, leading to insufficient qi and blood generation.';

  @override
  String get reportConstitutionCauseDietTitle => 'Diet';

  @override
  String get reportConstitutionCauseDietDesc =>
      'A cold-leaning diet and excessive raw or chilled foods can injure spleen yang and reduce transport and transformation.';

  @override
  String get reportConstitutionCauseEmotionTitle => 'Emotions';

  @override
  String get reportConstitutionCauseEmotionDesc =>
      'Excessive rumination and worry can impair the spleen, constrain qi movement, and weaken transport and transformation.';

  @override
  String get reportConstitutionCauseExerciseTitle => 'Exercise';

  @override
  String get reportConstitutionCauseExerciseDesc =>
      'Prolonged sitting and too little movement can slow qi and blood circulation and gradually weaken middle qi.';

  @override
  String get reportConstitutionDiseaseTitle => 'Potential Health Risks';

  @override
  String get reportConstitutionDiseaseSpleenWeakTitle =>
      'Weak spleen and stomach';

  @override
  String get reportConstitutionDiseaseSpleenWeakDesc =>
      'Indigestion, bloating, loose stools';

  @override
  String get reportConstitutionDiseaseQiBloodTitle => 'Qi and blood deficiency';

  @override
  String get reportConstitutionDiseaseQiBloodDesc =>
      'Dizziness, fatigue, sallow complexion';

  @override
  String get reportConstitutionDiseaseLowImmunityTitle => 'Low immunity';

  @override
  String get reportConstitutionDiseaseLowImmunityDesc =>
      'Frequent colds, easy fatigue';

  @override
  String get reportConstitutionDiseaseEmotionTitle => 'Emotional disorders';

  @override
  String get reportConstitutionDiseaseEmotionDesc =>
      'Anxiety, insomnia, depressive tendency';

  @override
  String get reportConstitutionBadHabitsTitle => 'Habits to Avoid';

  @override
  String get reportConstitutionHabitOverworkTitle => 'Overwork';

  @override
  String get reportConstitutionHabitOverworkDesc =>
      'Consumes qi and burdens the spleen, worsening qi deficiency';

  @override
  String get reportConstitutionHabitColdFoodTitle => 'Excess cold foods';

  @override
  String get reportConstitutionHabitColdFoodDesc =>
      'Cold pathogens injure yang and weaken the spleen and stomach';

  @override
  String get reportConstitutionHabitLateSleepTitle => 'Late nights';

  @override
  String get reportConstitutionHabitLateSleepDesc =>
      'Prevents yin from being stored and depletes essence and qi';

  @override
  String get reportConstitutionHabitDietingTitle => 'Excessive dieting';

  @override
  String get reportConstitutionHabitDietingDesc =>
      'Leaves qi and blood without a source and further weakens middle qi';

  @override
  String get reportConstitutionHabitBingeTitle => 'Binge eating';

  @override
  String get reportConstitutionHabitBingeDesc =>
      'Overloads the spleen and stomach and impairs transport';

  @override
  String get reportTherapyAcupointTitle => 'Recommended Acupoints';

  @override
  String get reportTherapyAcupointIntro =>
      'For the spleen qi deficiency pattern, the following acupoints are recommended for moxibustion or massage, about 10–15 minutes daily.';

  @override
  String get reportTherapyPointZusanliName => 'Zusanli';

  @override
  String get reportTherapyPointZusanliLocation =>
      '3 cun below the outer knee eye, one finger-breadth lateral to the tibia';

  @override
  String get reportTherapyPointZusanliEffect =>
      'Strengthens spleen and stomach, replenishes qi and blood, and serves as a major strengthening point';

  @override
  String get reportTherapyPointZusanliMeridian =>
      'Stomach Meridian of Foot-Yangming';

  @override
  String get reportTherapyPointPishuName => 'Pishu';

  @override
  String get reportTherapyPointPishuLocation =>
      '1.5 cun lateral to the lower border of the spinous process of T11';

  @override
  String get reportTherapyPointPishuEffect =>
      'Strengthens the spleen, transforms dampness, replenishes qi, and supports spleen-stomach function';

  @override
  String get reportTherapyPointPishuMeridian =>
      'Bladder Meridian of Foot-Taiyang';

  @override
  String get reportTherapyPointQihaiName => 'Qihai';

  @override
  String get reportTherapyPointQihaiLocation =>
      '1.5 cun below the navel on the anterior midline';

  @override
  String get reportTherapyPointQihaiEffect =>
      'Tonifies original qi, warms yang, and relieves qi-deficiency fatigue';

  @override
  String get reportTherapyPointQihaiMeridian => 'Ren Meridian';

  @override
  String get reportTherapyPointGuanyuanName => 'Guanyuan';

  @override
  String get reportTherapyPointGuanyuanLocation =>
      '3 cun below the navel on the anterior midline';

  @override
  String get reportTherapyPointGuanyuanEffect =>
      'Nourishes the source, warms yang, boosts qi, and strengthens constitution';

  @override
  String get reportTherapyPointGuanyuanMeridian => 'Ren Meridian';

  @override
  String get reportTherapyAcupointWarning =>
      'Avoid moxibustion during pregnancy, on broken skin, and during menstruation. Watch the heat carefully to prevent burns.';

  @override
  String get reportTherapyMentalTitle => 'Mental Wellness';

  @override
  String get reportTherapyMentalCalmTitle => 'Stay calm and clear';

  @override
  String get reportTherapyMentalCalmDesc =>
      'Reduce excessive rumination and keep the mind settled. In TCM, overthinking is believed to harm the spleen and deplete spleen qi.';

  @override
  String get reportTherapyMentalNatureTitle => 'Live in Rhythm with Nature';

  @override
  String get reportTherapyMentalNatureDesc =>
      'Align rest with the day-night rhythm. Sleep before midnight to nourish liver qi, and stretch in the early morning to support rising yang.';

  @override
  String get reportTherapyMentalEmotionTitle => 'Regulate emotions';

  @override
  String get reportTherapyMentalEmotionDesc =>
      'Stay open and optimistic, avoid emotional extremes, and express feelings moderately to relieve constrained qi.';

  @override
  String get reportTherapyMentalMeditationTitle => 'Seated meditation';

  @override
  String get reportTherapyMentalMeditationDesc =>
      'Sit quietly for 10 minutes each day and focus on breathing to help regulate spleen-stomach qi and support upright qi.';

  @override
  String get reportTherapySeasonalTitle => 'Seasonal Care';

  @override
  String get reportTherapySeasonSpringName => 'Spring';

  @override
  String get reportTherapySeasonSpringAdvice =>
      'In spring, nourish the liver and moderately increase sour foods. Eat chives and spinach, stretch the body, and take early walks to support rising yang.';

  @override
  String get reportTherapySeasonSpringAvoid =>
      'Avoid excessive fatigue and overly pungent dispersing foods';

  @override
  String get reportTherapySeasonSummerName => 'Summer';

  @override
  String get reportTherapySeasonSummerAdvice =>
      'In summer, nourish the heart and clear heat. Have lotus seeds and coix seed in moderation, rest at noon, and avoid heavy sweating that consumes qi.';

  @override
  String get reportTherapySeasonSummerAvoid =>
      'Avoid excessive cold drinks and intense exercise with heavy sweating';

  @override
  String get reportTherapySeasonAutumnName => 'Autumn';

  @override
  String get reportTherapySeasonAutumnAdvice =>
      'In autumn, nourish the lungs with moistening foods. Eat pears, lily bulbs, and tremella, go to bed early and rise early, and preserve essence.';

  @override
  String get reportTherapySeasonAutumnAvoid =>
      'Avoid excessive grief and overly spicy, drying foods';

  @override
  String get reportTherapySeasonWinterName => 'Winter';

  @override
  String get reportTherapySeasonWinterAdvice =>
      'In winter, nourish the kidneys and focus on storage. Eat black sesame, walnuts, and lamb in moderation, sleep earlier, rise later, and protect kidney yang.';

  @override
  String get reportTherapySeasonWinterAvoid =>
      'Avoid overwork and excessive sweating that disperses yang qi';

  @override
  String get reportAdviceTongueFeatureColorLabel => 'Color';

  @override
  String get scanToggleCamera => 'Flip camera';

  @override
  String get reportAdviceTongueFeatureShapeLabel => 'Shape';

  @override
  String get reportAdviceTongueFeatureCoatingColorLabel => 'Coating color';

  @override
  String get reportAdviceTongueFeatureCoatingTextureLabel => 'Coating texture';

  @override
  String get reportAdviceTongueFeatureCoatingTextureValue => 'Thick and greasy';

  @override
  String get reportAdviceTongueFeatureCoatingTextureDesc =>
      'A thick, greasy coating suggests heavier dampness and poor spleen transport';

  @override
  String get reportAdviceTongueFeatureTeethMarksLabel => 'Tooth marks';

  @override
  String get reportAdviceDietRecommendedLabel => 'Recommended';

  @override
  String get reportAdviceDietFoodYamName => 'Chinese yam';

  @override
  String get reportAdviceDietFoodYamDesc =>
      'Strengthens spleen and kidneys, tonifies qi and nourishes yin';

  @override
  String get reportAdviceDietFoodCoixName => 'Coix seed';

  @override
  String get reportAdviceDietFoodCoixDesc =>
      'Promotes damp drainage, strengthens the spleen, and eases diarrhea';

  @override
  String get reportAdviceDietFoodJujubeName => 'Red dates';

  @override
  String get reportAdviceDietFoodJujubeDesc =>
      'Tonifies qi and blood, strengthens spleen and stomach, calms the mind';

  @override
  String get reportAdviceDietFoodLablabName => 'White hyacinth bean';

  @override
  String get reportAdviceDietFoodLablabDesc =>
      'Strengthens the spleen, transforms dampness, and relieves summer heat';

  @override
  String get reportAdviceDietFoodCodonopsisName => 'Codonopsis';

  @override
  String get reportAdviceDietFoodCodonopsisDesc =>
      'Tonifies middle qi and supports the spleen and stomach';

  @override
  String get reportAdviceDietFoodPoriaName => 'Poria';

  @override
  String get reportAdviceDietFoodPoriaDesc =>
      'Supports the spleen, harmonizes the middle, and drains dampness';

  @override
  String get reportAdviceDietAvoidLabel => 'Avoid';

  @override
  String get reportAdviceDietAvoidColdFoods => 'Cold and raw foods';

  @override
  String get reportAdviceDietAvoidGreasy => 'Greasy, heavy foods';

  @override
  String get reportAdviceDietAvoidSpicy => 'Spicy irritants';

  @override
  String get reportAdviceDietAvoidSweetRich => 'Overly sweet, rich foods';

  @override
  String get reportAdviceDietAvoidAlcoholTobacco => 'Alcohol and tobacco';

  @override
  String get reportAdviceProductTitle => 'Recommended Products';

  @override
  String get reportAdviceProductSubtitle =>
      'Personalized based on your constitution';

  @override
  String get reportAdviceProductOneName => 'Spleen-Qi Support Pills';

  @override
  String get reportAdviceProductOneType => 'Patent medicine';

  @override
  String get reportAdviceProductOneDesc =>
      'Tonifies middle qi, strengthens the spleen, and harmonizes the stomach. Suitable for qi-deficiency constitutions with fatigue and poor appetite.';

  @override
  String get reportAdviceProductOneTag => 'Popular';

  @override
  String get reportAdviceProductTwoName => 'Shenling Baizhu Powder';

  @override
  String get reportAdviceProductTwoType => 'Traditional formula';

  @override
  String get reportAdviceProductTwoDesc =>
      'Strengthens spleen qi, drains dampness, and stops diarrhea. Commonly used for weak spleen qi, poor appetite, loose stools, and fatigue.';

  @override
  String get reportAdviceProductTwoTag => 'Classic';

  @override
  String get reportAdviceProductThreeName => 'Moxibustion Kit';

  @override
  String get reportAdviceProductThreeType => 'Therapy tool';

  @override
  String get reportAdviceProductThreeDesc =>
      'Mild moxa sticks with an acupoint guide for home care on Zusanli, Qihai, and Guanyuan.';

  @override
  String get reportAdviceProductThreeTag => 'Recommended';

  @override
  String get reportAdviceProductFourName => 'TCM Food Therapy Pack';

  @override
  String get reportAdviceProductFourType => 'Wellness ingredients';

  @override
  String get reportAdviceProductFourDesc =>
      'A selected weekly set of Chinese yam, coix seed, codonopsis, poria, and red dates.';

  @override
  String get reportAdviceProductFourTag => 'New';

  @override
  String get reportAdviceProductDisclaimer =>
      'These product suggestions are based on the constitution analysis and are for reference only. Use patent medicines under the guidance of a physician or pharmacist.';

  @override
  String get scanFaceFrameRetryMessage =>
      'No face landmark image was generated. Please scan again.';

  @override
  String get scanFaceUploadFailedTitle => 'Face upload failed';

  @override
  String get scanTongueUploadFailedTitle => 'Tongue upload failed';
}
