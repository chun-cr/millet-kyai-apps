// 分享归因总状态实体。统一保存 referer 身份、appId 映射和游客邀约上下文。

import 'app_id_mapping_entity.dart';
import 'guest_invite_context_entity.dart';
import 'share_identity_entity.dart';

class ShareReferralState {
  const ShareReferralState({
    this.appIdMapping = const AppIdMappingEntity(),
    this.shareIdentity = const ShareIdentityEntity(shareId: ''),
    this.sharerId = '',
    this.guestAuthContext,
  });

  final AppIdMappingEntity appIdMapping;
  final ShareIdentityEntity shareIdentity;
  final String sharerId;
  final GuestInviteContextEntity? guestAuthContext;

  String get refererId => shareIdentity.shareId;

  ShareReferralState copyWith({
    AppIdMappingEntity? appIdMapping,
    ShareIdentityEntity? shareIdentity,
    String? sharerId,
    GuestInviteContextEntity? guestAuthContext,
    bool clearGuestAuthContext = false,
  }) {
    return ShareReferralState(
      appIdMapping: appIdMapping ?? this.appIdMapping,
      shareIdentity: shareIdentity ?? this.shareIdentity,
      sharerId: sharerId ?? this.sharerId,
      guestAuthContext: clearGuestAuthContext
          ? null
          : guestAuthContext ?? this.guestAuthContext,
    );
  }

  factory ShareReferralState.fromJson(Map<String, dynamic> json) {
    final rawAppIdMapping = json['appIdMapping'];
    final rawShareIdentity = json['shareIdentity'];
    final rawGuestAuthContext = json['guestAuthContext'];

    return ShareReferralState(
      appIdMapping: rawAppIdMapping is Map<String, dynamic>
          ? AppIdMappingEntity.fromJson(rawAppIdMapping)
          : rawAppIdMapping is Map
          ? AppIdMappingEntity.fromJson(
              Map<String, dynamic>.from(rawAppIdMapping),
            )
          : const AppIdMappingEntity(),
      shareIdentity: ShareIdentityEntity.fromDynamic(rawShareIdentity),
      sharerId: _readString(json['sharerId']),
      guestAuthContext: rawGuestAuthContext is Map<String, dynamic>
          ? GuestInviteContextEntity.fromJson(rawGuestAuthContext)
          : rawGuestAuthContext is Map
          ? GuestInviteContextEntity.fromJson(
              Map<String, dynamic>.from(rawGuestAuthContext),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'appIdMapping': appIdMapping.toJson(),
      'shareIdentity': shareIdentity.toJson(),
      'sharerId': sharerId,
      if (guestAuthContext != null)
        'guestAuthContext': guestAuthContext!.toJson(),
    };
  }
}

String _readString(dynamic value) {
  return value == null ? '' : value.toString().trim();
}
