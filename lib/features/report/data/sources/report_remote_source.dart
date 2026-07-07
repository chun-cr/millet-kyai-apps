// 报告远端数据源。集中处理报告详情、分享二维码、商品项目推荐等接口协议差异。

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../models/report_detail.dart';

part 'report_remote_source_endpoints.dart';

class DiagnosisReportSummaryPage {
  const DiagnosisReportSummaryPage({
    required this.items,
    required this.pageNo,
    required this.pageSize,
    required this.totalCount,
  });

  final List<DiagnosisReportSummary> items;
  final int pageNo;
  final int pageSize;
  final int? totalCount;

  bool get hasMore {
    final total = totalCount;
    if (total != null) {
      return pageNo * pageSize < total;
    }
    return items.length >= pageSize;
  }
}

class ReportRemoteSource {
  /// 使用全局移动端 Dio 客户端。
  /// 这样报告接口也能自动复用登录态、应用标识和日志拦截能力。
  const ReportRemoteSource(this._dioClient);

  final DioClient _dioClient;

  Future<DiagnosisReportDetail> getReportDetail(
    String reportId, {
    int? topOrgId,
  }) async {
    final normalizedReportId = _requireText(reportId, 'reportId');
    try {
      return await _getAiDiagnosisReportDetail(
        normalizedReportId,
        topOrgId: topOrgId,
      );
    } on DioException catch (error) {
      final physiqueReportId = int.tryParse(normalizedReportId);
      if (physiqueReportId == null ||
          !_isReportDetailCompatibilityFailure(error)) {
        rethrow;
      }
      return _getPreDiagnosisReportDetail(physiqueReportId, topOrgId: topOrgId);
    }
  }

  Future<DiagnosisReportDetail> _getAiDiagnosisReportDetail(
    String reportId, {
    int? topOrgId,
  }) async {
    final envelope = await _getEnvelope(
      '/api/v1/saas/mobile/ai/diagnosis/report/${Uri.encodeComponent(reportId)}',
      queryParameters: _cleanPayload({'topOrgId': topOrgId}),
    );
    return DiagnosisReportDetail.fromJson(
      _requirePayload(
        envelope,
        message: 'Report detail response did not include a data payload.',
      ),
    );
  }

  Future<DiagnosisReportDetail> _getPreDiagnosisReportDetail(
    int reportId, {
    int? topOrgId,
  }) async {
    final envelope = await _getEnvelope(
      '/api/v1/saas/mobile/physique/report/pre/diagnosis',
      queryParameters: _cleanPayload({
        'reportId': reportId,
        'topOrgId': topOrgId,
      }),
    );
    final payload = Map<String, dynamic>.from(
      _requirePayload(
        envelope,
        message:
            'Pre-diagnosis report response did not include a data payload.',
      ),
    );
    final payloadId = payload['id'];
    if (payloadId == null || payloadId.toString().trim().isEmpty) {
      payload['id'] = reportId;
    }
    return DiagnosisReportDetail.fromJson(payload);
  }

  Future<DiagnosisReportDetail> getReportDetailByToken(String token) async {
    final envelope = await _getEnvelope(
      '/api/v1/saas/mobile/ai/diagnosis/report/detail',
      queryParameters: {'token': _requireText(token, 'token')},
    );
    return DiagnosisReportDetail.fromJson(
      _requirePayload(
        envelope,
        message: 'Token report detail response did not include a data payload.',
      ),
    );
  }

  Future<DiagnosisReportShareQrCode> getReportShareQrCode(
    String reportId,
  ) async {
    final normalizedReportId = reportId.trim();
    if (normalizedReportId.isEmpty) {
      throw ArgumentError.value(reportId, 'reportId', 'reportId is required');
    }

    final envelope = await _getEnvelope(
      '/api/v1/saas/mobile/physique/ai/diagnosis/report/$normalizedReportId/share/qrcode',
    );
    return DiagnosisReportShareQrCode.fromDynamic(envelope['data']);
  }

