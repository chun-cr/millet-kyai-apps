// 个人中心模块领域实体：`ProfilePointsTaskEntity`。用于在业务层和展示层之间传递稳定语义，避免直接耦合接口原始结构。

class ProfilePointsTaskEntity {
  const ProfilePointsTaskEntity({
    required this.code,
    required this.name,
    required this.amount,
    required this.description,
    required this.finishTimesTip,
    required this.extra,
    required this.btnName,
    required this.path,
  });

  final String code;
  final String name;
  final int amount;
  final String description;
  final String finishTimesTip;
  final Map<String, dynamic> extra;
  final String btnName;
  final String path;

  bool get hasPath => path.trim().isNotEmpty;

  factory ProfilePointsTaskEntity.fromJson(Map<String, dynamic> json) {
    final extra = json['extra'];
    return ProfilePointsTaskEntity(
      code: _normalizedString(json['code']) ?? '',
      name: _normalizedString(json['name']) ?? '',
      amount: _normalizedInt(json['amount']),
      description: _normalizedString(json['description']) ?? '',
      finishTimesTip: _normalizedString(json['finishTimesTip']) ?? '',
      extra: extra is Map<String, dynamic>
          ? extra
          : extra is Map
          ? Map<String, dynamic>.from(extra)
          : const {},
      btnName: _normalizedString(json['btnName']) ?? '',
      path: _normalizedString(json['path']) ?? '',
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
