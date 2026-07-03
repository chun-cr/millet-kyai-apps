// 分享域应用标识映射实体。用于承接当前客户端与分享后台之间的 appId 对应关系。

class AppIdMappingEntity {
  const AppIdMappingEntity({
    this.appId = '',
    this.tenantId = '',
    this.topOrgId = '',
    this.storeId = '',
    this.clinicId = '',
    this.defaultStoreId = '',
    this.defaultClinicId = '',
    this.raw = const <String, dynamic>{},
  });

  final String appId;
  final String tenantId;
  final String topOrgId;
  final String storeId;
  final String clinicId;
  final String defaultStoreId;
  final String defaultClinicId;
  final Map<String, dynamic> raw;

  bool get isEmpty =>
      appId.isEmpty &&
      tenantId.isEmpty &&
      topOrgId.isEmpty &&
      storeId.isEmpty &&
      clinicId.isEmpty &&
      defaultStoreId.isEmpty &&
      defaultClinicId.isEmpty &&
      raw.isEmpty;

  factory AppIdMappingEntity.fromJson(Map<String, dynamic> json) {
    final raw = Map<String, dynamic>.from(json);
    return AppIdMappingEntity(
      appId: _readString(raw['appId']),
      tenantId: _readString(raw['tenantId']),
      topOrgId: _readString(raw['topOrgId']),
      storeId: _readString(raw['storeId']),
      clinicId: _readString(raw['clinicId']),
      defaultStoreId: _readString(raw['defaultStoreId']),
      defaultClinicId: _readString(raw['defaultClinicId']),
      raw: raw,
    );
  }

  Map<String, dynamic> toJson() {
    if (raw.isNotEmpty) {
      return Map<String, dynamic>.from(raw);
    }

    final data = <String, dynamic>{
      'appId': appId,
      'tenantId': tenantId,
      'topOrgId': topOrgId,
      'storeId': storeId,
      'clinicId': clinicId,
      'defaultStoreId': defaultStoreId,
      'defaultClinicId': defaultClinicId,
    };
    data.removeWhere((key, value) => value is String && value.trim().isEmpty);
    return data;
  }
}

String _readString(dynamic value) {
  return value == null ? '' : value.toString().trim();
}
