// 认证模块领域实体：`VerificationCodeSendEntity`。用于在业务层和展示层之间传递稳定语义，避免直接耦合接口原始结构。

class VerificationCodeSendEntity {
  final String channel;
  final String maskedReceiver;
  final DateTime? expireAt;
  final DateTime? resendAt;

  const VerificationCodeSendEntity({
    required this.channel,
    required this.maskedReceiver,
    required this.expireAt,
    required this.resendAt,
  });
}
