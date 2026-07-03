// 认证模块页面：`LoginPage`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:millet_kyai_apps/core/di/injector.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/core/network/auth_session_store.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/auth_session_entity.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/verification_code_target.dart';
import 'package:millet_kyai_apps/features/auth/domain/repositories/auth_repository.dart'
    show VerificationCodeScene;
import 'package:millet_kyai_apps/features/profile/presentation/providers/profile_session_state.dart';

import '../../../../core/router/app_router.dart';
import '../../data/models/auth_request.dart';
import '../providers/auth_repository_provider.dart';
import 'package:millet_kyai_apps/features/share/presentation/providers/share_referral_provider.dart';
import '../providers/wechat_code_acquirer_provider.dart';
import '../utils/auth_verification_code_flow.dart';
import '../utils/verification_code_feedback.dart';
import '../widgets/auth_locale_button.dart';
import '../widgets/auth_top_toast.dart';
import '../widgets/country_code_picker.dart';

part 'login_page_logic.dart';
part 'login_page_view.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({
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
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

enum _LoginButtonPhase { idle, submitting }

class _LoginPageState extends ConsumerState<LoginPage>
    with
        TickerProviderStateMixin,
        VerificationCodeFlowMixin<LoginPage>,
        _LoginPageLogic,
        _LoginPageView {
  @override
  final _formKey = GlobalKey<FormState>();
  @override
  final _phoneCtrl = TextEditingController();
  @override
  final _emailCtrl = TextEditingController();
  @override
  final _passCtrl = TextEditingController();
  @override
  final _codeCtrl = TextEditingController();
  @override
  late final Listenable _formFieldsListenable = Listenable.merge([
    _phoneCtrl,
    _emailCtrl,
    _passCtrl,
    _codeCtrl,
  ]);
  @override
  final _verificationCodeFlow = VerificationCodeFlowState();
  @override
  bool _agreeTerms = false;
  @override
  bool _isEmailLogin = false;
  @override
  bool _obscurePass = true;
  @override
  bool _isPasswordLogin = false;
  @override
  VerificationCodeScene? _resolvedVerificationCodeScene;
  @override
  bool _wechatLoginLoading = false;
  @override
  final _errorToastController = AuthTopToastController();
  @override
  _LoginButtonPhase _buttonPhase = _LoginButtonPhase.idle;
  @override
  String _selectedCountryCode = '+86';
  @override
  String _selectedCountryFlag = '🇨🇳';
  @override
  final List<CountryCodeOption> _countryCodes = authCountryCodeOptions;

  late AnimationController _breatheController;
  late AnimationController _fadeController;
  @override
  late AnimationController _btnScaleCtrl;
  late AnimationController _exitCtrl;
  @override
  late Animation<double> _breatheAnim;
  late Animation<double> _fadeAnim;
  @override
  late Animation<double> _btnScaleAnim;

  static const Duration _submittingDuration = Duration(milliseconds: 800);
  static final RegExp _phonePattern = RegExp(r'^[0-9]{6,15}$');
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  bool get _isBusy => _buttonPhase != _LoginButtonPhase.idle;

  @override
  void initState() {
    super.initState();
    _isEmailLogin = widget.initialMode == 'email';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeShareReferral());
    });

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _breatheAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _btnScaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _btnScaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _btnScaleCtrl, curve: Curves.easeInOut));

    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _fadeController.dispose();
    _btnScaleCtrl.dispose();
    _exitCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _codeCtrl.dispose();
    _verificationCodeFlow.dispose();
    _errorToastController.dispose();
    super.dispose();
  }

  String _wechatUnsupportedMessage() {
    return context.l10n.authWechatUnsupported;
  }

  String _wechatCodeMissingMessage() {
    return context.l10n.authWechatCodeMissing;
  }

  String _wechatStatusMessage(String authStatus) {
    final normalizedStatus = authStatus.trim();
    if (normalizedStatus.isEmpty) {
      return context.l10n.authWechatCompletedWithoutToken;
    }
    return context.l10n.authWechatStatusPendingBinding(normalizedStatus);
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
      debugPrint('share referral initialization failed after login');
    }
  }

  Future<void> _completeLoginWithSession(
    AuthSessionEntity session, {
    String? redirectLocation,
    bool requiresProfileCompletion = false,
  }) async {
    await getIt<AuthSessionStore>().saveSession(session);
    await clearProfileScopedPersistence();
    invalidateProfileScopedProviders(ref);
    unawaited(_synchronizeShareReferralAfterAuth());

    if (!mounted) {
      return;
    }

    await _exitCtrl.forward();
    if (!mounted) {
      return;
    }

    setPreviewAuthenticated(true);
    context.go(
      requiresProfileCompletion
          ? _buildCompleteProfileLocation(redirectLocation)
          : _resolveSafeRedirect(redirectLocation) ?? AppRoutes.home,
    );
  }

  String _buildCompleteProfileLocation(String? redirectLocation) {
    final safeRedirect = _resolveSafeRedirect(redirectLocation);
    return Uri(
      path: AppRoutes.completeProfile,
      queryParameters: safeRedirect == null
          ? null
          : <String, String>{'redirect': safeRedirect},
    ).toString();
  }

  @override
  Future<void> _onWechatMiniProgramLogin() async {
    if (_wechatLoginLoading || _isBusy) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _wechatLoginLoading = true);

    try {
      final wechatCode = await ref
          .read(wechatCodeAcquirerProvider)
          .acquireWechatCode();
      final normalizedWechatCode = wechatCode?.trim() ?? '';
      if (normalizedWechatCode.isEmpty) {
        if (mounted) {
          _showErrorSnack(_wechatCodeMissingMessage());
        }
        return;
      }

      final result = await ref
          .read(authRepositoryProvider)
          .loginWithWechatMiniProgram(
            wechatCode: normalizedWechatCode,
            inviteTicket: await _resolveInviteTicketForAuth(),
          );

      if (result.hasSession && result.session != null) {
        await _completeLoginWithSession(
          result.session!,
          redirectLocation: _redirectLocation,
        );
        return;
      }

      if (!mounted) {
        return;
      }
      _showErrorSnack(_wechatStatusMessage(result.authStatus));
    } on UnimplementedError {
      if (!mounted) {
        return;
      }
      _showErrorSnack(_wechatUnsupportedMessage());
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      final serverMessage = authResponseMessage(error.response?.data);
      _showErrorSnack(serverMessage ?? context.l10n.authLoginFailed);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showErrorSnack(context.l10n.authLoginFailed);
    } finally {
      if (mounted) {
        setState(() => _wechatLoginLoading = false);
      }
    }
  }

  @override
  Future<void> _onSendCode() async {
    final l10n = context.l10n;
    final accountError = _isEmailLogin
        ? _validateEmail(_emailCtrl.text)
        : _validatePhone(_phoneCtrl.text);
    if (accountError != null) {
      _showErrorSnack(accountError);
      return;
    }
    final preferredScene =
        _resolvedVerificationCodeScene ?? VerificationCodeScene.login;
    final primaryResult = await sendVerificationCode(
      sceneOverride: preferredScene,
      presentError: false,
    );
    if (primaryResult.isSent) {
      if (mounted) {
        setState(() {
          _resolvedVerificationCodeScene = preferredScene;
        });
      }
      return;
    }

    if (preferredScene == VerificationCodeScene.login &&
        primaryResult.dioException != null &&
        isVerificationCodeUnregisteredError(primaryResult.dioException!)) {
      if (mounted) {
        setState(() {
          _resolvedVerificationCodeScene = null;
          resetVerificationCodeState(clearCode: false);
        });
      }
      final registerResult = await sendVerificationCode(
        sceneOverride: VerificationCodeScene.register,
      );
      if (registerResult.isSent && mounted) {
        setState(() {
          _resolvedVerificationCodeScene = VerificationCodeScene.register;
        });
      }
      return;
    }

    if (primaryResult.isFailed) {
      final responseData = primaryResult.dioException?.response?.data;
      _showErrorSnack(
        authResponseMessage(responseData) ?? l10n.authSendCodeFailed,
      );
    }
  }

  @override
  Future<void> _onLogin() async {
    if (!_usesPasswordCredential && !hasActiveVerificationCodeSubmission) {
      if (isVerificationCodeExpired) {
        setState(() {
          resetVerificationCodeState(clearCode: false);
        });
      }
      _showErrorSnack(context.l10n.authSendCodeFirst);
      return;
    }
    if (!_agreeTerms) {
      _showErrorSnack(context.l10n.registerAgreeTermsFirst);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _buttonPhase = _LoginButtonPhase.submitting);
    await _btnScaleCtrl.reverse();

    try {
      final repository = ref.read(authRepositoryProvider);
      late final AuthSessionEntity session;
      var verificationScene =
          _resolvedVerificationCodeScene ?? VerificationCodeScene.login;
      if (_usesPasswordCredential) {
        final inviteTicket = await _resolveInviteTicketForAuth();
        session = await repository.login(
          AuthRequest(
            countryCode: _selectedCountryCode,
            phoneNumber: _phoneCtrl.text.trim(),
            password: _passCtrl.text,
            inviteTicket: inviteTicket,
          ),
        );
      } else {
        final inviteTicket = await _resolveInviteTicketForAuth();
        try {
          session = await repository.authenticateVerificationCode(
            scene: verificationScene,
            challengeId: _challengeId!,
            verificationCode: _codeCtrl.text.trim(),
            inviteTicket: inviteTicket,
          );
        } on DioException catch (error) {
          if (verificationScene == VerificationCodeScene.login &&
              isVerificationCodeUnregisteredError(error)) {
            session = await repository.authenticateVerificationCode(
              scene: VerificationCodeScene.register,
              challengeId: _challengeId!,
              verificationCode: _codeCtrl.text.trim(),
              inviteTicket: inviteTicket,
            );
            verificationScene = VerificationCodeScene.register;
            if (mounted) {
              setState(() {
                _resolvedVerificationCodeScene = verificationScene;
              });
            }
          } else {
            rethrow;
          }
        }
      }

      final results = await Future.wait<dynamic>([
        Future<AuthSessionEntity>.value(session),
        Future.delayed(_submittingDuration),
      ]);
      final authSession = results.first as AuthSessionEntity;

      await _completeLoginWithSession(
        authSession,
        redirectLocation: _redirectLocation,
        requiresProfileCompletion:
            !_usesPasswordCredential &&
            verificationScene == VerificationCodeScene.register,
      );
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _buttonPhase = _LoginButtonPhase.idle);
      final responseData = error.response?.data;
      final serverMessage = authResponseMessage(responseData);
      final code = authResponseCode(responseData);
      if (!_usesPasswordCredential && (code == 11119 || code == 11121)) {
        resetVerificationCodeState();
      }
      if (!_usesPasswordCredential && (code == 11122 || code == 11123)) {
        _verificationCodeFlow.captchaVerified = false;
      }
      _showErrorSnack(serverMessage ?? context.l10n.authLoginFailed);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _buttonPhase = _LoginButtonPhase.idle);
      _showErrorSnack(context.l10n.authLoginFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardVisible = keyboardInset > 0;
    final keyboardViewportInset = keyboardVisible ? 12.0 : 0.0;
    final formBottomPadding = keyboardVisible ? keyboardInset + 20 : 0.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF8F2E8),
      body: AnimatedBuilder(
        animation: _exitCtrl,
        builder: (context, _) {
          final t = Curves.easeInCubic.transform(_exitCtrl.value);
          return GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Color(0xFFF8F2E8)),
                  ),
                ),
                Positioned(
                  left: -28,
                  top: -88,
                  right: -28,
                  child: Container(
                    height: 246,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        center: Alignment(0, -0.88),
                        radius: 1.24,
                        colors: [
                          Color(0xFFE4F4E6),
                          Color(0xFFB8DCC3),
                          Color(0xFF8EB69D),
                        ],
                        stops: [0, 0.56, 1],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.elliptical(420, 116),
                        bottomRight: Radius.elliptical(420, 116),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F6A8D76),
                          blurRadius: 30,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 124,
                  left: -32,
                  right: -32,
                  child: IgnorePointer(
                    child: Container(
                      height: 92,
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
                  child: IgnorePointer(child: _buildBackground()),
                ),
                SafeArea(
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.only(bottom: keyboardViewportInset),
                    child: Transform.translate(
                      offset: Offset(0, -40 * t),
                      child: Opacity(
                        opacity: (1.0 - t).clamp(0.0, 1.0),
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  0,
                                  18,
                                  0,
                                ),
                                child: AnimatedPadding(
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                  padding: EdgeInsets.only(
                                    bottom: formBottomPadding,
                                  ),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 390,
                                      ),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: constraints.maxHeight,
                                        ),
                                        child: IntrinsicHeight(
                                          child: AutofillGroup(
                                            child: Form(
                                              key: _formKey,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  const SizedBox(height: 12),
                                                  _buildBrandRow(),
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                      milliseconds: 280,
                                                    ),
                                                    curve: Curves.easeOutCubic,
                                                    height: keyboardVisible
                                                        ? 16
                                                        : 28,
                                                  ),
                                                  AnimatedSlide(
                                                    duration: const Duration(
                                                      milliseconds: 280,
                                                    ),
                                                    curve: Curves.easeOutCubic,
                                                    offset: Offset(
                                                      0,
                                                      keyboardVisible
                                                          ? -0.06
                                                          : 0,
                                                    ),
                                                    child: AnimatedScale(
                                                      duration: const Duration(
                                                        milliseconds: 280,
                                                      ),
                                                      curve:
                                                          Curves.easeOutCubic,
                                                      scale: keyboardVisible
                                                          ? 0.84
                                                          : 1,
                                                      alignment:
                                                          Alignment.topCenter,
                                                      child: _buildHeroVisual(),
                                                    ),
                                                  ),
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                      milliseconds: 280,
                                                    ),
                                                    curve: Curves.easeOutCubic,
                                                    height: keyboardVisible
                                                        ? 6
                                                        : 10,
                                                  ),
                                                  _buildHeroText(),
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                      milliseconds: 280,
                                                    ),
                                                    curve: Curves.easeOutCubic,
                                                    height: keyboardVisible
                                                        ? 18
                                                        : 22,
                                                  ),
                                                  _buildInputArea(),
                                                  const SizedBox(height: 18),
                                                  _buildAgreementSection(),
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                      milliseconds: 220,
                                                    ),
                                                    curve: Curves.easeOutCubic,
                                                    margin: EdgeInsets.only(
                                                      bottom: keyboardVisible
                                                          ? 8
                                                          : 0,
                                                    ),
                                                    child:
                                                        _buildPrimaryButton(),
                                                  ),
                                                  const Spacer(),
                                                  AnimatedSwitcher(
                                                    duration: const Duration(
                                                      milliseconds: 220,
                                                    ),
                                                    switchInCurve:
                                                        Curves.easeOutCubic,
                                                    switchOutCurve:
                                                        Curves.easeInCubic,
                                                    transitionBuilder:
                                                        (child, animation) {
                                                          return FadeTransition(
                                                            opacity: animation,
                                                            child:
                                                                SizeTransition(
                                                                  sizeFactor:
                                                                      animation,
                                                                  axisAlignment:
                                                                      -1,
                                                                  child: child,
                                                                ),
                                                          );
                                                        },
                                                    child: keyboardVisible
                                                        ? const SizedBox(
                                                            key: ValueKey(
                                                              'login_keyboard_compact',
                                                            ),
                                                            height: 12,
                                                          )
                                                        : Column(
                                                            key: const ValueKey(
                                                              'login_keyboard_full',
                                                            ),
                                                            children: [
                                                              _buildBottomAuxiliarySections(),
                                                              const SizedBox(
                                                                height: 36,
                                                              ),
                                                            ],
                                                          ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LoginBgPainter extends CustomPainter {
  const _LoginBgPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final washPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.1),
          const Color(0xFFF0E8D8).withValues(alpha: 0.1),
          Colors.transparent,
        ],
        stops: const [0, 0.34, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, washPaint);

    _drawRippleCluster(
      canvas,
      center: Offset(size.width - 22, size.height * 0.28),
      radii: const <double>[16, 24, 32, 40],
      color: const Color(0xFFB6AA96),
      startAngle: math.pi * 0.4,
      sweepAngle: math.pi * 1.15,
    );
    _drawRippleCluster(
      canvas,
      center: Offset(10, size.height - 84),
      radii: const <double>[22, 32, 42, 54, 68],
      color: const Color(0xFFB6AA96),
      startAngle: -math.pi * 0.12,
      sweepAngle: math.pi * 1.2,
    );

    final softCirclePaint = Paint()
      ..color = const Color(0xFF8AA891).withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.5),
      68,
      softCirclePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.24, size.height * 0.72),
      86,
      Paint()
        ..color = const Color(0xFFD8C8AF).withValues(alpha: 0.03)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawRippleCluster(
    Canvas canvas, {
    required Offset center,
    required List<double> radii,
    required Color color,
    required double startAngle,
    required double sweepAngle,
  }) {
    final arcPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final radius in radii) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_LoginBgPainter oldDelegate) => false;
}

