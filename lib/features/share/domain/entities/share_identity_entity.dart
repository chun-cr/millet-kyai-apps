// 分享身份实体。描述当前用户在分享体系中的 refererId、shareId 等身份信息。

class ShareIdentityEntity {
  const ShareIdentityEntity({
    required this.shareId,
    this.raw = const <String, dynamic>{},
  });

  final String shareId;
  final Map<String, dynamic> raw;

  bool get isEmpty => shareId.isEmpty && raw.isEmpty;

  ShareIdentityEntity copyWith({String? shareId, Map<String, dynamic>? raw}) {
    return ShareIdentityEntity(
      shareId: shareId ?? this.shareId,
      raw: raw ?? this.raw,
    );
  }

  factory ShareIdentityEntity.fromDynamic(dynamic data) {
    if (data is Map<String, dynamic>) {
      return ShareIdentityEntity(
        shareId: _readString(data['shareId'] ?? data['refererId']),
        raw: Map<String, dynamic>.from(data),
      );
    }
    if (data is Map) {
      final raw = Map<String, dynamic>.from(data);
      return ShareIdentityEntity(
        shareId: _readString(raw['shareId'] ?? raw['refererId']),
        raw: raw,
      );
    }
    return ShareIdentityEntity(shareId: _readString(data));
  }

  Map<String, dynamic> toJson() {
    if (raw.isNotEmpty) {
      return Map<String, dynamic>.from(raw);
    }
    if (shareId.isEmpty) {
      return const <String, dynamic>{};
    }
    return <String, dynamic>{'shareId': shareId};
  }
}

String _readString(dynamic value) {
  return value == null ? '' : value.toString().trim();
}
