// 认证模块数据模型：`VerificationCodeSendModel`。用于承接接口原始字段，并在需要时转换为上层可消费的稳定结构。

class VerificationCodeSendModel {
  final String channel;
  final String maskedReceiver;
  final DateTime? expireAt;
  final DateTime? resendAt;

  const VerificationCodeSendModel({
    required this.channel,
    required this.maskedReceiver,
    required this.expireAt,
    required this.resendAt,
  });

  factory VerificationCodeSendModel.fromJson(Map<String, dynamic> json) {
    final expireAtRaw = json['expireAt'] as String?;
    final resendAtRaw = json['resendAt'] as String?;

    return VerificationCodeSendModel(
      channel: (json['channel'] as String?) ?? 'PHONE',
      maskedReceiver: (json['maskedReceiver'] as String?) ?? '',
      expireAt: expireAtRaw == null ? null : DateTime.tryParse(expireAtRaw),
      resendAt: resendAtRaw == null ? null : DateTime.tryParse(resendAtRaw),
    );
  }
}
