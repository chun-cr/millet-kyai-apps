// 认证模块领域实体：`AuthSessionEntity`。用于在业务层和展示层之间传递稳定语义，避免直接耦合接口原始结构。

class AuthSessionEntity {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final String scope;

  const AuthSessionEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.scope,
  });
}
