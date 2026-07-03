// 个人中心模块领域实体：`ProfileMeEntity`。用于在业务层和展示层之间传递稳定语义，避免直接耦合接口原始结构。

class ProfileMeEntity {
  const ProfileMeEntity({
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
}