class _BaguaRingPainter extends CustomPainter {
  const _BaguaRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 4;
    final ringPaint = Paint()
      ..color = const Color(0xFF587464).withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    final innerRingPaint = Paint()
      ..color = const Color(0xFF587464).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawCircle(Offset(cx, cy), radius, ringPaint);
    canvas.drawCircle(Offset(cx, cy), radius - 12, innerRingPaint);
    for (int i = 0; i < 16; i++) {
      final angle = i * math.pi / 8;
      final tickStart = i.isEven ? radius - 9 : radius - 6;
      canvas.drawLine(
        Offset(
          cx + math.cos(angle) * tickStart,
          cy + math.sin(angle) * tickStart,
        ),
        Offset(cx + math.cos(angle) * radius, cy + math.sin(angle) * radius),
        ringPaint,
      );
    }

    for (int i = 0; i < 24; i++) {
      final angle = i * math.pi / 12;
      canvas.drawCircle(
        Offset(cx + math.cos(angle) * radius, cy + math.sin(angle) * radius),
        1.1,
        Paint()
          ..color = const Color(0xFF587464).withValues(alpha: 0.18)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(top: 12, left: 12, child: _Bracket(color: color, tl: true)),
        Positioned(top: 12, right: 12, child: _Bracket(color: color, tr: true)),
        Positioned(
          bottom: 12,
          left: 12,
          child: _Bracket(color: color, bl: true),
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: _Bracket(color: color, br: true),
        ),
      ],
    );
  }
}

