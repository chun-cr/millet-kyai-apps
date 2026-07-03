// 扫描模块远端数据源：`ScanRemoteSource`。负责与后端接口交互，并把请求/响应细节限制在数据层内部。

import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../models/scan_upload_result.dart';

class ScanUploadException implements Exception {
  const ScanUploadException({
    required this.stage,
    required this.path,
    required this.message,
    this.statusCode,
    this.businessCode,
    this.messageKey,
    this.requestId,
    this.responseBody,
  });

  factory ScanUploadException.fromDioException({
    required String stage,
    required String path,
    required DioException error,
  }) {
    final responseData = error.response?.data;
    final envelope = responseData is Map<String, dynamic>
        ? responseData
        : responseData is Map
        ? Map<String, dynamic>.from(responseData)
        : null;

    return ScanUploadException(
      stage: stage,
      path: path,
      message:
          envelope?['message'] as String? ??
          error.message ??
          'Unknown network upload error.',
      statusCode: error.response?.statusCode,
      businessCode: (envelope?['code'] as num?)?.toInt(),
      messageKey: envelope?['messageKey'] as String?,
      requestId: envelope?['requestId'] as String?,
      responseBody: responseData,
    );
  }

  final String stage;
  final String path;
  final String message;
  final int? statusCode;
  final int? businessCode;
  final String? messageKey;
  final String? requestId;
  final Object? responseBody;

  String get debugDescription {
    final buffer = StringBuffer()
      ..writeln('stage: $stage')
      ..writeln('path: $path')
      ..writeln('message: $message');
    if (statusCode != null) {
      buffer.writeln('httpStatus: $statusCode');
    }
    if (businessCode != null) {
      buffer.writeln('businessCode: $businessCode');
    }
    if (messageKey != null && messageKey!.isNotEmpty) {
      buffer.writeln('messageKey: $messageKey');
    }
    if (requestId != null && requestId!.isNotEmpty) {
      buffer.writeln('requestId: $requestId');
    }
    if (responseBody != null) {
      buffer.writeln('responseBody: ${_stringify(responseBody)}');
    }
    return buffer.toString().trimRight();
  }

  static String _stringify(Object? value) {
    if (value == null) {
      return 'null';
    }
    if (value is String) {
      return value;
    }
    try {
      return jsonEncode(value);
    } on Object {
      return value.toString();
    }
  }

  @override
  String toString() => debugDescription;
}

class ScanRemoteSource {
  ScanRemoteSource(this._dioClient);

  static const reportSource = 'KY_MA';
  static const _scanUploadRequestExtra = <String, dynamic>{
    DioClient.skipPlatformHeadersExtraKey: true,
  };

  final DioClient _dioClient;

  Future<ScanFaceUploadResult> uploadFace({
    required String faceFilePath,
    String? faceFrameFilePath,
    int? tenantId,
    int? topOrgId,
    int? storeId,
    int? clinicId,
    ProgressCallback? onSendProgress,
  }) async {
    const path = '/api/v1/saas/mobile/ai/diagnosis/upload/face';
    final payload = await _postMultipart(
      stage: 'face',
      path: path,
      data: FormData.fromMap({
        ..._buildTenantContextFields(
          tenantId: tenantId,
          topOrgId: topOrgId,
          storeId: storeId,
          clinicId: clinicId,
        ),
        'faceFile': await MultipartFile.fromFile(
          faceFilePath,
          filename: _fileName(faceFilePath),
        ),
        'faceFrameFile': await MultipartFile.fromFile(
          faceFrameFilePath ?? faceFilePath,
          filename: _fileName(faceFrameFilePath ?? faceFilePath),
        ),
      }),
      options: _scanUploadOptions(),
      onSendProgress: onSendProgress,
    );
    return ScanFaceUploadResult.fromJson(payload);
  }

