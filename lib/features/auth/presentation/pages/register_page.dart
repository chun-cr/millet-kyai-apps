// 认证模块页面：`RegisterPage`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:millet_kyai_apps/core/di/injector.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/core/l10n/seasonal_context.dart';
import 'package:millet_kyai_apps/core/network/auth_session_store.dart';
import 'package:millet_kyai_apps/core/router/app_router.dart';
import 'package:millet_kyai_apps/core/security/login_password_store.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/verification_code_target.dart';
import 'package:millet_kyai_apps/features/auth/domain/repositories/auth_repository.dart'
    show VerificationCodeScene;
import 'package:millet_kyai_apps/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:millet_kyai_apps/features/auth/presentation/utils/auth_verification_code_flow.dart';
import 'package:millet_kyai_apps/features/auth/presentation/utils/verification_code_feedback.dart';
import 'package:millet_kyai_apps/features/auth/presentation/widgets/country_code_picker.dart';
import 'package:millet_kyai_apps/features/auth/presentation/widgets/auth_top_toast.dart';
import 'package:millet_kyai_apps/features/profile/presentation/providers/profile_session_state.dart';
import 'package:millet_kyai_apps/features/share/presentation/providers/share_referral_provider.dart';

part 'complete_profile_page.dart';

String? _normalizeAuthRedirectLocation(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty || !normalized.startsWith('/')) {
    return null;
  }
  return normalized;
}

String _buildAuthRouteLocation(
  String path, {
  Map<String, String> queryParameters = const <String, String>{},
  String? redirectLocation,
}) {
  final resolvedQueryParameters = Map<String, String>.from(queryParameters);
  final normalizedRedirect = _normalizeAuthRedirectLocation(redirectLocation);
  if (normalizedRedirect != null) {
    resolvedQueryParameters['redirect'] = normalizedRedirect;
  }
  if (resolvedQueryParameters.isEmpty) {
    return path;
  }
  return Uri(path: path, queryParameters: resolvedQueryParameters).toString();
}

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({
    super.key,
    this.inviteTicket,
    this.initialMode,
    this.shareId,
    this.sharerId,
    this.visitorKey,
    this.redirectLocation,
  });

  final String? inviteTicket;
  final String? initialMode;
  final String? shareId;
  final String? sharerId;
  final String? visitorKey;
  final String? redirectLocation;

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

enum _RegisterMode { phone, email }

