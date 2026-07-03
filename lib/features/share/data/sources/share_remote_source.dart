// 分享远端数据源。集中处理分享身份、邀约票据和落地埋点相关接口调用。

import 'package:millet_kyai_apps/core/network/dio_client.dart';

import '../../domain/entities/app_id_mapping_entity.dart';
import '../../domain/entities/share_identity_entity.dart';
import '../../domain/entities/share_touch_result_entity.dart';

class ShareRemoteSource {
  ShareRemoteSource(this._dioClient);

  final DioClient _dioClient;

  Future<ShareTouchResultEntity> createShareTouch({
    required String shareId,
    required String landingPage,
    String? visitorKey,
  }) async {
    final response = await _dioClient.dio.post(
      '/api/v1/saas/mobile/shares/touches',
      data: <String, dynamic>{
        'shareId': shareId.trim(),
        'landingPage': landingPage.trim(),
        if (_trimmedOrNull(visitorKey) != null)
          'visitorKey': visitorKey!.trim(),
      },
    );
    return ShareTouchResultEntity.fromJson(_dataMap(response.data));
  }

  Future<AppIdMappingEntity> getAppIdMapping() async {
    final response = await _dioClient.dio.get(
      '/api/v1/saas/mobile/appId/mapping',
    );
    final data = _dataValue(response.data);
    if (data is Map<String, dynamic>) {
      return AppIdMappingEntity.fromJson(data);
    }
    if (data is Map) {
      return AppIdMappingEntity.fromJson(Map<String, dynamic>.from(data));
    }
    return const AppIdMappingEntity();
  }

  Future<ShareIdentityEntity> getRefererId() async {
    final response = await _dioClient.dio.get('/api/v1/saas/mobile/shares/me');
    return ShareIdentityEntity.fromDynamic(_dataValue(response.data));
  }

  String? _trimmedOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  Map<String, dynamic> _dataMap(dynamic responseData) {
    final data = _dataValue(responseData);
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw const FormatException('Missing response data');
  }

  dynamic _dataValue(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      throw const FormatException('Invalid response envelope');
    }
    return responseData['data'];
  }
}
