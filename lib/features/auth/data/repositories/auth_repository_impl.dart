// 认证模块仓储实现：`AuthRepositoryImpl`。负责组合数据源结果，并向上层输出稳定的业务数据。

import '../../domain/entities/auth_session_entity.dart';
import '../../domain/entities/password_register_result_entity.dart';
import '../../domain/entities/verification_code_challenge_entity.dart';
import '../../domain/entities/verification_code_send_entity.dart';
import '../../domain/entities/verification_code_target.dart';
import '../../domain/entities/wechat_mini_program_auth_result_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_request.dart';
import '../models/auth_session_model.dart';
import '../models/password_register_result_model.dart';
import '../models/wechat_mini_program_auth_result_model.dart';
import '../sources/auth_remote_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteSource _remoteSource;

  AuthRepositoryImpl(this._remoteSource);

  @override
  Future<AuthSessionEntity> login(AuthRequest request) async {
    final model = await _remoteSource.login(request);
    return _sessionEntity(model);
  }

  @override
  Future<AuthSessionEntity> register(AuthRequest request) async {
    final model = await _remoteSource.register(request);
    return _sessionEntity(model);
  }

  @override
  Future<WechatMiniProgramAuthResultEntity> loginWithWechatMiniProgram({
    required String wechatCode,
    String? inviteTicket,
  }) async {
    final model = await _remoteSource.loginWithWechatMiniProgram(
      wechatCode: wechatCode,
      inviteTicket: inviteTicket,
    );
    return _wechatAuthResultEntity(model);
  }

  @override
  Future<WechatMiniProgramAuthResultEntity> registerWithWechatMiniProgram({
    required String wechatCode,
    required String phoneCode,
    String? inviteTicket,
    String? visitorKey,
  }) async {
    final model = await _remoteSource.registerWithWechatMiniProgram(
      wechatCode: wechatCode,
      phoneCode: phoneCode,
      inviteTicket: inviteTicket,
      visitorKey: visitorKey,
    );
    return _wechatAuthResultEntity(model);
  }

  @override
  Future<PasswordRegisterResultEntity> registerPassword(
    AuthRequest request,
  ) async {
    final model = await _remoteSource.registerPassword(request);
    return PasswordRegisterResultEntity(
      result:
          model.result ==
              PasswordRegisterResultTypeModel.verificationCodeRequired
          ? PasswordRegisterResultType.verificationCodeRequired
          : PasswordRegisterResultType.registered,
      session: model.session == null ? null : _sessionEntity(model.session!),
      challenge: model.challenge == null
          ? null
          : VerificationCodeChallengeEntity(
              challengeId: model.challenge!.challengeId,
              captchaRequired: model.challenge!.captchaRequired,
              captchaProvider: model.challenge!.captchaProvider,
              captchaPayload: model.challenge!.captchaPayload,
              expireAt: model.challenge!.expireAt,
            ),
    );
  }

  @override
  Future<VerificationCodeChallengeEntity> createVerificationCodeChallenge({
    required VerificationCodeScene scene,
    required VerificationCodeTarget target,
  }) async {
    final model = await _remoteSource.createVerificationCodeChallenge(
      scene: scene,
      target: target,
    );
    return VerificationCodeChallengeEntity(
      challengeId: model.challengeId,
      captchaRequired: model.captchaRequired,
      captchaProvider: model.captchaProvider,
      captchaPayload: model.captchaPayload,
      channel: model.channel,
      maskedReceiver: model.maskedReceiver,
      expireAt: model.expireAt,
      resendAt: model.resendAt,
    );
  }

  @override
  Future<VerificationCodeSendEntity> sendCode({
    required String challengeId,
  }) async {
    final model = await _remoteSource.sendCode(challengeId: challengeId);
    return VerificationCodeSendEntity(
      channel: model.channel,
      maskedReceiver: model.maskedReceiver,
      expireAt: model.expireAt,
      resendAt: model.resendAt,
    );
  }

  @override
  Future<bool> verifyVerificationCodeCaptcha({
    required String challengeId,
    required String captchaProvider,
    required Map<String, String> captchaPayload,
  }) {
    return _remoteSource.verifyVerificationCodeCaptcha(
      challengeId: challengeId,
      captchaProvider: captchaProvider,
      captchaPayload: captchaPayload,
    );
  }

  @override
  Future<AuthSessionEntity> authenticateVerificationCode({
    required VerificationCodeScene scene,
    required String challengeId,
    required String verificationCode,
    String? inviteTicket,
  }) async {
    final model = await _remoteSource.authenticateVerificationCode(
      scene: scene,
      challengeId: challengeId,
      verificationCode: verificationCode,
      inviteTicket: inviteTicket,
    );
    return _sessionEntity(model);
  }

  @override
  Future<AuthSessionEntity> loginByVerificationCode({
    required String challengeId,
    required String verificationCode,
    String? inviteTicket,
  }) async {
    final model = await _remoteSource.loginByVerificationCode(
      challengeId: challengeId,
      verificationCode: verificationCode,
      inviteTicket: inviteTicket,
    );
    return _sessionEntity(model);
  }

  @override
  Future<AuthSessionEntity> registerByVerificationCode({
    required String challengeId,
    required String verificationCode,
    String? inviteTicket,
  }) async {
    final model = await _remoteSource.registerByVerificationCode(
      challengeId: challengeId,
      verificationCode: verificationCode,
      inviteTicket: inviteTicket,
    );
    return _sessionEntity(model);
  }

  @override
  Future<void> logout({required String refreshToken}) {
    return _remoteSource.logout(refreshToken: refreshToken);
  }

  AuthSessionEntity _sessionEntity(AuthSessionModel model) {
    return AuthSessionEntity(
      accessToken: model.accessToken,
      refreshToken: model.refreshToken,
      tokenType: model.tokenType,
      expiresIn: model.expiresIn,
      scope: model.scope,
    );
  }

  WechatMiniProgramAuthResultEntity _wechatAuthResultEntity(
    WechatMiniProgramAuthResultModel model,
  ) {
    return WechatMiniProgramAuthResultEntity(
      authStatus: model.authStatus,
      session: model.token == null ? null : _sessionEntity(model.token!),
      globalUserId: model.globalUserId,
      phoneNumber: model.phoneNumber,
    );
  }
}
