// 认证模块仓储契约：`AuthRepository`。对上提供稳定业务接口，对下屏蔽远端与本地数据细节。

import '../../data/models/auth_request.dart';
import '../entities/auth_session_entity.dart';
import '../entities/password_register_result_entity.dart';
import '../entities/verification_code_challenge_entity.dart';
import '../entities/verification_code_send_entity.dart';
import '../entities/verification_code_target.dart';
import '../entities/wechat_mini_program_auth_result_entity.dart';

enum VerificationCodeScene { login, register }

abstract class AuthRepository {
  Future<AuthSessionEntity> login(AuthRequest request);
  Future<AuthSessionEntity> register(AuthRequest request);
  Future<PasswordRegisterResultEntity> registerPassword(AuthRequest request);
  Future<WechatMiniProgramAuthResultEntity> loginWithWechatMiniProgram({
    required String wechatCode,
    String? inviteTicket,
  });
  Future<WechatMiniProgramAuthResultEntity> registerWithWechatMiniProgram({
    required String wechatCode,
    required String phoneCode,
    String? inviteTicket,
    String? visitorKey,
  });

  Future<VerificationCodeChallengeEntity> createVerificationCodeChallenge({
    required VerificationCodeScene scene,
    required VerificationCodeTarget target,
  });
  Future<VerificationCodeSendEntity> sendCode({required String challengeId});
  Future<bool> verifyVerificationCodeCaptcha({
    required String challengeId,
    required String captchaProvider,
    required Map<String, String> captchaPayload,
  });
  Future<AuthSessionEntity> authenticateVerificationCode({
    required VerificationCodeScene scene,
    required String challengeId,
    required String verificationCode,
    String? inviteTicket,
  });
  Future<AuthSessionEntity> loginByVerificationCode({
    required String challengeId,
    required String verificationCode,
    String? inviteTicket,
  });
  Future<AuthSessionEntity> registerByVerificationCode({
    required String challengeId,
    required String verificationCode,
    String? inviteTicket,
  });
  Future<void> logout({required String refreshToken});
}

class AuthRepositoryAdapter implements AuthRepository {
  @override
  Future<AuthSessionEntity> login(AuthRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSessionEntity> register(AuthRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<PasswordRegisterResultEntity> registerPassword(AuthRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<WechatMiniProgramAuthResultEntity> loginWithWechatMiniProgram({
    required String wechatCode,
    String? inviteTicket,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WechatMiniProgramAuthResultEntity> registerWithWechatMiniProgram({
    required String wechatCode,
    required String phoneCode,
    String? inviteTicket,
    String? visitorKey,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<VerificationCodeChallengeEntity> createVerificationCodeChallenge({
    required VerificationCodeScene scene,
    required VerificationCodeTarget target,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<VerificationCodeSendEntity> sendCode({required String challengeId}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> verifyVerificationCodeCaptcha({
    required String challengeId,
    required String captchaProvider,
    required Map<String, String> captchaPayload,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSessionEntity> authenticateVerificationCode({
    required VerificationCodeScene scene,
    required String challengeId,
    required String verificationCode,
    String? inviteTicket,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSessionEntity> loginByVerificationCode({
    required String challengeId,
    required String verificationCode,
    String? inviteTicket,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSessionEntity> registerByVerificationCode({
    required String challengeId,
    required String verificationCode,
    String? inviteTicket,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout({required String refreshToken}) {
    throw UnimplementedError();
  }
}
