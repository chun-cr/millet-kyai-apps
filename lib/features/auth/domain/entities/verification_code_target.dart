// 认证模块领域实体：`VerificationCodeTarget`。用于在业务层和展示层之间传递稳定语义，避免直接耦合接口原始结构。

enum VerificationCodeTargetType { phone, email }

class VerificationCodeTarget {
  const VerificationCodeTarget.phone({
    required this.value,
    required this.countryCode,
  }) : type = VerificationCodeTargetType.phone,
       assert(countryCode != null);

  const VerificationCodeTarget.email({required this.value})
    : type = VerificationCodeTargetType.email,
      countryCode = null;

  final VerificationCodeTargetType type;
  final String value;
  final String? countryCode;

  bool get isEmail => type == VerificationCodeTargetType.email;
}
