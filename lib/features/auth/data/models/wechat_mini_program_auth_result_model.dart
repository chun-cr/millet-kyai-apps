// 认证模块数据模型：`WechatMiniProgramAuthResultModel`。用于承接接口原始字段，并在需要时转换为上层可消费的稳定结构。

import 'auth_session_model.dart';

class WechatMiniProgramAuthResultModel {
  final String authStatus;
  final AuthSessionModel? token;
  final String? globalUserId;
  final String? phoneNumber;

  const WechatMiniProgramAuthResultModel({
    required this.authStatus,
    required this.token,
    required this.globalUserId,
    this.phoneNumber,
  });

  factory WechatMiniProgramAuthResultModel.fromJson(Map<String, dynamic> json) {
    String normalizedString(String key) {
      final value = json[key];
      if (value is! String) {
        return '';
      }
      return value.trim();
    }

    String? optionalString(String key) {
      final value = json[key];
      if (value is! String) {
        return null;
      }
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      return trimmed;
    }

    final tokenJson = json['token'];
    return WechatMiniProgramAuthResultModel(
      authStatus: normalizedString('authStatus'),
      token: tokenJson is Map<String, dynamic>
          ? AuthSessionModel.fromJson(tokenJson)
          : null,
      globalUserId: optionalString('globalUserId'),
      phoneNumber: optionalString('phoneNumber'),
    );
  }
}
