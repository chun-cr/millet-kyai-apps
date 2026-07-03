// 报告远端数据源。集中处理报告详情、分享二维码、商品项目推荐等接口协议差异。

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../models/report_detail.dart';

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
      return _getPreDiagnosisReportDetail(
        physiqueReportId,
        topOrgId: topOrgId,
      );
    }
  }

  Future<DiagnosisReportDetail> _getAiDiagnosisReportDetail(
    String reportId,
    {
    int? topOrgId,
  }
  ) async {
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
    int reportId,
    {
    int? topOrgId,
  }
  ) async {
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

  Future<List<Map<String, dynamic>>> getPhysiqueProducts({
    String? token,
    String? topOrgId,
    String? clinicId,
    List<int> physiqueIds = const [],
    List<int> symptomIds = const [],
  }) async {
    final queryParameters = _buildPhysiqueProductQueryParameters(
      token: token,
      topOrgId: topOrgId,
      clinicId: clinicId,
      physiqueIds: physiqueIds,
      symptomIds: symptomIds,
    );
    if (queryParameters.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final envelope = await _getEnvelope(
      _resolvePhysiqueProductsPath(queryParameters['token']?.toString()),
      queryParameters: queryParameters,
    );
    return List<Map<String, dynamic>>.unmodifiable(
      _extractPhysiqueProductItems(envelope),
    );
  }

  Future<List<Map<String, dynamic>>> getPhysiqueProjects({
    String? token,
    String? topOrgId,
    int? age,
    String? sex,
    List<int> physiqueIds = const [],
  }) async {
    final queryParameters = _buildPhysiqueProjectQueryParameters(
      token: token,
      topOrgId: topOrgId,
      age: age,
      sex: sex,
      physiqueIds: physiqueIds,
    );
    if (queryParameters.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final envelope = await _getEnvelope(
      _resolvePhysiqueProjectsPath(queryParameters['token']?.toString()),
      queryParameters: queryParameters,
    );
    return List<Map<String, dynamic>>.unmodifiable(
      _extractGenericItems(envelope, preferredKeys: const ['projects']),
    );
  }

  Future<Map<String, dynamic>?> getPhysiqueProductDetail(
    String productId,
  ) async {
    final normalizedProductId = productId.trim();
    if (normalizedProductId.isEmpty) {
      return null;
    }

    final envelope = await _getEnvelope(
      '/api/v1/saas/mobile/physique/product/${Uri.encodeComponent(normalizedProductId)}',
    );
    final payload = _extractPhysiqueProductDetail(envelope);
    if (payload.isEmpty) {
      return null;
    }
    return Map<String, dynamic>.unmodifiable(payload);
  }

  Future<Map<String, dynamic>> previewRetailOrder({
    required int storeId,
    required String deliveryType,
    required List<Map<String, dynamic>> items,
    int? employeeId,
    Map<String, dynamic>? deliveryAddress,
  }) async {
    return _postPayload(
      '/api/v1/saas/mobile/retail-orders/preview',
      data: _cleanPayload({
        'storeId': storeId,
        'employeeId': employeeId,
        'deliveryType': _requireText(deliveryType, 'deliveryType'),
        'deliveryAddress': deliveryAddress,
        'items': _requireItems(items, 'items'),
      }),
    );
  }

  Future<Map<String, dynamic>> submitRetailOrder({
    required int storeId,
    required String deliveryType,
    required int expectedPayAmountMinor,
    required List<Map<String, dynamic>> items,
    int? employeeId,
    Map<String, dynamic>? deliveryAddress,
    String? remark,
  }) async {
    return _postPayload(
      '/api/v1/saas/mobile/retail-orders',
      data: _cleanPayload({
        'storeId': storeId,
        'employeeId': employeeId,
        'deliveryType': _requireText(deliveryType, 'deliveryType'),
        'deliveryAddress': deliveryAddress,
        'expectedPayAmountMinor': expectedPayAmountMinor,
        'remark': _trimmedOrNull(remark),
        'items': _requireItems(items, 'items'),
      }),
    );
  }

  Future<Map<String, dynamic>> prepayRetailOrder(
    String orderId, {
    int? useStoredValueAmountMinor,
    int? usePointsAmount,
  }) async {
    final encodedOrderId = _encodedRequired(orderId, 'orderId');
    return _postPayload(
      '/api/v1/saas/mobile/retail-orders/$encodedOrderId/prepay',
      data: _cleanPayload({
        'useStoredValueAmountMinor': useStoredValueAmountMinor,
        'usePointsAmount': usePointsAmount,
      }),
      omitEmptyBody: true,
    );
  }

  Future<Map<String, dynamic>> getRetailOrderDetail(String orderId) {
    final encodedOrderId = _encodedRequired(orderId, 'orderId');
    return _getPayload('/api/v1/saas/mobile/retail-orders/$encodedOrderId');
  }

  Future<Map<String, dynamic>> getRetailSpuDetail({
    required String id,
    required int storeId,
    String? selectedRetailSkuId,
  }) {
    final encodedId = _encodedRequired(id, 'id');
    return _getPayload(
      '/api/v1/saas/mobile/retail-spus/$encodedId',
      queryParameters: _cleanPayload({
        'storeId': storeId,
        'selectedRetailSkuId': _trimmedOrNull(selectedRetailSkuId),
      }),
    );
  }

  Future<Map<String, dynamic>> getOrderCashier(String orderId) {
    final encodedOrderId = _encodedRequired(orderId, 'orderId');
    return _getPayload('/api/v1/saas/mobile/orders/$encodedOrderId/cashier');
  }

  Future<Map<String, dynamic>> prepayOrder(
    String orderId, {
    int? useStoredValueAmountMinor,
    int? usePointsAmount,
  }) {
    final encodedOrderId = _encodedRequired(orderId, 'orderId');
    return _postPayload(
      '/api/v1/saas/mobile/orders/$encodedOrderId/prepay',
      data: _cleanPayload({
        'useStoredValueAmountMinor': useStoredValueAmountMinor,
        'usePointsAmount': usePointsAmount,
      }),
      omitEmptyBody: true,
    );
  }

  Future<Map<String, dynamic>> getOrderPayStatus({
    required String orderId,
    int? t,
    String? key,
  }) {
    return _getPayload(
      '/api/v1/saas/mobile/orders/pay/status',
      queryParameters: _cleanPayload({
        'orderId': _requireText(orderId, 'orderId'),
        't': t,
        'key': _trimmedOrNull(key),
      }),
    );
  }

  Future<List<Map<String, dynamic>>> getPhysiqueTherapies({
    List<int> physiqueIds = const [],
    String? sex,
    int? age,
    String? token,
  }) async {
    final envelope = await _getEnvelope(
      '/api/v1/saas/mobile/physique/therapy',
      queryParameters: _cleanPayload({
        'physiqueIds': _normalizeIntIds(physiqueIds),
        'sex': _trimmedOrNull(sex),
        'age': age,
        'token': _trimmedOrNull(token),
      }),
    );
    return List<Map<String, dynamic>>.unmodifiable(
      _extractGenericItems(envelope, preferredKeys: const ['therapies']),
    );
  }

  Future<Map<String, dynamic>> createTongueReport(
    Map<String, dynamic> payload,
  ) {
    return _postPayload(
      '/api/v1/saas/mobile/physique/report/tongue',
      data: _cleanPayload(payload),
    );
  }

  Future<Map<String, dynamic>> modifyReportSex({
    required int reportId,
    required String sex,
    String? diseaseCategory,
  }) {
    return _postPayload(
      '/api/v1/saas/mobile/physique/report/sex/modify',
      data: _cleanPayload({
        'reportId': reportId,
        'sex': _requireText(sex, 'sex'),
        'diseaseCategory': _trimmedOrNull(diseaseCategory),
      }),
    );
  }

  Future<Map<String, dynamic>> getPreDiagnosisReport(
    int reportId, {
    int? topOrgId,
  }) {
    return _getPayload(
      '/api/v1/saas/mobile/physique/report/pre/diagnosis',
      queryParameters: _cleanPayload({
        'reportId': reportId,
        'topOrgId': topOrgId,
      }),
    );
  }

  Future<Map<String, dynamic>> getPhysiqueReportDetailByToken(String token) {
    return _getPayload(
      '/api/v1/saas/mobile/physique/ai/diagnosis/report/detail',
      queryParameters: {'token': _requireText(token, 'token')},
    );
  }

  Future<Map<String, dynamic>> getMobilePhysiqueReports({
    int? pageNo,
    int? pageSize,
    int? topOrgId,
    String? source,
  }) {
    return _getPayload(
      '/api/v1/saas/mobile/physique/report',
      queryParameters: _cleanPayload({
        'pageNo': pageNo,
        'pageSize': pageSize,
        'topOrgId': topOrgId,
        'source': _trimmedOrNull(source),
      }),
    );
  }

  Future<void> rebindReportOwner({
    required int reportId,
    int? oldUserId,
    String? name,
    String? phone,
  }) {
    return _postVoid(
      '/api/v1/saas/mobile/physique/report/owner/rebind',
      data: _cleanPayload({
        'reportId': reportId,
        'oldUserId': oldUserId,
        'name': _trimmedOrNull(name),
        'phone': _trimmedOrNull(phone),
      }),
    );
  }

  Future<Map<String, dynamic>> syncReport({
    required int reportId,
    int? topOrgId,
    int? clinicId,
    String? phone,
    String? name,
    bool? manualNameFlag,
  }) {
    return _postPayload(
      '/api/v1/saas/mobile/physique/report/sync',
      data: _cleanPayload({
        'reportId': reportId,
        'topOrgId': topOrgId,
        'clinicId': clinicId,
        'phone': _trimmedOrNull(phone),
        'name': _trimmedOrNull(name),
        'manualNameFlag': manualNameFlag,
      }),
    );
  }

  Future<void> addReportSymptom({
    required int reportId,
    required int symptomId,
    required String recommendType,
    String? symptomName,
  }) {
    return _postVoid(
      '/api/v1/saas/mobile/physique/ai/diagnosis/report/symptom',
      data: _cleanPayload({
        'reportId': reportId,
        'symptomId': symptomId,
        'symptomName': _trimmedOrNull(symptomName),
        'recommendType': _requireText(recommendType, 'recommendType'),
      }),
    );
  }

  Future<void> deleteReportSymptom({
    required int reportId,
    required int symptomId,
    required String recommendType,
  }) {
    return _deleteVoid(
      '/api/v1/saas/mobile/physique/ai/diagnosis/report/symptom',
      data: {
        'reportId': reportId,
        'symptomId': symptomId,
        'recommendType': _requireText(recommendType, 'recommendType'),
      },
    );
  }

  Future<void> saveReportSelfDescription({
    required int reportId,
    String? selfDescription,
  }) {
    return _postVoid(
      '/api/v1/saas/mobile/physique/ai/diagnosis/report/self/description',
      data: _cleanPayload({
        'reportId': reportId,
        'selfDescription': _trimmedOrNull(selfDescription),
      }),
    );
  }

  Future<Map<String, dynamic>> uploadReportExtraImage({
    required int reportId,
    required String imageFilePath,
    String? type,
    ProgressCallback? onSendProgress,
  }) async {
    final envelope = await _sendEnvelope(
      () async => _dioClient.dio.post<dynamic>(
        '/api/v1/saas/mobile/physique/ai/diagnosis/report/extra/image/upload',
        data: FormData.fromMap({
          'reportId': reportId,
          if (_trimmedOrNull(type) != null) 'type': type!.trim(),
          'imageFile': await MultipartFile.fromFile(
            imageFilePath,
            filename: _fileName(imageFilePath),
          ),
        }),
        onSendProgress: onSendProgress,
      ),
    );
    return Map<String, dynamic>.unmodifiable(_asMap(envelope['data']));
  }

  Future<void> removeReportExtraImage({
    required int reportId,
    String? type,
    String? imageUrl,
  }) {
    return _deleteVoid(
      '/api/v1/saas/mobile/physique/ai/diagnosis/report/extra/image',
      data: _cleanPayload({
        'reportId': reportId,
        'type': _trimmedOrNull(type),
        'imageUrl': _trimmedOrNull(imageUrl),
      }),
    );
  }

  Future<Map<String, dynamic>> unlockMobilePhysiqueReport({
    required int reportId,
    required String unlockingMethod,
    int? topOrgId,
    String? deviceToken,
  }) {
    return _postPayload(
      '/api/v1/saas/mobile/physique/report/unlock',
      data: _cleanPayload({
        'reportId': reportId,
        'topOrgId': topOrgId,
        'unlockingMethod': _requireText(unlockingMethod, 'unlockingMethod'),
        'deviceToken': _trimmedOrNull(deviceToken),
      }),
    );
  }

  Future<Map<String, dynamic>> autoUnlockMobilePhysiqueReport({
    required int reportId,
    required int cardId,
    int? topOrgId,
  }) {
    return _postPayload(
      '/api/v1/saas/mobile/physique/report/unlock/auto',
      data: _cleanPayload({
        'reportId': reportId,
        'topOrgId': topOrgId,
        'cardId': cardId,
      }),
    );
  }

  Future<Map<String, dynamic>> getAiDetectDeviceConfig({
    int? tenantId,
    int? storeId,
    int? topOrgId,
    int? clinicId,
    String? source,
    String? deviceId,
    String? deviceIdType,
    String? deviceToken,
  }) {
    return _getPayload(
      '/api/v1/saas/mobile/physique/ai/detect/device/config',
      queryParameters: _cleanPayload({
        'tenantId': tenantId,
        'storeId': storeId,
        'topOrgId': topOrgId,
        'clinicId': clinicId,
        'source': _trimmedOrNull(source),
        'deviceId': _trimmedOrNull(deviceId),
        'deviceIdType': _trimmedOrNull(deviceIdType),
        'deviceToken': _trimmedOrNull(deviceToken),
      }),
    );
  }

  Future<void> activateAiDetectToken({
    required String deviceToken,
    int? topOrgId,
    bool? ownerStaffAccount,
    bool useLegacyActivePath = false,
  }) {
    return _postVoid(
      useLegacyActivePath
          ? '/api/v1/saas/mobile/physique/ai/detect/token/active'
          : '/api/v1/saas/mobile/physique/ai/detect/token/activate',
      data: _cleanPayload({
        'deviceToken': _requireText(deviceToken, 'deviceToken'),
        'topOrgId': topOrgId,
        'ownerStaffAccount': ownerStaffAccount,
      }),
    );
  }

  Future<Map<String, dynamic>> getSurveyReportLockedStatus(int reportId) {
    return _getPayload(
      '/api/v1/saas/physiques/reports/$reportId/locked-status',
    );
  }

  Future<Map<String, dynamic>> getTimesCardReports({
    required int cardId,
    int? pageNo,
    int? pageSize,
  }) {
    return _getPayload(
      '/api/v1/saas/physiques/reports/times-card-reports',
      queryParameters: _cleanPayload({
        'cardId': cardId,
        'pageNo': pageNo,
        'pageSize': pageSize,
      }),
    );
  }

  Future<Map<String, dynamic>> unlockSurveyReport({
    required int reportId,
    required String unlockingMethod,
    String? deviceToken,
    int? cardId,
  }) {
    return _postPayload(
      '/api/v1/saas/physiques/reports/unlock',
      data: _cleanPayload({
        'reportId': reportId,
        'deviceToken': _trimmedOrNull(deviceToken),
        'cardId': cardId,
        'unlockingMethod': _requireText(unlockingMethod, 'unlockingMethod'),
      }),
    );
  }

  Future<Map<String, dynamic>> autoUnlockSurveyReport({
    required int reportId,
    required int cardId,
  }) {
    return _postPayload(
      '/api/v1/saas/physiques/reports/auto-unlock',
      data: {'reportId': reportId, 'cardId': cardId},
    );
  }

  Future<DiagnosisReportDetail> getSurveyReportDetail(int reportId) async {
    final envelope = await _getEnvelope(
      '/api/v1/saas/physiques/reports/$reportId',
    );
    return DiagnosisReportDetail.fromJson(
      _requirePayload(
        envelope,
        message:
            'Survey report detail response did not include a data payload.',
      ),
    );
  }

  Future<List<DiagnosisReportSummary>> getSurveyReportHistory(
    int reportId,
  ) async {
    final envelope = await _getEnvelope(
      '/api/v1/saas/physiques/reports/$reportId/history',
    );
    return _asList(envelope['data'])
        .map((item) => _asMap(item))
        .where((item) => item.isNotEmpty)
        .map(DiagnosisReportSummary.fromJson)
        .toList(growable: false);
  }

  Future<List<DiagnosisReportDetail>> compareSurveyReports(
    List<int> reportIds,
  ) async {
    final normalizedIds = _normalizeIntIds(reportIds);
    if (normalizedIds.isEmpty) {
      throw ArgumentError.value(
        reportIds,
        'reportIds',
        'reportIds is required',
      );
    }
    final envelope = await _getEnvelope(
      '/api/v1/saas/physiques/reports/compare',
      queryParameters: {'ids': normalizedIds},
    );
    return _asList(envelope['data'])
        .map((item) => _asMap(item))
        .where((item) => item.isNotEmpty)
        .map(DiagnosisReportDetail.fromJson)
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> getSurveyReportChatResult(int reportId) {
    return _getPayload('/api/v1/saas/physiques/reports/$reportId/chat-result');
  }

  Future<void> saveSurveyReportTreatmentSuggestion({
    required int reportId,
    required String treatmentSuggestion,
  }) {
    return _putVoid(
      '/api/v1/saas/physiques/reports/$reportId/treatment-suggestion',
      data: {
        'treatmentSuggestion': _requireText(
          treatmentSuggestion,
          'treatmentSuggestion',
        ),
      },
    );
  }

  Future<void> relateSurveyReportCustomer({
    required int reportId,
    required int customerId,
    String? name,
    String? phone,
  }) {
    return _putVoid(
      '/api/v1/saas/physiques/reports/$reportId/customer',
      data: _cleanPayload({
        'customerId': customerId,
        'name': _trimmedOrNull(name),
        'phone': _trimmedOrNull(phone),
      }),
    );
  }

  Future<Map<String, dynamic>> createSurveyReportDownloadToken(int reportId) {
    return _postPayload(
      '/api/v1/saas/physiques/reports/$reportId/download-token',
      omitEmptyBody: true,
    );
  }

  Future<DiagnosisReportDetail> getSurveyReportByToken(String token) async {
    final envelope = await _getEnvelope(
      '/api/v1/saas/physiques/reports/token-detail',
      queryParameters: {'token': _requireText(token, 'token')},
    );
    return DiagnosisReportDetail.fromJson(
      _requirePayload(
        envelope,
        message:
            'Survey report token detail response did not include a data payload.',
      ),
    );
  }

  Future<DiagnosisReportSummary?> getLatestReport({
    required String source,
    int? topOrgId,
  }) async {
    final envelope = await _getReportsEnvelope(
      pageNo: 1,
      pageSize: 1,
      source: source,
      topOrgId: topOrgId,
    );
    return _firstSummaryOrNull(envelope);
  }

  Future<List<DiagnosisReportSummary>> getAllReports({
    String? source,
    int? topOrgId,
    int pageSize = 50,
    bool resolveFaceImages = false,
  }) async {
    final reports = <DiagnosisReportSummary>[];
    var pageNo = 1;
    int? totalCount;

    while (true) {
      final envelope = await _getReportsEnvelope(
        pageNo: pageNo,
        pageSize: pageSize,
        source: source,
        topOrgId: topOrgId,
      );
      final items = _extractSummaries(envelope);
      if (items.isEmpty) {
        break;
      }

      reports.addAll(items);
      totalCount ??= _extractTotalCount(envelope);
      if ((totalCount != null && reports.length >= totalCount) ||
          items.length < pageSize) {
        break;
      }

      pageNo += 1;
    }

    if (!resolveFaceImages) {
      return reports;
    }

    return _resolveSummariesFaceImages(reports, topOrgId: topOrgId);
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
      if (source != null && source.trim().isNotEmpty) 'source': source,
      if (topOrgId != null) 'topOrgId': topOrgId,
    };

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
    List<DiagnosisReportSummary> summaries,
    {
    int? topOrgId,
  }
  ) async {
    final resolved = await Future.wait(
      summaries.map(
        (summary) => _resolveSummaryFaceImage(summary, topOrgId: topOrgId),
      ),
    );
    return List<DiagnosisReportSummary>.unmodifiable(resolved);
  }

  Future<DiagnosisReportSummary> _resolveSummaryFaceImage(
    DiagnosisReportSummary summary,
    {
    int? topOrgId,
  }
  ) async {
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
