// 涓汉涓績妯″潡椤甸潰锛歚SetLoginPasswordPage`銆傝礋璐ｇ粍缁囧綋鍓嶅満鏅殑涓昏甯冨眬銆佷氦浜掍簨浠朵互鍙婁笌瀵艰埅/鐘舵€佸眰鐨勮鎺ャ€?

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:millet_kyai_apps/core/di/injector.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/core/network/auth_session_store.dart';
import 'package:millet_kyai_apps/core/security/login_password_store.dart';
import 'package:millet_kyai_apps/features/auth/data/models/auth_request.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/auth_session_entity.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/password_register_result_entity.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/verification_code_challenge_entity.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/verification_code_target.dart';
import 'package:millet_kyai_apps/features/auth/domain/repositories/auth_repository.dart';
import 'package:millet_kyai_apps/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:millet_kyai_apps/features/auth/presentation/utils/auth_verification_code_flow.dart';
import 'package:millet_kyai_apps/features/auth/presentation/utils/verification_code_feedback.dart';
import 'package:millet_kyai_apps/features/auth/presentation/widgets/auth_top_toast.dart';
import 'package:millet_kyai_apps/features/profile/presentation/providers/profile_repository_provider.dart';
import 'package:millet_kyai_apps/features/profile/presentation/providers/profile_session_state.dart';

const _kPasswordPageBg = Color(0xFFF4F1EB);
const _kPasswordCardBg = Colors.white;
const _kPasswordPrimary = Color(0xFF2D6A4F);
const _kPasswordTextPrimary = Color(0xFF1E1810);
const _kPasswordTextSecondary = Color(0xFF7A6F63);

class SetLoginPasswordPage extends ConsumerStatefulWidget {
  const SetLoginPasswordPage({super.key});

  @override
  ConsumerState<SetLoginPasswordPage> createState() =>
      _SetLoginPasswordPageState();
}