  Future<Map<String, dynamic>> _getEnvelope(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _sendEnvelope(
      () => _dioClient.dio.get<dynamic>(path, queryParameters: queryParameters),
    );
  }

  Future<Map<String, dynamic>> _getPayload(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final envelope = await _getEnvelope(path, queryParameters: queryParameters);
    return Map<String, dynamic>.unmodifiable(_asMap(envelope['data']));
  }

  Future<Map<String, dynamic>> _postPayload(
    String path, {
    Map<String, dynamic>? data,
    bool omitEmptyBody = false,
  }) async {
    final payload = data == null ? null : _cleanPayload(data);
    final envelope = await _sendEnvelope(
      () => _dioClient.dio.post<dynamic>(
        path,
        data: omitEmptyBody && (payload == null || payload.isEmpty)
            ? null
            : payload,
      ),
    );
    return Map<String, dynamic>.unmodifiable(_asMap(envelope['data']));
  }

  Future<void> _postVoid(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    await _sendEnvelope(() => _dioClient.dio.post<dynamic>(path, data: data));
  }

  Future<void> _putVoid(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    await _sendEnvelope(() => _dioClient.dio.put<dynamic>(path, data: data));
  }

  Future<void> _deleteVoid(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    await _sendEnvelope(() => _dioClient.dio.delete<dynamic>(path, data: data));
  }

