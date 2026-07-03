import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'脉AI健康'**
  String get appTitle;

  /// No description provided for @appBrandPrefix.
  ///
  /// In zh, this message translates to:
  /// **'脉 '**
  String get appBrandPrefix;

  /// No description provided for @appBrandSuffix.
  ///
  /// In zh, this message translates to:
  /// **' 健康'**
  String get appBrandSuffix;

  /// No description provided for @seasonalSolarTermTag.
  ///
  /// In zh, this message translates to:
  /// **'{solarTerm} · {element}'**
  String seasonalSolarTermTag(String solarTerm, String element);

  /// No description provided for @solarTermMinorCold.
  ///
  /// In zh, this message translates to:
  /// **'小寒'**
  String get solarTermMinorCold;

  /// No description provided for @solarTermMajorCold.
  ///
  /// In zh, this message translates to:
  /// **'大寒'**
  String get solarTermMajorCold;

  /// No description provided for @solarTermStartOfSpring.
  ///
  /// In zh, this message translates to:
  /// **'立春'**
  String get solarTermStartOfSpring;

  /// No description provided for @solarTermRainWater.
  ///
  /// In zh, this message translates to:
  /// **'雨水'**
  String get solarTermRainWater;

  /// No description provided for @solarTermAwakeningOfInsects.
  ///
  /// In zh, this message translates to:
  /// **'惊蛰'**
  String get solarTermAwakeningOfInsects;

  /// No description provided for @solarTermSpringEquinox.
  ///
  /// In zh, this message translates to:
  /// **'春分'**
  String get solarTermSpringEquinox;

  /// No description provided for @solarTermClearAndBright.
  ///
  /// In zh, this message translates to:
  /// **'清明'**
  String get solarTermClearAndBright;

  /// No description provided for @solarTermGrainRain.
  ///
  /// In zh, this message translates to:
  /// **'谷雨'**
  String get solarTermGrainRain;

  /// No description provided for @solarTermStartOfSummer.
  ///
  /// In zh, this message translates to:
  /// **'立夏'**
  String get solarTermStartOfSummer;

  /// No description provided for @solarTermGrainFull.
  ///
  /// In zh, this message translates to:
  /// **'小满'**
  String get solarTermGrainFull;

  /// No description provided for @solarTermGrainInEar.
  ///
  /// In zh, this message translates to:
  /// **'芒种'**
  String get solarTermGrainInEar;

  /// No description provided for @solarTermSummerSolstice.
  ///
  /// In zh, this message translates to:
  /// **'夏至'**
  String get solarTermSummerSolstice;

  /// No description provided for @solarTermMinorHeat.
  ///
  /// In zh, this message translates to:
  /// **'小暑'**
  String get solarTermMinorHeat;

  /// No description provided for @solarTermMajorHeat.
  ///
  /// In zh, this message translates to:
  /// **'大暑'**
  String get solarTermMajorHeat;

  /// No description provided for @solarTermStartOfAutumn.
  ///
  /// In zh, this message translates to:
  /// **'立秋'**
  String get solarTermStartOfAutumn;

  /// No description provided for @solarTermEndOfHeat.
  ///
  /// In zh, this message translates to:
  /// **'处暑'**
  String get solarTermEndOfHeat;

  /// No description provided for @solarTermWhiteDew.
  ///
  /// In zh, this message translates to:
  /// **'白露'**
  String get solarTermWhiteDew;

  /// No description provided for @solarTermAutumnEquinox.
  ///
  /// In zh, this message translates to:
  /// **'秋分'**
  String get solarTermAutumnEquinox;

  /// No description provided for @solarTermColdDew.
  ///
  /// In zh, this message translates to:
  /// **'寒露'**
  String get solarTermColdDew;

  /// No description provided for @solarTermFrostDescent.
  ///
  /// In zh, this message translates to:
  /// **'霜降'**
  String get solarTermFrostDescent;

  /// No description provided for @solarTermStartOfWinter.
  ///
  /// In zh, this message translates to:
  /// **'立冬'**
  String get solarTermStartOfWinter;

  /// No description provided for @solarTermMinorSnow.
  ///
  /// In zh, this message translates to:
  /// **'小雪'**
  String get solarTermMinorSnow;

  /// No description provided for @solarTermMajorSnow.
  ///
  /// In zh, this message translates to:
  /// **'大雪'**
  String get solarTermMajorSnow;

  /// No description provided for @solarTermWinterSolstice.
  ///
  /// In zh, this message translates to:
  /// **'冬至'**
  String get solarTermWinterSolstice;

  /// No description provided for @authInspectionMotto.
  ///
  /// In zh, this message translates to:
  /// **'望 · 闻 · 问 · 切'**
  String get authInspectionMotto;

  /// No description provided for @authPhoneLogin.
  ///
  /// In zh, this message translates to:
  /// **'手机号登录'**
  String get authPhoneLogin;

  /// No description provided for @authEmailLogin.
  ///
  /// In zh, this message translates to:
  /// **'邮箱登录'**
  String get authEmailLogin;

  /// No description provided for @authPhoneLabel.
  ///
  /// In zh, this message translates to:
  /// **'手机号'**
  String get authPhoneLabel;

  /// No description provided for @authPhoneHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入手机号'**
  String get authPhoneHint;

  /// No description provided for @authPhoneFormatError.
  ///
  /// In zh, this message translates to:
  /// **'请输入正确的手机号'**
  String get authPhoneFormatError;

  /// No description provided for @authEmailLabel.
  ///
  /// In zh, this message translates to:
  /// **'邮箱'**
  String get authEmailLabel;

  /// No description provided for @authEmailHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入邮箱'**
  String get authEmailHint;

  /// No description provided for @authEmailFormatError.
  ///
  /// In zh, this message translates to:
  /// **'请输入正确的邮箱'**
  String get authEmailFormatError;

  /// No description provided for @authNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'昵称'**
  String get authNameLabel;

  /// No description provided for @authNameHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入你的昵称'**
  String get authNameHint;

  /// No description provided for @authPasswordLabel.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入密码'**
  String get authPasswordHint;

  /// No description provided for @authPasswordMin6.
  ///
  /// In zh, this message translates to:
  /// **'密码不能少于6位'**
  String get authPasswordMin6;

  /// No description provided for @authPasswordMin8.
  ///
  /// In zh, this message translates to:
  /// **'密码不少于8位'**
  String get authPasswordMin8;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In zh, this message translates to:
  /// **'确认密码'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authConfirmPasswordHint.
  ///
  /// In zh, this message translates to:
  /// **'再次输入密码'**
  String get authConfirmPasswordHint;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In zh, this message translates to:
  /// **'两次密码不一致'**
  String get authPasswordMismatch;

  /// No description provided for @authForgotPassword.
  ///
  /// In zh, this message translates to:
  /// **'忘记密码？'**
  String get authForgotPassword;

  /// No description provided for @authLoginButton.
  ///
  /// In zh, this message translates to:
  /// **'登录账号'**
  String get authLoginButton;

  /// No description provided for @authLoginFailed.
  ///
  /// In zh, this message translates to:
  /// **'登录失败，请稍后重试'**
  String get authLoginFailed;

  /// No description provided for @authOtherMethods.
  ///
  /// In zh, this message translates to:
  /// **'其他方式'**
  String get authOtherMethods;

  /// No description provided for @authWechatLogin.
  ///
  /// In zh, this message translates to:
  /// **'微信小程序登录'**
  String get authWechatLogin;

  /// No description provided for @authAppleLogin.
  ///
  /// In zh, this message translates to:
  /// **'Apple 登录'**
  String get authAppleLogin;

  /// No description provided for @authVerificationCodeLabel.
  ///
  /// In zh, this message translates to:
  /// **'验证码'**
  String get authVerificationCodeLabel;

  /// No description provided for @authVerificationCodeHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入验证码'**
  String get authVerificationCodeHint;

  /// No description provided for @authSendCode.
  ///
  /// In zh, this message translates to:
  /// **'发送验证码'**
  String get authSendCode;

  /// No description provided for @authResendCode.
  ///
  /// In zh, this message translates to:
  /// **'{seconds}s 后重发'**
  String authResendCode(int seconds);

  /// No description provided for @authPasswordLogin.
  ///
  /// In zh, this message translates to:
  /// **'密码登录'**
  String get authPasswordLogin;

  /// No description provided for @authCodeLogin.
  ///
  /// In zh, this message translates to:
  /// **'验证码登录'**
  String get authCodeLogin;

  /// No description provided for @authLoggingIn.
  ///
  /// In zh, this message translates to:
  /// **'登录中…'**
  String get authLoggingIn;

  /// No description provided for @authSendCodeFailed.
  ///
  /// In zh, this message translates to:
  /// **'验证码发送失败，请稍后重试'**
  String get authSendCodeFailed;

  /// No description provided for @authCodeSent.
  ///
  /// In zh, this message translates to:
  /// **'验证码已发送，请注意查收'**
  String get authCodeSent;

  /// No description provided for @authCodeSentToReceiver.
  ///
  /// In zh, this message translates to:
  /// **'验证码已发送至 {receiver}'**
  String authCodeSentToReceiver(String receiver);

  /// No description provided for @authWechatUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'微信授权环境未接入，请先实现 acquireWechatCode()。'**
  String get authWechatUnsupported;

  /// No description provided for @authWechatCodeMissing.
  ///
  /// In zh, this message translates to:
  /// **'未获取到微信授权码，请重试。'**
  String get authWechatCodeMissing;

  /// No description provided for @authWechatCompletedWithoutToken.
  ///
  /// In zh, this message translates to:
  /// **'微信授权已完成，但当前未返回登录令牌。'**
  String get authWechatCompletedWithoutToken;

  /// No description provided for @authWechatStatusPendingBinding.
  ///
  /// In zh, this message translates to:
  /// **'微信授权返回状态：{status}，后续绑定流程待接入。'**
  String authWechatStatusPendingBinding(String status);

  /// No description provided for @authSendCodeFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先获取验证码'**
  String get authSendCodeFirst;

  /// No description provided for @commonContinue.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get commonContinue;

  /// No description provided for @authCaptchaTitle.
  ///
  /// In zh, this message translates to:
  /// **'人机验证'**
  String get authCaptchaTitle;

  /// No description provided for @authCaptchaManualPrompt.
  ///
  /// In zh, this message translates to:
  /// **'需要先完成 {provider} 验证。请粘贴 provider 返回的 JSON 结果后继续。'**
  String authCaptchaManualPrompt(String provider);

  /// No description provided for @authCaptchaInitPayloadLabel.
  ///
  /// In zh, this message translates to:
  /// **'初始化参数'**
  String get authCaptchaInitPayloadLabel;

  /// No description provided for @authCaptchaResultJsonLabel.
  ///
  /// In zh, this message translates to:
  /// **'验证结果 JSON'**
  String get authCaptchaResultJsonLabel;

  /// No description provided for @authCaptchaManualResultHint.
  ///
  /// In zh, this message translates to:
  /// **'例如：ticket=ticket-001'**
  String get authCaptchaManualResultHint;

  /// No description provided for @authCaptchaInvalidJson.
  ///
  /// In zh, this message translates to:
  /// **'请输入合法的 JSON 对象'**
  String get authCaptchaInvalidJson;

  /// No description provided for @authCaptchaFailed.
  ///
  /// In zh, this message translates to:
  /// **'人机验证未通过，请重试'**
  String get authCaptchaFailed;

  /// No description provided for @authCaptchaLoadingPage.
  ///
  /// In zh, this message translates to:
  /// **'正在加载验证码页面...'**
  String get authCaptchaLoadingPage;

  /// No description provided for @authCaptchaReady.
  ///
  /// In zh, this message translates to:
  /// **'验证码组件已就绪，请完成人机验证'**
  String get authCaptchaReady;

  /// No description provided for @authCaptchaPageLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'验证码页面加载失败，请关闭后重试'**
  String get authCaptchaPageLoadFailed;

  /// No description provided for @authCaptchaInitFailed.
  ///
  /// In zh, this message translates to:
  /// **'验证码初始化失败，请关闭后重试'**
  String get authCaptchaInitFailed;

  /// No description provided for @authCaptchaRequiredUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'当前环境暂不支持人机验证，请稍后再试'**
  String get authCaptchaRequiredUnsupported;

  /// No description provided for @authForgotPasswordTip.
  ///
  /// In zh, this message translates to:
  /// **'请通过注册手机号重置密码，或联系客服处理'**
  String get authForgotPasswordTip;

  /// No description provided for @commonConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get commonConfirm;

  /// No description provided for @authNoAccount.
  ///
  /// In zh, this message translates to:
  /// **'还没有账号？'**
  String get authNoAccount;

  /// No description provided for @authRegisterNow.
  ///
  /// In zh, this message translates to:
  /// **'立即注册'**
  String get authRegisterNow;

  /// No description provided for @registerGoLogin.
  ///
  /// In zh, this message translates to:
  /// **'去登录'**
  String get registerGoLogin;

  /// No description provided for @registerCreateAccountTitle.
  ///
  /// In zh, this message translates to:
  /// **'创建你的账号'**
  String get registerCreateAccountTitle;

  /// No description provided for @registerCreateAccountSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'通过手机号与验证码创建账号，快速开始体验'**
  String get registerCreateAccountSubtitle;

  /// No description provided for @registerCreateAccountAction.
  ///
  /// In zh, this message translates to:
  /// **'创建账号'**
  String get registerCreateAccountAction;

  /// No description provided for @registerCreateFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建账号失败，请稍后重试'**
  String get registerCreateFailed;

  /// No description provided for @registerPasswordSetupPrompt.
  ///
  /// In zh, this message translates to:
  /// **'注册成功，可在“我的 - 设置 - 账号与安全”中设置登录密码'**
  String get registerPasswordSetupPrompt;

  /// No description provided for @registerPhoneMode.
  ///
  /// In zh, this message translates to:
  /// **'手机注册'**
  String get registerPhoneMode;

  /// No description provided for @registerEmailMode.
  ///
  /// In zh, this message translates to:
  /// **'邮箱注册'**
  String get registerEmailMode;

  /// No description provided for @registerAlreadyHaveAccount.
  ///
  /// In zh, this message translates to:
  /// **'已有账号？'**
  String get registerAlreadyHaveAccount;

  /// No description provided for @registerLoginNow.
  ///
  /// In zh, this message translates to:
  /// **'立即登录'**
  String get registerLoginNow;

  /// No description provided for @registerGenderOptional.
  ///
  /// In zh, this message translates to:
  /// **'性别'**
  String get registerGenderOptional;

  /// No description provided for @registerGenderRequired.
  ///
  /// In zh, this message translates to:
  /// **'请选择性别'**
  String get registerGenderRequired;

  /// No description provided for @completeProfileTitle.
  ///
  /// In zh, this message translates to:
  /// **'完善资料'**
  String get completeProfileTitle;

  /// No description provided for @completeProfileSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'补充头像、昵称和性别，以便后续理疗建议更贴合你。'**
  String get completeProfileSubtitle;

  /// No description provided for @completeProfileSkip.
  ///
  /// In zh, this message translates to:
  /// **'跳过'**
  String get completeProfileSkip;

  /// No description provided for @completeProfileStart.
  ///
  /// In zh, this message translates to:
  /// **'开启体验'**
  String get completeProfileStart;

  /// No description provided for @registerGenderMale.
  ///
  /// In zh, this message translates to:
  /// **'男'**
  String get registerGenderMale;

  /// No description provided for @registerGenderFemale.
  ///
  /// In zh, this message translates to:
  /// **'女'**
  String get registerGenderFemale;

  /// No description provided for @registerGenderOther.
  ///
  /// In zh, this message translates to:
  /// **'不透露'**
  String get registerGenderOther;

  /// No description provided for @registerPasswordHint.
  ///
  /// In zh, this message translates to:
  /// **'至少8位，包含字母和数字'**
  String get registerPasswordHint;

  /// No description provided for @registerAgreeTermsFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先同意用户协议和隐私政策'**
  String get registerAgreeTermsFirst;

  /// No description provided for @registerReadAndAgree.
  ///
  /// In zh, this message translates to:
  /// **'我已阅读并同意'**
  String get registerReadAndAgree;

  /// No description provided for @registerUserAgreement.
  ///
  /// In zh, this message translates to:
  /// **'《用户协议》'**
  String get registerUserAgreement;

  /// No description provided for @registerAnd.
  ///
  /// In zh, this message translates to:
  /// **'和'**
  String get registerAnd;

  /// No description provided for @registerPrivacyPolicy.
  ///
  /// In zh, this message translates to:
  /// **'《隐私政策》'**
  String get registerPrivacyPolicy;

  /// No description provided for @registerHealthDataClause.
  ///
  /// In zh, this message translates to:
  /// **'，包括健康数据的收集与使用说明'**
  String get registerHealthDataClause;

  /// No description provided for @registerPrivacyTip.
  ///
  /// In zh, this message translates to:
  /// **'你的健康数据仅用于 AI 诊断分析，经过加密存储，不会用于商业用途或分享给第三方。'**
  String get registerPrivacyTip;

  /// No description provided for @passwordStrengthWeak.
  ///
  /// In zh, this message translates to:
  /// **'弱'**
  String get passwordStrengthWeak;

  /// No description provided for @passwordStrengthMedium.
  ///
  /// In zh, this message translates to:
  /// **'中'**
  String get passwordStrengthMedium;

  /// No description provided for @passwordStrengthStrong.
  ///
  /// In zh, this message translates to:
  /// **'强'**
  String get passwordStrengthStrong;

  /// No description provided for @passwordStrengthVeryStrong.
  ///
  /// In zh, this message translates to:
  /// **'非常强'**
  String get passwordStrengthVeryStrong;

  /// No description provided for @bottomNavHome.
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get bottomNavHome;

  /// No description provided for @bottomNavScan.
  ///
  /// In zh, this message translates to:
  /// **'扫描'**
  String get bottomNavScan;

  /// No description provided for @bottomNavReport.
  ///
  /// In zh, this message translates to:
  /// **'报告'**
  String get bottomNavReport;

  /// No description provided for @bottomNavProfile.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get bottomNavProfile;

  /// No description provided for @commonCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get commonSave;

  /// No description provided for @commonRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get commonRetry;

  /// No description provided for @commonLoading.
  ///
  /// In zh, this message translates to:
  /// **'加载中'**
  String get commonLoading;

  /// No description provided for @commonViewAll.
  ///
  /// In zh, this message translates to:
  /// **'查看全部'**
  String get commonViewAll;

  /// No description provided for @commonFeatureInDevelopment.
  ///
  /// In zh, this message translates to:
  /// **'功能开发中'**
  String get commonFeatureInDevelopment;

  /// No description provided for @commonPleaseEnterName.
  ///
  /// In zh, this message translates to:
  /// **'请输入姓名'**
  String get commonPleaseEnterName;

  /// No description provided for @unitTimes.
  ///
  /// In zh, this message translates to:
  /// **'次'**
  String get unitTimes;

  /// No description provided for @unitPoints.
  ///
  /// In zh, this message translates to:
  /// **'分'**
  String get unitPoints;

  /// No description provided for @unitStage.
  ///
  /// In zh, this message translates to:
  /// **'阶段'**
  String get unitStage;

  /// No description provided for @statusUnlocked.
  ///
  /// In zh, this message translates to:
  /// **'已解锁'**
  String get statusUnlocked;

  /// No description provided for @statusLocked.
  ///
  /// In zh, this message translates to:
  /// **'未解锁'**
  String get statusLocked;

  /// No description provided for @actionUnlockNow.
  ///
  /// In zh, this message translates to:
  /// **'立即解锁'**
  String get actionUnlockNow;

  /// No description provided for @historyReportTitle.
  ///
  /// In zh, this message translates to:
  /// **'体质测评报告'**
  String get historyReportTitle;

  /// No description provided for @historyPastReports.
  ///
  /// In zh, this message translates to:
  /// **'过往报告'**
  String get historyPastReports;

  /// No description provided for @historyHealthTrend.
  ///
  /// In zh, this message translates to:
  /// **'健康走势'**
  String get historyHealthTrend;

  /// No description provided for @historyHealthIndex.
  ///
  /// In zh, this message translates to:
  /// **'健康指数'**
  String get historyHealthIndex;

  /// No description provided for @historyRiskTrend.
  ///
  /// In zh, this message translates to:
  /// **'风险指数走势'**
  String get historyRiskTrend;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In zh, this message translates to:
  /// **'早安，{name}'**
  String homeGreetingMorning(String name);

  /// No description provided for @homeGreetingQuestion.
  ///
  /// In zh, this message translates to:
  /// **'今日气色如何？'**
  String get homeGreetingQuestion;

  /// No description provided for @homeStatusSummary.
  ///
  /// In zh, this message translates to:
  /// **'{constitution} · 上次检测 {days}天前'**
  String homeStatusSummary(String constitution, int days);

  /// No description provided for @homeSuggestion.
  ///
  /// In zh, this message translates to:
  /// **'建议：多喝水，保持规律作息'**
  String get homeSuggestion;

  /// No description provided for @homeQuickScanTitle.
  ///
  /// In zh, this message translates to:
  /// **'AI 望诊入口'**
  String get homeQuickScanTitle;

  /// No description provided for @homeQuickScanTag.
  ///
  /// In zh, this message translates to:
  /// **'望·闻·问·切'**
  String get homeQuickScanTag;

  /// No description provided for @homeQuickScanFaceTitle.
  ///
  /// In zh, this message translates to:
  /// **'面部望诊'**
  String get homeQuickScanFaceTitle;

  /// No description provided for @homeQuickScanFaceSub.
  ///
  /// In zh, this message translates to:
  /// **'观气色'**
  String get homeQuickScanFaceSub;

  /// No description provided for @homeQuickScanTongueTitle.
  ///
  /// In zh, this message translates to:
  /// **'舌象诊断'**
  String get homeQuickScanTongueTitle;

  /// No description provided for @homeQuickScanTongueSub.
  ///
  /// In zh, this message translates to:
  /// **'察舌苔'**
  String get homeQuickScanTongueSub;

  /// No description provided for @homeQuickScanPalmTitle.
  ///
  /// In zh, this message translates to:
  /// **'手掌经络'**
  String get homeQuickScanPalmTitle;

  /// No description provided for @homeQuickScanPalmSub.
  ///
  /// In zh, this message translates to:
  /// **'看掌纹'**
  String get homeQuickScanPalmSub;

  /// No description provided for @homeFunctionNavTitle.
  ///
  /// In zh, this message translates to:
  /// **'功能导航'**
  String get homeFunctionNavTitle;

  /// No description provided for @homeFunctionConstitution.
  ///
  /// In zh, this message translates to:
  /// **'体质分析'**
  String get homeFunctionConstitution;

  /// No description provided for @homeFunctionMeridianTherapy.
  ///
  /// In zh, this message translates to:
  /// **'经络调理'**
  String get homeFunctionMeridianTherapy;

  /// No description provided for @homeFunctionDietAdvice.
  ///
  /// In zh, this message translates to:
  /// **'饮食建议'**
  String get homeFunctionDietAdvice;

  /// No description provided for @homeFunctionMentalWellness.
  ///
  /// In zh, this message translates to:
  /// **'精神养生'**
  String get homeFunctionMentalWellness;

  /// No description provided for @homeFunctionSeasonalCare.
  ///
  /// In zh, this message translates to:
  /// **'四季保养'**
  String get homeFunctionSeasonalCare;

  /// No description provided for @homeFunctionHistory.
  ///
  /// In zh, this message translates to:
  /// **'历史记录'**
  String get homeFunctionHistory;

  /// No description provided for @homeTodayCareTitle.
  ///
  /// In zh, this message translates to:
  /// **'今日养生'**
  String get homeTodayCareTitle;

  /// No description provided for @homeTodayCareCount.
  ///
  /// In zh, this message translates to:
  /// **'两则建议'**
  String get homeTodayCareCount;

  /// No description provided for @homeTipDietTag.
  ///
  /// In zh, this message translates to:
  /// **'饮食'**
  String get homeTipDietTag;

  /// No description provided for @homeTipDietWuxing.
  ///
  /// In zh, this message translates to:
  /// **'土'**
  String get homeTipDietWuxing;

  /// No description provided for @homeTipDietBody.
  ///
  /// In zh, this message translates to:
  /// **'今日节气宜食清淡，山药、百合有助于润肺健脾，适合气虚体质人群。'**
  String get homeTipDietBody;

  /// No description provided for @homeTipRoutineTag.
  ///
  /// In zh, this message translates to:
  /// **'起居'**
  String get homeTipRoutineTag;

  /// No description provided for @homeTipRoutineWuxing.
  ///
  /// In zh, this message translates to:
  /// **'水'**
  String get homeTipRoutineWuxing;

  /// No description provided for @homeTipRoutineBody.
  ///
  /// In zh, this message translates to:
  /// **'子时（23:00 前）入睡有助于肝胆排毒，建议减少夜间屏幕使用时间。'**
  String get homeTipRoutineBody;

  /// No description provided for @homeCollapsedTitle.
  ///
  /// In zh, this message translates to:
  /// **'脉 AI 健康'**
  String get homeCollapsedTitle;

  /// No description provided for @homeHealthScoreLabel.
  ///
  /// In zh, this message translates to:
  /// **'健康分'**
  String get homeHealthScoreLabel;

  /// No description provided for @homeBalancedConstitution.
  ///
  /// In zh, this message translates to:
  /// **'平和体质'**
  String get homeBalancedConstitution;

  /// No description provided for @homeBalanceState.
  ///
  /// In zh, this message translates to:
  /// **'阴阳较平衡'**
  String get homeBalanceState;

  /// No description provided for @homeStartFullScan.
  ///
  /// In zh, this message translates to:
  /// **'开始全套智能检测'**
  String get homeStartFullScan;

  /// No description provided for @homeLastReportInsight.
  ///
  /// In zh, this message translates to:
  /// **'气虚偏颇 · 脾胃虚弱'**
  String get homeLastReportInsight;

  /// No description provided for @homeLastReportSummary.
  ///
  /// In zh, this message translates to:
  /// **'脾气亏虚，运化失健。面色偏黄，舌淡苔白，建议健脾益气，规律作息。'**
  String get homeLastReportSummary;

  /// No description provided for @profileTitle.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get profileTitle;

  /// No description provided for @profileBadgeBalanced.
  ///
  /// In zh, this message translates to:
  /// **'平和质'**
  String get profileBadgeBalanced;

  /// No description provided for @profileDisplayName.
  ///
  /// In zh, this message translates to:
  /// **'小明'**
  String get profileDisplayName;

  /// No description provided for @profileStatusStable.
  ///
  /// In zh, this message translates to:
  /// **'今日状态平稳，宜守中养气'**
  String get profileStatusStable;

  /// No description provided for @profileBalancedType.
  ///
  /// In zh, this message translates to:
  /// **'平和体质'**
  String get profileBalancedType;

  /// No description provided for @profileMetricConsultCount.
  ///
  /// In zh, this message translates to:
  /// **'累计问诊'**
  String get profileMetricConsultCount;

  /// No description provided for @profileMetricHealthScore.
  ///
  /// In zh, this message translates to:
  /// **'当前健康力'**
  String get profileMetricHealthScore;

  /// No description provided for @profileMetricConstitutionStages.
  ///
  /// In zh, this message translates to:
  /// **'体质演变'**
  String get profileMetricConstitutionStages;

  /// No description provided for @profileSectionFoundation.
  ///
  /// In zh, this message translates to:
  /// **'健康基底'**
  String get profileSectionFoundation;

  /// No description provided for @profileHeight.
  ///
  /// In zh, this message translates to:
  /// **'身高'**
  String get profileHeight;

  /// No description provided for @profileWeight.
  ///
  /// In zh, this message translates to:
  /// **'体重'**
  String get profileWeight;

  /// No description provided for @profileInnateBase.
  ///
  /// In zh, this message translates to:
  /// **'先天底色'**
  String get profileInnateBase;

  /// No description provided for @profileInnateBaseValue.
  ///
  /// In zh, this message translates to:
  /// **'脾胃偏虚家族倾向'**
  String get profileInnateBaseValue;

  /// No description provided for @profileInnateBaseNote.
  ///
  /// In zh, this message translates to:
  /// **'父母均有脾胃虚弱史，先天底子偏向中气不足。'**
  String get profileInnateBaseNote;

  /// No description provided for @profileCurrentBias.
  ///
  /// In zh, this message translates to:
  /// **'当前偏颇'**
  String get profileCurrentBias;

  /// No description provided for @profileCurrentBiasValue.
  ///
  /// In zh, this message translates to:
  /// **'气虚夹湿'**
  String get profileCurrentBiasValue;

  /// No description provided for @profileCurrentBiasNote.
  ///
  /// In zh, this message translates to:
  /// **'近阶段偏颇主要集中在气虚与湿困，易受作息与饮食影响。'**
  String get profileCurrentBiasNote;

  /// No description provided for @profileHealthScore30Days.
  ///
  /// In zh, this message translates to:
  /// **'近30天健康分'**
  String get profileHealthScore30Days;

  /// No description provided for @profileHealthScoreTrendNote.
  ///
  /// In zh, this message translates to:
  /// **'整体平稳，最近一周轻度波动。'**
  String get profileHealthScoreTrendNote;

  /// No description provided for @profileSectionCabin.
  ///
  /// In zh, this message translates to:
  /// **'我的调理舱'**
  String get profileSectionCabin;

  /// No description provided for @profileCabinAcupoints.
  ///
  /// In zh, this message translates to:
  /// **'收藏穴位'**
  String get profileCabinAcupoints;

  /// No description provided for @profileCabinAcupointsValue.
  ///
  /// In zh, this message translates to:
  /// **'足三里 · 气海 · 关元'**
  String get profileCabinAcupointsValue;

  /// No description provided for @profileCabinDiet.
  ///
  /// In zh, this message translates to:
  /// **'专属食疗方'**
  String get profileCabinDiet;

  /// No description provided for @profileCabinDietValue.
  ///
  /// In zh, this message translates to:
  /// **'山药薏仁粥 · 党参茯苓炖鸡'**
  String get profileCabinDietValue;

  /// No description provided for @profileCabinFollowup.
  ///
  /// In zh, this message translates to:
  /// **'复诊提醒'**
  String get profileCabinFollowup;

  /// No description provided for @profileCabinFollowupValue.
  ///
  /// In zh, this message translates to:
  /// **'距下次调理评估还有 3 天'**
  String get profileCabinFollowupValue;

  /// No description provided for @profileSectionServices.
  ///
  /// In zh, this message translates to:
  /// **'健康服务'**
  String get profileSectionServices;

  /// No description provided for @profileMenuAccount.
  ///
  /// In zh, this message translates to:
  /// **'账户与家人档案'**
  String get profileMenuAccount;

  /// No description provided for @profileMenuAccountSub.
  ///
  /// In zh, this message translates to:
  /// **'个人资料、家人信息与健康档案'**
  String get profileMenuAccountSub;

  /// No description provided for @profileMenuShippingAddress.
  ///
  /// In zh, this message translates to:
  /// **'收货地址'**
  String get profileMenuShippingAddress;

  /// No description provided for @profileMenuShippingAddressSub.
  ///
  /// In zh, this message translates to:
  /// **'新增、编辑和管理收货地址'**
  String get profileMenuShippingAddressSub;

  /// No description provided for @profileMenuPoints.
  ///
  /// In zh, this message translates to:
  /// **'积分中心'**
  String get profileMenuPoints;

  /// No description provided for @profileMenuPointsSub.
  ///
  /// In zh, this message translates to:
  /// **'签到领积分，查看积分明细'**
  String get profileMenuPointsSub;

  /// No description provided for @profileMenuSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get profileMenuSettings;

  /// No description provided for @profileMenuSettingsSub.
  ///
  /// In zh, this message translates to:
  /// **'账号与安全、登录方式和通用偏好'**
  String get profileMenuSettingsSub;

  /// No description provided for @profileMenuReminder.
  ///
  /// In zh, this message translates to:
  /// **'健康节气提醒'**
  String get profileMenuReminder;

  /// No description provided for @profileMenuReminderSub.
  ///
  /// In zh, this message translates to:
  /// **'通知、作息与节气养护建议'**
  String get profileMenuReminderSub;

  /// No description provided for @profileMenuAdvisor.
  ///
  /// In zh, this message translates to:
  /// **'联系专属健康顾问'**
  String get profileMenuAdvisor;

  /// No description provided for @profileMenuAdvisorSub.
  ///
  /// In zh, this message translates to:
  /// **'调理疑问、复诊沟通与健康咨询'**
  String get profileMenuAdvisorSub;

  /// No description provided for @profileMenuLanguage.
  ///
  /// In zh, this message translates to:
  /// **'语言设置'**
  String get profileMenuLanguage;

  /// No description provided for @profileMenuLanguageSub.
  ///
  /// In zh, this message translates to:
  /// **'切换应用显示语言'**
  String get profileMenuLanguageSub;

  /// No description provided for @profileMenuAbout.
  ///
  /// In zh, this message translates to:
  /// **'关于脉 AI'**
  String get profileMenuAbout;

  /// No description provided for @profileMenuAboutSub.
  ///
  /// In zh, this message translates to:
  /// **'了解服务说明与当前版本 v1.0.0'**
  String get profileMenuAboutSub;

  /// No description provided for @profileAddressTitle.
  ///
  /// In zh, this message translates to:
  /// **'收货地址'**
  String get profileAddressTitle;

  /// No description provided for @profileAddressAdd.
  ///
  /// In zh, this message translates to:
  /// **'新增地址'**
  String get profileAddressAdd;

  /// No description provided for @profileAddressEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'还没有收货地址'**
  String get profileAddressEmptyTitle;

  /// No description provided for @profileAddressEmptyBody.
  ///
  /// In zh, this message translates to:
  /// **'添加常用收货地址后，下单时可以更快填写收货信息。'**
  String get profileAddressEmptyBody;

  /// No description provided for @profileAddressReceiver.
  ///
  /// In zh, this message translates to:
  /// **'收货人'**
  String get profileAddressReceiver;

  /// No description provided for @profileAddressPhone.
  ///
  /// In zh, this message translates to:
  /// **'手机号'**
  String get profileAddressPhone;

  /// No description provided for @profileAddressProvinceName.
  ///
  /// In zh, this message translates to:
  /// **'省份名称'**
  String get profileAddressProvinceName;

  /// No description provided for @profileAddressProvinceCode.
  ///
  /// In zh, this message translates to:
  /// **'省份编码'**
  String get profileAddressProvinceCode;

  /// No description provided for @profileAddressCityName.
  ///
  /// In zh, this message translates to:
  /// **'城市名称'**
  String get profileAddressCityName;

  /// No description provided for @profileAddressCityCode.
  ///
  /// In zh, this message translates to:
  /// **'城市编码'**
  String get profileAddressCityCode;

  /// No description provided for @profileAddressDistrictName.
  ///
  /// In zh, this message translates to:
  /// **'区县名称'**
  String get profileAddressDistrictName;

  /// No description provided for @profileAddressDistrictCode.
  ///
  /// In zh, this message translates to:
  /// **'区县编码'**
  String get profileAddressDistrictCode;

  /// No description provided for @profileAddressStreetName.
  ///
  /// In zh, this message translates to:
  /// **'街道名称'**
  String get profileAddressStreetName;

  /// No description provided for @profileAddressStreetCode.
  ///
  /// In zh, this message translates to:
  /// **'街道编码'**
  String get profileAddressStreetCode;

  /// No description provided for @profileAddressRegion.
  ///
  /// In zh, this message translates to:
  /// **'所在地区'**
  String get profileAddressRegion;

  /// No description provided for @profileAddressDetail.
  ///
  /// In zh, this message translates to:
  /// **'详细地址'**
  String get profileAddressDetail;

  /// No description provided for @profileAddressTag.
  ///
  /// In zh, this message translates to:
  /// **'地址标签'**
  String get profileAddressTag;

  /// No description provided for @profileAddressSetDefault.
  ///
  /// In zh, this message translates to:
  /// **'设为默认'**
  String get profileAddressSetDefault;

  /// No description provided for @profileAddressDefault.
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get profileAddressDefault;

  /// No description provided for @profileAddressEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get profileAddressEdit;

  /// No description provided for @profileAddressDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get profileAddressDelete;

  /// No description provided for @profileAddressDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除收货地址'**
  String get profileAddressDeleteTitle;

  /// No description provided for @profileAddressDeleteBody.
  ///
  /// In zh, this message translates to:
  /// **'删除后将无法恢复，是否继续？'**
  String get profileAddressDeleteBody;

  /// No description provided for @profileAddressDeleteAction.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get profileAddressDeleteAction;

  /// No description provided for @profileAddressFormAddTitle.
  ///
  /// In zh, this message translates to:
  /// **'新增收货地址'**
  String get profileAddressFormAddTitle;

  /// No description provided for @profileAddressFormEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑收货地址'**
  String get profileAddressFormEditTitle;

  /// No description provided for @profileAddressValidationReceiver.
  ///
  /// In zh, this message translates to:
  /// **'请输入收货人姓名'**
  String get profileAddressValidationReceiver;

  /// No description provided for @profileAddressValidationPhone.
  ///
  /// In zh, this message translates to:
  /// **'请输入正确的手机号'**
  String get profileAddressValidationPhone;

  /// No description provided for @profileAddressValidationProvinceName.
  ///
  /// In zh, this message translates to:
  /// **'请输入省份名称'**
  String get profileAddressValidationProvinceName;

  /// No description provided for @profileAddressValidationProvinceCode.
  ///
  /// In zh, this message translates to:
  /// **'请输入省份编码'**
  String get profileAddressValidationProvinceCode;

  /// No description provided for @profileAddressValidationCityName.
  ///
  /// In zh, this message translates to:
  /// **'请输入城市名称'**
  String get profileAddressValidationCityName;

  /// No description provided for @profileAddressValidationCityCode.
  ///
  /// In zh, this message translates to:
  /// **'请输入城市编码'**
  String get profileAddressValidationCityCode;

  /// No description provided for @profileAddressValidationDistrictName.
  ///
  /// In zh, this message translates to:
  /// **'请输入区县名称'**
  String get profileAddressValidationDistrictName;

  /// No description provided for @profileAddressValidationDistrictCode.
  ///
  /// In zh, this message translates to:
  /// **'请输入区县编码'**
  String get profileAddressValidationDistrictCode;

  /// No description provided for @profileAddressValidationRegion.
  ///
  /// In zh, this message translates to:
  /// **'请输入所在地区'**
  String get profileAddressValidationRegion;

  /// No description provided for @profileAddressValidationDetail.
  ///
  /// In zh, this message translates to:
  /// **'请输入详细地址'**
  String get profileAddressValidationDetail;

  /// No description provided for @profileAddressValidationCodeFormat.
  ///
  /// In zh, this message translates to:
  /// **'编码仅支持字母、数字、下划线和短横线'**
  String get profileAddressValidationCodeFormat;

  /// No description provided for @profileAddressValidationStreetPair.
  ///
  /// In zh, this message translates to:
  /// **'街道名称与街道编码需要同时填写或同时留空'**
  String get profileAddressValidationStreetPair;

  /// No description provided for @profileAddressDefaultToggle.
  ///
  /// In zh, this message translates to:
  /// **'设为默认收货地址'**
  String get profileAddressDefaultToggle;

  /// No description provided for @profileAddressSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存收货地址失败，请稍后重试'**
  String get profileAddressSaveFailed;

  /// No description provided for @profileAddressLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载收货地址失败，请稍后重试'**
  String get profileAddressLoadFailed;

  /// No description provided for @profileAddressDeleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除收货地址失败，请稍后重试'**
  String get profileAddressDeleteFailed;

  /// No description provided for @profileAddressDefaultFailed.
  ///
  /// In zh, this message translates to:
  /// **'设置默认收货地址失败，请稍后重试'**
  String get profileAddressDefaultFailed;

  /// No description provided for @profilePointsTitle.
  ///
  /// In zh, this message translates to:
  /// **'积分中心'**
  String get profilePointsTitle;

  /// No description provided for @profilePointsBalance.
  ///
  /// In zh, this message translates to:
  /// **'当前积分'**
  String get profilePointsBalance;

  /// No description provided for @profilePointsTodayGain.
  ///
  /// In zh, this message translates to:
  /// **'今日获得'**
  String get profilePointsTodayGain;

  /// No description provided for @profilePointsWeekGain.
  ///
  /// In zh, this message translates to:
  /// **'本周获得'**
  String get profilePointsWeekGain;

  /// No description provided for @profilePointsHisTotal.
  ///
  /// In zh, this message translates to:
  /// **'累计获得'**
  String get profilePointsHisTotal;

  /// No description provided for @profilePointsMonthlyEarned.
  ///
  /// In zh, this message translates to:
  /// **'本月获得'**
  String get profilePointsMonthlyEarned;

  /// No description provided for @profilePointsMonthlySpent.
  ///
  /// In zh, this message translates to:
  /// **'本月消耗'**
  String get profilePointsMonthlySpent;

  /// No description provided for @profilePointsCheckIn.
  ///
  /// In zh, this message translates to:
  /// **'每日签到 +5'**
  String get profilePointsCheckIn;

  /// No description provided for @profilePointsCheckInDone.
  ///
  /// In zh, this message translates to:
  /// **'今日已签到'**
  String get profilePointsCheckInDone;

  /// No description provided for @profilePointsCheckInHint.
  ///
  /// In zh, this message translates to:
  /// **'每日签到可领取积分奖励，后续可用于兑换优惠权益。'**
  String get profilePointsCheckInHint;

  /// No description provided for @profilePointsCheckInFailed.
  ///
  /// In zh, this message translates to:
  /// **'签到失败，请稍后重试'**
  String get profilePointsCheckInFailed;

  /// No description provided for @profilePointsCheckInSuccess.
  ///
  /// In zh, this message translates to:
  /// **'签到成功，已获得 {points} 积分'**
  String profilePointsCheckInSuccess(int points);

  /// No description provided for @profilePointsHistory.
  ///
  /// In zh, this message translates to:
  /// **'积分明细'**
  String get profilePointsHistory;

  /// No description provided for @profilePointsTasks.
  ///
  /// In zh, this message translates to:
  /// **'积分任务'**
  String get profilePointsTasks;

  /// No description provided for @profilePointsRegisterTask.
  ///
  /// In zh, this message translates to:
  /// **'新手任务'**
  String get profilePointsRegisterTask;

  /// No description provided for @profilePointsTaskEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无可领取积分任务'**
  String get profilePointsTaskEmpty;

  /// No description provided for @profilePointsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无积分记录'**
  String get profilePointsEmpty;

  /// No description provided for @profilePointsLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载积分信息失败，请稍后重试'**
  String get profilePointsLoadFailed;

  /// No description provided for @profilePointsLoadMore.
  ///
  /// In zh, this message translates to:
  /// **'加载更多'**
  String get profilePointsLoadMore;

  /// No description provided for @profilePointsLoadMoreFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载更多积分记录失败，请稍后重试'**
  String get profilePointsLoadMoreFailed;

  /// No description provided for @profilePointsTaskActionUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'任务入口“{action}”暂不可用'**
  String profilePointsTaskActionUnsupported(String action);

  /// No description provided for @profilePointsEntryDailyCheckIn.
  ///
  /// In zh, this message translates to:
  /// **'每日签到'**
  String get profilePointsEntryDailyCheckIn;

  /// No description provided for @profilePointsEntryDailyCheckInSub.
  ///
  /// In zh, this message translates to:
  /// **'完成今日签到，积分已入账'**
  String get profilePointsEntryDailyCheckInSub;

  /// No description provided for @profilePointsEntryWelcome.
  ///
  /// In zh, this message translates to:
  /// **'新人欢迎积分'**
  String get profilePointsEntryWelcome;

  /// No description provided for @profilePointsEntryWelcomeSub.
  ///
  /// In zh, this message translates to:
  /// **'完成新用户激活后发放'**
  String get profilePointsEntryWelcomeSub;

  /// No description provided for @profilePointsEntryAssessment.
  ///
  /// In zh, this message translates to:
  /// **'体质评估奖励'**
  String get profilePointsEntryAssessment;

  /// No description provided for @profilePointsEntryAssessmentSub.
  ///
  /// In zh, this message translates to:
  /// **'完成个性化体质评估后发放'**
  String get profilePointsEntryAssessmentSub;

  /// No description provided for @profilePointsEntryCoupon.
  ///
  /// In zh, this message translates to:
  /// **'兑换咨询优惠券'**
  String get profilePointsEntryCoupon;

  /// No description provided for @profilePointsEntryCouponSub.
  ///
  /// In zh, this message translates to:
  /// **'使用积分兑换优惠权益'**
  String get profilePointsEntryCouponSub;

  /// No description provided for @profileLogout.
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get profileLogout;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In zh, this message translates to:
  /// **'账号'**
  String get settingsSectionAccount;

  /// No description provided for @settingsAccountSecurity.
  ///
  /// In zh, this message translates to:
  /// **'账号与安全'**
  String get settingsAccountSecurity;

  /// No description provided for @settingsAccountSecuritySub.
  ///
  /// In zh, this message translates to:
  /// **'登录方式、手机号与密码安全管理'**
  String get settingsAccountSecuritySub;

  /// No description provided for @accountSecurityTitle.
  ///
  /// In zh, this message translates to:
  /// **'账号与安全'**
  String get accountSecurityTitle;

  /// No description provided for @accountSecurityPhoneCodeTip.
  ///
  /// In zh, this message translates to:
  /// **'当前注册默认使用手机验证码登录，后续可按需补充设置登录密码。'**
  String get accountSecurityPhoneCodeTip;

  /// No description provided for @accountSecurityLoginPassword.
  ///
  /// In zh, this message translates to:
  /// **'设置登录密码'**
  String get accountSecurityLoginPassword;

  /// No description provided for @accountSecurityLoginPasswordSub.
  ///
  /// In zh, this message translates to:
  /// **'设置后可使用手机号与密码登录；未设置时继续使用验证码登录。'**
  String get accountSecurityLoginPasswordSub;

  /// No description provided for @accountSecurityPasswordSet.
  ///
  /// In zh, this message translates to:
  /// **'已设置'**
  String get accountSecurityPasswordSet;

  /// No description provided for @accountSecurityPasswordUnset.
  ///
  /// In zh, this message translates to:
  /// **'未设置'**
  String get accountSecurityPasswordUnset;

  /// No description provided for @setLoginPasswordTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置登录密码'**
  String get setLoginPasswordTitle;

  /// No description provided for @setLoginPasswordSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'设置后可使用手机号与密码登录；若暂不设置，仍可使用验证码登录。'**
  String get setLoginPasswordSubtitle;

  /// No description provided for @setLoginPasswordAction.
  ///
  /// In zh, this message translates to:
  /// **'保存密码'**
  String get setLoginPasswordAction;

  /// No description provided for @setLoginPasswordSuccess.
  ///
  /// In zh, this message translates to:
  /// **'登录密码已设置'**
  String get setLoginPasswordSuccess;

  /// No description provided for @localeSheetTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择语言'**
  String get localeSheetTitle;

  /// No description provided for @localeFollowSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get localeFollowSystem;

  /// No description provided for @localeChineseSimplified.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get localeChineseSimplified;

  /// No description provided for @localeEnglish.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get localeEnglish;

  /// No description provided for @localeJapanese.
  ///
  /// In zh, this message translates to:
  /// **'日本語'**
  String get localeJapanese;

  /// No description provided for @localeKorean.
  ///
  /// In zh, this message translates to:
  /// **'한국어'**
  String get localeKorean;

  /// No description provided for @commonViewDetails.
  ///
  /// In zh, this message translates to:
  /// **'查看详情'**
  String get commonViewDetails;

  /// No description provided for @commonFiveElements.
  ///
  /// In zh, this message translates to:
  /// **'五行'**
  String get commonFiveElements;

  /// No description provided for @profileBmiNormal.
  ///
  /// In zh, this message translates to:
  /// **'正常'**
  String get profileBmiNormal;

  /// No description provided for @scanStepFace.
  ///
  /// In zh, this message translates to:
  /// **'面部'**
  String get scanStepFace;

  /// No description provided for @scanStepTongue.
  ///
  /// In zh, this message translates to:
  /// **'舌头'**
  String get scanStepTongue;

  /// No description provided for @scanStepPalm.
  ///
  /// In zh, this message translates to:
  /// **'手掌'**
  String get scanStepPalm;

  /// No description provided for @scanSkipThisStep.
  ///
  /// In zh, this message translates to:
  /// **'跳过此步骤'**
  String get scanSkipThisStep;

  /// No description provided for @scanProgressLabel.
  ///
  /// In zh, this message translates to:
  /// **'扫描进度'**
  String get scanProgressLabel;

  /// No description provided for @scanAnalyzingProgress.
  ///
  /// In zh, this message translates to:
  /// **'分析中... {progress}%'**
  String scanAnalyzingProgress(int progress);

  /// No description provided for @scanCameraPreviewUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'{platform} 暂不支持相机预览。'**
  String scanCameraPreviewUnsupported(String platform);

  /// No description provided for @scanGuideHeaderTitle.
  ///
  /// In zh, this message translates to:
  /// **'AI 健康扫描'**
  String get scanGuideHeaderTitle;

  /// No description provided for @scanGuideHeroTitle.
  ///
  /// In zh, this message translates to:
  /// **'三步望诊，辨识体质'**
  String get scanGuideHeroTitle;

  /// No description provided for @scanGuideHeroSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'结合现代 AI 技术与传统中医望诊理论\n为您提供专属体质分析报告'**
  String get scanGuideHeroSubtitle;

  /// No description provided for @scanGuideStep1Title.
  ///
  /// In zh, this message translates to:
  /// **'面部扫描'**
  String get scanGuideStep1Title;

  /// No description provided for @scanGuideStep1Desc.
  ///
  /// In zh, this message translates to:
  /// **'分析面色光泽与五官特征'**
  String get scanGuideStep1Desc;

  /// No description provided for @scanGuideStep1Detail.
  ///
  /// In zh, this message translates to:
  /// **'通过面部气色判断脏腑盛衰，观察神、色、形、态'**
  String get scanGuideStep1Detail;

  /// No description provided for @scanGuideStep2Title.
  ///
  /// In zh, this message translates to:
  /// **'舌头扫描'**
  String get scanGuideStep2Title;

  /// No description provided for @scanGuideStep2Desc.
  ///
  /// In zh, this message translates to:
  /// **'观察舌质颜色与舌苔厚薄'**
  String get scanGuideStep2Desc;

  /// No description provided for @scanGuideStep2Detail.
  ///
  /// In zh, this message translates to:
  /// **'舌为心之苗，脾之外候，舌象反映气血津液盛衰'**
  String get scanGuideStep2Detail;

  /// No description provided for @scanGuideStep3Title.
  ///
  /// In zh, this message translates to:
  /// **'手掌扫描'**
  String get scanGuideStep3Title;

  /// No description provided for @scanGuideStep3Desc.
  ///
  /// In zh, this message translates to:
  /// **'识别掌纹分布与局部气色'**
  String get scanGuideStep3Desc;

  /// No description provided for @scanGuideStep3Detail.
  ///
  /// In zh, this message translates to:
  /// **'手掌色泽与纹路折射经络气血的运行状态'**
  String get scanGuideStep3Detail;

  /// No description provided for @scanGuideStepLabel.
  ///
  /// In zh, this message translates to:
  /// **'步骤 {step}：{title}'**
  String scanGuideStepLabel(int step, String title);

  /// No description provided for @scanGuideWarmPromptTitle.
  ///
  /// In zh, this message translates to:
  /// **'温馨提示'**
  String get scanGuideWarmPromptTitle;

  /// No description provided for @scanGuideWarmPromptContent.
  ///
  /// In zh, this message translates to:
  /// **'请在自然光线充足处进行，扫描前清洁面部，取下帽子、眼镜等饰品，保持放松自然状态'**
  String get scanGuideWarmPromptContent;

  /// No description provided for @scanGuideEstimate.
  ///
  /// In zh, this message translates to:
  /// **'预计 2 分钟完成 · 请在光线充足处进行'**
  String get scanGuideEstimate;

  /// No description provided for @scanGuideStartButton.
  ///
  /// In zh, this message translates to:
  /// **'开始扫描'**
  String get scanGuideStartButton;

  /// No description provided for @scanGuidePrivacyNote.
  ///
  /// In zh, this message translates to:
  /// **'扫描数据仅用于健康分析，不会上传至第三方'**
  String get scanGuidePrivacyNote;

  /// No description provided for @scanFaceDetectionPermissionRequired.
  ///
  /// In zh, this message translates to:
  /// **'需要相机权限才能进行面部描点'**
  String get scanFaceDetectionPermissionRequired;

  /// No description provided for @scanCameraPermissionRequired.
  ///
  /// In zh, this message translates to:
  /// **'需要相机权限'**
  String get scanCameraPermissionRequired;

  /// No description provided for @scanKeepStill.
  ///
  /// In zh, this message translates to:
  /// **'请保持不动'**
  String get scanKeepStill;

  /// No description provided for @scanMoveLeft.
  ///
  /// In zh, this message translates to:
  /// **'← 请向左移动'**
  String get scanMoveLeft;

  /// No description provided for @scanMoveRight.
  ///
  /// In zh, this message translates to:
  /// **'→ 请向右移动'**
  String get scanMoveRight;

  /// No description provided for @scanMoveUp.
  ///
  /// In zh, this message translates to:
  /// **'↑ 请向上移动'**
  String get scanMoveUp;

  /// No description provided for @scanMoveDown.
  ///
  /// In zh, this message translates to:
  /// **'↓ 请向下移动'**
  String get scanMoveDown;

  /// No description provided for @scanTipBrightLight.
  ///
  /// In zh, this message translates to:
  /// **'光线充足'**
  String get scanTipBrightLight;

  /// No description provided for @scanTipKeepSteady.
  ///
  /// In zh, this message translates to:
  /// **'保持稳定'**
  String get scanTipKeepSteady;

  /// No description provided for @scanScanning.
  ///
  /// In zh, this message translates to:
  /// **'扫描中…'**
  String get scanScanning;

  /// No description provided for @scanFaceAlignInFrame.
  ///
  /// In zh, this message translates to:
  /// **'请将面部对准框内'**
  String get scanFaceAlignInFrame;

  /// No description provided for @scanFaceDetectedReady.
  ///
  /// In zh, this message translates to:
  /// **'面部已就位 ✓'**
  String get scanFaceDetectedReady;

  /// No description provided for @scanFaceTitle.
  ///
  /// In zh, this message translates to:
  /// **'面部望诊'**
  String get scanFaceTitle;

  /// No description provided for @scanFaceTag.
  ///
  /// In zh, this message translates to:
  /// **'面诊'**
  String get scanFaceTag;

  /// No description provided for @scanFaceSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'将面部置于椭圆框内，保持正视，自然放松表情'**
  String get scanFaceSubtitle;

  /// No description provided for @scanFaceDetail.
  ///
  /// In zh, this message translates to:
  /// **'通过面部气色判断脏腑盛衰，观察神、色、形、态'**
  String get scanFaceDetail;

  /// No description provided for @scanFaceTipNoMakeup.
  ///
  /// In zh, this message translates to:
  /// **'不要化妆'**
  String get scanFaceTipNoMakeup;

  /// No description provided for @scanFaceTipLookForward.
  ///
  /// In zh, this message translates to:
  /// **'正视前方'**
  String get scanFaceTipLookForward;

  /// No description provided for @scanFaceStartButton.
  ///
  /// In zh, this message translates to:
  /// **'开始面部扫描'**
  String get scanFaceStartButton;

  /// No description provided for @scanTongueCompleted.
  ///
  /// In zh, this message translates to:
  /// **'舌象扫描完成 ✓'**
  String get scanTongueCompleted;

  /// No description provided for @scanTongueTapToStart.
  ///
  /// In zh, this message translates to:
  /// **'点击下方按钮开始扫描'**
  String get scanTongueTapToStart;

  /// No description provided for @scanTongueDetectedHold.
  ///
  /// In zh, this message translates to:
  /// **'已识别舌头，请保持 2 秒'**
  String get scanTongueDetectedHold;

  /// No description provided for @scanTongueMouthDetected.
  ///
  /// In zh, this message translates to:
  /// **'已检测口部，请自然伸舌'**
  String get scanTongueMouthDetected;

  /// No description provided for @scanTongueAlignHint.
  ///
  /// In zh, this message translates to:
  /// **'请伸出舌头，对准框内'**
  String get scanTongueAlignHint;

  /// No description provided for @scanTongueTitle.
  ///
  /// In zh, this message translates to:
  /// **'舌象诊断'**
  String get scanTongueTitle;

  /// No description provided for @scanTongueTag.
  ///
  /// In zh, this message translates to:
  /// **'舌诊'**
  String get scanTongueTag;

  /// No description provided for @scanTongueSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'自然伸出舌头，舌面充分展开，保持 2 秒'**
  String get scanTongueSubtitle;

  /// No description provided for @scanTongueDetail.
  ///
  /// In zh, this message translates to:
  /// **'舌为心之苗，脾之外候，舌象反映气血津液盛衰'**
  String get scanTongueDetail;

  /// No description provided for @scanTongueTipNoColoredFood.
  ///
  /// In zh, this message translates to:
  /// **'勿食有色食物'**
  String get scanTongueTipNoColoredFood;

  /// No description provided for @scanTongueTipTongueFlat.
  ///
  /// In zh, this message translates to:
  /// **'舌头平伸'**
  String get scanTongueTipTongueFlat;

  /// No description provided for @scanTongueStartButton.
  ///
  /// In zh, this message translates to:
  /// **'开始舌象扫描'**
  String get scanTongueStartButton;

  /// No description provided for @scanTongueNextPalm.
  ///
  /// In zh, this message translates to:
  /// **'下一步：手掌扫描'**
  String get scanTongueNextPalm;

  /// No description provided for @scanPalmMoveCloser.
  ///
  /// In zh, this message translates to:
  /// **'手掌太远，请靠近一点'**
  String get scanPalmMoveCloser;

  /// No description provided for @scanPalmMoveFarther.
  ///
  /// In zh, this message translates to:
  /// **'手掌太近，请离远一点'**
  String get scanPalmMoveFarther;

  /// No description provided for @scanPalmWaitingPermission.
  ///
  /// In zh, this message translates to:
  /// **'等待权限'**
  String get scanPalmWaitingPermission;

  /// No description provided for @scanPalmCompleted.
  ///
  /// In zh, this message translates to:
  /// **'手掌扫描完成 ✓'**
  String get scanPalmCompleted;

  /// No description provided for @scanPalmReadyHold.
  ///
  /// In zh, this message translates to:
  /// **'已识别伸直手掌，请保持 2 秒'**
  String get scanPalmReadyHold;

  /// No description provided for @scanPalmOpenDetectedStraighten.
  ///
  /// In zh, this message translates to:
  /// **'已检测到张开手掌，请将手掌伸直'**
  String get scanPalmOpenDetectedStraighten;

  /// No description provided for @scanPalmDetectedGesture.
  ///
  /// In zh, this message translates to:
  /// **'检测到：{gesture}'**
  String scanPalmDetectedGesture(String gesture);

  /// No description provided for @scanPalmStretchOpen.
  ///
  /// In zh, this message translates to:
  /// **'请将手掌伸直并自然张开'**
  String get scanPalmStretchOpen;

  /// No description provided for @scanPalmAlignHint.
  ///
  /// In zh, this message translates to:
  /// **'请将手掌放入框内'**
  String get scanPalmAlignHint;

  /// No description provided for @scanGestureOpenPalm.
  ///
  /// In zh, this message translates to:
  /// **'张开手掌'**
  String get scanGestureOpenPalm;

  /// No description provided for @scanGestureClosedFist.
  ///
  /// In zh, this message translates to:
  /// **'握拳'**
  String get scanGestureClosedFist;

  /// No description provided for @scanGestureVictory.
  ///
  /// In zh, this message translates to:
  /// **'比耶'**
  String get scanGestureVictory;

  /// No description provided for @scanGestureThumbUp.
  ///
  /// In zh, this message translates to:
  /// **'竖起拇指'**
  String get scanGestureThumbUp;

  /// No description provided for @scanGestureThumbDown.
  ///
  /// In zh, this message translates to:
  /// **'拇指向下'**
  String get scanGestureThumbDown;

  /// No description provided for @scanGesturePointingUp.
  ///
  /// In zh, this message translates to:
  /// **'食指向上'**
  String get scanGesturePointingUp;

  /// No description provided for @scanGestureILoveYou.
  ///
  /// In zh, this message translates to:
  /// **'我爱你手势'**
  String get scanGestureILoveYou;

  /// No description provided for @scanPalmTitle.
  ///
  /// In zh, this message translates to:
  /// **'手掌经络'**
  String get scanPalmTitle;

  /// No description provided for @scanPalmTag.
  ///
  /// In zh, this message translates to:
  /// **'掌诊'**
  String get scanPalmTag;

  /// No description provided for @scanPalmSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'将手掌自然伸向镜头，参考倾斜轮廓摆放，手指自然分开'**
  String get scanPalmSubtitle;

  /// No description provided for @scanPalmDetail.
  ///
  /// In zh, this message translates to:
  /// **'观察手掌纹路、色泽、形态，推断五脏六腑之病理'**
  String get scanPalmDetail;

  /// No description provided for @scanPalmTipFlatten.
  ///
  /// In zh, this message translates to:
  /// **'手掌展平'**
  String get scanPalmTipFlatten;

  /// No description provided for @scanPalmViewingReportSoon.
  ///
  /// In zh, this message translates to:
  /// **'即将查看报告'**
  String get scanPalmViewingReportSoon;

  /// No description provided for @scanPalmHoldButton.
  ///
  /// In zh, this message translates to:
  /// **'请伸直手掌并保持 2 秒'**
  String get scanPalmHoldButton;

  /// No description provided for @scanQuestionTitle.
  ///
  /// In zh, this message translates to:
  /// **'问诊补充'**
  String get scanQuestionTitle;

  /// No description provided for @scanQuestionSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'再补充几个问题，可让体质判断和最终报告更完整。你也可以直接跳过，按当前扫描结果查看报告。'**
  String get scanQuestionSubtitle;

  /// No description provided for @scanQuestionSkipDirectReport.
  ///
  /// In zh, this message translates to:
  /// **'跳过，直接看报告'**
  String get scanQuestionSkipDirectReport;

  /// No description provided for @scanQuestionAnsweredCount.
  ///
  /// In zh, this message translates to:
  /// **'已回答 {count} 题'**
  String scanQuestionAnsweredCount(int count);

  /// No description provided for @scanQuestionOptionalTag.
  ///
  /// In zh, this message translates to:
  /// **'可跳过'**
  String get scanQuestionOptionalTag;

  /// No description provided for @scanQuestionLoadingTitle.
  ///
  /// In zh, this message translates to:
  /// **'正在准备补充问题'**
  String get scanQuestionLoadingTitle;

  /// No description provided for @scanQuestionLoadingBody.
  ///
  /// In zh, this message translates to:
  /// **'正在拉取下一题并整理问答上下文，请稍候。'**
  String get scanQuestionLoadingBody;

  /// No description provided for @scanQuestionLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'问题加载失败'**
  String get scanQuestionLoadFailed;

  /// No description provided for @scanQuestionRetry.
  ///
  /// In zh, this message translates to:
  /// **'重新加载'**
  String get scanQuestionRetry;

  /// No description provided for @scanQuestionMissingQuestion.
  ///
  /// In zh, this message translates to:
  /// **'当前没有可展示的问题，请重试或直接查看报告。'**
  String get scanQuestionMissingQuestion;

  /// No description provided for @scanQuestionFooterHint.
  ///
  /// In zh, this message translates to:
  /// **'问答结果仅用于完善体质分析，不会影响已完成的扫描图像上传。'**
  String get scanQuestionFooterHint;

  /// No description provided for @scanQuestionProgressTitle.
  ///
  /// In zh, this message translates to:
  /// **'第 {current}/{total} 题'**
  String scanQuestionProgressTitle(int current, int total);

  /// No description provided for @scanQuestionSectionTitle.
  ///
  /// In zh, this message translates to:
  /// **'补充问题'**
  String get scanQuestionSectionTitle;

  /// No description provided for @scanQuestionSubmitAndReport.
  ///
  /// In zh, this message translates to:
  /// **'提交答案并生成报告'**
  String get scanQuestionSubmitAndReport;

  /// No description provided for @scanQuestionNextButton.
  ///
  /// In zh, this message translates to:
  /// **'下一题'**
  String get scanQuestionNextButton;

  /// No description provided for @reportTabOverview.
  ///
  /// In zh, this message translates to:
  /// **'总览'**
  String get reportTabOverview;

  /// No description provided for @reportTabConstitution.
  ///
  /// In zh, this message translates to:
  /// **'体质'**
  String get reportTabConstitution;

  /// No description provided for @reportTabTherapy.
  ///
  /// In zh, this message translates to:
  /// **'调理'**
  String get reportTabTherapy;

  /// No description provided for @reportTabAdvice.
  ///
  /// In zh, this message translates to:
  /// **'建议'**
  String get reportTabAdvice;

  /// No description provided for @reportHeaderCollapsedTitle.
  ///
  /// In zh, this message translates to:
  /// **'AI 健康报告'**
  String get reportHeaderCollapsedTitle;

  /// No description provided for @reportHeroMeta.
  ///
  /// In zh, this message translates to:
  /// **'2025.03.14  ·  AI 四诊合参'**
  String get reportHeroMeta;

  /// No description provided for @reportHeroTitle.
  ///
  /// In zh, this message translates to:
  /// **'{name}的健康报告'**
  String reportHeroTitle(String name);

  /// No description provided for @reportHeroSecondaryBias.
  ///
  /// In zh, this message translates to:
  /// **'气虚偏颇'**
  String get reportHeroSecondaryBias;

  /// No description provided for @reportHeroSummary.
  ///
  /// In zh, this message translates to:
  /// **'脾气亏虚，运化失健。面色偏黄，舌淡苔白。'**
  String get reportHeroSummary;

  /// No description provided for @reportHealthScoreLabel.
  ///
  /// In zh, this message translates to:
  /// **'健康分'**
  String get reportHealthScoreLabel;

  /// No description provided for @reportHealthStatus.
  ///
  /// In zh, this message translates to:
  /// **'体质状况 良好'**
  String get reportHealthStatus;

  /// No description provided for @reportOverviewFaceDiagnosisDesc.
  ///
  /// In zh, this message translates to:
  /// **'气色偏黄，神采尚可'**
  String get reportOverviewFaceDiagnosisDesc;

  /// No description provided for @reportOverviewTongueDiagnosisDesc.
  ///
  /// In zh, this message translates to:
  /// **'舌淡苔白，略厚'**
  String get reportOverviewTongueDiagnosisDesc;

  /// No description provided for @reportOverviewPalmDiagnosisDesc.
  ///
  /// In zh, this message translates to:
  /// **'掌纹细浅，气色平'**
  String get reportOverviewPalmDiagnosisDesc;

  /// No description provided for @reportOverviewDiagScoresTitle.
  ///
  /// In zh, this message translates to:
  /// **'三诊评分'**
  String get reportOverviewDiagScoresTitle;

  /// No description provided for @reportOverviewFeatureDetailsTitle.
  ///
  /// In zh, this message translates to:
  /// **'体征详情'**
  String get reportOverviewFeatureDetailsTitle;

  /// No description provided for @reportOverviewTongueTitle.
  ///
  /// In zh, this message translates to:
  /// **'舌象'**
  String get reportOverviewTongueTitle;

  /// No description provided for @reportOverviewTongueImagePlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'舌象图片'**
  String get reportOverviewTongueImagePlaceholder;

  /// No description provided for @reportOverviewTongueColorLabel.
  ///
  /// In zh, this message translates to:
  /// **'舌色'**
  String get reportOverviewTongueColorLabel;

  /// No description provided for @reportOverviewTongueColorValue.
  ///
  /// In zh, this message translates to:
  /// **'淡红'**
  String get reportOverviewTongueColorValue;

  /// No description provided for @reportOverviewTongueCoatingLabel.
  ///
  /// In zh, this message translates to:
  /// **'苔质'**
  String get reportOverviewTongueCoatingLabel;

  /// No description provided for @reportOverviewTongueCoatingValue.
  ///
  /// In zh, this message translates to:
  /// **'白苔·略厚'**
  String get reportOverviewTongueCoatingValue;

  /// No description provided for @reportOverviewTongueShapeLabel.
  ///
  /// In zh, this message translates to:
  /// **'舌形'**
  String get reportOverviewTongueShapeLabel;

  /// No description provided for @reportOverviewTongueShapeValue.
  ///
  /// In zh, this message translates to:
  /// **'正常'**
  String get reportOverviewTongueShapeValue;

  /// No description provided for @reportOverviewWuxingTitle.
  ///
  /// In zh, this message translates to:
  /// **'五行 · 木旺'**
  String get reportOverviewWuxingTitle;

  /// No description provided for @reportOverviewDiagnosisSummaryTitle.
  ///
  /// In zh, this message translates to:
  /// **'辨证摘要'**
  String get reportOverviewDiagnosisSummaryTitle;

  /// No description provided for @reportOverviewDiagnosisSummaryBody.
  ///
  /// In zh, this message translates to:
  /// **'辨证：脾气亏虚，运化失健。面色偏黄，舌淡苔白，脉象细缓，气短乏力，食欲欠佳。证属脾虚气弱，兼有湿邪内阻。'**
  String get reportOverviewDiagnosisSummaryBody;

  /// No description provided for @reportOverviewDiagnosisTagSpleenWeak.
  ///
  /// In zh, this message translates to:
  /// **'脾胃虚弱'**
  String get reportOverviewDiagnosisTagSpleenWeak;

  /// No description provided for @reportOverviewModuleConstitutionTitle.
  ///
  /// In zh, this message translates to:
  /// **'体质详解'**
  String get reportOverviewModuleConstitutionTitle;

  /// No description provided for @reportOverviewModuleConstitutionSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'了解你的体质'**
  String get reportOverviewModuleConstitutionSubtitle;

  /// No description provided for @reportOverviewModuleAcupointTitle.
  ///
  /// In zh, this message translates to:
  /// **'辩证取穴'**
  String get reportOverviewModuleAcupointTitle;

  /// No description provided for @reportOverviewModuleAcupointSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'穴位调理方案'**
  String get reportOverviewModuleAcupointSubtitle;

  /// No description provided for @reportOverviewModuleDietTitle.
  ///
  /// In zh, this message translates to:
  /// **'饮食建议'**
  String get reportOverviewModuleDietTitle;

  /// No description provided for @reportOverviewModuleDietSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'食补调养方案'**
  String get reportOverviewModuleDietSubtitle;

  /// No description provided for @reportOverviewModuleSeasonalTitle.
  ///
  /// In zh, this message translates to:
  /// **'四季保养'**
  String get reportOverviewModuleSeasonalTitle;

  /// No description provided for @reportOverviewModuleSeasonalSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'顺时养生'**
  String get reportOverviewModuleSeasonalSubtitle;

  /// No description provided for @reportOverviewModuleNavTitle.
  ///
  /// In zh, this message translates to:
  /// **'模块导航'**
  String get reportOverviewModuleNavTitle;

  /// No description provided for @reportOverviewScanMetaDisclaimer.
  ///
  /// In zh, this message translates to:
  /// **'本报告由 AI 四诊合参生成，仅供健康参考，不构成医疗诊断。如有不适请咨询专业医师。'**
  String get reportOverviewScanMetaDisclaimer;

  /// No description provided for @reportConstitutionDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'体质详解'**
  String get reportConstitutionDetailTitle;

  /// No description provided for @reportConstitutionCoreConclusionLabel.
  ///
  /// In zh, this message translates to:
  /// **'核心结论'**
  String get reportConstitutionCoreConclusionLabel;

  /// No description provided for @reportConstitutionCoreConclusionValue.
  ///
  /// In zh, this message translates to:
  /// **'主导偏颇体质：气虚质'**
  String get reportConstitutionCoreConclusionValue;

  /// No description provided for @reportConstitutionCoreConclusionBody.
  ///
  /// In zh, this message translates to:
  /// **'整体以平和质为基础，但伴有较明显的气虚倾向。雷达图中平和质与气虚质占比相对突出，说明体质底子尚可，但在劳累、饮食失调和作息紊乱时，更容易出现乏力、脾胃运化不足等表现。'**
  String get reportConstitutionCoreConclusionBody;

  /// No description provided for @reportConstitutionYangDeficiency.
  ///
  /// In zh, this message translates to:
  /// **'阳虚质'**
  String get reportConstitutionYangDeficiency;

  /// No description provided for @reportConstitutionYinDeficiency.
  ///
  /// In zh, this message translates to:
  /// **'阴虚质'**
  String get reportConstitutionYinDeficiency;

  /// No description provided for @reportConstitutionDampHeat.
  ///
  /// In zh, this message translates to:
  /// **'湿热质'**
  String get reportConstitutionDampHeat;

  /// No description provided for @reportConstitutionBloodStasis.
  ///
  /// In zh, this message translates to:
  /// **'血瘀质'**
  String get reportConstitutionBloodStasis;

  /// No description provided for @reportConstitutionQiStagnation.
  ///
  /// In zh, this message translates to:
  /// **'气郁质'**
  String get reportConstitutionQiStagnation;

  /// No description provided for @reportConstitutionSpecial.
  ///
  /// In zh, this message translates to:
  /// **'特禀质'**
  String get reportConstitutionSpecial;

  /// No description provided for @reportCausalAnalysisTitle.
  ///
  /// In zh, this message translates to:
  /// **'分析成因'**
  String get reportCausalAnalysisTitle;

  /// No description provided for @reportCauseRoutine.
  ///
  /// In zh, this message translates to:
  /// **'作息'**
  String get reportCauseRoutine;

  /// No description provided for @reportCauseRoutineBody.
  ///
  /// In zh, this message translates to:
  /// **'长期晚睡，子时未眠，伤及肝肾精气，导致气血生化不足。'**
  String get reportCauseRoutineBody;

  /// No description provided for @reportCauseDiet.
  ///
  /// In zh, this message translates to:
  /// **'饮食'**
  String get reportCauseDiet;

  /// No description provided for @reportCauseDietBody.
  ///
  /// In zh, this message translates to:
  /// **'饮食偏凉，过食生冷，寒邪损伤脾阳，运化功能减退。'**
  String get reportCauseDietBody;

  /// No description provided for @reportCauseEmotion.
  ///
  /// In zh, this message translates to:
  /// **'情志'**
  String get reportCauseEmotion;

  /// No description provided for @reportCauseEmotionBody.
  ///
  /// In zh, this message translates to:
  /// **'思虑过度，忧思伤脾，气机郁结，运化失司。'**
  String get reportCauseEmotionBody;

  /// No description provided for @reportCauseExercise.
  ///
  /// In zh, this message translates to:
  /// **'运动'**
  String get reportCauseExercise;

  /// No description provided for @reportCauseExerciseBody.
  ///
  /// In zh, this message translates to:
  /// **'久坐少动，气血运行不畅，中气渐虚。'**
  String get reportCauseExerciseBody;

  /// No description provided for @reportDiseaseTendencyTitle.
  ///
  /// In zh, this message translates to:
  /// **'易诱发的疾病'**
  String get reportDiseaseTendencyTitle;

  /// No description provided for @reportDiseaseSpleenWeak.
  ///
  /// In zh, this message translates to:
  /// **'脾胃虚弱'**
  String get reportDiseaseSpleenWeak;

  /// No description provided for @reportDiseaseSpleenWeakBody.
  ///
  /// In zh, this message translates to:
  /// **'消化不良、腹胀、便溏'**
  String get reportDiseaseSpleenWeakBody;

  /// No description provided for @reportDiseaseQiBloodDeficiency.
  ///
  /// In zh, this message translates to:
  /// **'气血亏虚'**
  String get reportDiseaseQiBloodDeficiency;

  /// No description provided for @reportDiseaseQiBloodDeficiencyBody.
  ///
  /// In zh, this message translates to:
  /// **'头晕、乏力、面色萎黄'**
  String get reportDiseaseQiBloodDeficiencyBody;

  /// No description provided for @reportDiseaseLowImmunity.
  ///
  /// In zh, this message translates to:
  /// **'免疫低下'**
  String get reportDiseaseLowImmunity;

  /// No description provided for @reportDiseaseLowImmunityBody.
  ///
  /// In zh, this message translates to:
  /// **'反复感冒、易疲劳'**
  String get reportDiseaseLowImmunityBody;

  /// No description provided for @reportDiseaseEmotional.
  ///
  /// In zh, this message translates to:
  /// **'情志疾患'**
  String get reportDiseaseEmotional;

  /// No description provided for @reportDiseaseEmotionalBody.
  ///
  /// In zh, this message translates to:
  /// **'焦虑、失眠、抑郁倾向'**
  String get reportDiseaseEmotionalBody;

  /// No description provided for @reportBadHabitsTitle.
  ///
  /// In zh, this message translates to:
  /// **'不当的举动'**
  String get reportBadHabitsTitle;

  /// No description provided for @reportBadHabitOverwork.
  ///
  /// In zh, this message translates to:
  /// **'过度劳累'**
  String get reportBadHabitOverwork;

  /// No description provided for @reportBadHabitOverworkBody.
  ///
  /// In zh, this message translates to:
  /// **'耗气伤脾，加重气虚'**
  String get reportBadHabitOverworkBody;

  /// No description provided for @reportBadHabitColdFood.
  ///
  /// In zh, this message translates to:
  /// **'贪凉饮冷'**
  String get reportBadHabitColdFood;

  /// No description provided for @reportBadHabitColdFoodBody.
  ///
  /// In zh, this message translates to:
  /// **'寒邪伤阳，损伤脾胃'**
  String get reportBadHabitColdFoodBody;

  /// No description provided for @reportBadHabitLateSleep.
  ///
  /// In zh, this message translates to:
  /// **'熬夜晚睡'**
  String get reportBadHabitLateSleep;

  /// No description provided for @reportBadHabitLateSleepBody.
  ///
  /// In zh, this message translates to:
  /// **'阴气不得收敛，精气损耗'**
  String get reportBadHabitLateSleepBody;

  /// No description provided for @reportBadHabitDieting.
  ///
  /// In zh, this message translates to:
  /// **'过度节食'**
  String get reportBadHabitDieting;

  /// No description provided for @reportBadHabitDietingBody.
  ///
  /// In zh, this message translates to:
  /// **'气血生化无源，更伤中气'**
  String get reportBadHabitDietingBody;

  /// No description provided for @reportBadHabitBinge.
  ///
  /// In zh, this message translates to:
  /// **'暴饮暴食'**
  String get reportBadHabitBinge;

  /// No description provided for @reportBadHabitBingeBody.
  ///
  /// In zh, this message translates to:
  /// **'脾胃负担过重，运化失司'**
  String get reportBadHabitBingeBody;

  /// No description provided for @reportTherapyAcupointsTitle.
  ///
  /// In zh, this message translates to:
  /// **'辩证取穴'**
  String get reportTherapyAcupointsTitle;

  /// No description provided for @reportTherapyAcupointsIntro.
  ///
  /// In zh, this message translates to:
  /// **'依据脾气亏虚证型，推荐以下穴位进行艾灸或按摩调理，每日10–15分钟。'**
  String get reportTherapyAcupointsIntro;

  /// No description provided for @reportTherapyAcuPointZusanli.
  ///
  /// In zh, this message translates to:
  /// **'足三里'**
  String get reportTherapyAcuPointZusanli;

  /// No description provided for @reportTherapyAcuPointZusanliLocation.
  ///
  /// In zh, this message translates to:
  /// **'外膝眼下3寸，胫骨旁开1横指'**
  String get reportTherapyAcuPointZusanliLocation;

  /// No description provided for @reportTherapyAcuPointZusanliEffect.
  ///
  /// In zh, this message translates to:
  /// **'健脾益胃、补益气血，为强壮要穴'**
  String get reportTherapyAcuPointZusanliEffect;

  /// No description provided for @reportTherapyAcuPointZusanliMeridian.
  ///
  /// In zh, this message translates to:
  /// **'足阳明胃经'**
  String get reportTherapyAcuPointZusanliMeridian;

  /// No description provided for @reportTherapyAcuPointPishu.
  ///
  /// In zh, this message translates to:
  /// **'脾俞'**
  String get reportTherapyAcuPointPishu;

  /// No description provided for @reportTherapyAcuPointPishuLocation.
  ///
  /// In zh, this message translates to:
  /// **'第11胸椎棘突下旁开1.5寸'**
  String get reportTherapyAcuPointPishuLocation;

  /// No description provided for @reportTherapyAcuPointPishuEffect.
  ///
  /// In zh, this message translates to:
  /// **'健脾化湿、益气补虚，调节脾胃功能'**
  String get reportTherapyAcuPointPishuEffect;

  /// No description provided for @reportTherapyAcuPointPishuMeridian.
  ///
  /// In zh, this message translates to:
  /// **'足太阳膀胱经'**
  String get reportTherapyAcuPointPishuMeridian;

  /// No description provided for @reportTherapyAcuPointQihai.
  ///
  /// In zh, this message translates to:
  /// **'气海'**
  String get reportTherapyAcuPointQihai;

  /// No description provided for @reportTherapyAcuPointQihaiLocation.
  ///
  /// In zh, this message translates to:
  /// **'脐下1.5寸，腹正中线上'**
  String get reportTherapyAcuPointQihaiLocation;

  /// No description provided for @reportTherapyAcuPointQihaiEffect.
  ///
  /// In zh, this message translates to:
  /// **'补益元气、温阳固本，改善气虚乏力'**
  String get reportTherapyAcuPointQihaiEffect;

  /// No description provided for @reportTherapyAcuPointQihaiMeridian.
  ///
  /// In zh, this message translates to:
  /// **'任脉'**
  String get reportTherapyAcuPointQihaiMeridian;

  /// No description provided for @reportTherapyAcuPointGuanyuan.
  ///
  /// In zh, this message translates to:
  /// **'关元'**
  String get reportTherapyAcuPointGuanyuan;

  /// No description provided for @reportTherapyAcuPointGuanyuanLocation.
  ///
  /// In zh, this message translates to:
  /// **'脐下3寸，腹正中线上'**
  String get reportTherapyAcuPointGuanyuanLocation;

  /// No description provided for @reportTherapyAcuPointGuanyuanEffect.
  ///
  /// In zh, this message translates to:
  /// **'培元固本、温阳益气，增强体质'**
  String get reportTherapyAcuPointGuanyuanEffect;

  /// No description provided for @reportTherapyAcuPointGuanyuanMeridian.
  ///
  /// In zh, this message translates to:
  /// **'任脉'**
  String get reportTherapyAcuPointGuanyuanMeridian;

  /// No description provided for @reportTherapyAcupointsWarning.
  ///
  /// In zh, this message translates to:
  /// **'孕妇、皮肤破损处及月经期间请避免艾灸。操作时注意火候，防止烫伤。'**
  String get reportTherapyAcupointsWarning;

  /// No description provided for @reportMentalWellnessTitle.
  ///
  /// In zh, this message translates to:
  /// **'精神养生'**
  String get reportMentalWellnessTitle;

  /// No description provided for @reportMentalTipCalm.
  ///
  /// In zh, this message translates to:
  /// **'恬淡虚无'**
  String get reportMentalTipCalm;

  /// No description provided for @reportMentalTipCalmBody.
  ///
  /// In zh, this message translates to:
  /// **'减少过度思虑，保持心神宁静。中医认为“思伤脾”，思虑过度最易损耗脾气。'**
  String get reportMentalTipCalmBody;

  /// No description provided for @reportMentalTipNature.
  ///
  /// In zh, this message translates to:
  /// **'顺应自然'**
  String get reportMentalTipNature;

  /// No description provided for @reportMentalTipNatureBody.
  ///
  /// In zh, this message translates to:
  /// **'作息顺应昼夜节律，子时前入睡以养肝气，卯时舒展筋骨以助阳气升发。'**
  String get reportMentalTipNatureBody;

  /// No description provided for @reportMentalTipEmotion.
  ///
  /// In zh, this message translates to:
  /// **'调畅情志'**
  String get reportMentalTipEmotion;

  /// No description provided for @reportMentalTipEmotionBody.
  ///
  /// In zh, this message translates to:
  /// **'保持乐观豁达，避免情绪大起大落。适度倾诉，疏导郁结气机。'**
  String get reportMentalTipEmotionBody;

  /// No description provided for @reportMentalTipMeditation.
  ///
  /// In zh, this message translates to:
  /// **'静坐冥想'**
  String get reportMentalTipMeditation;

  /// No description provided for @reportMentalTipMeditationBody.
  ///
  /// In zh, this message translates to:
  /// **'每日静坐10分钟，专注呼吸，有助于调节脾胃气机，增强正气。'**
  String get reportMentalTipMeditationBody;

  /// No description provided for @reportSeasonalCareTitle.
  ///
  /// In zh, this message translates to:
  /// **'四季保养'**
  String get reportSeasonalCareTitle;

  /// No description provided for @reportSeasonSpring.
  ///
  /// In zh, this message translates to:
  /// **'春'**
  String get reportSeasonSpring;

  /// No description provided for @reportSeasonSpringAdvice.
  ///
  /// In zh, this message translates to:
  /// **'春季养肝，适当增酸。多食韭菜、菠菜，舒展筋骨，早起散步以助阳气升发。'**
  String get reportSeasonSpringAdvice;

  /// No description provided for @reportSeasonSpringAvoid.
  ///
  /// In zh, this message translates to:
  /// **'避免过度疲劳，勿食过于辛散之品'**
  String get reportSeasonSpringAvoid;

  /// No description provided for @reportSeasonSummer.
  ///
  /// In zh, this message translates to:
  /// **'夏'**
  String get reportSeasonSummer;

  /// No description provided for @reportSeasonSummerAdvice.
  ///
  /// In zh, this message translates to:
  /// **'夏季养心，注意清热。适当食用莲子、薏仁，午间小憩，避免大汗伤气。'**
  String get reportSeasonSummerAdvice;

  /// No description provided for @reportSeasonSummerAvoid.
  ///
  /// In zh, this message translates to:
  /// **'忌贪凉饮冷，忌剧烈运动大汗'**
  String get reportSeasonSummerAvoid;

  /// No description provided for @reportSeasonAutumn.
  ///
  /// In zh, this message translates to:
  /// **'秋'**
  String get reportSeasonAutumn;

  /// No description provided for @reportSeasonAutumnAdvice.
  ///
  /// In zh, this message translates to:
  /// **'秋季养肺，以润为主。多食梨、百合、银耳，早睡早起，收敛精气。'**
  String get reportSeasonAutumnAdvice;

  /// No description provided for @reportSeasonAutumnAvoid.
  ///
  /// In zh, this message translates to:
  /// **'忌过度悲忧，忌食辛辣燥烈之品'**
  String get reportSeasonAutumnAvoid;

  /// No description provided for @reportSeasonWinter.
  ///
  /// In zh, this message translates to:
  /// **'冬'**
  String get reportSeasonWinter;

  /// No description provided for @reportSeasonWinterAdvice.
  ///
  /// In zh, this message translates to:
  /// **'冬季养肾，以藏为要。适食黑芝麻、核桃、羊肉，早卧晚起，固护肾阳。'**
  String get reportSeasonWinterAdvice;

  /// No description provided for @reportSeasonWinterAvoid.
  ///
  /// In zh, this message translates to:
  /// **'忌过度劳累，忌大量出汗耗散阳气'**
  String get reportSeasonWinterAvoid;

  /// No description provided for @reportAdviceTongueAnalysisTitle.
  ///
  /// In zh, this message translates to:
  /// **'舌象详解'**
  String get reportAdviceTongueAnalysisTitle;

  /// No description provided for @reportAdviceTongueScoreLabel.
  ///
  /// In zh, this message translates to:
  /// **'舌象综合评分'**
  String get reportAdviceTongueScoreLabel;

  /// No description provided for @reportAdviceTongueScoreSummary.
  ///
  /// In zh, this message translates to:
  /// **'脾虚湿盛，气血偏弱'**
  String get reportAdviceTongueScoreSummary;

  /// No description provided for @reportAdviceTongueFeatureColor.
  ///
  /// In zh, this message translates to:
  /// **'舌色'**
  String get reportAdviceTongueFeatureColor;

  /// No description provided for @reportAdviceTongueFeatureColorValue.
  ///
  /// In zh, this message translates to:
  /// **'淡红'**
  String get reportAdviceTongueFeatureColorValue;

  /// No description provided for @reportAdviceTongueFeatureColorDesc.
  ///
  /// In zh, this message translates to:
  /// **'舌色淡红为正常，偏淡提示气血不足'**
  String get reportAdviceTongueFeatureColorDesc;

  /// No description provided for @reportAdviceTongueFeatureShape.
  ///
  /// In zh, this message translates to:
  /// **'舌形'**
  String get reportAdviceTongueFeatureShape;

  /// No description provided for @reportAdviceTongueFeatureShapeValue.
  ///
  /// In zh, this message translates to:
  /// **'正常偏胖'**
  String get reportAdviceTongueFeatureShapeValue;

  /// No description provided for @reportAdviceTongueFeatureShapeDesc.
  ///
  /// In zh, this message translates to:
  /// **'舌体偏胖伴有齿痕，提示脾虚湿盛'**
  String get reportAdviceTongueFeatureShapeDesc;

  /// No description provided for @reportAdviceTongueFeatureCoatingColor.
  ///
  /// In zh, this message translates to:
  /// **'苔色'**
  String get reportAdviceTongueFeatureCoatingColor;

  /// No description provided for @reportAdviceTongueFeatureCoatingColorValue.
  ///
  /// In zh, this message translates to:
  /// **'白苔'**
  String get reportAdviceTongueFeatureCoatingColorValue;

  /// No description provided for @reportAdviceTongueFeatureCoatingColorDesc.
  ///
  /// In zh, this message translates to:
  /// **'苔白主寒主表，提示阳气稍不足'**
  String get reportAdviceTongueFeatureCoatingColorDesc;

  /// No description provided for @reportAdviceTongueFeatureTexture.
  ///
  /// In zh, this message translates to:
  /// **'苔质'**
  String get reportAdviceTongueFeatureTexture;

  /// No description provided for @reportAdviceTongueFeatureTextureValue.
  ///
  /// In zh, this message translates to:
  /// **'厚腻'**
  String get reportAdviceTongueFeatureTextureValue;

  /// No description provided for @reportAdviceTongueFeatureTextureDesc.
  ///
  /// In zh, this message translates to:
  /// **'苔厚腻提示湿邪较重，脾运不畅'**
  String get reportAdviceTongueFeatureTextureDesc;

  /// No description provided for @reportAdviceTongueFeatureTeethMarks.
  ///
  /// In zh, this message translates to:
  /// **'齿痕'**
  String get reportAdviceTongueFeatureTeethMarks;

  /// No description provided for @reportAdviceTongueFeatureTeethMarksValue.
  ///
  /// In zh, this message translates to:
  /// **'有'**
  String get reportAdviceTongueFeatureTeethMarksValue;

  /// No description provided for @reportAdviceTongueFeatureTeethMarksDesc.
  ///
  /// In zh, this message translates to:
  /// **'舌边齿痕为脾虚典型表现，气虚无力运化'**
  String get reportAdviceTongueFeatureTeethMarksDesc;

  /// No description provided for @reportAdviceDietTitle.
  ///
  /// In zh, this message translates to:
  /// **'饮食建议'**
  String get reportAdviceDietTitle;

  /// No description provided for @reportAdviceDietIntro.
  ///
  /// In zh, this message translates to:
  /// **'脾气亏虚宜食甘温益气、健脾和胃之品，忌食寒凉生冷及难消化食物。'**
  String get reportAdviceDietIntro;

  /// No description provided for @reportAdviceDietRecommendedTitle.
  ///
  /// In zh, this message translates to:
  /// **'宜食'**
  String get reportAdviceDietRecommendedTitle;

  /// No description provided for @reportAdviceDietAvoidTitle.
  ///
  /// In zh, this message translates to:
  /// **'忌食'**
  String get reportAdviceDietAvoidTitle;

  /// No description provided for @reportAdviceDietRecipeTitle.
  ///
  /// In zh, this message translates to:
  /// **'推荐食谱'**
  String get reportAdviceDietRecipeTitle;

  /// No description provided for @reportAdviceDietRecipeBody.
  ///
  /// In zh, this message translates to:
  /// **'山药薏仁粥：山药50g、薏仁30g、红枣5颗同煮，早餐食用，健脾益气效果显著。\n\n党参茯苓炖鸡：补中益气，适合气虚体质日常调养。'**
  String get reportAdviceDietRecipeBody;

  /// No description provided for @reportAdviceFoodShanyao.
  ///
  /// In zh, this message translates to:
  /// **'山药'**
  String get reportAdviceFoodShanyao;

  /// No description provided for @reportAdviceFoodShanyaoDesc.
  ///
  /// In zh, this message translates to:
  /// **'健脾益肾，补气养阴'**
  String get reportAdviceFoodShanyaoDesc;

  /// No description provided for @reportAdviceFoodYiyiren.
  ///
  /// In zh, this message translates to:
  /// **'薏仁'**
  String get reportAdviceFoodYiyiren;

  /// No description provided for @reportAdviceFoodYiyirenDesc.
  ///
  /// In zh, this message translates to:
  /// **'利水渗湿，健脾止泻'**
  String get reportAdviceFoodYiyirenDesc;

  /// No description provided for @reportAdviceFoodHongzao.
  ///
  /// In zh, this message translates to:
  /// **'红枣'**
  String get reportAdviceFoodHongzao;

  /// No description provided for @reportAdviceFoodHongzaoDesc.
  ///
  /// In zh, this message translates to:
  /// **'补气血，健脾胃，安神'**
  String get reportAdviceFoodHongzaoDesc;

  /// No description provided for @reportAdviceFoodBiandou.
  ///
  /// In zh, this message translates to:
  /// **'白扁豆'**
  String get reportAdviceFoodBiandou;

  /// No description provided for @reportAdviceFoodBiandouDesc.
  ///
  /// In zh, this message translates to:
  /// **'健脾化湿，消暑除烦'**
  String get reportAdviceFoodBiandouDesc;

  /// No description provided for @reportAdviceFoodDangshen.
  ///
  /// In zh, this message translates to:
  /// **'党参'**
  String get reportAdviceFoodDangshen;

  /// No description provided for @reportAdviceFoodDangshenDesc.
  ///
  /// In zh, this message translates to:
  /// **'补中益气，健脾养胃'**
  String get reportAdviceFoodDangshenDesc;

  /// No description provided for @reportAdviceFoodFuling.
  ///
  /// In zh, this message translates to:
  /// **'茯苓'**
  String get reportAdviceFoodFuling;

  /// No description provided for @reportAdviceFoodFulingDesc.
  ///
  /// In zh, this message translates to:
  /// **'健脾和中，利水渗湿'**
  String get reportAdviceFoodFulingDesc;

  /// No description provided for @reportAdviceAvoidColdFood.
  ///
  /// In zh, this message translates to:
  /// **'生冷食物'**
  String get reportAdviceAvoidColdFood;

  /// No description provided for @reportAdviceAvoidGreasy.
  ///
  /// In zh, this message translates to:
  /// **'油腻厚味'**
  String get reportAdviceAvoidGreasy;

  /// No description provided for @reportAdviceAvoidSpicy.
  ///
  /// In zh, this message translates to:
  /// **'辛辣刺激'**
  String get reportAdviceAvoidSpicy;

  /// No description provided for @reportAdviceAvoidSweet.
  ///
  /// In zh, this message translates to:
  /// **'甜腻之品'**
  String get reportAdviceAvoidSweet;

  /// No description provided for @reportAdviceAvoidAlcohol.
  ///
  /// In zh, this message translates to:
  /// **'烟酒'**
  String get reportAdviceAvoidAlcohol;

  /// No description provided for @reportAdviceProjectsTitle.
  ///
  /// In zh, this message translates to:
  /// **'服务项目推荐'**
  String get reportAdviceProjectsTitle;

  /// No description provided for @reportAdviceProjectsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'依据报告结果推荐可到店咨询的调理项目'**
  String get reportAdviceProjectsSubtitle;

  /// No description provided for @reportAdviceProjectsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'当前暂无匹配的服务项目推荐。'**
  String get reportAdviceProjectsEmpty;

  /// No description provided for @reportAdviceProjectsDisclaimer.
  ///
  /// In zh, this message translates to:
  /// **'以上服务项目推荐基于体质分析结果，仅供参考。实际服务内容与预约安排以门店说明为准。'**
  String get reportAdviceProjectsDisclaimer;

  /// No description provided for @reportAdviceProjectDetailButton.
  ///
  /// In zh, this message translates to:
  /// **'查看项目 >'**
  String get reportAdviceProjectDetailButton;

  /// No description provided for @reportAdviceProductsTitle.
  ///
  /// In zh, this message translates to:
  /// **'推荐商品'**
  String get reportAdviceProductsTitle;

  /// No description provided for @reportAdviceProductsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'依据报告结果推荐可配送商品'**
  String get reportAdviceProductsSubtitle;

  /// No description provided for @reportAdviceProductsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'当前暂无匹配的商品推荐。'**
  String get reportAdviceProductsEmpty;

  /// No description provided for @reportAdviceProductsDisclaimer.
  ///
  /// In zh, this message translates to:
  /// **'以上商品推荐基于体质分析结果，仅供参考。实际库存、规格与配送范围以门店说明为准。'**
  String get reportAdviceProductsDisclaimer;

  /// No description provided for @reportProductCommonShipping.
  ///
  /// In zh, this message translates to:
  /// **'工作日 48 小时内安排发货，支持全程物流追踪。'**
  String get reportProductCommonShipping;

  /// No description provided for @reportProjectCommonServiceNote.
  ///
  /// In zh, this message translates to:
  /// **'需由门店评估后安排具体服务内容。'**
  String get reportProjectCommonServiceNote;

  /// No description provided for @reportProjectCommonConsultNote.
  ///
  /// In zh, this message translates to:
  /// **'支持到店咨询与预约，实际排期以门店安排为准。'**
  String get reportProjectCommonConsultNote;

  /// No description provided for @reportProjectWarmMoxibustion.
  ///
  /// In zh, this message translates to:
  /// **'温养艾灸调理'**
  String get reportProjectWarmMoxibustion;

  /// No description provided for @reportProjectWarmMoxibustionType.
  ///
  /// In zh, this message translates to:
  /// **'到店温补项目'**
  String get reportProjectWarmMoxibustionType;

  /// No description provided for @reportProjectWarmMoxibustionDesc.
  ///
  /// In zh, this message translates to:
  /// **'结合报告中的寒湿与气虚倾向，优先推荐温和艾灸与局部温养护理。'**
  String get reportProjectWarmMoxibustionDesc;

  /// No description provided for @reportProjectWarmMoxibustionTag.
  ///
  /// In zh, this message translates to:
  /// **'门店推荐'**
  String get reportProjectWarmMoxibustionTag;

  /// No description provided for @reportProjectWarmMoxibustionDuration.
  ///
  /// In zh, this message translates to:
  /// **'单次约 45 分钟'**
  String get reportProjectWarmMoxibustionDuration;

  /// No description provided for @reportProjectMeridianRelief.
  ///
  /// In zh, this message translates to:
  /// **'经络舒缓护理'**
  String get reportProjectMeridianRelief;

  /// No description provided for @reportProjectMeridianReliefType.
  ///
  /// In zh, this message translates to:
  /// **'经络调理项目'**
  String get reportProjectMeridianReliefType;

  /// No description provided for @reportProjectMeridianReliefDesc.
  ///
  /// In zh, this message translates to:
  /// **'围绕疲劳、睡眠与气血运行问题，安排舒缓型经络调理与放松护理。'**
  String get reportProjectMeridianReliefDesc;

  /// No description provided for @reportProjectMeridianReliefTag.
  ///
  /// In zh, this message translates to:
  /// **'适合初次体验'**
  String get reportProjectMeridianReliefTag;

  /// No description provided for @reportProjectMeridianReliefDuration.
  ///
  /// In zh, this message translates to:
  /// **'单次约 60 分钟'**
  String get reportProjectMeridianReliefDuration;

  /// No description provided for @reportProductJianpiwanPack.
  ///
  /// In zh, this message translates to:
  /// **'1 瓶装 / 200 丸，适合日常脾胃调理周期使用。'**
  String get reportProductJianpiwanPack;

  /// No description provided for @reportProductShenlingPack.
  ///
  /// In zh, this message translates to:
  /// **'10 袋装 / 盒，适合日常轻养脾胃与补气调护。'**
  String get reportProductShenlingPack;

  /// No description provided for @reportProductAijiuPack.
  ///
  /// In zh, this message translates to:
  /// **'20 贴装 / 盒，适合居家温和艾灸护理。'**
  String get reportProductAijiuPack;

  /// No description provided for @reportProductFoodPackPack.
  ///
  /// In zh, this message translates to:
  /// **'7 日食养组合包，含山药、薏仁、茯苓等食养食材。'**
  String get reportProductFoodPackPack;

  /// No description provided for @reportProductDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'商品详情'**
  String get reportProductDetailTitle;

  /// No description provided for @reportProductDetailHeroBadge.
  ///
  /// In zh, this message translates to:
  /// **'报告关联推荐'**
  String get reportProductDetailHeroBadge;

  /// No description provided for @reportProductDetailRecommendationTitle.
  ///
  /// In zh, this message translates to:
  /// **'推荐理由'**
  String get reportProductDetailRecommendationTitle;

  /// No description provided for @reportProductDetailPackageTitle.
  ///
  /// In zh, this message translates to:
  /// **'包装与规格'**
  String get reportProductDetailPackageTitle;

  /// No description provided for @reportProductDetailShippingTitle.
  ///
  /// In zh, this message translates to:
  /// **'配送说明'**
  String get reportProductDetailShippingTitle;

  /// No description provided for @reportProductDetailServiceTitle.
  ///
  /// In zh, this message translates to:
  /// **'服务说明'**
  String get reportProductDetailServiceTitle;

  /// No description provided for @reportProductDetailServiceBody.
  ///
  /// In zh, this message translates to:
  /// **'当前为推荐商品展示与演示下单流程，后续可接入真实订单系统与 Apple Pay / Google Pay。'**
  String get reportProductDetailServiceBody;

  /// No description provided for @reportProductDetailQuantityTitle.
  ///
  /// In zh, this message translates to:
  /// **'购买数量'**
  String get reportProductDetailQuantityTitle;

  /// No description provided for @reportProductDetailQuantitySummary.
  ///
  /// In zh, this message translates to:
  /// **'已选择 {count} 件'**
  String reportProductDetailQuantitySummary(int count);

  /// No description provided for @reportProductDetailFinalPrice.
  ///
  /// In zh, this message translates to:
  /// **'到手参考价'**
  String get reportProductDetailFinalPrice;

  /// No description provided for @reportProductDetailCheckoutButton.
  ///
  /// In zh, this message translates to:
  /// **'进入结算'**
  String get reportProductDetailCheckoutButton;

  /// No description provided for @reportProductDetailReportLinked.
  ///
  /// In zh, this message translates to:
  /// **'与报告建议联动'**
  String get reportProductDetailReportLinked;

  /// No description provided for @reportProjectDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'项目详情'**
  String get reportProjectDetailTitle;

  /// No description provided for @reportProjectDetailHeroBadge.
  ///
  /// In zh, this message translates to:
  /// **'报告关联项目'**
  String get reportProjectDetailHeroBadge;

  /// No description provided for @reportProjectDetailRecommendationTitle.
  ///
  /// In zh, this message translates to:
  /// **'推荐理由'**
  String get reportProjectDetailRecommendationTitle;

  /// No description provided for @reportProjectDetailDurationTitle.
  ///
  /// In zh, this message translates to:
  /// **'服务时长'**
  String get reportProjectDetailDurationTitle;

  /// No description provided for @reportProjectDetailServiceTitle.
  ///
  /// In zh, this message translates to:
  /// **'服务说明'**
  String get reportProjectDetailServiceTitle;

  /// No description provided for @reportProjectDetailConsultTitle.
  ///
  /// In zh, this message translates to:
  /// **'咨询与预约'**
  String get reportProjectDetailConsultTitle;

  /// No description provided for @reportProjectDetailActionButton.
  ///
  /// In zh, this message translates to:
  /// **'预约咨询'**
  String get reportProjectDetailActionButton;

  /// No description provided for @reportProjectDetailReportLinked.
  ///
  /// In zh, this message translates to:
  /// **'与报告建议联动'**
  String get reportProjectDetailReportLinked;

  /// No description provided for @reportProductCheckoutTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认订单'**
  String get reportProductCheckoutTitle;

  /// No description provided for @reportProductCheckoutSectionAddress.
  ///
  /// In zh, this message translates to:
  /// **'收货信息'**
  String get reportProductCheckoutSectionAddress;

  /// No description provided for @reportProductCheckoutRecipient.
  ///
  /// In zh, this message translates to:
  /// **'收货人'**
  String get reportProductCheckoutRecipient;

  /// No description provided for @reportProductCheckoutPhone.
  ///
  /// In zh, this message translates to:
  /// **'联系电话'**
  String get reportProductCheckoutPhone;

  /// No description provided for @reportProductCheckoutAddress.
  ///
  /// In zh, this message translates to:
  /// **'收货地址'**
  String get reportProductCheckoutAddress;

  /// No description provided for @reportProductCheckoutOrderSummary.
  ///
  /// In zh, this message translates to:
  /// **'订单明细'**
  String get reportProductCheckoutOrderSummary;

  /// No description provided for @reportProductCheckoutQuantityLabel.
  ///
  /// In zh, this message translates to:
  /// **'数量'**
  String get reportProductCheckoutQuantityLabel;

  /// No description provided for @reportProductCheckoutSubtotal.
  ///
  /// In zh, this message translates to:
  /// **'商品小计'**
  String get reportProductCheckoutSubtotal;

  /// No description provided for @reportProductCheckoutShippingFee.
  ///
  /// In zh, this message translates to:
  /// **'配送费'**
  String get reportProductCheckoutShippingFee;

  /// No description provided for @reportProductCheckoutServiceFee.
  ///
  /// In zh, this message translates to:
  /// **'服务费'**
  String get reportProductCheckoutServiceFee;

  /// No description provided for @reportProductCheckoutTotal.
  ///
  /// In zh, this message translates to:
  /// **'合计'**
  String get reportProductCheckoutTotal;

  /// No description provided for @reportProductCheckoutPaymentTitle.
  ///
  /// In zh, this message translates to:
  /// **'支付方式'**
  String get reportProductCheckoutPaymentTitle;

  /// No description provided for @reportProductCheckoutApplePayTitle.
  ///
  /// In zh, this message translates to:
  /// **'Apple Pay'**
  String get reportProductCheckoutApplePayTitle;

  /// No description provided for @reportProductCheckoutApplePaySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'预留 Apple Pay 接入位，后续接真实商户能力。'**
  String get reportProductCheckoutApplePaySubtitle;

  /// No description provided for @reportProductCheckoutApplePayDialogBody.
  ///
  /// In zh, this message translates to:
  /// **'当前版本尚未接入真实 Apple Pay。现在点击仅用于说明未来支付入口位置，建议继续使用演示下单流程联调页面。'**
  String get reportProductCheckoutApplePayDialogBody;

  /// No description provided for @reportProductCheckoutGooglePayTitle.
  ///
  /// In zh, this message translates to:
  /// **'Google Pay'**
  String get reportProductCheckoutGooglePayTitle;

  /// No description provided for @reportProductCheckoutGooglePaySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'预留 Google Pay 接入位，后续接真实支付能力。'**
  String get reportProductCheckoutGooglePaySubtitle;

  /// No description provided for @reportProductCheckoutGooglePayDialogBody.
  ///
  /// In zh, this message translates to:
  /// **'当前版本尚未接入真实 Google Pay。现在点击仅用于说明未来支付入口位置，建议继续使用演示下单流程联调页面。'**
  String get reportProductCheckoutGooglePayDialogBody;

  /// No description provided for @reportProductCheckoutMockSubmit.
  ///
  /// In zh, this message translates to:
  /// **'创建演示订单'**
  String get reportProductCheckoutMockSubmit;

  /// No description provided for @reportProductCheckoutSubmitting.
  ///
  /// In zh, this message translates to:
  /// **'正在创建订单…'**
  String get reportProductCheckoutSubmitting;

  /// No description provided for @reportProductCheckoutSuccessTitle.
  ///
  /// In zh, this message translates to:
  /// **'演示订单已创建'**
  String get reportProductCheckoutSuccessTitle;

  /// No description provided for @reportProductCheckoutSuccessBody.
  ///
  /// In zh, this message translates to:
  /// **'当前仅完成前端订单流程演示，后续接入真实下单与 Apple Pay / Google Pay 后会替换为正式支付链路。'**
  String get reportProductCheckoutSuccessBody;

  /// No description provided for @reportUnlockTitle.
  ///
  /// In zh, this message translates to:
  /// **'解锁完整报告'**
  String get reportUnlockTitle;

  /// No description provided for @reportUnlockDescription.
  ///
  /// In zh, this message translates to:
  /// **'查看完整体质分析、调理方案与个性化建议。'**
  String get reportUnlockDescription;

  /// No description provided for @reportUnlockButton.
  ///
  /// In zh, this message translates to:
  /// **'解锁报告'**
  String get reportUnlockButton;

  /// No description provided for @reportUnlockSheetTitle.
  ///
  /// In zh, this message translates to:
  /// **'解锁完整报告'**
  String get reportUnlockSheetTitle;

  /// No description provided for @reportUnlockSheetBody.
  ///
  /// In zh, this message translates to:
  /// **'解锁后可查看体质详解、调理方案和个性化建议的全部内容。'**
  String get reportUnlockSheetBody;

  /// No description provided for @reportUnlockInvitationTag.
  ///
  /// In zh, this message translates to:
  /// **'尊享深度健康解读'**
  String get reportUnlockInvitationTag;

  /// No description provided for @reportUnlockInvitationSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'开启完整报告后，可继续查看更细致的体质洞察、调理路径与个性化养护建议。'**
  String get reportUnlockInvitationSubtitle;

  /// No description provided for @reportUnlockBenefitConstitution.
  ///
  /// In zh, this message translates to:
  /// **'完整查看体质成因、风险倾向与深度解读'**
  String get reportUnlockBenefitConstitution;

  /// No description provided for @reportUnlockBenefitTherapy.
  ///
  /// In zh, this message translates to:
  /// **'获得专属穴位方案、精神养生与四季调理建议'**
  String get reportUnlockBenefitTherapy;

  /// No description provided for @reportUnlockBenefitAdvice.
  ///
  /// In zh, this message translates to:
  /// **'解锁舌象详解、饮食方向与相关产品推荐'**
  String get reportUnlockBenefitAdvice;

  /// No description provided for @reportUnlockSheetPrice.
  ///
  /// In zh, this message translates to:
  /// **'模拟价格：¥29.90'**
  String get reportUnlockSheetPrice;

  /// No description provided for @reportUnlockSheetPriceFallback.
  ///
  /// In zh, this message translates to:
  /// **'App Store 价格加载中'**
  String get reportUnlockSheetPriceFallback;

  /// No description provided for @reportUnlockSheetConfirm.
  ///
  /// In zh, this message translates to:
  /// **'通过 Apple IAP 解锁'**
  String get reportUnlockSheetConfirm;

  /// No description provided for @reportUnlockSheetPurchasing.
  ///
  /// In zh, this message translates to:
  /// **'正在发起购买…'**
  String get reportUnlockSheetPurchasing;

  /// No description provided for @reportUnlockSheetRestoring.
  ///
  /// In zh, this message translates to:
  /// **'正在恢复购买…'**
  String get reportUnlockSheetRestoring;

  /// No description provided for @reportUnlockRestoreButton.
  ///
  /// In zh, this message translates to:
  /// **'恢复购买'**
  String get reportUnlockRestoreButton;

  /// No description provided for @reportUnlockSheetStoreHint.
  ///
  /// In zh, this message translates to:
  /// **'通过 Apple App Store 安全支付，支持恢复非消耗型购买。'**
  String get reportUnlockSheetStoreHint;

  /// No description provided for @reportUnlockStatusStoreUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'当前无法连接 App Store，请联网后重试。'**
  String get reportUnlockStatusStoreUnavailable;

  /// No description provided for @reportUnlockStatusProductUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'暂未获取到可售商品，请检查商品 ID 或稍后重试。'**
  String get reportUnlockStatusProductUnavailable;

  /// No description provided for @reportUnlockStatusPurchaseFailed.
  ///
  /// In zh, this message translates to:
  /// **'购买未完成，请稍后重试。'**
  String get reportUnlockStatusPurchaseFailed;

  /// No description provided for @reportUnlockStatusPurchaseCancelled.
  ///
  /// In zh, this message translates to:
  /// **'你已取消本次购买。'**
  String get reportUnlockStatusPurchaseCancelled;

  /// No description provided for @reportUnlockStatusRestoreNotFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到可恢复的购买记录。'**
  String get reportUnlockStatusRestoreNotFound;

  /// No description provided for @reportUnlockStatusPurchasing.
  ///
  /// In zh, this message translates to:
  /// **'等待 App Store 返回购买结果。'**
  String get reportUnlockStatusPurchasing;

  /// No description provided for @reportUnlockStatusRestoring.
  ///
  /// In zh, this message translates to:
  /// **'正在从 App Store 恢复已购记录。'**
  String get reportUnlockStatusRestoring;

  /// No description provided for @reportUnlockSheetMockHint.
  ///
  /// In zh, this message translates to:
  /// **'当前为本地模拟购买流程，后续可替换为 Apple IAP。'**
  String get reportUnlockSheetMockHint;

  /// No description provided for @reportUnlockCausalAnalysisTitle.
  ///
  /// In zh, this message translates to:
  /// **'解锁成因深度分析'**
  String get reportUnlockCausalAnalysisTitle;

  /// No description provided for @reportUnlockCausalAnalysisSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'查看体质成因与关键诱因。'**
  String get reportUnlockCausalAnalysisSubtitle;

  /// No description provided for @reportUnlockDiseaseTendencyTitle.
  ///
  /// In zh, this message translates to:
  /// **'解锁疾病倾向预警'**
  String get reportUnlockDiseaseTendencyTitle;

  /// No description provided for @reportUnlockDiseaseTendencySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'查看易发问题与预警重点。'**
  String get reportUnlockDiseaseTendencySubtitle;

  /// No description provided for @reportUnlockBadHabitsTitle.
  ///
  /// In zh, this message translates to:
  /// **'解锁不当行为提示'**
  String get reportUnlockBadHabitsTitle;

  /// No description provided for @reportUnlockBadHabitsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'查看需要调整的日常习惯。'**
  String get reportUnlockBadHabitsSubtitle;

  /// No description provided for @reportUnlockAcupuncturePointsTitle.
  ///
  /// In zh, this message translates to:
  /// **'解锁专属穴位方案'**
  String get reportUnlockAcupuncturePointsTitle;

  /// No description provided for @reportUnlockAcupuncturePointsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'查看专属穴位与调理重点。'**
  String get reportUnlockAcupuncturePointsSubtitle;

  /// No description provided for @reportUnlockMentalWellnessTitle.
  ///
  /// In zh, this message translates to:
  /// **'解锁精神养生建议'**
  String get reportUnlockMentalWellnessTitle;

  /// No description provided for @reportUnlockMentalWellnessSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'查看情绪调养与舒缓建议。'**
  String get reportUnlockMentalWellnessSubtitle;

  /// No description provided for @reportUnlockSeasonalCareTitle.
  ///
  /// In zh, this message translates to:
  /// **'解锁四季养生方案'**
  String get reportUnlockSeasonalCareTitle;

  /// No description provided for @reportSeasonalCareCurrentTitle.
  ///
  /// In zh, this message translates to:
  /// **'当前节气：{solarTerm}'**
  String reportSeasonalCareCurrentTitle(String solarTerm);

  /// No description provided for @reportSeasonalCareCurrentSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'已为你定位当前时令，可优先查看对应养护建议。'**
  String get reportSeasonalCareCurrentSubtitle;

  /// No description provided for @reportUnlockSeasonalCareSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'查看本季作息与养护重点。'**
  String get reportUnlockSeasonalCareSubtitle;

  /// No description provided for @reportUnlockTongueAnalysisTitle.
  ///
  /// In zh, this message translates to:
  /// **'解锁舌象详细解读'**
  String get reportUnlockTongueAnalysisTitle;

  /// No description provided for @reportUnlockTongueAnalysisSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'查看舌象评分与细项解读。'**
  String get reportUnlockTongueAnalysisSubtitle;

  /// No description provided for @reportUnlockDietAdviceTitle.
  ///
  /// In zh, this message translates to:
  /// **'解锁个性化饮食方案'**
  String get reportUnlockDietAdviceTitle;

  /// No description provided for @reportUnlockDietAdviceSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'查看适宜食材与饮食方向。'**
  String get reportUnlockDietAdviceSubtitle;

  /// No description provided for @reportPremiumConstitutionSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'查看体质成因、风险倾向与完整分析。'**
  String get reportPremiumConstitutionSubtitle;

  /// No description provided for @reportPremiumConstitutionPreview1.
  ///
  /// In zh, this message translates to:
  /// **'主偏向：气虚质'**
  String get reportPremiumConstitutionPreview1;

  /// No description provided for @reportPremiumConstitutionPreview2.
  ///
  /// In zh, this message translates to:
  /// **'可解锁完整体质与风险趋势解读'**
  String get reportPremiumConstitutionPreview2;

  /// No description provided for @reportPremiumTherapySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'查看专属穴位、精神养生与四季调理建议。'**
  String get reportPremiumTherapySubtitle;

  /// No description provided for @reportPremiumTherapyPreview1.
  ///
  /// In zh, this message translates to:
  /// **'推荐重点：足三里 · 气海'**
  String get reportPremiumTherapyPreview1;

  /// No description provided for @reportPremiumTherapyPreview2.
  ///
  /// In zh, this message translates to:
  /// **'可解锁完整调理路径与执行建议'**
  String get reportPremiumTherapyPreview2;

  /// No description provided for @reportPremiumAdviceSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'查看食疗方案、舌象详解与产品建议。'**
  String get reportPremiumAdviceSubtitle;

  /// No description provided for @reportPremiumAdvicePreview1.
  ///
  /// In zh, this message translates to:
  /// **'饮食方向：健脾祛湿'**
  String get reportPremiumAdvicePreview1;

  /// No description provided for @reportPremiumAdvicePreview2.
  ///
  /// In zh, this message translates to:
  /// **'可解锁完整食疗、舌象与产品内容'**
  String get reportPremiumAdvicePreview2;

  /// No description provided for @reportProductJianpiwan.
  ///
  /// In zh, this message translates to:
  /// **'健脾益气丸'**
  String get reportProductJianpiwan;

  /// No description provided for @reportProductJianpiwanType.
  ///
  /// In zh, this message translates to:
  /// **'中成药'**
  String get reportProductJianpiwanType;

  /// No description provided for @reportProductJianpiwanDesc.
  ///
  /// In zh, this message translates to:
  /// **'补中益气，健脾和胃。适合气虚体质，改善乏力、食欲不振。'**
  String get reportProductJianpiwanDesc;

  /// No description provided for @reportProductJianpiwanTag.
  ///
  /// In zh, this message translates to:
  /// **'热销'**
  String get reportProductJianpiwanTag;

  /// No description provided for @reportProductShenling.
  ///
  /// In zh, this message translates to:
  /// **'参苓白术散'**
  String get reportProductShenling;

  /// No description provided for @reportProductShenlingType.
  ///
  /// In zh, this message translates to:
  /// **'传统方剂'**
  String get reportProductShenlingType;

  /// No description provided for @reportProductShenlingDesc.
  ///
  /// In zh, this message translates to:
  /// **'健脾益气，渗湿止泻。主治脾气虚弱，食少便溏，体倦乏力。'**
  String get reportProductShenlingDesc;

  /// No description provided for @reportProductShenlingTag.
  ///
  /// In zh, this message translates to:
  /// **'经典'**
  String get reportProductShenlingTag;

  /// No description provided for @reportProductAijiu.
  ///
  /// In zh, this message translates to:
  /// **'艾灸套装'**
  String get reportProductAijiu;

  /// No description provided for @reportProductAijiuType.
  ///
  /// In zh, this message translates to:
  /// **'调理器具'**
  String get reportProductAijiuType;

  /// No description provided for @reportProductAijiuDesc.
  ///
  /// In zh, this message translates to:
  /// **'温和艾条配合取穴定位图，居家艾灸足三里、气海、关元。'**
  String get reportProductAijiuDesc;

  /// No description provided for @reportProductAijiuTag.
  ///
  /// In zh, this message translates to:
  /// **'推荐'**
  String get reportProductAijiuTag;

  /// No description provided for @reportProductFoodPack.
  ///
  /// In zh, this message translates to:
  /// **'中医食疗食材包'**
  String get reportProductFoodPack;

  /// No description provided for @reportProductFoodPackType.
  ///
  /// In zh, this message translates to:
  /// **'养生食材'**
  String get reportProductFoodPackType;

  /// No description provided for @reportProductFoodPackDesc.
  ///
  /// In zh, this message translates to:
  /// **'山药、薏仁、党参、茯苓、红枣精选组合，一周食疗方案。'**
  String get reportProductFoodPackDesc;

  /// No description provided for @reportProductFoodPackTag.
  ///
  /// In zh, this message translates to:
  /// **'新品'**
  String get reportProductFoodPackTag;

  /// No description provided for @reportWuxingWood.
  ///
  /// In zh, this message translates to:
  /// **'木'**
  String get reportWuxingWood;

  /// No description provided for @reportWuxingFire.
  ///
  /// In zh, this message translates to:
  /// **'火'**
  String get reportWuxingFire;

  /// No description provided for @reportWuxingEarth.
  ///
  /// In zh, this message translates to:
  /// **'土'**
  String get reportWuxingEarth;

  /// No description provided for @reportWuxingMetal.
  ///
  /// In zh, this message translates to:
  /// **'金'**
  String get reportWuxingMetal;

  /// No description provided for @reportWuxingWater.
  ///
  /// In zh, this message translates to:
  /// **'水'**
  String get reportWuxingWater;

  /// No description provided for @reportAdviceProductDetailButton.
  ///
  /// In zh, this message translates to:
  /// **'查看商品 >'**
  String get reportAdviceProductDetailButton;

  /// No description provided for @metricFaceDiagnosis.
  ///
  /// In zh, this message translates to:
  /// **'面诊'**
  String get metricFaceDiagnosis;

  /// No description provided for @metricTongueDiagnosis.
  ///
  /// In zh, this message translates to:
  /// **'舌诊'**
  String get metricTongueDiagnosis;

  /// No description provided for @metricPalmDiagnosis.
  ///
  /// In zh, this message translates to:
  /// **'掌诊'**
  String get metricPalmDiagnosis;

  /// No description provided for @scanGuideTitle.
  ///
  /// In zh, this message translates to:
  /// **'AI 望诊入口'**
  String get scanGuideTitle;

  /// No description provided for @constitutionBalanced.
  ///
  /// In zh, this message translates to:
  /// **'平和质'**
  String get constitutionBalanced;

  /// No description provided for @constitutionQiDeficiency.
  ///
  /// In zh, this message translates to:
  /// **'气虚质'**
  String get constitutionQiDeficiency;

  /// No description provided for @constitutionDampness.
  ///
  /// In zh, this message translates to:
  /// **'痰湿质'**
  String get constitutionDampness;

  /// No description provided for @riskSpleenStomach.
  ///
  /// In zh, this message translates to:
  /// **'脾胃'**
  String get riskSpleenStomach;

  /// No description provided for @riskQiDeficiency.
  ///
  /// In zh, this message translates to:
  /// **'气虚'**
  String get riskQiDeficiency;

  /// No description provided for @riskDampness.
  ///
  /// In zh, this message translates to:
  /// **'湿困'**
  String get riskDampness;

  /// No description provided for @daysAgo.
  ///
  /// In zh, this message translates to:
  /// **'{days}天前'**
  String daysAgo(int days);

  /// No description provided for @scoreWithUnit.
  ///
  /// In zh, this message translates to:
  /// **'{score}分'**
  String scoreWithUnit(num score);

  /// No description provided for @percentValue.
  ///
  /// In zh, this message translates to:
  /// **'{value}%'**
  String percentValue(num value);

  /// No description provided for @reportConstitutionPhlegmDampness.
  ///
  /// In zh, this message translates to:
  /// **'痰湿质'**
  String get reportConstitutionPhlegmDampness;

  /// No description provided for @reportConstitutionInheritedSpecial.
  ///
  /// In zh, this message translates to:
  /// **'特禀质'**
  String get reportConstitutionInheritedSpecial;

  /// No description provided for @reportConstitutionCausalTitle.
  ///
  /// In zh, this message translates to:
  /// **'分析成因'**
  String get reportConstitutionCausalTitle;

  /// No description provided for @reportConstitutionCauseRoutineTitle.
  ///
  /// In zh, this message translates to:
  /// **'作息'**
  String get reportConstitutionCauseRoutineTitle;

  /// No description provided for @reportConstitutionCauseRoutineDesc.
  ///
  /// In zh, this message translates to:
  /// **'长期晚睡，子时未眠，伤及肝肾精气，导致气血生化不足。'**
  String get reportConstitutionCauseRoutineDesc;

  /// No description provided for @reportConstitutionCauseDietTitle.
  ///
  /// In zh, this message translates to:
  /// **'饮食'**
  String get reportConstitutionCauseDietTitle;

  /// No description provided for @reportConstitutionCauseDietDesc.
  ///
  /// In zh, this message translates to:
  /// **'饮食偏凉，过食生冷，寒邪损伤脾阳，运化功能减退。'**
  String get reportConstitutionCauseDietDesc;

  /// No description provided for @reportConstitutionCauseEmotionTitle.
  ///
  /// In zh, this message translates to:
  /// **'情志'**
  String get reportConstitutionCauseEmotionTitle;

  /// No description provided for @reportConstitutionCauseEmotionDesc.
  ///
  /// In zh, this message translates to:
  /// **'思虑过度，忧思伤脾，气机郁结，运化失司。'**
  String get reportConstitutionCauseEmotionDesc;

  /// No description provided for @reportConstitutionCauseExerciseTitle.
  ///
  /// In zh, this message translates to:
  /// **'运动'**
  String get reportConstitutionCauseExerciseTitle;

  /// No description provided for @reportConstitutionCauseExerciseDesc.
  ///
  /// In zh, this message translates to:
  /// **'久坐少动，气血运行不畅，中气渐虚。'**
  String get reportConstitutionCauseExerciseDesc;

  /// No description provided for @reportConstitutionDiseaseTitle.
  ///
  /// In zh, this message translates to:
  /// **'易诱发的疾病'**
  String get reportConstitutionDiseaseTitle;

  /// No description provided for @reportConstitutionDiseaseSpleenWeakTitle.
  ///
  /// In zh, this message translates to:
  /// **'脾胃虚弱'**
  String get reportConstitutionDiseaseSpleenWeakTitle;

  /// No description provided for @reportConstitutionDiseaseSpleenWeakDesc.
  ///
  /// In zh, this message translates to:
  /// **'消化不良、腹胀、便溏'**
  String get reportConstitutionDiseaseSpleenWeakDesc;

  /// No description provided for @reportConstitutionDiseaseQiBloodTitle.
  ///
  /// In zh, this message translates to:
  /// **'气血亏虚'**
  String get reportConstitutionDiseaseQiBloodTitle;

  /// No description provided for @reportConstitutionDiseaseQiBloodDesc.
  ///
  /// In zh, this message translates to:
  /// **'头晕、乏力、面色萎黄'**
  String get reportConstitutionDiseaseQiBloodDesc;

  /// No description provided for @reportConstitutionDiseaseLowImmunityTitle.
  ///
  /// In zh, this message translates to:
  /// **'免疫低下'**
  String get reportConstitutionDiseaseLowImmunityTitle;

  /// No description provided for @reportConstitutionDiseaseLowImmunityDesc.
  ///
  /// In zh, this message translates to:
  /// **'反复感冒、易疲劳'**
  String get reportConstitutionDiseaseLowImmunityDesc;

  /// No description provided for @reportConstitutionDiseaseEmotionTitle.
  ///
  /// In zh, this message translates to:
  /// **'情志疾患'**
  String get reportConstitutionDiseaseEmotionTitle;

  /// No description provided for @reportConstitutionDiseaseEmotionDesc.
  ///
  /// In zh, this message translates to:
  /// **'焦虑、失眠、抑郁倾向'**
  String get reportConstitutionDiseaseEmotionDesc;

  /// No description provided for @reportConstitutionBadHabitsTitle.
  ///
  /// In zh, this message translates to:
  /// **'不当的举动'**
  String get reportConstitutionBadHabitsTitle;

  /// No description provided for @reportConstitutionHabitOverworkTitle.
  ///
  /// In zh, this message translates to:
  /// **'过度劳累'**
  String get reportConstitutionHabitOverworkTitle;

  /// No description provided for @reportConstitutionHabitOverworkDesc.
  ///
  /// In zh, this message translates to:
  /// **'耗气伤脾，加重气虚'**
  String get reportConstitutionHabitOverworkDesc;

  /// No description provided for @reportConstitutionHabitColdFoodTitle.
  ///
  /// In zh, this message translates to:
  /// **'贪凉饮冷'**
  String get reportConstitutionHabitColdFoodTitle;

  /// No description provided for @reportConstitutionHabitColdFoodDesc.
  ///
  /// In zh, this message translates to:
  /// **'寒邪伤阳，损伤脾胃'**
  String get reportConstitutionHabitColdFoodDesc;

  /// No description provided for @reportConstitutionHabitLateSleepTitle.
  ///
  /// In zh, this message translates to:
  /// **'熬夜晚睡'**
  String get reportConstitutionHabitLateSleepTitle;

  /// No description provided for @reportConstitutionHabitLateSleepDesc.
  ///
  /// In zh, this message translates to:
  /// **'阴气不得收敛，精气损耗'**
  String get reportConstitutionHabitLateSleepDesc;

  /// No description provided for @reportConstitutionHabitDietingTitle.
  ///
  /// In zh, this message translates to:
  /// **'过度节食'**
  String get reportConstitutionHabitDietingTitle;

  /// No description provided for @reportConstitutionHabitDietingDesc.
  ///
  /// In zh, this message translates to:
  /// **'气血生化无源，更伤中气'**
  String get reportConstitutionHabitDietingDesc;

  /// No description provided for @reportConstitutionHabitBingeTitle.
  ///
  /// In zh, this message translates to:
  /// **'暴饮暴食'**
  String get reportConstitutionHabitBingeTitle;

  /// No description provided for @reportConstitutionHabitBingeDesc.
  ///
  /// In zh, this message translates to:
  /// **'脾胃负担过重，运化失司'**
  String get reportConstitutionHabitBingeDesc;

  /// No description provided for @reportTherapyAcupointTitle.
  ///
  /// In zh, this message translates to:
  /// **'辩证取穴'**
  String get reportTherapyAcupointTitle;

  /// No description provided for @reportTherapyAcupointIntro.
  ///
  /// In zh, this message translates to:
  /// **'依据脾气亏虚证型，推荐以下穴位进行艾灸或按摩调理，每日10–15分钟。'**
  String get reportTherapyAcupointIntro;

  /// No description provided for @reportTherapyPointZusanliName.
  ///
  /// In zh, this message translates to:
  /// **'足三里'**
  String get reportTherapyPointZusanliName;

  /// No description provided for @reportTherapyPointZusanliLocation.
  ///
  /// In zh, this message translates to:
  /// **'外膝眼下3寸，胫骨旁开1横指'**
  String get reportTherapyPointZusanliLocation;

  /// No description provided for @reportTherapyPointZusanliEffect.
  ///
  /// In zh, this message translates to:
  /// **'健脾益胃、补益气血，为强壮要穴'**
  String get reportTherapyPointZusanliEffect;

  /// No description provided for @reportTherapyPointZusanliMeridian.
  ///
  /// In zh, this message translates to:
  /// **'足阳明胃经'**
  String get reportTherapyPointZusanliMeridian;

  /// No description provided for @reportTherapyPointPishuName.
  ///
  /// In zh, this message translates to:
  /// **'脾俞'**
  String get reportTherapyPointPishuName;

  /// No description provided for @reportTherapyPointPishuLocation.
  ///
  /// In zh, this message translates to:
  /// **'第11胸椎棘突下旁开1.5寸'**
  String get reportTherapyPointPishuLocation;

  /// No description provided for @reportTherapyPointPishuEffect.
  ///
  /// In zh, this message translates to:
  /// **'健脾化湿、益气补虚，调节脾胃功能'**
  String get reportTherapyPointPishuEffect;

  /// No description provided for @reportTherapyPointPishuMeridian.
  ///
  /// In zh, this message translates to:
  /// **'足太阳膀胱经'**
  String get reportTherapyPointPishuMeridian;

  /// No description provided for @reportTherapyPointQihaiName.
  ///
  /// In zh, this message translates to:
  /// **'气海'**
  String get reportTherapyPointQihaiName;

  /// No description provided for @reportTherapyPointQihaiLocation.
  ///
  /// In zh, this message translates to:
  /// **'脐下1.5寸，腹正中线上'**
  String get reportTherapyPointQihaiLocation;

  /// No description provided for @reportTherapyPointQihaiEffect.
  ///
  /// In zh, this message translates to:
  /// **'补益元气、温阳固本，改善气虚乏力'**
  String get reportTherapyPointQihaiEffect;

  /// No description provided for @reportTherapyPointQihaiMeridian.
  ///
  /// In zh, this message translates to:
  /// **'任脉'**
  String get reportTherapyPointQihaiMeridian;

  /// No description provided for @reportTherapyPointGuanyuanName.
  ///
  /// In zh, this message translates to:
  /// **'关元'**
  String get reportTherapyPointGuanyuanName;

  /// No description provided for @reportTherapyPointGuanyuanLocation.
  ///
  /// In zh, this message translates to:
  /// **'脐下3寸，腹正中线上'**
  String get reportTherapyPointGuanyuanLocation;

  /// No description provided for @reportTherapyPointGuanyuanEffect.
  ///
  /// In zh, this message translates to:
  /// **'培元固本、温阳益气，增强体质'**
  String get reportTherapyPointGuanyuanEffect;

  /// No description provided for @reportTherapyPointGuanyuanMeridian.
  ///
  /// In zh, this message translates to:
  /// **'任脉'**
  String get reportTherapyPointGuanyuanMeridian;

  /// No description provided for @reportTherapyAcupointWarning.
  ///
  /// In zh, this message translates to:
  /// **'孕妇、皮肤破损处及月经期间请避免艾灸。操作时注意火候，防止烫伤。'**
  String get reportTherapyAcupointWarning;

  /// No description provided for @reportTherapyMentalTitle.
  ///
  /// In zh, this message translates to:
  /// **'精神养生'**
  String get reportTherapyMentalTitle;

  /// No description provided for @reportTherapyMentalCalmTitle.
  ///
  /// In zh, this message translates to:
  /// **'恬淡虚无'**
  String get reportTherapyMentalCalmTitle;

  /// No description provided for @reportTherapyMentalCalmDesc.
  ///
  /// In zh, this message translates to:
  /// **'减少过度思虑，保持心神宁静。中医认为“思伤脾”，思虑过度最易损耗脾气。'**
  String get reportTherapyMentalCalmDesc;

  /// No description provided for @reportTherapyMentalNatureTitle.
  ///
  /// In zh, this message translates to:
  /// **'顺应自然'**
  String get reportTherapyMentalNatureTitle;

  /// No description provided for @reportTherapyMentalNatureDesc.
  ///
  /// In zh, this message translates to:
  /// **'作息顺应昼夜节律，子时前入睡以养肝气，卯时舒展筋骨以助阳气升发。'**
  String get reportTherapyMentalNatureDesc;

  /// No description provided for @reportTherapyMentalEmotionTitle.
  ///
  /// In zh, this message translates to:
  /// **'调畅情志'**
  String get reportTherapyMentalEmotionTitle;

  /// No description provided for @reportTherapyMentalEmotionDesc.
  ///
  /// In zh, this message translates to:
  /// **'保持乐观豁达，避免情绪大起大落。适度倾诉，疏导郁结气机。'**
  String get reportTherapyMentalEmotionDesc;

  /// No description provided for @reportTherapyMentalMeditationTitle.
  ///
  /// In zh, this message translates to:
  /// **'静坐冥想'**
  String get reportTherapyMentalMeditationTitle;

  /// No description provided for @reportTherapyMentalMeditationDesc.
  ///
  /// In zh, this message translates to:
  /// **'每日静坐10分钟，专注呼吸，有助于调节脾胃气机，增强正气。'**
  String get reportTherapyMentalMeditationDesc;

  /// No description provided for @reportTherapySeasonalTitle.
  ///
  /// In zh, this message translates to:
  /// **'四季保养'**
  String get reportTherapySeasonalTitle;

  /// No description provided for @reportTherapySeasonSpringName.
  ///
  /// In zh, this message translates to:
  /// **'春'**
  String get reportTherapySeasonSpringName;

  /// No description provided for @reportTherapySeasonSpringAdvice.
  ///
  /// In zh, this message translates to:
  /// **'春季养肝，适当增酸。多食韭菜、菠菜，舒展筋骨，早起散步以助阳气升发。'**
  String get reportTherapySeasonSpringAdvice;

  /// No description provided for @reportTherapySeasonSpringAvoid.
  ///
  /// In zh, this message translates to:
  /// **'避免过度疲劳，勿食过于辛散之品'**
  String get reportTherapySeasonSpringAvoid;

  /// No description provided for @reportTherapySeasonSummerName.
  ///
  /// In zh, this message translates to:
  /// **'夏'**
  String get reportTherapySeasonSummerName;

  /// No description provided for @reportTherapySeasonSummerAdvice.
  ///
  /// In zh, this message translates to:
  /// **'夏季养心，注意清热。适当食用莲子、薏仁，午间小憩，避免大汗伤气。'**
  String get reportTherapySeasonSummerAdvice;

  /// No description provided for @reportTherapySeasonSummerAvoid.
  ///
  /// In zh, this message translates to:
  /// **'忌贪凉饮冷，忌剧烈运动大汗'**
  String get reportTherapySeasonSummerAvoid;

  /// No description provided for @reportTherapySeasonAutumnName.
  ///
  /// In zh, this message translates to:
  /// **'秋'**
  String get reportTherapySeasonAutumnName;

  /// No description provided for @reportTherapySeasonAutumnAdvice.
  ///
  /// In zh, this message translates to:
  /// **'秋季养肺，以润为主。多食梨、百合、银耳，早睡早起，收敛精气。'**
  String get reportTherapySeasonAutumnAdvice;

  /// No description provided for @reportTherapySeasonAutumnAvoid.
  ///
  /// In zh, this message translates to:
  /// **'忌过度悲忧，忌食辛辣燥烈之品'**
  String get reportTherapySeasonAutumnAvoid;

  /// No description provided for @reportTherapySeasonWinterName.
  ///
  /// In zh, this message translates to:
  /// **'冬'**
  String get reportTherapySeasonWinterName;

  /// No description provided for @reportTherapySeasonWinterAdvice.
  ///
  /// In zh, this message translates to:
  /// **'冬季养肾，以藏为要。适食黑芝麻、核桃、羊肉，早卧晚起，固护肾阳。'**
  String get reportTherapySeasonWinterAdvice;

  /// No description provided for @reportTherapySeasonWinterAvoid.
  ///
  /// In zh, this message translates to:
  /// **'忌过度劳累，忌大量出汗耗散阳气'**
  String get reportTherapySeasonWinterAvoid;

  /// No description provided for @reportAdviceTongueFeatureColorLabel.
  ///
  /// In zh, this message translates to:
  /// **'舌色'**
  String get reportAdviceTongueFeatureColorLabel;

  /// No description provided for @scanToggleCamera.
  ///
  /// In zh, this message translates to:
  /// **'反转相机'**
  String get scanToggleCamera;

  /// No description provided for @reportAdviceTongueFeatureShapeLabel.
  ///
  /// In zh, this message translates to:
  /// **'舌形'**
  String get reportAdviceTongueFeatureShapeLabel;

  /// No description provided for @reportAdviceTongueFeatureCoatingColorLabel.
  ///
  /// In zh, this message translates to:
  /// **'苔色'**
  String get reportAdviceTongueFeatureCoatingColorLabel;

  /// No description provided for @reportAdviceTongueFeatureCoatingTextureLabel.
  ///
  /// In zh, this message translates to:
  /// **'苔质'**
  String get reportAdviceTongueFeatureCoatingTextureLabel;

  /// No description provided for @reportAdviceTongueFeatureCoatingTextureValue.
  ///
  /// In zh, this message translates to:
  /// **'厚腻'**
  String get reportAdviceTongueFeatureCoatingTextureValue;

  /// No description provided for @reportAdviceTongueFeatureCoatingTextureDesc.
  ///
  /// In zh, this message translates to:
  /// **'苔厚腻提示湿邪较重，脾运不畅'**
  String get reportAdviceTongueFeatureCoatingTextureDesc;

  /// No description provided for @reportAdviceTongueFeatureTeethMarksLabel.
  ///
  /// In zh, this message translates to:
  /// **'齿痕'**
  String get reportAdviceTongueFeatureTeethMarksLabel;

  /// No description provided for @reportAdviceDietRecommendedLabel.
  ///
  /// In zh, this message translates to:
  /// **'宜食'**
  String get reportAdviceDietRecommendedLabel;

  /// No description provided for @reportAdviceDietFoodYamName.
  ///
  /// In zh, this message translates to:
  /// **'山药'**
  String get reportAdviceDietFoodYamName;

  /// No description provided for @reportAdviceDietFoodYamDesc.
  ///
  /// In zh, this message translates to:
  /// **'健脾益肾，补气养阴'**
  String get reportAdviceDietFoodYamDesc;

  /// No description provided for @reportAdviceDietFoodCoixName.
  ///
  /// In zh, this message translates to:
  /// **'薏仁'**
  String get reportAdviceDietFoodCoixName;

  /// No description provided for @reportAdviceDietFoodCoixDesc.
  ///
  /// In zh, this message translates to:
  /// **'利水渗湿，健脾止泻'**
  String get reportAdviceDietFoodCoixDesc;

  /// No description provided for @reportAdviceDietFoodJujubeName.
  ///
  /// In zh, this message translates to:
  /// **'红枣'**
  String get reportAdviceDietFoodJujubeName;

  /// No description provided for @reportAdviceDietFoodJujubeDesc.
  ///
  /// In zh, this message translates to:
  /// **'补气血，健脾胃，安神'**
  String get reportAdviceDietFoodJujubeDesc;

  /// No description provided for @reportAdviceDietFoodLablabName.
  ///
  /// In zh, this message translates to:
  /// **'白扁豆'**
  String get reportAdviceDietFoodLablabName;

  /// No description provided for @reportAdviceDietFoodLablabDesc.
  ///
  /// In zh, this message translates to:
  /// **'健脾化湿，消暑除烦'**
  String get reportAdviceDietFoodLablabDesc;

  /// No description provided for @reportAdviceDietFoodCodonopsisName.
  ///
  /// In zh, this message translates to:
  /// **'党参'**
  String get reportAdviceDietFoodCodonopsisName;

  /// No description provided for @reportAdviceDietFoodCodonopsisDesc.
  ///
  /// In zh, this message translates to:
  /// **'补中益气，健脾养胃'**
  String get reportAdviceDietFoodCodonopsisDesc;

  /// No description provided for @reportAdviceDietFoodPoriaName.
  ///
  /// In zh, this message translates to:
  /// **'茯苓'**
  String get reportAdviceDietFoodPoriaName;

  /// No description provided for @reportAdviceDietFoodPoriaDesc.
  ///
  /// In zh, this message translates to:
  /// **'健脾和中，利水渗湿'**
  String get reportAdviceDietFoodPoriaDesc;

  /// No description provided for @reportAdviceDietAvoidLabel.
  ///
  /// In zh, this message translates to:
  /// **'忌食'**
  String get reportAdviceDietAvoidLabel;

  /// No description provided for @reportAdviceDietAvoidColdFoods.
  ///
  /// In zh, this message translates to:
  /// **'生冷食物'**
  String get reportAdviceDietAvoidColdFoods;

  /// No description provided for @reportAdviceDietAvoidGreasy.
  ///
  /// In zh, this message translates to:
  /// **'油腻厚味'**
  String get reportAdviceDietAvoidGreasy;

  /// No description provided for @reportAdviceDietAvoidSpicy.
  ///
  /// In zh, this message translates to:
  /// **'辛辣刺激'**
  String get reportAdviceDietAvoidSpicy;

  /// No description provided for @reportAdviceDietAvoidSweetRich.
  ///
  /// In zh, this message translates to:
  /// **'甜腻之品'**
  String get reportAdviceDietAvoidSweetRich;

  /// No description provided for @reportAdviceDietAvoidAlcoholTobacco.
  ///
  /// In zh, this message translates to:
  /// **'烟酒'**
  String get reportAdviceDietAvoidAlcoholTobacco;

  /// No description provided for @reportAdviceProductTitle.
  ///
  /// In zh, this message translates to:
  /// **'相关产品推荐'**
  String get reportAdviceProductTitle;

  /// No description provided for @reportAdviceProductSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'依据体质个性化推荐'**
  String get reportAdviceProductSubtitle;

  /// No description provided for @reportAdviceProductOneName.
  ///
  /// In zh, this message translates to:
  /// **'健脾益气丸'**
  String get reportAdviceProductOneName;

  /// No description provided for @reportAdviceProductOneType.
  ///
  /// In zh, this message translates to:
  /// **'中成药'**
  String get reportAdviceProductOneType;

  /// No description provided for @reportAdviceProductOneDesc.
  ///
  /// In zh, this message translates to:
  /// **'补中益气，健脾和胃。适合气虚体质，改善乏力、食欲不振。'**
  String get reportAdviceProductOneDesc;

  /// No description provided for @reportAdviceProductOneTag.
  ///
  /// In zh, this message translates to:
  /// **'热销'**
  String get reportAdviceProductOneTag;

  /// No description provided for @reportAdviceProductTwoName.
  ///
  /// In zh, this message translates to:
  /// **'参苓白术散'**
  String get reportAdviceProductTwoName;

  /// No description provided for @reportAdviceProductTwoType.
  ///
  /// In zh, this message translates to:
  /// **'传统方剂'**
  String get reportAdviceProductTwoType;

  /// No description provided for @reportAdviceProductTwoDesc.
  ///
  /// In zh, this message translates to:
  /// **'健脾益气，渗湿止泻。主治脾气虚弱，食少便溏，体倦乏力。'**
  String get reportAdviceProductTwoDesc;

  /// No description provided for @reportAdviceProductTwoTag.
  ///
  /// In zh, this message translates to:
  /// **'经典'**
  String get reportAdviceProductTwoTag;

  /// No description provided for @reportAdviceProductThreeName.
  ///
  /// In zh, this message translates to:
  /// **'艾灸套装'**
  String get reportAdviceProductThreeName;

  /// No description provided for @reportAdviceProductThreeType.
  ///
  /// In zh, this message translates to:
  /// **'调理器具'**
  String get reportAdviceProductThreeType;

  /// No description provided for @reportAdviceProductThreeDesc.
  ///
  /// In zh, this message translates to:
  /// **'温和艾条配合取穴定位图，居家艾灸足三里、气海、关元。'**
  String get reportAdviceProductThreeDesc;

  /// No description provided for @reportAdviceProductThreeTag.
  ///
  /// In zh, this message translates to:
  /// **'推荐'**
  String get reportAdviceProductThreeTag;

  /// No description provided for @reportAdviceProductFourName.
  ///
  /// In zh, this message translates to:
  /// **'中医食疗食材包'**
  String get reportAdviceProductFourName;

  /// No description provided for @reportAdviceProductFourType.
  ///
  /// In zh, this message translates to:
  /// **'养生食材'**
  String get reportAdviceProductFourType;

  /// No description provided for @reportAdviceProductFourDesc.
  ///
  /// In zh, this message translates to:
  /// **'山药、薏仁、党参、茯苓、红枣精选组合，一周食疗方案。'**
  String get reportAdviceProductFourDesc;

  /// No description provided for @reportAdviceProductFourTag.
  ///
  /// In zh, this message translates to:
  /// **'新品'**
  String get reportAdviceProductFourTag;

  /// No description provided for @reportAdviceProductDisclaimer.
  ///
  /// In zh, this message translates to:
  /// **'以上产品推荐基于体质分析结果，仅供参考。中成药的使用请在医师或药师指导下进行。'**
  String get reportAdviceProductDisclaimer;

  /// No description provided for @scanFaceFrameRetryMessage.
  ///
  /// In zh, this message translates to:
  /// **'未生成人脸描点图，请重新扫描。'**
  String get scanFaceFrameRetryMessage;

  /// No description provided for @scanFaceUploadFailedTitle.
  ///
  /// In zh, this message translates to:
  /// **'人脸上传失败'**
  String get scanFaceUploadFailedTitle;

  /// No description provided for @scanTongueUploadFailedTitle.
  ///
  /// In zh, this message translates to:
  /// **'舌诊上传失败'**
  String get scanTongueUploadFailedTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
