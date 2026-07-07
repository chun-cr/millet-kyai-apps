part of 'report_remote_source.dart';

extension ReportRemoteSourceEndpoints on ReportRemoteSource {
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

  Future<DiagnosisReportSummaryPage> getReportsPage({
    String? source,
    int? topOrgId,
    int pageNo = 1,
    int pageSize = 20,
    bool resolveFaceImages = false,
  }) async {
    final safePageNo = pageNo < 1 ? 1 : pageNo;
    final safePageSize = pageSize < 1 ? 20 : pageSize;
    final envelope = await _getReportsEnvelope(
      pageNo: safePageNo,
      pageSize: safePageSize,
      source: source,
      topOrgId: topOrgId,
    );
    final items = _extractSummaries(envelope);
    final resolvedItems = resolveFaceImages
        ? await _resolveSummariesFaceImages(items, topOrgId: topOrgId)
        : items;

    return DiagnosisReportSummaryPage(
      items: resolvedItems,
      pageNo: safePageNo,
      pageSize: safePageSize,
      totalCount: _extractTotalCount(envelope),
    );
  }
}
