// 扫描模块远端数据源：`PhysiqueQuestionRemoteSource`。负责与后端接口交互，并把请求/响应细节限制在数据层内部。

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import 'scan_remote_source.dart';
import '../models/physique_question_models.dart';

class PhysiqueQuestionRemoteSource {
  PhysiqueQuestionRemoteSource(this._dioClient);

  final DioClient _dioClient;

  Future<PhysiqueQuestionEnvelope> fetchNextQuestion(
    PhysiqueQuestionRequest request,
  ) async {
    const path = '/api/v1/saas/mobile/physique/question/next';
    try {
      final response = await _dioClient.dio.post<dynamic>(
        path,
        data: request.toJson(),
      );
      final envelope = _asMap(response.data);
      if (envelope == null) {
        throw const FormatException('Invalid response envelope.');
      }
      final parsed = PhysiqueQuestionEnvelope.fromJson(envelope);
      final businessCode = parsed.code;
      if (businessCode != null && businessCode != 0) {
        throw ScanUploadException(
          stage: 'physique_question',
          path: path,
          message: parsed.message ?? 'Question request failed.',
          businessCode: businessCode,
          messageKey: parsed.messageKey,
          requestId: parsed.requestId,
          responseBody: envelope,
        );
      }
      return parsed;
    } on DioException catch (error) {
      throw ScanUploadException.fromDioException(
        stage: 'physique_question',
        path: path,
        error: error,
      );
    }
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
}