  Future<Map<String, dynamic>> _sendEnvelope(
    Future<Response<dynamic>> Function() request,
  ) async {
    final response = await request();
    final envelope = _asMap(response.data);
    final businessCode = (envelope['code'] as num?)?.toInt();
    if (businessCode != null && businessCode != 0) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: envelope['message']?.toString() ?? 'Request failed.',
      );
    }
    return envelope;
  }

  Map<String, dynamic> _cleanPayload(Map<String, dynamic> payload) {
    return Map<String, dynamic>.from(payload)..removeWhere((key, value) {
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

  String _encodedRequired(String value, String name) {
    return Uri.encodeComponent(_requireText(value, name));
  }

  String? _trimmedOrNull(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  List<Map<String, dynamic>> _requireItems(
    List<Map<String, dynamic>> items,
    String name,
  ) {
    if (items.isEmpty) {
      throw ArgumentError.value(items, name, '$name is required');
    }
    return items.map(_cleanPayload).toList(growable: false);
  }

  String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/');
    return segments.isEmpty ? normalized : segments.last;
  }

  Map<String, dynamic> _requirePayload(
    Map<String, dynamic> envelope, {
    required String message,
  }) {
    final payload = _asMap(envelope['data']);
    if (payload.isEmpty) {
      throw StateError(message);
    }
    return payload;
  }

  DiagnosisReportSummary? _firstSummaryOrNull(Map<String, dynamic> envelope) {
    final items = _extractSummaries(envelope);
    if (items.isEmpty) {
      return null;
    }
    return items.first;
  }

  Future<Map<String, dynamic>> _getReportsEnvelope({
    required int pageNo,
    required int pageSize,
    String? source,
    int? topOrgId,
  }) async {
    final queryParameters = <String, dynamic>{
      'pageNo': pageNo,
      'pageSize': pageSize,
    };
    if (source != null && source.trim().isNotEmpty) {
      queryParameters['source'] = source;
    }
    if (topOrgId != null) {
      queryParameters['topOrgId'] = topOrgId;
    }

    try {
      return await _getEnvelope(
        '/api/v1/saas/mobile/physique/report',
        queryParameters: queryParameters,
      );
    } on DioException {
      // 旧接口不一定接受 source 参数，失败时回退到不带 source 的通用分页查询。
      if (!queryParameters.containsKey('source')) {
        rethrow;
      }
      return _getEnvelope(
        '/api/v1/saas/physiques/reports',
        queryParameters: <String, dynamic>{
          'pageNo': pageNo,
          'pageSize': pageSize,
        },
      );
    }
  }

  List<DiagnosisReportSummary> _extractSummaries(
    Map<String, dynamic> envelope,
  ) {
    final items = _extractPagedItems(envelope);
    return items
        .map((item) => _asMap(item))
        .where((item) => item.isNotEmpty)
        .map(DiagnosisReportSummary.fromJson)
        .toList(growable: false);
  }

  List<dynamic> _extractPagedItems(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    final directItems = _asList(data);
    if (directItems.isNotEmpty) {
      return directItems;
    }

    final payload = _asMap(data);
    for (final key in const ['datas', 'records', 'list', 'items']) {
      final items = _asList(payload[key]);
      if (items.isNotEmpty) {
        return items;
      }
    }
    return const <dynamic>[];
  }

  int? _extractTotalCount(Map<String, dynamic> envelope) {
    final payload = _asMap(envelope['data']);
    final total =
        _asNum(payload['totalCount']) ??
        _asNum(payload['total']) ??
        _asNum(payload['count']) ??
        _asNum(payload['totalElements']);
    return total?.toInt();
  }

  bool _isReportDetailCompatibilityFailure(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 400 || statusCode == 404) {
      return true;
    }

    final envelope = _asMap(error.response?.data);
    final businessCode = _asNum(envelope['code'])?.toInt();
    return businessCode == 400 || businessCode == 404;
  }

  Future<List<DiagnosisReportSummary>> _resolveSummariesFaceImages(
    List<DiagnosisReportSummary> summaries, {
    int? topOrgId,
  }) async {
    final resolved = await Future.wait(
      summaries.map(
        (summary) => _resolveSummaryFaceImage(summary, topOrgId: topOrgId),
      ),
    );
    return List<DiagnosisReportSummary>.unmodifiable(resolved);
  }

  Future<DiagnosisReportSummary> _resolveSummaryFaceImage(
    DiagnosisReportSummary summary, {
    int? topOrgId,
  }) async {
    if (summary.faceImageUrl.trim().isNotEmpty || summary.id.trim().isEmpty) {
      return summary;
    }

    try {
      final detail = await getReportDetail(summary.id, topOrgId: topOrgId);
      final resolvedFaceImageUrl = detail.faceAnalysisResult.imageUrl.trim();
      if (resolvedFaceImageUrl.isEmpty) {
        return summary;
      }
      return summary.copyWith(faceImageUrl: resolvedFaceImageUrl);
    } on DioException {
      return summary;
    } on StateError {
      return summary;
    }
  }
}

String _resolvePhysiqueProductsPath(String? token) {
  return token != null && token.trim().isNotEmpty
      ? '/api/v1/saas/mobile/physique/products/by/token'
      : '/api/v1/saas/mobile/physique/products';
}

String _resolvePhysiqueProjectsPath(String? token) {
  return token != null && token.trim().isNotEmpty
      ? '/api/v1/saas/mobile/physique/project/by/token'
      : '/api/v1/saas/mobile/physique/project';
}

Map<String, dynamic> _buildPhysiqueProductQueryParameters({
  required String? token,
  required String? topOrgId,
  required String? clinicId,
  required List<int> physiqueIds,
  required List<int> symptomIds,
}) {
  final queryParameters = <String, dynamic>{};

  final normalizedToken = token?.trim() ?? '';
  if (normalizedToken.isNotEmpty) {
    queryParameters['token'] = normalizedToken;
  }

  final compatParams = _buildTenantStoreCompatQueryParameters(
    tenantId: topOrgId?.trim() ?? '',
    storeId: clinicId?.trim(),
  );
  queryParameters.addAll(compatParams);

  final normalizedPhysiqueIds = _normalizeIntIds(physiqueIds);
  if (normalizedPhysiqueIds.isNotEmpty) {
    queryParameters['physiqueIds'] = normalizedPhysiqueIds;
  }

  final normalizedSymptomIds = _normalizeIntIds(symptomIds);
  if (normalizedSymptomIds.isNotEmpty) {
    queryParameters['symptomIds'] = normalizedSymptomIds;
  }

  return queryParameters;
}

Map<String, dynamic> _buildPhysiqueProjectQueryParameters({
  required String? token,
  required String? topOrgId,
  required int? age,
  required String? sex,
  required List<int> physiqueIds,
}) {
  final queryParameters = <String, dynamic>{};

  final normalizedToken = token?.trim() ?? '';
  final normalizedTopOrgId = topOrgId?.trim() ?? '';
  if (normalizedToken.isEmpty && normalizedTopOrgId.isEmpty) {
    return queryParameters;
  }

  if (normalizedToken.isNotEmpty) {
    queryParameters['token'] = normalizedToken;
  }

  queryParameters.addAll(
    _buildTenantStoreCompatQueryParameters(tenantId: normalizedTopOrgId),
  );

  if (age != null && age > 0) {
    queryParameters['age'] = age;
  }

  final normalizedSex = sex?.trim() ?? '';
  if (normalizedSex.isNotEmpty) {
    queryParameters['sex'] = normalizedSex;
  }

  final normalizedPhysiqueIds = _normalizeIntIds(physiqueIds);
  if (normalizedPhysiqueIds.isNotEmpty) {
    queryParameters['physiqueIds'] = normalizedPhysiqueIds;
  }

  return queryParameters;
}

List<Map<String, dynamic>> _extractPhysiqueProductItems(
  Map<String, dynamic> envelope,
) {
  return _extractGenericItems(envelope, preferredKeys: const ['products']);
}

List<Map<String, dynamic>> _extractGenericItems(
  Map<String, dynamic> envelope, {
  List<String> preferredKeys = const [],
}) {
  final payload = _asMap(envelope['data']);
  if (payload.isEmpty) {
    final raw = envelope['data'];
    if (raw is List) {
      return raw
          .map((item) => _asMap(item))
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  final keys = <String>[
    ...preferredKeys,
    'datas',
    'records',
    'items',
    'list',
    'rows',
  ];
  var foundExplicitListKey = false;
  for (final key in keys) {
    if (!payload.containsKey(key)) {
      continue;
    }
    foundExplicitListKey = true;
    final items = _asList(payload[key])
        .map((item) => _asMap(item))
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (items.isNotEmpty) {
      return items;
    }
  }

  if (foundExplicitListKey) {
    return const <Map<String, dynamic>>[];
  }

  // 某些详情接口直接把对象放在 data 下，没有 items/list 包装，保底按单项返回。
  return [payload];
}

Map<String, dynamic> _extractPhysiqueProductDetail(
  Map<String, dynamic> envelope,
) {
  final payload = _asMap(envelope['data']);
  if (payload.isEmpty) {
    return const <String, dynamic>{};
  }

  for (final key in const ['data', 'item', 'product', 'detail', 'info']) {
    final nested = _asMap(payload[key]);
    if (nested.isNotEmpty) {
      return nested;
    }
  }

  return payload;
}

List<int> _normalizeIntIds(Iterable<int> ids) {
  final normalized = <int>[];
  for (final id in ids) {
    if (id <= 0 || normalized.contains(id)) {
      continue;
    }
    normalized.add(id);
  }
  return normalized;
}

Map<String, dynamic> _buildTenantStoreCompatQueryParameters({
  required String tenantId,
  String? storeId,
}) {
  final queryParameters = <String, dynamic>{};
  final normalizedTenantId = tenantId.trim();
  if (normalizedTenantId.isNotEmpty) {
    queryParameters['tenantId'] = normalizedTenantId;
    queryParameters['topOrgId'] = normalizedTenantId;
  }

  final normalizedStoreId = storeId?.trim() ?? '';
  if (normalizedStoreId.isNotEmpty) {
    queryParameters['storeId'] = normalizedStoreId;
    queryParameters['clinicId'] = normalizedStoreId;
  }

  return queryParameters;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

List<dynamic> _asList(Object? value) {
  if (value is List) {
    return value;
  }
  return const <dynamic>[];
}

num? _asNum(Object? value) {
  if (value is num) {
    return value;
  }
  if (value is String) {
    return num.tryParse(value);
  }
  return null;
}
