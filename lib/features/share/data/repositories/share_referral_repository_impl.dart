// 分享归因仓储实现。负责把远端接口结果转换成上层可直接消费的领域实体。

import '../../domain/entities/app_id_mapping_entity.dart';
import '../../domain/entities/share_identity_entity.dart';
import '../../domain/entities/share_touch_result_entity.dart';
import '../../domain/repositories/share_referral_repository.dart';
import '../sources/share_remote_source.dart';

class ShareReferralRepositoryImpl implements ShareReferralRepository {
  ShareReferralRepositoryImpl(this._remoteSource);

  final ShareRemoteSource _remoteSource;

  @override
  Future<ShareTouchResultEntity> createShareTouch({
    required String shareId,
    required String landingPage,
    String? visitorKey,
  }) {
    return _remoteSource.createShareTouch(
      shareId: shareId,
      landingPage: landingPage,
      visitorKey: visitorKey,
    );
  }

  @override
  Future<AppIdMappingEntity> getAppIdMapping() {
    return _remoteSource.getAppIdMapping();
  }

  @override
  Future<ShareIdentityEntity> getRefererId() {
    return _remoteSource.getRefererId();
  }
}
