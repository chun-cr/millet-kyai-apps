// 个人中心模块领域实体：`ProfilePointsAccountStatEntity`。用于在业务层和展示层之间传递稳定语义，避免直接耦合接口原始结构。

class ProfilePointsAccountStatEntity {
  const ProfilePointsAccountStatEntity({
    required this.id,
    required this.userId,
    required this.availableAmount,
    required this.hisTotalAmount,
    required this.todayGainAmount,
    required this.weekGainAmount,
    required this.signIn,
  });

  final String id;
  final String userId;
  final int availableAmount;
  final int hisTotalAmount;
  final int todayGainAmount;
  final int weekGainAmount;
  final bool signIn;

  factory ProfilePointsAccountStatEntity.fromJson(Map<String, dynamic> json) {
    return ProfilePointsAccountStatEntity(
      id: _normalizedString(json['id']) ?? '',
      userId: _normalizedString(json['userId']) ?? '',
      availableAmount: _normalizedInt(json['availableAmount']),
      hisTotalAmount: _normalizedInt(json['hisTotalAmount']),
      todayGainAmount: _normalizedInt(json['todayGainAmount']),
      weekGainAmount: _normalizedInt(json['weekGainAmount']),
      signIn: json['signIn'] as bool? ?? false,
    );
  }
}

String? _normalizedString(dynamic value) {
  final trimmed = value?.toString().trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

int _normalizedInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
