// 游客邀约上下文实体。把 inviteTicket、跳转目标和 visitorKey 等登录前链路状态收敛到一个对象里。

class GuestInviteContextEntity {
  const GuestInviteContextEntity({
    this.inviteShareId = '',
    this.inviteTicket = '',
    this.inviteTicketExpireTime = '',
    this.visitorKey = '',
    this.redirect = '',
    this.wechatCode = '',
  });

  final String inviteShareId;
  final String inviteTicket;
  final String inviteTicketExpireTime;
  final String visitorKey;
  final String redirect;
  final String wechatCode;

  bool get hasShareId => inviteShareId.isNotEmpty;
  bool get hasInviteTicket => inviteTicket.isNotEmpty;

  bool hasReusableInviteTicket({DateTime? now}) {
    if (!hasShareId || !hasInviteTicket) {
      return false;
    }
    final expireAt = DateTime.tryParse(inviteTicketExpireTime);
    if (expireAt == null) {
      return true;
    }
    return expireAt.isAfter(now ?? DateTime.now());
  }

  GuestInviteContextEntity copyWith({
    String? inviteShareId,
    String? inviteTicket,
    String? inviteTicketExpireTime,
    String? visitorKey,
    String? redirect,
    String? wechatCode,
  }) {
    return GuestInviteContextEntity(
      inviteShareId: inviteShareId ?? this.inviteShareId,
      inviteTicket: inviteTicket ?? this.inviteTicket,
      inviteTicketExpireTime:
          inviteTicketExpireTime ?? this.inviteTicketExpireTime,
      visitorKey: visitorKey ?? this.visitorKey,
      redirect: redirect ?? this.redirect,
      wechatCode: wechatCode ?? this.wechatCode,
    );
  }

  factory GuestInviteContextEntity.fromJson(Map<String, dynamic> json) {
    return GuestInviteContextEntity(
      inviteShareId: _readString(json['inviteShareId']),
      inviteTicket: _readString(json['inviteTicket']),
      inviteTicketExpireTime: _readString(json['inviteTicketExpireTime']),
      visitorKey: _readString(json['visitorKey']),
      redirect: _readString(json['redirect']),
      wechatCode: _readString(json['wechatCode']),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'inviteShareId': inviteShareId,
      'inviteTicket': inviteTicket,
      'inviteTicketExpireTime': inviteTicketExpireTime,
      'visitorKey': visitorKey,
      'redirect': redirect,
      'wechatCode': wechatCode,
    };
    data.removeWhere((key, value) => value is String && value.trim().isEmpty);
    return data;
  }
}

String _readString(dynamic value) {
  return value == null ? '' : value.toString().trim();
}
