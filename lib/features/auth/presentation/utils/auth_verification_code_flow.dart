// 认证模块展示层工具：`AuthVerificationCodeFlow`。负责承载展示层通用的计算、映射或调试辅助逻辑。

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/verification_code_send_entity.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/verification_code_target.dart';
import 'package:millet_kyai_apps/features/auth/domain/repositories/auth_repository.dart';
import 'package:millet_kyai_apps/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:millet_kyai_apps/features/auth/presentation/providers/captcha_resolver_provider.dart';

const int kVerificationCodeLength = 6;

class VerificationCodeFlowState {
  bool codeSending = false;
  bool codeCountingDown = false;
  int codeCountdown = 60;
  Timer? countdownTimer;
  bool verificationCodeSent = false;
  String? codeTargetValue;
  String? codeTargetCountryCode;
  String? challengeId;
  DateTime? challengeExpireAt;
  DateTime? verificationCodeExpireAt;
  String? maskedReceiver;
  String? captchaProvider;
  Map<String, dynamic>? captchaInitPayload;
  bool captchaVerified = false;

  void dispose() {
    countdownTimer?.cancel();
    countdownTimer = null;
  }
}

enum VerificationCodeSendResultType { sent, blocked, failed }

class VerificationCodeSendResult {
  const VerificationCodeSendResult._(
    this.type, {
    this.dioException,
    this.error,
  });

  const VerificationCodeSendResult.sent()
    : this._(VerificationCodeSendResultType.sent);

  const VerificationCodeSendResult.blocked()
    : this._(VerificationCodeSendResultType.blocked);

  const VerificationCodeSendResult.failedDio(DioException dioException)
    : this._(VerificationCodeSendResultType.failed, dioException: dioException);

  const VerificationCodeSendResult.failed(Object error)
    : this._(VerificationCodeSendResultType.failed, error: error);

  final VerificationCodeSendResultType type;
  final DioException? dioException;
  final Object? error;

  bool get isSent => type == VerificationCodeSendResultType.sent;
  bool get isBlocked => type == VerificationCodeSendResultType.blocked;
  bool get isFailed => type == VerificationCodeSendResultType.failed;
}

Object? authResponseCode(dynamic responseData) {
  if (responseData is! Map<String, dynamic>) {
    return null;
  }
  return responseData['code'];
}

String? authResponseMessage(dynamic responseData) {
  if (responseData is! Map<String, dynamic>) {
    return null;
  }
  final message = responseData['message'];
  if (message is String && message.trim().isNotEmpty) {
    return message.trim();
  }
  return null;
}

bool isVerificationCodeUnregisteredError(DioException error) {
  final responseData = error.response?.data;
  final responseCode = authResponseCode(responseData);
  final statusCode = error.response?.statusCode;
  final responseMessage = authResponseMessage(responseData);
  final joinedMessage = [
    responseMessage,
    error.message,
  ].whereType<String>().join(' ').toLowerCase();

  if (statusCode == 404 || responseCode == 404) {
    return true;
  }

  if (responseCode is String) {
    final normalizedCode = responseCode.trim().toUpperCase();
    if (normalizedCode.contains('NOT_REGISTER') ||
        normalizedCode.contains('NOT_FOUND') ||
        normalizedCode.contains('USER_NOT_EXIST') ||
        normalizedCode.contains('ACCOUNT_NOT_EXIST')) {
      return true;
    }
  }

  const keywords = <String>[
    '未注册',
    '尚未注册',
    '未找到',
    '不存在',
    '用户不存在',
    '账号不存在',
    '账户不存在',
    '手机号未注册',
    '邮箱未注册',
    'not registered',
    'unregistered',
    'not found',
    'user not found',
    'account not found',
    'does not exist',
  ];
  return keywords.any((keyword) => joinedMessage.contains(keyword));
}

VerificationCodeSendEntity? verificationCodeSendEntityFromEnvelope(
  dynamic responseData, {
  String? fallbackMaskedReceiver,
}) {
  if (responseData is! Map<String, dynamic>) {
    return null;
  }
  final data = responseData['data'];
  if (data is! Map<String, dynamic>) {
    return null;
  }
  final resendAtRaw = data['resendAt'] as String?;
  final expireAtRaw = data['expireAt'] as String?;
  return VerificationCodeSendEntity(
    channel: (data['channel'] as String?) ?? 'PHONE',
    maskedReceiver:
        (data['maskedReceiver'] as String?) ?? (fallbackMaskedReceiver ?? ''),
    expireAt: expireAtRaw == null ? null : DateTime.tryParse(expireAtRaw),
    resendAt: resendAtRaw == null ? null : DateTime.tryParse(resendAtRaw),
  );
}