class _SetLoginPasswordPageState extends ConsumerState<SetLoginPasswordPage>
    with VerificationCodeFlowMixin<SetLoginPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _codeFocusNode = FocusNode();
  final _verificationCodeFlow = VerificationCodeFlowState();
  final _toastController = AuthTopToastController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSaving = false;
  bool _requiresVerification = false;
  String? _accountPhone;
  String? _accountCountryCode;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _codeCtrl.dispose();
    _codeFocusNode.dispose();
    _verificationCodeFlow.dispose();
    _toastController.dispose();
    super.dispose();
  }

  bool get _codeSending => _verificationCodeFlow.codeSending;
  bool get _codeCountingDown => _verificationCodeFlow.codeCountingDown;
  int get _codeCountdown => _verificationCodeFlow.codeCountdown;
  String? get _challengeId => _verificationCodeFlow.challengeId;
  String? get _maskedReceiver => _verificationCodeFlow.maskedReceiver;

  @override
  VerificationCodeFlowState get verificationCodeFlow => _verificationCodeFlow;

  @override
  TextEditingController get verificationCodeController => _codeCtrl;

  @override
  String get currentVerificationAccountValue => _accountPhone ?? '';

  @override
  String? get currentVerificationCountryCode => _accountCountryCode;

  @override
  VerificationCodeTarget get currentVerificationCodeTarget =>
      VerificationCodeTarget.phone(
        value: _accountPhone ?? '',
        countryCode: _accountCountryCode ?? '+86',
      );

  @override
  VerificationCodeScene get verificationCodeScene =>
      VerificationCodeScene.register;

  @override
  String get verificationCodeSuccessMessageText =>
      verificationCodeSentSuccessMessage(
        context,
        isEmail: false,
        fallbackMessage: context.l10n.authCodeSent,
      );

  @override
  void showVerificationError(String message) => _showErrorToast(message);

  @override
  void showVerificationSuccess(String message) => _showSuccessToast(message);

  String? _trimmedOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  void _showErrorToast(String message) {
    if (!mounted) {
      return;
    }
    _toastController.show(context, message);
  }

  void _showSuccessToast(String message) {
    if (!mounted) {
      return;
    }
    _toastController.show(
      context,
      message,
      kind: AuthTopToastKind.success,
      duration: const Duration(seconds: 2),
    );
  }

  Future<bool> _ensurePasswordAccount() async {
    if (_trimmedOrNull(_accountPhone) != null) {
      return true;
    }

    final loginFailedText = context.l10n.authLoginFailed;

    try {
      final profile = await ref.read(profileRepositoryProvider).fetchMe();
      final phone = _trimmedOrNull(profile.phone);
      if (phone == null) {
        _showErrorToast(loginFailedText);
        return false;
      }
      final countryCode = _trimmedOrNull(profile.countryCode) ?? '+86';
      if (!mounted) {
        return false;
      }
      setState(() {
        _accountPhone = phone;
        _accountCountryCode = countryCode;
      });
      return true;
    } on DioException catch (error) {
      _showErrorToast(
        authResponseMessage(error.response?.data) ?? loginFailedText,
      );
      return false;
    } catch (_) {
      _showErrorToast(loginFailedText);
      return false;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_requiresVerification) {
      await _confirmVerificationCode();
      return;
    }

    await _startPasswordSetup();
  }

  Future<void> _startPasswordSetup() async {
    setState(() => _isSaving = true);

    try {
      final accountReady = await _ensurePasswordAccount();
      if (!mounted) {
        return;
      }
      if (!accountReady) {
        setState(() => _isSaving = false);
        return;
      }

      final result = await ref.read(authRepositoryProvider).registerPassword(
            AuthRequest(
              countryCode: _accountCountryCode ?? '',
              phoneNumber: _accountPhone ?? '',
              password: _passwordCtrl.text.trim(),
            ),
          );
      if (!mounted) {
        return;
      }

      if (result.result == PasswordRegisterResultType.registered) {
        await _completePasswordSetup(session: result.session);
        return;
      }

      final challenge = result.challenge;
      if (challenge == null || challenge.challengeId.trim().isEmpty) {
        _showErrorToast(context.l10n.authSendCodeFailed);
        setState(() => _isSaving = false);
        return;
      }

      setState(() {
        _requiresVerification = true;
        _seedVerificationChallenge(challenge);
      });
      final sent = await _sendCodeForPasswordChallenge();
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      if (sent) {
        FocusScope.of(context).requestFocus(_codeFocusNode);
      }
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      _showErrorToast(
        authResponseMessage(error.response?.data) ??
            context.l10n.registerCreateFailed,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      _showErrorToast(context.l10n.registerCreateFailed);
    }
  }

  void _seedVerificationChallenge(VerificationCodeChallengeEntity challenge) {
    resetVerificationCodeState();
    _verificationCodeFlow.challengeId = challenge.challengeId.trim();
    _verificationCodeFlow.challengeExpireAt = challenge.expireAt;
    _verificationCodeFlow.codeTargetValue = _accountPhone;
    _verificationCodeFlow.codeTargetCountryCode = _accountCountryCode;
    _verificationCodeFlow.captchaProvider = challenge.captchaProvider;
    _verificationCodeFlow.captchaInitPayload = challenge.captchaPayload;
    _verificationCodeFlow.captchaVerified = !challenge.captchaRequired;
    _verificationCodeFlow.maskedReceiver = challenge.maskedReceiver;
  }

  Future<void> _confirmVerificationCode() async {
    if (!hasActiveVerificationCodeSubmission) {
      if (isVerificationCodeExpired) {
        setState(() {
          resetVerificationCodeState(clearCode: false);
        });
      }
      _showErrorToast(context.l10n.authSendCodeFirst);
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .authenticateVerificationCode(
            scene: VerificationCodeScene.register,
            challengeId: _challengeId!,
            verificationCode: _codeCtrl.text.trim(),
          );
      await _completePasswordSetup(session: session);
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      final responseData = error.response?.data;
      final code = authResponseCode(responseData);
      if (code == 11119 || code == 11121) {
        resetVerificationCodeState();
        _requiresVerification = false;
      }
      setState(() => _isSaving = false);
      _showErrorToast(
        authResponseMessage(responseData) ?? context.l10n.registerCreateFailed,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      _showErrorToast(context.l10n.registerCreateFailed);
    }
  }

  Future<bool> _sendCodeForPasswordChallenge() async {
    if (_codeSending || _codeCountingDown) {
      return false;
    }
    final challengeId = _challengeId;
    if (challengeId == null || challengeId.isEmpty) {
      _showErrorToast(context.l10n.authSendCodeFirst);
      return false;
    }

    final repository = ref.read(authRepositoryProvider);
    setState(() {
      _verificationCodeFlow.codeSending = true;
    });

    try {
      final captchaVerified = await ensureCaptchaVerifiedIfNeeded(repository);
      if (!mounted) {
        return false;
      }
      if (!captchaVerified) {
        setState(() {
          _verificationCodeFlow.codeSending = false;
        });
        return false;
      }

      final sendResult = await repository.sendCode(challengeId: challengeId);
      showVerificationSuccess(verificationCodeSuccessMessageText);
      if (!mounted) {
        return true;
      }
      startVerificationCodeCountdown(sendResult);
      return true;
    } on DioException catch (error) {
      if (!mounted) {
        return false;
      }
      final responseData = error.response?.data;
      final code = authResponseCode(responseData);
      setState(() {
        _verificationCodeFlow.codeSending = false;
        if (code == 11119 || code == 11121) {
          _requiresVerification = false;
          resetVerificationCodeState();
        } else if (code == 11122 || code == 11123) {
          _verificationCodeFlow.captchaVerified = false;
        }
      });
      _showErrorToast(
        authResponseMessage(responseData) ?? context.l10n.authSendCodeFailed,
      );
      return false;
    } catch (_) {
      if (!mounted) {
        return false;
      }
      setState(() {
        _verificationCodeFlow.codeSending = false;
      });
      _showErrorToast(context.l10n.authSendCodeFailed);
      return false;
    }
  }

  Future<void> _onSendCode() async {
    final accountReady = await _ensurePasswordAccount();
    if (!mounted || !accountReady) {
      return;
    }
    final sent = await _sendCodeForPasswordChallenge();
    if (!mounted) {
      return;
    }
    if (sent) {
      FocusScope.of(context).requestFocus(_codeFocusNode);
    }
  }

  Future<void> _completePasswordSetup({AuthSessionEntity? session}) async {
    if (session != null) {
      await getIt<AuthSessionStore>().saveSession(session);
      await clearProfileScopedPersistence();
      invalidateProfileScopedProviders(ref);
    }
    await getIt<LoginPasswordStore>().setHasLoginPassword(true);
    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPasswordPageBg,
      appBar: AppBar(
        backgroundColor: _kPasswordPageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.setLoginPasswordTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kPasswordTextPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          decoration: BoxDecoration(
            color: _kPasswordCardBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _kPasswordPrimary.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.setLoginPasswordSubtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: _kPasswordTextSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                _PasswordField(
                  controller: _passwordCtrl,
                  label: context.l10n.authPasswordLabel,
                  hintText: context.l10n.registerPasswordHint,
                  obscureText: _obscurePassword,
                  enabled: !_requiresVerification && !_isSaving,
                  onToggle: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return context.l10n.authPasswordMin8;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _PasswordField(
                  controller: _confirmPasswordCtrl,
                  label: context.l10n.authConfirmPasswordLabel,
                  hintText: context.l10n.authConfirmPasswordHint,
                  obscureText: _obscureConfirmPassword,
                  enabled: !_requiresVerification && !_isSaving,
                  onToggle: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                  validator: (value) {
                    if (value != _passwordCtrl.text) {
                      return context.l10n.authPasswordMismatch;
                    }
                    return null;
                  },
                ),
                if (_requiresVerification) ...[
                  const SizedBox(height: 14),
                  _buildCodeField(),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPasswordPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          context.l10n.setLoginPasswordAction,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeField() {
    final l10n = context.l10n;
    final maskedReceiver = _maskedReceiver;
    return Column(
      key: const ValueKey('set_login_password_code_field'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.authVerificationCodeLabel,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kPasswordTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _codeCtrl,
          focusNode: _codeFocusNode,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(kVerificationCodeLength),
          ],
          onChanged: dismissVerificationCodeInputIfComplete,
          style: const TextStyle(fontSize: 14, color: _kPasswordTextPrimary),
          decoration: InputDecoration(
            hintText: l10n.authVerificationCodeHint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFA09080)),
            filled: true,
            fillColor: const Color(0xFFF9F7F2),
            prefixIcon: const Icon(
              Icons.shield_outlined,
              size: 18,
              color: Color(0xFFA09080),
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 94,
              minHeight: 54,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _codeSending
                    ? const SizedBox(
                        key: ValueKey('set_login_password_send_code_loading'),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _kPasswordPrimary,
                        ),
                      )
                    : _codeCountingDown
                    ? Text(
                        l10n.authResendCode(_codeCountdown),
                        key: const ValueKey(
                          'set_login_password_send_code_countdown',
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB28749),
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : TextButton(
                        key: const ValueKey(
                          'set_login_password_send_code_button',
                        ),
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _kPasswordPrimary.withValues(alpha: 0.12),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _kPasswordPrimary.withValues(alpha: 0.12),
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: _kPasswordPrimary),
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
            style: TextStyle(
              fontSize: 12,
              color: _kPasswordTextSecondary.withValues(alpha: 0.82),
            ),
          ),
        ],
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool obscureText;
  final bool enabled;
  final VoidCallback onToggle;
  final String? Function(String?) validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.obscureText,
    required this.enabled,
    required this.onToggle,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kPasswordTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: _kPasswordTextPrimary),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFA09080)),
            filled: true,
            fillColor: const Color(0xFFF9F7F2),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: Color(0xFFA09080),
            ),
            suffixIcon: IconButton(
              onPressed: enabled ? onToggle : null,
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: const Color(0xFFA09080),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _kPasswordPrimary.withValues(alpha: 0.12),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _kPasswordPrimary.withValues(alpha: 0.12),
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: _kPasswordPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
