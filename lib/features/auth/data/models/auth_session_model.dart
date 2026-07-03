// 认证模块数据模型：`AuthSessionModel`。用于承接接口原始字段，并在需要时转换为上层可消费的稳定结构。

class AuthSessionModel {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final String scope;

  const AuthSessionModel({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.scope,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    String requiredString(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Missing or empty auth session field: $key');
      }
      return value;
    }

    int requiredInt(String key) {
      final value = json[key];
      if (value is num) {
        return value.toInt();
      }
      throw FormatException('Missing or invalid auth session field: $key');
    }

    return AuthSessionModel(
      accessToken: requiredString('accessToken'),
      refreshToken: requiredString('refreshToken'),
      tokenType: requiredString('tokenType'),
      expiresIn: requiredInt('expiresIn'),
      scope: requiredString('scope'),
    );
  }
}
