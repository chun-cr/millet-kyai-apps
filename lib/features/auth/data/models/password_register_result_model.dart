// 认证模块数据模型：`PasswordRegisterResultModel`。用于承接接口原始字段，并在需要时转换为上层可消费的稳定结构。

import 'auth_session_model.dart';
import 'verification_code_challenge_model.dart';

enum PasswordRegisterResultTypeModel { registered, verificationCodeRequired }

class PasswordRegisterResultModel {
  const PasswordRegisterResultModel({
    required this.result,
    required this.session,
    required this.challenge,
  });

  final PasswordRegisterResultTypeModel result;
  final AuthSessionModel? session;
  final VerificationCodeChallengeModel? challenge;

  factory PasswordRegisterResultModel.fromJson(Map<String, dynamic> json) {
    final resultRaw = (json['result'] as String?)?.trim();
    final token = json['token'];
    final challenge = json['challenge'];
    final hasChallenge = challenge is Map<String, dynamic>;
    final hasToken = token is Map<String, dynamic> || _looksLikeTokenMap(json);
    final result = resultRaw == 'VERIFICATION_CODE_REQUIRED' || hasChallenge
        ? PasswordRegisterResultTypeModel.verificationCodeRequired
        : PasswordRegisterResultTypeModel.registered;

    return PasswordRegisterResultModel(
      result: result,
      session: hasToken
          ? AuthSessionModel.fromJson(
              token is Map<String, dynamic> ? token : json,
            )
          : null,
      challenge: hasChallenge
          ? VerificationCodeChallengeModel.fromJson(challenge)
          : null,
    );
  }

  static bool _looksLikeTokenMap(Map<String, dynamic> json) {
    return json['accessToken'] is String &&
        json['refreshToken'] is String &&
        json['tokenType'] is String &&
        json['expiresIn'] != null;
  }
}