  Future<ScanTongueUploadResult> uploadTongue({
    required String imageFilePath,
    required ScanFaceUploadResult faceUpload,
    int imageType = 1,
    String source = reportSource,
    int? tenantId,
    int? topOrgId,
    int? storeId,
    int? clinicId,
    ProgressCallback? onSendProgress,
  }) async {
    const path = '/api/v1/saas/mobile/ai/diagnosis/upload';
    final payload = await _postMultipart(
      stage: 'tongue',
      path: path,
      data: FormData.fromMap({
        'source': source,
        'imageType': imageType,
        'genReportFlag': '1',
        'finishedFlag': '0',
        ..._buildTenantContextFields(
          tenantId: tenantId,
          topOrgId: topOrgId,
          storeId: storeId,
          clinicId: clinicId,
        ),
        'faceData': faceUpload.toTongueFaceDataJson(),
        'imageFile': await MultipartFile.fromFile(
          imageFilePath,
          filename: _fileName(imageFilePath),
        ),
      }),
      options: _scanUploadOptions(),
      onSendProgress: onSendProgress,
    );
    return ScanTongueUploadResult.fromJson(payload);
  }

  Future<ScanPalmUploadResult> uploadPalm({
    required String handFilePath,
    String? handFrameFilePath,
    required String reportId,
    ProgressCallback? onSendProgress,
  }) async {
    const path = '/api/v1/saas/mobile/ai/diagnosis/upload/hand';
    final payload = await _postMultipart(
      stage: 'palm',
      path: path,
      allowEmptyPayload: true,
      data: FormData.fromMap({
        'reportId': reportId,
        'handFile': await MultipartFile.fromFile(
          handFilePath,
          filename: _fileName(handFilePath),
        ),
        'handFrameFile': await MultipartFile.fromFile(
          handFrameFilePath ?? handFilePath,
          filename: _fileName(handFrameFilePath ?? handFilePath),
        ),
      }),
      options: _scanUploadOptions(),
      onSendProgress: onSendProgress,
    );
    return ScanPalmUploadResult.fromJson(payload);
  }

  Future<Map<String, dynamic>> _postMultipart({
    required String stage,
    required String path,
    required FormData data,
    Options? options,
    bool allowEmptyPayload = false,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final response = await _dioClient.dio.post<dynamic>(
        path,
        data: data,
        options: options,
        onSendProgress: onSendProgress,
      );
      return _extractSuccessPayload(
        stage: stage,
        path: path,
        data: response.data,
        allowEmptyPayload: allowEmptyPayload,
      );
    } on DioException catch (error) {
      final exception = ScanUploadException.fromDioException(
        stage: stage,
        path: path,
        error: error,
      );
      AppLogger.network('Scan upload failed: ${exception.debugDescription}');
      throw exception;
    }
  }

  Options _scanUploadOptions() {
    return Options(extra: Map<String, dynamic>.from(_scanUploadRequestExtra));
  }

  Map<String, dynamic> _extractSuccessPayload({
    required String stage,
    required String path,
    required dynamic data,
    bool allowEmptyPayload = false,
  }) {
    final envelope = _asMap(data);
    if (envelope == null) {
      throw ScanUploadException(
        stage: stage,
        path: path,
        message: 'Invalid response envelope.',
        responseBody: data,
      );
    }

    final businessCode = (envelope['code'] as num?)?.toInt();
    if (businessCode != null && businessCode != 0) {
      throw ScanUploadException(
        stage: stage,
        path: path,
        message: envelope['message'] as String? ?? 'Upload request failed.',
        businessCode: businessCode,
        messageKey: envelope['messageKey'] as String?,
        requestId: envelope['requestId'] as String?,
        responseBody: envelope,
      );
    }

    final payload = _asMap(envelope['data']);
    if (payload == null) {
      if (allowEmptyPayload &&
          envelope.containsKey('data') &&
          envelope['data'] == null) {
        return const <String, dynamic>{};
      }
      throw ScanUploadException(
        stage: stage,
        path: path,
        message: 'Invalid response payload.',
        responseBody: envelope,
      );
    }
    return payload;
  }

  String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/');
    return segments.isEmpty ? normalized : segments.last;
  }

  Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  Map<String, dynamic> _buildTenantContextFields({
    required int? tenantId,
    required int? topOrgId,
    required int? storeId,
    required int? clinicId,
  }) {
    return <String, dynamic>{
      ...?_singleTenantContextField('tenantId', tenantId),
      ...?_singleTenantContextField('topOrgId', topOrgId),
      ...?_singleTenantContextField('storeId', storeId),
      ...?_singleTenantContextField('clinicId', clinicId),
    };
  }

  Map<String, dynamic>? _singleTenantContextField(String key, int? value) {
    if (value == null) {
      return null;
    }
    return <String, dynamic>{key: value};
  }
}
