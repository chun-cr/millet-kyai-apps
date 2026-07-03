// 个人中心模块领域实体：`ProfileShippingAddressEntity`。用于在业务层和展示层之间传递稳定语义，避免直接耦合接口原始结构。

class ProfileShippingAddressEntity {
  const ProfileShippingAddressEntity({
    required this.id,
    required this.receiverName,
    required this.receiverMobile,
    required this.provinceCode,
    required this.provinceName,
    required this.cityCode,
    required this.cityName,
    required this.districtCode,
    required this.districtName,
    this.streetCode,
    this.streetName,
    required this.detailAddress,
    required this.isDefault,
  });

  final String id;
  final String receiverName;
  final String receiverMobile;
  final String provinceCode;
  final String provinceName;
  final String cityCode;
  final String cityName;
  final String districtCode;
  final String districtName;
  final String? streetCode;
  final String? streetName;
  final String detailAddress;
  final bool isDefault;

  String get phone => receiverMobile;

  String get regionLabel {
    final parts = [
      provinceName,
      cityName,
      districtName,
      _normalizedString(streetName),
    ].whereType<String>().where((item) => item.trim().isNotEmpty);
    return parts.join(' ');
  }

  String get fullAddress {
    final parts = [
      regionLabel,
      detailAddress.trim(),
    ].where((item) => item.trim().isNotEmpty);
    return parts.join(' ');
  }

  ProfileShippingAddressEntity copyWith({
    String? id,
    String? receiverName,
    String? receiverMobile,
    String? provinceCode,
    String? provinceName,
    String? cityCode,
    String? cityName,
    String? districtCode,
    String? districtName,
    String? streetCode,
    String? streetName,
    String? detailAddress,
    bool? isDefault,
  }) {
    return ProfileShippingAddressEntity(
      id: id ?? this.id,
      receiverName: receiverName ?? this.receiverName,
      receiverMobile: receiverMobile ?? this.receiverMobile,
      provinceCode: provinceCode ?? this.provinceCode,
      provinceName: provinceName ?? this.provinceName,
      cityCode: cityCode ?? this.cityCode,
      cityName: cityName ?? this.cityName,
      districtCode: districtCode ?? this.districtCode,
      districtName: districtName ?? this.districtName,
      streetCode: streetCode ?? this.streetCode,
      streetName: streetName ?? this.streetName,
      detailAddress: detailAddress ?? this.detailAddress,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory ProfileShippingAddressEntity.fromJson(Map<String, dynamic> json) {
    final legacyRegion = _normalizedString(json['region']);
    final legacyTag = _normalizedString(json['tag']);
    return ProfileShippingAddressEntity(
      id:
          _normalizedString(json['addressId']) ??
          _normalizedString(json['id']) ??
          '',
      receiverName: _normalizedString(json['receiverName']) ?? '',
      receiverMobile:
          _normalizedString(json['receiverMobile']) ??
          _normalizedString(json['phone']) ??
          '',
      provinceCode: _normalizedString(json['provinceCode']) ?? '',
      provinceName:
          _normalizedString(json['provinceName']) ?? legacyRegion ?? '',
      cityCode: _normalizedString(json['cityCode']) ?? '',
      cityName: _normalizedString(json['cityName']) ?? '',
      districtCode: _normalizedString(json['districtCode']) ?? '',
      districtName: _normalizedString(json['districtName']) ?? '',
      streetCode: _normalizedString(json['streetCode']),
      streetName: _normalizedString(json['streetName']) ?? legacyTag,
      detailAddress: _normalizedString(json['detailAddress']) ?? '',
      isDefault:
          json['defaultAddress'] as bool? ??
          json['isDefault'] as bool? ??
          false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addressId': id,
      'receiverName': receiverName,
      'receiverMobile': receiverMobile,
      'provinceCode': provinceCode,
      'provinceName': provinceName,
      'cityCode': cityCode,
      'cityName': cityName,
      'districtCode': districtCode,
      'districtName': districtName,
      'streetCode': streetCode,
      'streetName': streetName,
      'detailAddress': detailAddress,
      'defaultAddress': isDefault,
    };
  }

  Map<String, dynamic> toCreateRequestJson() {
    final payload = <String, dynamic>{
      'receiverName': receiverName,
      'receiverMobile': receiverMobile,
      'provinceCode': provinceCode,
      'provinceName': provinceName,
      'cityCode': cityCode,
      'cityName': cityName,
      'districtCode': districtCode,
      'districtName': districtName,
      'detailAddress': detailAddress,
      'defaultAddress': isDefault,
    };

    final normalizedStreetCode = _normalizedString(streetCode);
    final normalizedStreetName = _normalizedString(streetName);
    if (normalizedStreetCode != null) {
      payload['streetCode'] = normalizedStreetCode;
    }
    if (normalizedStreetName != null) {
      payload['streetName'] = normalizedStreetName;
    }
    return payload;
  }
}

String? _normalizedString(dynamic value) {
  final trimmed = value?.toString().trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