mixin VerificationCodeFlowMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  VerificationCodeFlowState get verificationCodeFlow;
  TextEditingController get verificationCodeController;
  String get currentVerificationAccountValue;
  String? get currentVerificationCountryCode;
  VerificationCodeTarget get currentVerificationCodeTarget;
  VerificationCodeScene get verificationCodeScene;
  String get verificationCodeSuccessMessageText;
  void showVerificationError(String message);
  void showVerificationSuccess(String message);

  void resetVerificationCodeState({
    bool clearCode = true,
    bool clearChallenge = true,
  }) {
    verificationCodeFlow.countdownTimer?.cancel();
    verificationCodeFlow.countdownTimer = null;
    verificationCodeFlow.codeSending = false;
    verificationCodeFlow.codeCountingDown = false;
    verificationCodeFlow.codeCountdown = 60;
    verificationCodeFlow.verificationCodeSent = false;
    verificationCodeFlow.codeTargetValue = null;
    verificationCodeFlow.codeTargetCountryCode = null;
    verificationCodeFlow.verificationCodeExpireAt = null;
    verificationCodeFlow.maskedReceiver = null;
    if (clearChallenge) {
      verificationCodeFlow.challengeId = null;
      verificationCodeFlow.challengeExpireAt = null;
      verificationCodeFlow.captchaProvider = null;
      verificationCodeFlow.captchaInitPayload = null;
      verificationCodeFlow.captchaVerified = false;
    }
    if (clearCode) {
      verificationCodeController.clear();
    }
  }

  bool get shouldRefreshVerificationChallenge {
    final challengeId = verificationCodeFlow.challengeId;
    final expireAt = verificationCodeFlow.challengeExpireAt;
    if (challengeId == null || challengeId.isEmpty || expireAt == null) {
      return true;
    }
    return !expireAt.isAfter(DateTime.now());
  }

  bool get isVerificationCodeExpired {
    if (!verificationCodeFlow.verificationCodeSent) {
      return false;
    }
    final expireAt =
        verificationCodeFlow.verificationCodeExpireAt ??
        verificationCodeFlow.challengeExpireAt;
    if (expireAt == null) {
      return false;
    }
    return !expireAt.isAfter(DateTime.now());
  }

  bool get hasActiveVerificationCodeSubmission {
    final challengeId = verificationCodeFlow.challengeId;
    final targetValue = verificationCodeFlow.codeTargetValue;
    if (challengeId == null || challengeId.isEmpty) {
      return false;
    }
    if (!verificationCodeFlow.verificationCodeSent || targetValue == null) {
      return false;
    }
    if (currentVerificationAccountValue != targetValue) {
      return false;
    }
    if (currentVerificationCountryCode !=
        verificationCodeFlow.codeTargetCountryCode) {
      return false;
    }
    return !isVerificationCodeExpired;
  }

  void resetVerificationStateIfTargetChanged(String value) {
    final targetValue = verificationCodeFlow.codeTargetValue;
    if (targetValue == null) {
      return;
    }
    if (value.trim() != targetValue) {
      setState(() {
        resetVerificationCodeState();
      });
    }
  }

  void dismissVerificationCodeInputIfComplete(String value) {
    if (value.trim().length != kVerificationCodeLength) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.hide'));
  }

  Future<bool> ensureCaptchaVerifiedIfNeeded(AuthRepository repository) async {
    final challengeId = verificationCodeFlow.challengeId;
    final provider = verificationCodeFlow.captchaProvider;
    final l10n = context.l10n;
    if (challengeId == null || challengeId.isEmpty) {
      return false;
    }
    if (provider == null ||
        provider.isEmpty ||
        verificationCodeFlow.captchaVerified) {
      return true;
    }

    final payload = await ref
        .read(captchaResolverProvider)
        .resolve(
          context: context,
          challengeId: challengeId,
          provider: provider,
          initPayload: verificationCodeFlow.captchaInitPayload,
        );
    if (!mounted || payload == null) {
      return false;
    }

    try {
      final verified = await repository.verifyVerificationCodeCaptcha(
        challengeId: challengeId,
        captchaProvider: provider,
        captchaPayload: payload,
      );
      if (!mounted) {
        return false;
      }
      if (!verified) {
        showVerificationError(l10n.authCaptchaFailed);
        return false;
      }
      setState(() {
        verificationCodeFlow.captchaVerified = true;
      });
      return true;
    } on DioException catch (error) {
      final responseData = error.response?.data;
      final code = authResponseCode(responseData);
      if (mounted && (code == 11119 || code == 11121)) {
        setState(() {
          resetVerificationCodeState(clearCode: false);
        });
      }
      showVerificationError(
        authResponseMessage(responseData) ?? l10n.authCaptchaFailed,
      );
      return false;
    } catch (_) {
      showVerificationError(l10n.authCaptchaFailed);
      return false;
    }
  }

  Future<VerificationCodeSendResult> sendVerificationCode({
    VerificationCodeScene? sceneOverride,
    bool presentSuccess = true,
    bool presentError = true,
  }) async {
    final l10n = context.l10n;
    if (verificationCodeFlow.codeSending ||
        verificationCodeFlow.codeCountingDown) {
      return const VerificationCodeSendResult.blocked();
    }

    setState(() {
      verificationCodeFlow.codeSending = true;
    });

    try {
      final repository = ref.read(authRepositoryProvider);
      if (shouldRefreshVerificationChallenge) {
        final challenge = await repository.createVerificationCodeChallenge(
          scene: sceneOverride ?? verificationCodeScene,
          target: currentVerificationCodeTarget,
        );
        verificationCodeFlow.challengeId = challenge.challengeId;
        verificationCodeFlow.challengeExpireAt = challenge.expireAt;
        verificationCodeFlow.codeTargetValue = currentVerificationAccountValue;
        verificationCodeFlow.codeTargetCountryCode =
            currentVerificationCountryCode;
        verificationCodeFlow.captchaProvider = challenge.captchaProvider;
        verificationCodeFlow.captchaInitPayload = challenge.captchaPayload;
        verificationCodeFlow.captchaVerified = !challenge.captchaRequired;
      }

      final captchaVerified = await ensureCaptchaVerifiedIfNeeded(repository);
      if (!captchaVerified) {
        if (mounted) {
          setState(() {
            verificationCodeFlow.codeSending = false;
          });
        }
        return const VerificationCodeSendResult.blocked();
      }

      final sendResult = await repository.sendCode(
        challengeId: verificationCodeFlow.challengeId!,
      );
      if (presentSuccess) {
        showVerificationSuccess(verificationCodeSuccessMessageText);
      }
      if (!mounted) {
        return const VerificationCodeSendResult.sent();
      }
      startVerificationCodeCountdown(sendResult);
      return const VerificationCodeSendResult.sent();
    } on DioException catch (error) {
      final responseData = error.response?.data;
      final serverMessage = authResponseMessage(responseData);
      if (mounted) {
        setState(() {
          verificationCodeFlow.codeSending = false;
        });
      }
      final code = authResponseCode(responseData);
      if (code == 11119 || code == 11121) {
        if (mounted) {
          setState(() {
            resetVerificationCodeState();
          });
        }
      }
      if (code == 11122 || code == 11123) {
        if (mounted) {
          setState(() {
            verificationCodeFlow.captchaVerified = false;
          });
        }
      }
      if (code == 11120) {
        final sendResult = verificationCodeSendEntityFromEnvelope(
          responseData,
          fallbackMaskedReceiver: verificationCodeFlow.maskedReceiver,
        );
        if (sendResult != null && mounted) {
          startVerificationCodeCountdown(sendResult);
        }
        if (sendResult != null) {
          if (presentError) {
            showVerificationError(serverMessage ?? l10n.authSendCodeFailed);
          }
          return const VerificationCodeSendResult.sent();
        }
      }
      if (presentError) {
        showVerificationError(serverMessage ?? l10n.authSendCodeFailed);
      }
      return VerificationCodeSendResult.failedDio(error);
    } catch (_) {
      if (mounted) {
        setState(() {
          verificationCodeFlow.codeSending = false;
        });
      }
      if (presentError) {
        showVerificationError(l10n.authSendCodeFailed);
      }
      return const VerificationCodeSendResult.failed('unknown');
    }
  }

  void startVerificationCodeCountdown(VerificationCodeSendEntity sendResult) {
    verificationCodeFlow.countdownTimer?.cancel();
    verificationCodeFlow.countdownTimer = null;

    final seconds = _secondsUntil(sendResult.resendAt);
    setState(() {
      verificationCodeFlow.codeSending = false;
      verificationCodeFlow.codeCountingDown = seconds > 0;
      verificationCodeFlow.codeCountdown = seconds > 0 ? seconds : 60;
      verificationCodeFlow.verificationCodeSent = true;
      verificationCodeFlow.codeTargetValue = currentVerificationAccountValue;
      verificationCodeFlow.codeTargetCountryCode =
          currentVerificationCountryCode;
      verificationCodeFlow.verificationCodeExpireAt =
          sendResult.expireAt ?? verificationCodeFlow.challengeExpireAt;
      verificationCodeFlow.maskedReceiver = sendResult.maskedReceiver;
    });

    if (seconds <= 0) {
      return;
    }

    verificationCodeFlow.countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          verificationCodeFlow.countdownTimer = null;
          return;
        }
        setState(() {
          verificationCodeFlow.codeCountdown--;
        });
        if (verificationCodeFlow.codeCountdown <= 0) {
          timer.cancel();
          setState(() {
            verificationCodeFlow.countdownTimer = null;
            verificationCodeFlow.codeCountingDown = false;
            verificationCodeFlow.codeCountdown = 60;
          });
        }
      },
    );
  }

  int _secondsUntil(DateTime? target) {
    if (target == null) {
      return 60;
    }
    final diff = target.difference(DateTime.now()).inSeconds;
    return diff <= 0 ? 0 : diff;
  }
}
