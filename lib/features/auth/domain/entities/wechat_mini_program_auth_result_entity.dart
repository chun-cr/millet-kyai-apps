// 认证模块领域实体：`WechatMiniProgramAuthResultEntity`。用于在业务层和展示层之间传递稳定语义，避免直接耦合接口原始结构。

import 'auth_session_entity.dart';

class WechatMiniProgramAuthResultEntity {
  final String authStatus;
  final AuthSessionEntity? session;
  final String? globalUserId;
  final String? phoneNumber;

  const WechatMiniProgramAuthResultEntity({
    required this.authStatus,
    required this.session,
    required this.globalUserId,
    this.phoneNumber,
  });

  bool get hasSession => session != null;
}
