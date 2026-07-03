import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/core/network/dio_client.dart';
import 'package:millet_kyai_apps/features/scan/data/models/physique_question_models.dart';
import 'package:millet_kyai_apps/features/scan/data/sources/physique_question_remote_source.dart';

class _StubResponse {
  const _StubResponse(this.statusCode, this.body);

  final int statusCode;
  final Map<String, dynamic> body;
}

class _QueueHttpClientAdapter implements HttpClientAdapter {
  _QueueHttpClientAdapter(this._responses);

  final List<_StubResponse> _responses;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = _responses.removeAt(0);
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }
}

void main() {
  test(
    'fetchNextQuestion posts request body to physique question endpoint',
    () async {
      final adapter = _QueueHttpClientAdapter(<_StubResponse>[
        const _StubResponse(200, <String, dynamic>{
          'code': 0,
          'data': <String, dynamic>{
            'question': <String, dynamic>{
              'id': 11,
              'title': 'How have you been sleeping?',
              'options': <Map<String, String>>[
                <String, String>{'optionValue': 'good', 'optionName': 'Good'},
              ],
            },
          },
        }),
      ]);
      final dioClient = DioClient();
      dioClient.dio.interceptors.clear();
      dioClient.dio.httpClientAdapter = adapter;
      final source = PhysiqueQuestionRemoteSource(dioClient);

      final envelope = await source.fetchNextQuestion(
        const PhysiqueQuestionRequest(
          gender: 'F',
          phyCategory: 'PHY-TEST',
          age: 28,
          clinicId: 3,
          topOrgId: 8,
          tongueReportId: 33,
          medicalCaseId: 44,
          answers: <PhysiqueQuestionRequestAnswer>[
            PhysiqueQuestionRequestAnswer(id: 1, optionValue: 'A'),
          ],
        ),
      );

      expect(adapter.requests, hasLength(1));
      expect(
        adapter.requests.single.path,
        '/api/v1/saas/mobile/physique/question/next',
      );
      expect(adapter.requests.single.data, <String, dynamic>{
        'gender': 'F',
        'phyCategory': 'PHY-TEST',
        'age': 28,
        'clinicId': 3,
        'topOrgId': 8,
        'tongueReportId': 33,
        'medicalCaseId': 44,
        'answers': <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'optionValue': 'A'},
        ],
      });
      expect(envelope.code, 0);
      expect(envelope.data['question'], isA<Map<String, dynamic>>());
    },
  );
}
