// 认证模块领域实体：`PasswordRegisterResultEntity`。用于在业务层和展示层之间传递稳定语义，避免直接耦合接口原始结构。

import 'auth_session_entity.dart';
import 'verification_code_challenge_entity.dart';

enum PasswordRegisterResultType { registered, verificationCodeRequired }

class PasswordRegisterResultEntity {
  const PasswordRegisterResultEntity({
    required this.result,
    required this.session,
    required this.challenge,
  });

  final PasswordRegisterResultType result;
  final AuthSessionEntity? session;
  final VerificationCodeChallengeEntity? challenge;
}