class _Bracket extends StatelessWidget {
  const _Bracket({
    required this.color,
    this.tl = false,
    this.tr = false,
    this.bl = false,
    this.br = false,
  });

  final Color color;
  final bool tl;
  final bool tr;
  final bool bl;
  final bool br;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        border: Border(
          top: (tl || tr)
              ? BorderSide(color: color.withValues(alpha: 0.56), width: 1.6)
              : BorderSide.none,
          left: (tl || bl)
              ? BorderSide(color: color.withValues(alpha: 0.56), width: 1.6)
              : BorderSide.none,
          right: (tr || br)
              ? BorderSide(color: color.withValues(alpha: 0.56), width: 1.6)
              : BorderSide.none,
          bottom: (bl || br)
              ? BorderSide(color: color.withValues(alpha: 0.56), width: 1.6)
              : BorderSide.none,
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1.5,
            ),
          ),
        ),
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1F1A16).withValues(alpha: 0.88),
        letterSpacing: 0.2,
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    this.buttonKey,
    required this.icon,
    required this.iconColor,
    this.labelColor,
    required this.label,
    this.loading = false,
    required this.onTap,
  });

  final Key? buttonKey;
  final IconData icon;
  final Color iconColor;
  final Color? labelColor;
  final String label;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: buttonKey,
      onTap: loading ? null : onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFECE2D5), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14928B7A),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: iconColor,
                ),
              )
            else
              Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: labelColor ?? const Color(0xFF3A3028),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
