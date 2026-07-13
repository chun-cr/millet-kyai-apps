// 扫描模块数据模型：`ScanSession`。用于承接接口原始字段，并在需要时转换为上层可消费的稳定结构。

import 'dart:async';

import 'scan_upload_result.dart';
import 'physique_question_models.dart';

class ScanSession {
  static const reportSource = 'KY_MA';

  ScanFaceUploadResult? _faceUpload;
  ScanTongueUploadResult? _tongueUpload;
  String? _lastReportId;
  int? _tenantId;
  int? _topOrgId;
  int? _storeId;
  int? _clinicId;
  String? _questionName;
  String? _questionPhone;
  String? _questionGender;
  PhysiqueQuestionFlowSnapshot? _questionFlowSnapshot;
  Future<PhysiqueQuestionFlowSnapshot>? _questionPrefetchFuture;
  Map<String, dynamic>? _questionCompletionResult;
  bool _faceScanSkipped = false;

  ScanFaceUploadResult? get faceUpload => _faceUpload;
  ScanTongueUploadResult? get tongueUpload => _tongueUpload;
  bool get faceScanSkipped => _faceScanSkipped;
  String? get reportId => _lastReportId?.isNotEmpty == true
      ? _lastReportId
      : _tongueUpload?.hasGeneratedReport == true
      ? _tongueUpload!.reportId
      : null;
  int? get detectedAge => _faceUpload?.age?.round();
  String get detectedGender => _faceUpload?.sex?.toString().trim() ?? '';
  int? get tongueReportId => _tongueUpload?.hasGeneratedReport == true
      ? _tongueUpload!.tongueReportId
      : null;
  int? get medicalCaseId => _tongueUpload?.medicalCaseId;
  int? get nextQuestionT => _tongueUpload?.nextQuestionT;
  String get nextQuestionKey => _tongueUpload?.nextQuestionKey.trim() ?? '';
  String get phyCategory => _tongueUpload?.phyCategory.trim() ?? '';
  int? get tenantId => _tenantId;
  int? get topOrgId => _topOrgId;
  int? get storeId => _storeId;
  int? get clinicId => _clinicId;
  String? get questionName => _questionName;
  String? get questionPhone => _questionPhone;
  String? get questionGender => _questionGender;
  PhysiqueQuestionFlowSnapshot? get questionFlowSnapshot =>
      _questionFlowSnapshot;
  Future<PhysiqueQuestionFlowSnapshot>? get questionPrefetchFuture =>
      _questionPrefetchFuture;
  Map<String, dynamic>? get questionCompletionResult {
    final data = _questionCompletionResult;
    return data == null ? null : Map<String, dynamic>.unmodifiable(data);
  }

  void reset() {
    _faceUpload = null;
    _tongueUpload = null;
    _lastReportId = null;
    _tenantId = null;
    _topOrgId = null;
    _storeId = null;
    _clinicId = null;
    _questionName = null;
    _questionPhone = null;
    _questionGender = null;
    _questionFlowSnapshot = null;
    _questionPrefetchFuture = null;
    _questionCompletionResult = null;
    _faceScanSkipped = false;
  }

  void saveFaceUpload(ScanFaceUploadResult result) {
    _faceUpload = result;
    _faceScanSkipped = false;
  }

  void markFaceScanSkipped() {
    _faceUpload = const ScanFaceUploadResult(<String, dynamic>{});
    _faceScanSkipped = true;
  }

  void saveTongueUpload(ScanTongueUploadResult result) {
    _tongueUpload = result;
    if (result.hasGeneratedReport) {
      _lastReportId = result.reportId;
    }
  }

  void saveReportId(String reportId) {
    if (reportId.isNotEmpty) {
      _lastReportId = reportId;
    }
  }

  void saveQuestionProfileSnapshot({
    String? name,
    String? phone,
    String? gender,
  }) {
    _questionName = _presentOrExisting(name, _questionName);
    _questionPhone = _presentOrExisting(phone, _questionPhone);
    _questionGender = _presentOrExisting(gender, _questionGender);
  }

  void saveTenantContext({
    int? tenantId,
    int? topOrgId,
    int? storeId,
    int? clinicId,
  }) {
    _tenantId = tenantId ?? _tenantId;
    _topOrgId = topOrgId ?? _topOrgId;
    _storeId = storeId ?? _storeId;
    _clinicId = clinicId ?? _clinicId;
  }

  void saveQuestionFlowSnapshot(PhysiqueQuestionFlowSnapshot snapshot) {
    _questionFlowSnapshot = snapshot;
  }

  void saveQuestionCompletionResult(Map<String, dynamic> data) {
    _questionCompletionResult = Map<String, dynamic>.from(data);
  }

  void clearQuestionFlowSnapshot() {
    _questionFlowSnapshot = null;
  }

  void clearQuestionPrefetch() {
    _questionPrefetchFuture = null;
  }

  Future<PhysiqueQuestionFlowSnapshot> trackQuestionPrefetch(
    Future<PhysiqueQuestionFlowSnapshot> future,
  ) {
    _questionPrefetchFuture = future;
    unawaited(
      future
          .whenComplete(() {
            if (identical(_questionPrefetchFuture, future)) {
              _questionPrefetchFuture = null;
            }
          })
          .then<void>((_) {}, onError: (Object _) {}),
    );
    return future;
  }

  String? _presentOrExisting(String? value, String? existing) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return existing;
    }
    return trimmed;
  }
}
