// 认证模块数据模型：`VerificationCodeChallengeModel`。用于承接接口原始字段，并在需要时转换为上层可消费的稳定结构。

class VerificationCodeChallengeModel {
  final String challengeId;
  final bool captchaRequired;
  final String? captchaProvider;
  final Map<String, dynamic>? captchaPayload;
  final String? channel;
  final String? maskedReceiver;
  final DateTime? expireAt;
  final DateTime? resendAt;

  const VerificationCodeChallengeModel({
    required this.challengeId,
    required this.captchaRequired,
    required this.captchaProvider,
    required this.captchaPayload,
    this.channel,
    this.maskedReceiver,
    required this.expireAt,
    this.resendAt,
  });

  factory VerificationCodeChallengeModel.fromJson(Map<String, dynamic> json) {
    final captcha = json['captcha'] as Map<String, dynamic>?;
    final expireAtRaw = json['expireAt'] as String?;
    final resendAtRaw = json['resendAt'] as String?;

    return VerificationCodeChallengeModel(
      challengeId: (json['challengeId'] as String?) ?? '',
      captchaRequired: json['captchaRequired'] as bool? ?? false,
      captchaProvider: captcha?['provider'] as String?,
      captchaPayload: captcha?['payload'] as Map<String, dynamic>?,
      channel: json['channel'] as String?,
      maskedReceiver: json['maskedReceiver'] as String?,
      expireAt: expireAtRaw == null ? null : DateTime.tryParse(expireAtRaw),
      resendAt: resendAtRaw == null ? null : DateTime.tryParse(resendAtRaw),
    );
  }
}
