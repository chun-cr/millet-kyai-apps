// 个人中心模块数据模型：`ProfileMeModel`。用于承接接口原始字段，并在需要时转换为上层可消费的稳定结构。

import '../../domain/entities/profile_me_entity.dart';

class ProfileMeModel {
  const ProfileMeModel({
    this.globalUserId,
    this.userNo,
    this.nickname,
    this.avatarUrl,
    this.realName,
    this.countryCode,
    this.phone,
    this.gender,
    this.userStatus,
    this.defaultLocale,
    this.defaultTimezone,
    this.lastLoginTime,
    this.registerSource,
  });

  factory ProfileMeModel.fromJson(Map<String, dynamic> json) {
    return ProfileMeModel(
      globalUserId: json['globalUserId'] as String?,
      userNo: json['userNo'] as String?,
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      realName: json['realName'] as String?,
      countryCode: json['countryCode'] as String?,
      phone: json['phone'] as String?,
      gender: json['gender'] as String?,
      userStatus: json['userStatus'] as String?,
      defaultLocale: json['defaultLocale'] as String?,
      defaultTimezone: json['defaultTimezone'] as String?,
      lastLoginTime: json['lastLoginTime'] as String?,
      registerSource: json['registerSource'] as String?,
    );
  }

  final String? globalUserId;
  final String? userNo;
  final String? nickname;
  final String? avatarUrl;
  final String? realName;
  final String? countryCode;
  final String? phone;
  final String? gender;
  final String? userStatus;
  final String? defaultLocale;
  final String? defaultTimezone;
  final String? lastLoginTime;
  final String? registerSource;

  ProfileMeEntity toEntity() {
    return ProfileMeEntity(
      globalUserId: globalUserId,
      userNo: userNo,
      nickname: nickname,
      avatarUrl: avatarUrl,
      realName: realName,
      countryCode: countryCode,
      phone: phone,
      gender: gender,
      userStatus: userStatus,
      defaultLocale: defaultLocale,
      defaultTimezone: defaultTimezone,
      lastLoginTime: lastLoginTime,
      registerSource: registerSource,
    );
  }
}
