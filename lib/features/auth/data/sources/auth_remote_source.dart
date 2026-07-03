// 认证远端数据源。负责把登录、注册、验证码和社交认证请求映射到后端移动端接口。

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/verification_code_target.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_request.dart';
import '../models/auth_session_model.dart';
import '../models/password_register_result_model.dart';
import '../models/verification_code_challenge_model.dart';
import '../models/verification_code_send_model.dart';
import '../models/wechat_mini_program_auth_result_model.dart';

class AuthRemoteSource {
  /// 持有共享 Dio 客户端。
  /// 认证相关的请求组装统一放在这里，避免页面层散落接口字段细节。
  final DioClient _dioClient;

  AuthRemoteSource(this._dioClient);

  String? _trimmedOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  Map<String, dynamic> _dataMap(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      throw const FormatException('Invalid response envelope');
    }
    final data = responseData['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Missing response data');
    }
    return data;
  }

  String _sceneValue(VerificationCodeScene scene) {
    return switch (scene) {
      VerificationCodeScene.login => 'LOGIN',
      VerificationCodeScene.register => 'REGISTER',
    };
  }

  Map<String, dynamic> _loginPayload(AuthRequest request) {
    // 登录接口兼容手机号和邮箱，统一通过 loginValue 透传账号主键。
    final loginValue = request.phoneNumber.trim();
    final password = _trimmedOrNull(request.password);
    final countryCode = _trimmedOrNull(request.countryCode);
    final inviteTicket = _trimmedOrNull(request.inviteTicket);
    final payload = <String, dynamic>{'loginValue': loginValue};
    if (countryCode != null) {
      payload['countryCode'] = countryCode;
    }
    if (password != null) {
      payload['password'] = password;
    }
    if (inviteTicket != null) {
      payload['inviteTicket'] = inviteTicket;
    }
    return payload;
  }

  Map<String, dynamic> _passwordRegisterPayload(AuthRequest request) {
    final loginValue = request.phoneNumber.trim();
    final password = _trimmedOrNull(request.password);
    final countryCode = _trimmedOrNull(request.countryCode);
    final inviteTicket = _trimmedOrNull(request.inviteTicket);
    final payload = <String, dynamic>{
      'loginValue': loginValue,
      'phoneNumber': loginValue,
    };
    if (countryCode != null) {
      payload['countryCode'] = countryCode;
    }
    if (password != null) {
      payload['password'] = password;
    }
    if (inviteTicket != null) {
      payload['inviteTicket'] = inviteTicket;
    }
    return payload;
  }

  Future<AuthSessionModel> login(AuthRequest request) async {
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/login/password',
      data: _loginPayload(request),
    );
    return AuthSessionModel.fromJson(_dataMap(response.data));
  }

  Future<AuthSessionModel> register(AuthRequest request) async {
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/register/password',
      data: _passwordRegisterPayload(request),
    );
    return AuthSessionModel.fromJson(_dataMap(response.data));
  }

  Future<WechatMiniProgramAuthResultModel> loginWithWechatMiniProgram({
    required String wechatCode,
    String? inviteTicket,
  }) async {
    final normalizedInviteTicket = _trimmedOrNull(inviteTicket);
    final payload = <String, dynamic>{
      'appId': DioClient.wechatMiniProgramAppId,
      'wechatCode': wechatCode.trim(),
      'inviteTicket': normalizedInviteTicket,
    }..removeWhere((key, value) => value == null);
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/login/wechat-mini-program',
      data: payload,
    );
    return WechatMiniProgramAuthResultModel.fromJson(_dataMap(response.data));
  }

  Future<WechatMiniProgramAuthResultModel> registerWithWechatMiniProgram({
    required String wechatCode,
    required String phoneCode,
    String? inviteTicket,
    String? visitorKey,
  }) async {
    final payload = <String, dynamic>{
      'appId': DioClient.wechatMiniProgramAppId,
      'wechatCode': wechatCode.trim(),
      'phoneCode': phoneCode.trim(),
      'inviteTicket': _trimmedOrNull(inviteTicket),
      'visitorKey': _trimmedOrNull(visitorKey),
    }..removeWhere((key, value) => value == null);
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/register/wechat-mini-program',
      data: payload,
    );
    return WechatMiniProgramAuthResultModel.fromJson(_dataMap(response.data));
  }

  Future<PasswordRegisterResultModel> registerPassword(
    AuthRequest request,
  ) async {
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/register/password',
      data: _passwordRegisterPayload(request),
    );
    return PasswordRegisterResultModel.fromJson(_dataMap(response.data));
  }

  Future<VerificationCodeChallengeModel> createVerificationCodeChallenge({
    required VerificationCodeScene scene,
    required VerificationCodeTarget target,
  }) async {
    // 服务端当前仍同时读取 phoneNumber 和 loginValue，这里双写以兼容
    // 手机号/邮箱两种目标以及旧接口字段约定。
    final loginValue = _trimmedOrNull(target.value) ?? '';
    final normalizedCountryCode = _trimmedOrNull(target.countryCode);
    final challengePayload = <String, dynamic>{
      'scene': _sceneValue(scene),
      'phoneNumber': loginValue,
      'loginValue': loginValue,
    };
    if (normalizedCountryCode != null) {
      challengePayload['countryCode'] = normalizedCountryCode;
    }
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/verification-code/challenge',
      data: challengePayload,
    );
    return VerificationCodeChallengeModel.fromJson(_dataMap(response.data));
  }

  Future<VerificationCodeSendModel> sendCode({
    required String challengeId,
  }) async {
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/verification-code/send',
      data: {'challengeId': challengeId},
    );
    return VerificationCodeSendModel.fromJson(_dataMap(response.data));
  }

  Future<bool> verifyVerificationCodeCaptcha({
    required String challengeId,
    required String captchaProvider,
    required Map<String, String> captchaPayload,
  }) async {
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/verification-code/captcha/verify',
      data: {
        'challengeId': challengeId,
        'captchaProvider': captchaProvider,
        'captchaPayload': captchaPayload,
      },
    );
    return _dataMap(response.data)['captchaVerified'] == true;
  }

  Future<AuthSessionModel> authenticateVerificationCode({
    required VerificationCodeScene scene,
    required String challengeId,
    required String verificationCode,
    String? inviteTicket,
  }) async {
    final response = await _dioClient.dio.post(
      scene == VerificationCodeScene.register
          ? '/api/v1/saas/mobile/auth/register/verification-code'
          : '/api/v1/saas/mobile/auth/login/verification-code',
      data: _verificationCodeAuthPayload(
        challengeId: challengeId,
        verificationCode: verificationCode,
        inviteTicket: inviteTicket,
      ),
    );
    return AuthSessionModel.fromJson(_dataMap(response.data));
  }

  Future<AuthSessionModel> loginByVerificationCode({
    required String challengeId,
    required String verificationCode,
    String? inviteTicket,
  }) async {
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/login/verification-code',
      data: _verificationCodeAuthPayload(
        challengeId: challengeId,
        verificationCode: verificationCode,
        inviteTicket: inviteTicket,
      ),
    );
    return AuthSessionModel.fromJson(_dataMap(response.data));
  }

  Future<AuthSessionModel> registerByVerificationCode({
    required String challengeId,
    required String verificationCode,
    String? inviteTicket,
  }) async {
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/register/verification-code',
      data: _verificationCodeAuthPayload(
        challengeId: challengeId,
        verificationCode: verificationCode,
        inviteTicket: inviteTicket,
      ),
    );
    return AuthSessionModel.fromJson(_dataMap(response.data));
  }

  Map<String, dynamic> _verificationCodeAuthPayload({
    required String challengeId,
    required String verificationCode,
    String? inviteTicket,
  }) {
    return <String, dynamic>{
      'challengeId': challengeId.trim(),
      'verificationCode': verificationCode.trim(),
      'inviteTicket': _trimmedOrNull(inviteTicket),
    }..removeWhere((key, value) => value == null);
  }

  Future<void> logout({required String refreshToken}) async {
    await _dioClient.dio.post(
      '/api/v1/saas/mobile/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  }
}
