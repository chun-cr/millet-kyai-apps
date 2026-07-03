import '../../../../core/network/dio_client.dart';

class MobileUtilityRemoteSource {
  const MobileUtilityRemoteSource(this._dioClient);

  final DioClient _dioClient;

  Future<Map<String, dynamic>> getCurrentIndexPopup({int? type}) async {
    final response = await _dioClient.dio.get<dynamic>(
      '/api/v1/saas/mobile/index/popup',
      queryParameters: _clean({'type': type}),
    );
    return _dataMap(response.data);
  }

  Future<List<Map<String, dynamic>>> getIndexContent({
    bool? withPlayAuth,
  }) async {
    final response = await _dioClient.dio.get<dynamic>(
      '/api/v1/saas/mobile/index/content',
      queryParameters: _clean({'withPlayAuth': withPlayAuth}),
    );
    return _dataList(response.data);
  }

  Future<Map<String, dynamic>> getAuditingCheck() async {
    final response = await _dioClient.dio.get<dynamic>(
      '/api/v1/saas/mobile/auditing/check',
    );
    return _dataMap(response.data);
  }

  Future<Map<String, dynamic>> getSupportedLocales() async {
    final response = await _dioClient.dio.get<dynamic>(
      '/api/v1/saas/mobile/i18n/locales/supported',
    );
    return _dataMap(response.data);
  }

  Future<Map<String, dynamic>> getAngelicaLoginQrCode({
    required String platform,
    required String authKey,
    String? channel,
  }) async {
    final response = await _dioClient.dio.get<dynamic>(
      '/api/v1/saas/mobile/angelica/login/qrcode',
      queryParameters: _clean({
        'platform': _requireText(platform, 'platform'),
        'authKey': _requireText(authKey, 'authKey'),
        'channel': _trimmedOrNull(channel),
      }),
    );
    return _dataMap(response.data);
  }

  Future<List<Map<String, dynamic>>> getToolMiniApps({
    String? currentAppId,
  }) async {
    final response = await _dioClient.dio.get<dynamic>(
      '/api/v1/saas/mobile/angelica/tool/mini/apps',
      queryParameters: _clean({'currentAppId': _trimmedOrNull(currentAppId)}),
    );
    return _dataList(response.data);
  }

  Future<void> authorizeAngelicaScanLogin({
    required String key,
    bool? authorized,
  }) async {
    final response = await _dioClient.dio.post<dynamic>(
      '/api/v1/saas/mobile/login/authorize/ang',
      data: _clean({
        'key': _requireText(key, 'key'),
        'authorized': authorized,
      }),
    );
    _ensureEnvelope(response.data);
  }

  Future<Map<String, dynamic>> parseSceneCode(String code) async {
    final response = await _dioClient.dio.post<dynamic>(
      '/api/v1/saas/mobile/scene/parse',
      data: {'code': _requireText(code, 'code')},
    );
    return _dataMap(response.data);
  }

  Future<String> getSceneImageUrl({required int id, int? width}) async {
    final response = await _dioClient.dio.get<dynamic>(
      '/api/v1/saas/mobile/scene/image/url',
      queryParameters: _clean({'id': id, 'width': width}),
    );
    final data = _dataValue(response.data);
    return data?.toString() ?? '';
  }

  Future<void> subscribeUserMessage({
    required String templateId,
    String? acceptFlag,
    String? keepingFlag,
  }) async {
    final response = await _dioClient.dio.post<dynamic>(
      '/api/v1/saas/mobile/user/sub/msg/subscribe',
      data: _clean({
        'templateId': _requireText(templateId, 'templateId'),
        'acceptFlag': _trimmedOrNull(acceptFlag),
        'keepingFlag': _trimmedOrNull(keepingFlag),
      }),
    );
    _ensureEnvelope(response.data);
  }

  Future<Map<String, dynamic>> getUserMessageKeepingFlag({
    String? templateId,
    List<String> templateIds = const [],
  }) async {
    final response = await _dioClient.dio.get<dynamic>(
      '/api/v1/saas/mobile/user/sub/msg/template/keeping/flag',
      queryParameters: _clean({
        'templateId': _trimmedOrNull(templateId),
        'templateIds': templateIds
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toList(growable: false),
      }),
    );
    return _dataMap(response.data);
  }

  Map<String, dynamic> _dataMap(dynamic responseData) {
    final data = _dataValue(responseData);
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return const <String, dynamic>{};
  }

  List<Map<String, dynamic>> _dataList(dynamic responseData) {
    final data = _dataValue(responseData);
    if (data is List) {
      return data
          .map((item) => item is Map<String, dynamic>
              ? item
              : item is Map
              ? Map<String, dynamic>.from(item)
              : const <String, dynamic>{})
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  dynamic _dataValue(dynamic responseData) {
    return _ensureEnvelope(responseData)['data'];
  }

  Map<String, dynamic> _ensureEnvelope(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      throw const FormatException('Invalid response envelope');
    }
    final businessCode = (responseData['code'] as num?)?.toInt();
    if (businessCode != null && businessCode != 0) {
      throw FormatException(
        responseData['message']?.toString() ?? 'Request failed',
      );
    }
    return responseData;
  }

  Map<String, dynamic> _clean(Map<String, dynamic> payload) {
    return Map<String, dynamic>.from(payload)
      ..removeWhere((key, value) {
        if (value == null) {
          return true;
        }
        if (value is String && value.trim().isEmpty) {
          return true;
        }
        if (value is Iterable && value.isEmpty) {
          return true;
        }
        return false;
      });
  }

  String _requireText(String value, String name) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, name, '$name is required');
    }
    return normalized;
  }

  String? _trimmedOrNull(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