class _RegisterPageState extends ConsumerState<RegisterPage>
    with TickerProviderStateMixin, VerificationCodeFlowMixin<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _verificationCodeFlow = VerificationCodeFlowState();
  final _phoneFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _codeFocusNode = FocusNode();
  bool _agreeTerms = false;
  bool _isLoading = false;
  final _errorToastController = AuthTopToastController();
  _RegisterMode _registerMode = _RegisterMode.phone;
  String _selectedCountryCode = '+86';
  String _selectedCountryFlag = authCountryCodeOptions.first.flag;

  late AnimationController _rotateController;
  late AnimationController _fadeController;

  static final RegExp _phonePattern = RegExp(r'^[0-9]{6,15}$');
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  final List<CountryCodeOption> _countryCodes = authCountryCodeOptions;

  // 密码强度
  @override
  void initState() {
    super.initState();
    _registerMode = widget.initialMode == 'email'
        ? _RegisterMode.email
        : _RegisterMode.phone;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeShareReferral());
    });
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _fadeController.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    _codeFocusNode.dispose();
    _verificationCodeFlow.dispose();
    _errorToastController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (_registerMode == _RegisterMode.email) {
      return null;
    }
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return context.l10n.authPhoneHint;
    }
    if (!_phonePattern.hasMatch(input)) {
      return context.l10n.authPhoneFormatError;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (_registerMode == _RegisterMode.phone) {
      return null;
    }
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return context.l10n.authEmailHint;
    }
    if (!_emailPattern.hasMatch(input)) {
      return context.l10n.authEmailFormatError;
    }
    return null;
  }

  String? get _inviteTicket {
    final inviteTicket = widget.inviteTicket?.trim();
    if (inviteTicket == null || inviteTicket.isEmpty) {
      return null;
    }
    return inviteTicket;
  }

  String? get _incomingShareId {
    final shareId = widget.shareId?.trim();
    if (shareId != null && shareId.isNotEmpty) {
      return shareId;
    }
    final sharerId = widget.sharerId?.trim();
    if (sharerId == null || sharerId.isEmpty) {
      return null;
    }
    return sharerId;
  }

  String? get _visitorKey {
    final visitorKey = widget.visitorKey?.trim();
    if (visitorKey == null || visitorKey.isEmpty) {
      return null;
    }
    return visitorKey;
  }

  String? get _redirectLocation {
    return _normalizeAuthRedirectLocation(widget.redirectLocation);
  }

  bool get _isEmailRegister => _registerMode == _RegisterMode.email;
  String get _currentEntryMode => _isEmailRegister ? 'email' : 'phone';
  String get _currentAccountValue =>
      _isEmailRegister ? _emailCtrl.text.trim() : _phoneCtrl.text.trim();
  String? get _currentAccountCountryCode =>
      _isEmailRegister ? null : _selectedCountryCode;
  VerificationCodeTarget get _currentVerificationCodeTarget => _isEmailRegister
      ? VerificationCodeTarget.email(value: _emailCtrl.text.trim())
      : VerificationCodeTarget.phone(
          value: _phoneCtrl.text.trim(),
          countryCode: _selectedCountryCode,
        );
  bool get _codeSending => _verificationCodeFlow.codeSending;
  bool get _codeCountingDown => _verificationCodeFlow.codeCountingDown;
  int get _codeCountdown => _verificationCodeFlow.codeCountdown;
  String? get _codeTargetCountryCode =>
      _verificationCodeFlow.codeTargetCountryCode;
  String? get _challengeId => _verificationCodeFlow.challengeId;
  String? get _maskedReceiver => _verificationCodeFlow.maskedReceiver;

  @override
  VerificationCodeFlowState get verificationCodeFlow => _verificationCodeFlow;

  @override
  TextEditingController get verificationCodeController => _codeCtrl;

  @override
  String get currentVerificationAccountValue => _currentAccountValue;

  @override
  String? get currentVerificationCountryCode => _currentAccountCountryCode;

  @override
  VerificationCodeTarget get currentVerificationCodeTarget =>
      _currentVerificationCodeTarget;

  @override
  VerificationCodeScene get verificationCodeScene =>
      VerificationCodeScene.register;

  @override
  String get verificationCodeSuccessMessageText =>
      verificationCodeSentSuccessMessage(
        context,
        isEmail: _isEmailRegister,
        fallbackMessage: context.l10n.authCodeSent,
      );

  @override
  void showVerificationError(String message) => _showErrorSnack(message);

  @override
  void showVerificationSuccess(String message) => _showSuccessSnack(message);

  String get _loginLocation {
    final queryParameters = <String, String>{};
    queryParameters['mode'] = _currentEntryMode;
    if (_inviteTicket != null) {
      queryParameters['inviteTicket'] = _inviteTicket!;
    }
    if (_incomingShareId != null) {
      queryParameters['shareId'] = _incomingShareId!;
    }
    if (_visitorKey != null) {
      queryParameters['visitorKey'] = _visitorKey!;
    }
    return _buildAuthRouteLocation(
      AppRoutes.login,
      queryParameters: queryParameters,
      redirectLocation: _redirectLocation,
    );
  }

  Future<void> _initializeShareReferral() async {
    await ref
        .read(shareReferralControllerProvider.notifier)
        .handleIncomingShare(
          shareId: widget.shareId,
          sharerId: widget.sharerId,
          visitorKey: widget.visitorKey,
          redirect: widget.redirectLocation,
          isAuthenticated: isPreviewAuthenticated,
        );
  }

  Future<void> _synchronizeShareReferralAfterAuth() async {
    try {
      await ref
          .read(shareReferralControllerProvider.notifier)
          .initializeAfterAuth();
    } catch (_) {
      debugPrint('share referral initialization failed after register');
    }
  }

  Future<String?> _resolveInviteTicketForAuth() {
    return ref
        .read(shareReferralControllerProvider.notifier)
        .resolveInviteTicketForAuth(
          explicitInviteTicket: _inviteTicket,
          shareId: _incomingShareId,
          sharerId: widget.sharerId,
          visitorKey: _visitorKey,
          redirect: _redirectLocation ?? AppRoutes.register,
        );
  }

  void _handlePhoneChanged(String value) {
    final trimmed = value.trim();
    if (_registerMode == _RegisterMode.phone && trimmed.contains('@')) {
      _switchRegisterMode(_RegisterMode.email, incomingValue: trimmed);
      _phoneCtrl.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        FocusScope.of(context).requestFocus(_emailFocusNode);
      });
      return;
    }
    resetVerificationStateIfTargetChanged(value);
  }

  void _handleEmailChanged(String value) {
    resetVerificationStateIfTargetChanged(value);
  }

  void _switchRegisterMode(_RegisterMode mode, {String? incomingValue}) {
    if (_registerMode == mode && incomingValue == null) {
      return;
    }
    setState(() {
      _registerMode = mode;
      resetVerificationCodeState();
      _formKey.currentState?.reset();
      if (incomingValue != null) {
        _emailCtrl.value = TextEditingValue(
          text: incomingValue,
          selection: TextSelection.collapsed(offset: incomingValue.length),
        );
      }
    });
  }

  String _registerModeLabel(_RegisterMode mode) {
    return switch (mode) {
      _RegisterMode.phone => context.l10n.registerPhoneMode,
      _RegisterMode.email => context.l10n.registerEmailMode,
    };
  }

  String _registerLoginPrompt() {
    return context.l10n.registerAlreadyHaveAccount;
  }

  String _registerLoginActionLabel() {
    return context.l10n.registerLoginNow;
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    _errorToastController.show(context, message);
  }

  void _showSuccessSnack(String message) {
    if (!mounted) return;
    _errorToastController.show(
      context,
      message,
      kind: AuthTopToastKind.success,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _onSendCode() async {
    final accountError = _isEmailRegister
        ? _validateEmail(_emailCtrl.text)
        : _validatePhone(_phoneCtrl.text);
    if (accountError != null) {
      _showErrorSnack(accountError);
      return;
    }
    await sendVerificationCode();
    if (!mounted || !_verificationCodeFlow.verificationCodeSent) {
      return;
    }
    FocusScope.of(context).requestFocus(_codeFocusNode);
  }

  Future<void> _onRegister() async {
    if (!hasActiveVerificationCodeSubmission) {
      if (isVerificationCodeExpired) {
        setState(() {
          resetVerificationCodeState(clearCode: false);
        });
      }
      _showErrorSnack(context.l10n.authSendCodeFirst);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      _showErrorSnack(context.l10n.registerAgreeTermsFirst);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final inviteTicket = await _resolveInviteTicketForAuth();
      final session = await repository.authenticateVerificationCode(
        scene: VerificationCodeScene.register,
        challengeId: _challengeId!,
        verificationCode: _codeCtrl.text.trim(),
        inviteTicket: inviteTicket,
      );
      await getIt<AuthSessionStore>().saveSession(session);
      await clearProfileScopedPersistence();
      invalidateProfileScopedProviders(ref);
      unawaited(_synchronizeShareReferralAfterAuth());
      if (!mounted) return;
      setState(() => _isLoading = false);
      context.go(
        _buildAuthRouteLocation(
          AppRoutes.completeProfile,
          redirectLocation: _redirectLocation,
        ),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final responseData = error.response?.data;
      final serverMessage = authResponseMessage(responseData);
      final code = authResponseCode(responseData);
      if (code == 11119 || code == 11121) {
        resetVerificationCodeState();
      }
      if (code == 11122 || code == 11123) {
        _verificationCodeFlow.captchaVerified = false;
      }
      _showErrorSnack(serverMessage ?? context.l10n.registerCreateFailed);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnack(context.l10n.registerCreateFailed);
    }
  }

  void _goToLogin() {
    context.go(_loginLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2E8),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFF8F2E8)),
              ),
            ),
            Positioned(
              left: -24,
              top: -84,
              right: -24,
              child: Container(
                height: 258,
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    center: Alignment(0, -0.9),
                    radius: 1.22,
                    colors: [
                      Color(0xFFDCF1E0),
                      Color(0xFFB8DCC3),
                      Color(0xFF89B59A),
                    ],
                    stops: [0, 0.58, 1],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.elliptical(420, 118),
                    bottomRight: Radius.elliptical(420, 118),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1F6A8D76),
                      blurRadius: 32,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 126,
              left: -32,
              right: -32,
              child: IgnorePointer(
                child: Container(
                  height: 96,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00FFFFFF),
                        Color(0xCCFFFDF9),
                        Color(0xFFF8F2E8),
                      ],
                      stops: [0, 0.56, 1],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _rotateController,
                  builder: (context, child) => CustomPaint(
                    painter: _RegBgPainter(
                      rotation: _rotateController.value * 2 * math.pi,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _fadeController,
                  curve: Curves.easeOut,
                ),
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 390),
                          child: _buildAccountCreationPage(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final seasonalTag = context.l10n.seasonalTagLabel(SeasonalContext.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: SizedBox(
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: _goToLogin,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.58),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF78A48B).withValues(alpha: 0.16),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x1A3D5C48),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 14,
                    color: Color(0xFF486957),
                  ),
                ),
              ),
            ),
            // 品牌
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF46745F), Color(0xFF7BAA90)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x22618674),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(child: _BrandMark()),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF233528),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      children: [
                        TextSpan(text: context.l10n.appBrandPrefix),
                        const TextSpan(
                          text: 'AI',
                          style: TextStyle(color: Color(0xFF4F8C70)),
                        ),
                        TextSpan(text: context.l10n.appBrandSuffix),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                key: const ValueKey('register_seasonal_tag'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: const Color(0xFFB8954F).withValues(alpha: 0.28),
                    width: 1,
                  ),
                ),
                child: Text(
                  seasonalTag,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFFB18A49),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCreationPage() {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _buildSecurityVisual()),
              const SizedBox(height: 18),
              Text(
                context.l10n.registerCreateAccountTitle,
                style: const TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF28221B),
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildFormContent(),
              const SizedBox(height: 20),
              _buildLoginRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRegisterModeTabs(),
        const SizedBox(height: 22),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: _buildRegisterFormTransition,
            child: _isEmailRegister
                ? _buildEmailRegisterFields()
                : _buildPhoneRegisterFields(),
          ),
        ),
        const SizedBox(height: 20),
        _buildTermsRow(),
        const SizedBox(height: 22),
        _buildRegisterButton(),
      ],
    );
  }

  Widget _buildSecurityVisual() {
    return SizedBox(
      width: 152,
      height: 152,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 144,
            height: 144,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.08, -0.2),
                colors: [
                  Colors.white.withValues(alpha: 0.58),
                  const Color(0xFFE1F0E2).withValues(alpha: 0.26),
                  Colors.white.withValues(alpha: 0.02),
                ],
                stops: const [0, 0.5, 1],
              ),
            ),
          ),
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0x4D93BEA7),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _rotateController,
            builder: (context, child) => Transform.rotate(
              angle: _rotateController.value * math.pi,
              child: CustomPaint(
                size: const Size(132, 132),
                painter: const _SmallBaguaRingPainter(),
              ),
            ),
          ),
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF9FEFA), Color(0xFFD4E7D6)],
              ),
              border: Border.all(color: const Color(0xAAFFFFFF), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Color(0x2B5C826E),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ],
            ),
          ),
          // 内圆
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.15, -0.25),
                radius: 0.92,
                colors: [
                  Colors.white.withValues(alpha: 0.62),
                  const Color(0xFFC7DDCA).withValues(alpha: 0.42),
                ],
              ),
              border: Border.all(color: const Color(0x22566D58), width: 1.2),
            ),
          ),
          // 四角刻度
          Positioned(
            top: 17,
            left: 17,
            child: _Bracket(color: const Color(0xFF2D6A4F), tl: true),
          ),
          Positioned(
            top: 17,
            right: 17,
            child: _Bracket(color: const Color(0xFF2D6A4F), tr: true),
          ),
          Positioned(
            bottom: 17,
            left: 17,
            child: _Bracket(color: const Color(0xFFC9A84C), bl: true),
          ),
          Positioned(
            bottom: 17,
            right: 17,
            child: _Bracket(color: const Color(0xFFC9A84C), br: true),
          ),
          const CustomPaint(size: Size(94, 94), painter: _HarmonySealPainter()),
        ],
      ),
    );
  }

  Widget _buildRegisterFormTransition(
    Widget child,
    Animation<double> animation,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final slidesFromRight =
        child.key == const ValueKey('register_email_fields');
    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(slidesFromRight ? 0.12 : -0.12, 0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  }

  Widget _buildRegisterModeTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2ECE1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE6DED1), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RegisterModeTab(
              tabKey: const ValueKey('register_phone_tab'),
              label: _registerModeLabel(_RegisterMode.phone),
              selected: !_isEmailRegister,
              onTap: () => _switchRegisterMode(_RegisterMode.phone),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _RegisterModeTab(
              tabKey: const ValueKey('register_email_tab'),
              label: _registerModeLabel(_RegisterMode.email),
              selected: _isEmailRegister,
              onTap: () => _switchRegisterMode(_RegisterMode.email),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneRegisterFields() {
    return Column(
      key: const ValueKey('register_phone_fields'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InputLabel(text: context.l10n.authPhoneLabel),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _phoneCtrl,
          focusNode: _phoneFocusNode,
          hint: context.l10n.authPhoneHint,
          prefixIconWidget: _buildCountryCodePrefix(),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          keyboardType: TextInputType.phone,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: _handlePhoneChanged,
          validator: _validatePhone,
        ),
        const SizedBox(height: 16),
        _buildCodeField(),
      ],
    );
  }

  Widget _buildEmailRegisterFields() {
    return Column(
      key: const ValueKey('register_email_fields'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InputLabel(text: context.l10n.authEmailLabel),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _emailCtrl,
          focusNode: _emailFocusNode,
          hint: context.l10n.authEmailHint,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: _handleEmailChanged,
          validator: _validateEmail,
        ),
        const SizedBox(height: 16),
        _buildCodeField(),
      ],
    );
  }

  Widget _buildCountryCodePrefix() {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CountryCodePopoverPicker(
            key: const ValueKey('register_country_code_menu_trigger'),
            flag: _selectedCountryFlag,
            code: _selectedCountryCode,
            options: _countryCodes,
            onSelected: (selected) {
              setState(() {
                if (_codeTargetCountryCode != null &&
                    _codeTargetCountryCode != selected.code) {
                  resetVerificationCodeState();
                }
                _selectedCountryCode = selected.code;
                _selectedCountryFlag = selected.flag;
              });
            },
          ),
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.only(left: 8, right: 10),
            color: const Color(0xFFE3DACB),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeField() {
    final l10n = context.l10n;
    final maskedReceiver = _maskedReceiver;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputLabel(text: l10n.authVerificationCodeLabel),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _codeCtrl,
          focusNode: _codeFocusNode,
          hint: l10n.authVerificationCodeHint,
          prefixIcon: Icons.shield_outlined,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(kVerificationCodeLength),
          ],
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: dismissVerificationCodeInputIfComplete,
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _codeSending
                  ? const SizedBox(
                      key: ValueKey('register_send_code_loading'),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2D6A4F),
                      ),
                    )
                  : _codeCountingDown
                  ? Text(
                      l10n.authResendCode(_codeCountdown),
                      key: const ValueKey('register_send_code_countdown'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB28749),
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : TextButton(
                      key: const ValueKey('register_send_code_button'),
                      onPressed: _onSendCode,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l10n.authSendCode,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB28749),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ),
          validator: (value) {
            if (value == null ||
                value.trim().length != kVerificationCodeLength) {
              return l10n.authVerificationCodeHint;
            }
            return null;
          },
        ),
        if (maskedReceiver != null && maskedReceiver.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            context.l10n.authCodeSentToReceiver(maskedReceiver),
            key: const ValueKey('register_masked_receiver_hint'),
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF5A5349).withValues(alpha: 0.72),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTermsRow() {
    return GestureDetector(
      key: const ValueKey('register_terms_row'),
      onTap: () => setState(() => _agreeTerms = !_agreeTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(6),
              gradient: _agreeTerms
                  ? const LinearGradient(
                      colors: [Color(0xFF7AA98E), Color(0xFF98C4AA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              border: Border.all(
                color: _agreeTerms
                    ? Colors.transparent
                    : const Color(0xFFE0D6C8),
                width: 1.2,
              ),
            ),
            child: _agreeTerms
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF534B41).withValues(alpha: 0.82),
                  height: 1.55,
                ),
                children: [
                  TextSpan(text: context.l10n.registerReadAndAgree),
                  TextSpan(
                    text: context.l10n.registerUserAgreement,
                    style: const TextStyle(
                      color: Color(0xFF3D7B61),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: context.l10n.registerAnd),
                  TextSpan(
                    text: context.l10n.registerPrivacyPolicy,
                    style: const TextStyle(
                      color: Color(0xFF3D7B61),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: context.l10n.registerHealthDataClause),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRow() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          _registerLoginPrompt(),
          style: const TextStyle(fontSize: 13, color: Color(0xFF6A635A)),
        ),
        TextButton(
          key: const ValueKey('register_go_login_button'),
          onPressed: _goToLogin,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _registerLoginActionLabel(),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF3D7B61),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return GestureDetector(
      key: const ValueKey('register_create_account_button'),
      onTap: _isLoading ? null : _onRegister,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFA9D0B6), Color(0xFF8CB99F), Color(0xFF7DA98F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0x336E9B81),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.l10n.registerCreateAccountAction,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    FocusNode? focusNode,
    IconData? prefixIcon,
    Widget? prefixIconWidget,
    BoxConstraints? prefixIconConstraints,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    Iterable<String>? autofillHints,
    AutovalidateMode? autovalidateMode,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      autovalidateMode: autovalidateMode,
      onChanged: onChanged,
      cursorColor: const Color(0xFF5D826D),
      textAlignVertical: TextAlignVertical.center,
      style: const TextStyle(
        fontSize: 14.5,
        color: Color(0xFF2F281F),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFFB6A58E)),
        filled: true,
        fillColor: const Color(0xFFFFFCF7),
        prefixIcon:
            prefixIconWidget ??
            (prefixIcon == null
                ? null
                : Icon(prefixIcon, size: 18, color: const Color(0xFFC0AF98))),
        prefixIconConstraints:
            prefixIconConstraints ??
            const BoxConstraints(minWidth: 48, minHeight: 56),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 8),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints: suffixIcon != null
            ? const BoxConstraints(minWidth: 84, minHeight: 56)
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        errorStyle: const TextStyle(fontSize: 11.5, height: 1.25),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: const Color(0xFFECE3D6), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: const Color(0xFFECE3D6), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF8CAD98), width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.red.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
      ),
      validator: validator,
    );
  }
}
