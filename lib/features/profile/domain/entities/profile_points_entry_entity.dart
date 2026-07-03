// 个人中心模块领域实体：`ProfilePointsEntryEntity`。用于在业务层和展示层之间传递稳定语义，避免直接耦合接口原始结构。

class ProfilePointsEntryEntity {
  const ProfilePointsEntryEntity({
    required this.id,
    required this.description,
    required this.remarks,
    required this.incomeAmount,
    required this.createTime,
  });

  final String id;
  final String description;
  final String remarks;
  final int incomeAmount;
  final DateTime createTime;

  bool get isIncome => incomeAmount >= 0;

  String get title {
    final normalizedDescription = description.trim();
    if (normalizedDescription.isNotEmpty) {
      return normalizedDescription;
    }
    final normalizedRemarks = remarks.trim();
    if (normalizedRemarks.isNotEmpty) {
      return normalizedRemarks;
    }
    return id;
  }

  String get subtitle => remarks.trim();

  factory ProfilePointsEntryEntity.fromJson(Map<String, dynamic> json) {
    return ProfilePointsEntryEntity(
      id: _normalizedString(json['id']) ?? '',
      description: _normalizedString(json['description']) ?? '',
      remarks: _normalizedString(json['remarks']) ?? '',
      incomeAmount: _normalizedInt(json['incomeAmount']),
      createTime:
          DateTime.tryParse(_normalizedString(json['createTime']) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'remarks': remarks,
      'incomeAmount': incomeAmount,
      'createTime': createTime.toIso8601String(),
    };
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
