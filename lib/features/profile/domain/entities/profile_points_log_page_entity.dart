// 个人中心模块领域实体：`ProfilePointsLogPageEntity`。用于在业务层和展示层之间传递稳定语义，避免直接耦合接口原始结构。

import 'profile_points_entry_entity.dart';

class ProfilePointsLogPageEntity {
  const ProfilePointsLogPageEntity({
    required this.records,
    required this.total,
    required this.pageNo,
    required this.pageSize,
  });

  final List<ProfilePointsEntryEntity> records;
  final int total;
  final int pageNo;
  final int pageSize;

  bool get hasMore => records.length < total;

  factory ProfilePointsLogPageEntity.fromJson(Map<String, dynamic> json) {
    final records = json['records'];
    return ProfilePointsLogPageEntity(
      records: records is List
          ? records
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .map(ProfilePointsEntryEntity.fromJson)
                .toList(growable: false)
          : const [],
      total: _normalizedInt(json['total']),
      pageNo: _normalizedInt(json['pageNo']),
      pageSize: _normalizedInt(json['pageSize']),
    );
  }
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
