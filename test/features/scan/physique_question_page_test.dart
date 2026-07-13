import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/core/network/dio_client.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_me_entity.dart';
import 'package:millet_kyai_apps/features/scan/data/models/physique_question_models.dart';
import 'package:millet_kyai_apps/features/scan/data/models/scan_session.dart';
import 'package:millet_kyai_apps/features/scan/data/models/scan_upload_result.dart';
import 'package:millet_kyai_apps/features/scan/data/sources/physique_question_remote_source.dart';
import 'package:millet_kyai_apps/features/scan/data/sources/scan_remote_source.dart';
import 'package:millet_kyai_apps/features/scan/presentation/pages/physique_question_page.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';

class _RecordingPhysiqueQuestionRemoteSource
    extends PhysiqueQuestionRemoteSource {
  _RecordingPhysiqueQuestionRemoteSource(this._responses) : super(DioClient());

  final List<PhysiqueQuestionEnvelope> _responses;
  final List<PhysiqueQuestionRequest> requests = <PhysiqueQuestionRequest>[];

  @override
  Future<PhysiqueQuestionEnvelope> fetchNextQuestion(
    PhysiqueQuestionRequest request,
  ) async {
    requests.add(request);
    return _responses.removeAt(0);
  }
}

class _QueuePhysiqueQuestionRemoteSource extends PhysiqueQuestionRemoteSource {
  _QueuePhysiqueQuestionRemoteSource(this._results) : super(DioClient());

  final List<Object> _results;
  final List<PhysiqueQuestionRequest> requests = <PhysiqueQuestionRequest>[];

  @override
  Future<PhysiqueQuestionEnvelope> fetchNextQuestion(
    PhysiqueQuestionRequest request,
  ) async {
    requests.add(request);
    final result = _results.removeAt(0);
    if (result is PhysiqueQuestionEnvelope) {
      return result;
    }
    throw result;
  }
}

Future<void> _pumpQuestionPage(
  WidgetTester tester, {
  required ScanSession scanSession,
  required PhysiqueQuestionRemoteSource remoteSource,
  required Future<void> Function(String? reportId) onNavigate,
  ProfileMeEntity? profile = const ProfileMeEntity(
    realName: 'Test User',
    phone: '13800000000',
    gender: 'female',
  ),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: PhysiqueQuestionPage(
        remoteSource: remoteSource,
        scanSession: scanSession,
        profileLoader: (_) async => profile,
        navigateToReport: (context, reportId) => onNavigate(reportId),
      ),
    ),
  );
  await tester.pump();
}

ScanSession _buildScanSession() {
  final session = ScanSession();
  session.saveFaceUpload(
    const ScanFaceUploadResult(<String, dynamic>{
      'faceNum': 1,
      'imageId': 'face-image',
      'imageUrl': 'https://example.com/face.png',
      'age': 29,
      'sex': 'F',
    }),
  );
  session.saveTongueUpload(
    const ScanTongueUploadResult(<String, dynamic>{
      'analysisResult': <String, dynamic>{'success': true, 'hasTongue': true},
      'tongueReport': <String, dynamic>{
        'success': true,
        'reportId': 'report-123',
        'id': 789,
        'medicalCaseId': 456,
      },
    }),
  );
  return session;
}

ScanSession _buildScanSessionWithoutReportId() {
  final session = ScanSession();
  session.saveFaceUpload(
    const ScanFaceUploadResult(<String, dynamic>{
      'faceNum': 1,
      'imageId': 'face-image',
      'imageUrl': 'https://example.com/face.png',
      'age': 29,
      'sex': 'F',
    }),
  );
  session.saveTongueUpload(
    const ScanTongueUploadResult(<String, dynamic>{
      'analysisResult': <String, dynamic>{},
      'tongueReport': <String, dynamic>{'id': 789, 'medicalCaseId': 456},
    }),
  );
  return session;
}

ScanSession _buildScanSessionWithoutTongueReportId() {
  final session = ScanSession();
  session.saveFaceUpload(
    const ScanFaceUploadResult(<String, dynamic>{
      'faceNum': 1,
      'imageId': 'face-image',
      'imageUrl': 'https://example.com/face.png',
      'age': 29,
      'sex': 'F',
    }),
  );
  session.saveTongueUpload(
    const ScanTongueUploadResult(<String, dynamic>{
      'analysisResult': <String, dynamic>{'success': true, 'hasTongue': true},
      'tongueReport': <String, dynamic>{
        'success': true,
        'reportId': 'report-123',
        'medicalCaseId': 456,
      },
    }),
  );
  return session;
}

void main() {
  testWidgets('skip keeps current report id and jumps to report', (
    tester,
  ) async {
    final scanSession = _buildScanSession();
    final remoteSource = _RecordingPhysiqueQuestionRemoteSource(
      <PhysiqueQuestionEnvelope>[
        const PhysiqueQuestionEnvelope(
          code: 0,
          data: <String, dynamic>{
            'question': <String, dynamic>{
              'id': 11,
              'title': 'How have you been sleeping?',
              'options': <Map<String, String>>[
                <String, String>{'optionValue': 'good', 'optionName': 'Good'},
              ],
            },
          },
        ),
      ],
    );

    String? navigatedReportId;
    await _pumpQuestionPage(
      tester,
      scanSession: scanSession,
      remoteSource: remoteSource,
      onNavigate: (reportId) async => navigatedReportId = reportId,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('scan_question_skip_button')));
    await tester.pump();

    expect(navigatedReportId, 'report-123');
  });

  testWidgets(
    'bootstrap retries transient not-ready failure then shows question',
    (tester) async {
      final scanSession = _buildScanSession();
      final remoteSource = _QueuePhysiqueQuestionRemoteSource(<Object>[
        const ScanUploadException(
          stage: 'physique_question',
          path: '/api/v1/saas/physiques/next-question',
          message: 'Not Found',
          statusCode: 404,
          messageKey: 'physique.question_not_ready',
        ),
        const PhysiqueQuestionEnvelope(
          code: 0,
          data: <String, dynamic>{
            'next': <String, dynamic>{
              'id': 11,
              'question': 'How have you been sleeping?',
              'options': <Map<String, String>>[
                <String, String>{'value': 'good', 'text': 'Good'},
              ],
            },
          },
        ),
      ]);

      String? navigatedReportId;
      await _pumpQuestionPage(
        tester,
        scanSession: scanSession,
        remoteSource: remoteSource,
        onNavigate: (reportId) async => navigatedReportId = reportId,
      );
      await tester.pump(const Duration(milliseconds: 301));
      await tester.pumpAndSettle();

      expect(navigatedReportId, isNull);
      expect(remoteSource.requests, hasLength(2));
      expect(find.text('How have you been sleeping?'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
    },
  );

  testWidgets(
    'bootstrap does not treat initial completed payload as skip to report',
    (tester) async {
      final scanSession = _buildScanSession();
      final remoteSource = _QueuePhysiqueQuestionRemoteSource(<Object>[
        const PhysiqueQuestionEnvelope(
          code: 0,
          data: <String, dynamic>{
            'result': <String, dynamic>{'reportId': 'report-final'},
          },
        ),
        const PhysiqueQuestionEnvelope(
          code: 0,
          data: <String, dynamic>{
            'next': <String, dynamic>{
              'id': 11,
              'question': 'How have you been sleeping?',
              'options': <Map<String, String>>[
                <String, String>{'value': 'good', 'text': 'Good'},
              ],
            },
          },
        ),
      ]);

      String? navigatedReportId;
      await _pumpQuestionPage(
        tester,
        scanSession: scanSession,
        remoteSource: remoteSource,
        onNavigate: (reportId) async => navigatedReportId = reportId,
      );
      await tester.pump(const Duration(milliseconds: 301));
      await tester.pumpAndSettle();

      expect(navigatedReportId, isNull);
      expect(remoteSource.requests, hasLength(2));
      expect(find.text('How have you been sleeping?'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
    },
  );

  testWidgets('bootstrap request only includes the physique API contract', (
    tester,
  ) async {
    final scanSession = _buildScanSessionWithoutTongueReportId();
    final remoteSource = _RecordingPhysiqueQuestionRemoteSource(
      <PhysiqueQuestionEnvelope>[
        const PhysiqueQuestionEnvelope(
          code: 0,
          data: <String, dynamic>{
            'next': <String, dynamic>{
              'id': 11,
              'question': 'How have you been sleeping?',
              'options': <Map<String, String>>[
                <String, String>{'value': 'good', 'text': 'Good'},
              ],
            },
          },
        ),
      ],
    );

    await _pumpQuestionPage(
      tester,
      scanSession: scanSession,
      remoteSource: remoteSource,
      onNavigate: (_) async {},
    );
    await tester.pumpAndSettle();

    expect(remoteSource.requests, hasLength(1));
    expect(remoteSource.requests.single.toJson(), <String, dynamic>{
      'gender': 'F',
      'phyCategory': 'tzpd',
      'answers': <Map<String, dynamic>>[],
    });
    expect(find.text('How have you been sleeping?'), findsOneWidget);
  });

  testWidgets('plain 404 is not retried as question readiness', (tester) async {
    final scanSession = _buildScanSession();
    final remoteSource = _QueuePhysiqueQuestionRemoteSource(<Object>[
      const ScanUploadException(
        stage: 'physique_question',
        path: '/api/v1/saas/physiques/next-question',
        message: 'Not Found',
        statusCode: 404,
      ),
    ]);

    await _pumpQuestionPage(
      tester,
      scanSession: scanSession,
      remoteSource: remoteSource,
      onNavigate: (_) async {},
    );
    await tester.pumpAndSettle();

    expect(remoteSource.requests, hasLength(1));
    expect(find.byKey(const ValueKey('scan_question_error')), findsOneWidget);
    expect(find.textContaining('Not Found'), findsOneWidget);
  });

  testWidgets('bootstrap request uses physique API payload shape', (
    tester,
  ) async {
    final scanSession = _buildScanSession();
    final remoteSource = _RecordingPhysiqueQuestionRemoteSource(
      <PhysiqueQuestionEnvelope>[
        const PhysiqueQuestionEnvelope(
          code: 0,
          data: <String, dynamic>{
            'question': <String, dynamic>{
              'id': 11,
              'title': 'How have you been sleeping?',
              'options': <Map<String, String>>[
                <String, String>{'optionValue': 'good', 'optionName': 'Good'},
              ],
            },
          },
        ),
      ],
    );

    await _pumpQuestionPage(
      tester,
      scanSession: scanSession,
      remoteSource: remoteSource,
      onNavigate: (_) async {},
    );
    await tester.pumpAndSettle();

    expect(remoteSource.requests, hasLength(1));
    expect(remoteSource.requests.single.toJson(), <String, dynamic>{
      'gender': 'F',
      'phyCategory': 'tzpd',
      'answers': <Map<String, dynamic>>[],
    });
  });

  testWidgets('bootstrap renders question response with backend alias fields', (
    tester,
  ) async {
    final scanSession = _buildScanSession();
    final remoteSource = _RecordingPhysiqueQuestionRemoteSource(
      <PhysiqueQuestionEnvelope>[
        const PhysiqueQuestionEnvelope(
          code: 0,
          data: <String, dynamic>{
            'payload': <String, dynamic>{
              'nextQuestion': <String, dynamic>{
                'question_id': '21',
                'questionName': 'How is your appetite?',
                'answerList': <Map<String, String>>[
                  <String, String>{'answerValue': '2', 'answerText': 'Good'},
                  <String, String>{'answerValue': '0', 'answerText': 'Poor'},
                ],
                'questionIndex': '1',
                'total': '3',
              },
            },
          },
        ),
      ],
    );

    await _pumpQuestionPage(
      tester,
      scanSession: scanSession,
      remoteSource: remoteSource,
      onNavigate: (_) async {},
    );
    await tester.pumpAndSettle();

    expect(remoteSource.requests, hasLength(1));
    expect(find.text('How is your appetite?'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('Poor'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('scan_question_option_2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('scan_question_option_0')),
      findsOneWidget,
    );
  });

  testWidgets('skip without reportId shows error instead of navigating', (
    tester,
  ) async {
    final scanSession = _buildScanSessionWithoutReportId();
    final remoteSource = _RecordingPhysiqueQuestionRemoteSource(
      <PhysiqueQuestionEnvelope>[
        const PhysiqueQuestionEnvelope(
          code: 0,
          data: <String, dynamic>{
            'question': <String, dynamic>{
              'id': 11,
              'title': 'How have you been sleeping?',
              'options': <Map<String, String>>[
                <String, String>{'optionValue': 'good', 'optionName': 'Good'},
              ],
            },
          },
        ),
      ],
    );

    var didNavigate = false;
    await _pumpQuestionPage(
      tester,
      scanSession: scanSession,
      remoteSource: remoteSource,
      onNavigate: (_) async => didNavigate = true,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('scan_question_skip_button')));
    await tester.pumpAndSettle();

    expect(didNavigate, isFalse);
    expect(find.byKey(const ValueKey('scan_question_error')), findsOneWidget);
  });

  testWidgets(
    'single-choice option tap sends accumulated answers and navigates',
    (tester) async {
      final scanSession = _buildScanSession();
      final remoteSource = _RecordingPhysiqueQuestionRemoteSource(
        <PhysiqueQuestionEnvelope>[
          const PhysiqueQuestionEnvelope(
            code: 0,
            data: <String, dynamic>{
              'next': <String, dynamic>{
                'id': 11,
                'question': 'How have you been sleeping?',
                'options': <Map<String, String>>[
                  <String, String>{'value': 'good', 'text': 'Good'},
                  <String, String>{'value': 'normal', 'text': 'Normal'},
                ],
                'currentIndex': 1,
                'totalCount': 1,
              },
            },
          ),
          const PhysiqueQuestionEnvelope(
            code: 0,
            data: <String, dynamic>{'reportId': 'report-final'},
          ),
        ],
      );

      String? navigatedReportId;
      await _pumpQuestionPage(
        tester,
        scanSession: scanSession,
        remoteSource: remoteSource,
        onNavigate: (reportId) async => navigatedReportId = reportId,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('scan_question_title')), findsOneWidget);
      expect(find.text('How have you been sleeping?'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('scan_question_submit_button')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('scan_question_option_normal')),
      );
      await tester.pumpAndSettle();

      expect(remoteSource.requests, hasLength(2));
      expect(remoteSource.requests.last.toJson(), <String, dynamic>{
        'gender': 'F',
        'phyCategory': 'tzpd',
        'answers': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 11,
            'optionValues': <String>['normal'],
          },
        ],
      });
      expect(navigatedReportId, 'report-123');
      expect(scanSession.questionCompletionResult, <String, dynamic>{
        'reportId': 'report-final',
      });
    },
  );

  testWidgets('multiple-choice submit sends every selected option value', (
    tester,
  ) async {
    final scanSession = _buildScanSession();
    final remoteSource = _RecordingPhysiqueQuestionRemoteSource(
      <PhysiqueQuestionEnvelope>[
        const PhysiqueQuestionEnvelope(
          code: 0,
          data: <String, dynamic>{
            'next': <String, dynamic>{
              'id': 11,
              'question': 'Which symptoms do you have?',
              'multiple': true,
              'options': <Map<String, String>>[
                <String, String>{'value': 'dry-mouth', 'text': 'Dry mouth'},
                <String, String>{'value': 'poor-sleep', 'text': 'Poor sleep'},
              ],
            },
          },
        ),
        const PhysiqueQuestionEnvelope(
          code: 0,
          data: <String, dynamic>{'reportId': 'report-final'},
        ),
      ],
    );

    await _pumpQuestionPage(
      tester,
      scanSession: scanSession,
      remoteSource: remoteSource,
      onNavigate: (_) async {},
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('scan_question_option_dry-mouth')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan_question_option_poor-sleep')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('scan_question_submit_button')));
    await tester.pumpAndSettle();

    expect(remoteSource.requests, hasLength(2));
    expect(remoteSource.requests.last.toJson()['answers'], <Object>[
      <String, dynamic>{
        'id': 11,
        'optionValues': <String>['dry-mouth', 'poor-sleep'],
      },
    ]);
  });

  testWidgets(
    'incomplete next question response stays on the question instead of completing',
    (tester) async {
      final scanSession = _buildScanSession();
      final remoteSource = _RecordingPhysiqueQuestionRemoteSource(
        <PhysiqueQuestionEnvelope>[
          const PhysiqueQuestionEnvelope(
            code: 0,
            data: <String, dynamic>{
              'next': <String, dynamic>{
                'id': 11,
                'question': 'How have you been sleeping?',
                'options': <Map<String, String>>[
                  <String, String>{'value': 'good', 'text': 'Good'},
                ],
              },
            },
          ),
          const PhysiqueQuestionEnvelope(
            code: 0,
            data: <String, dynamic>{
              'next': <String, dynamic>{
                'id': 12,
                'question': 'How is your appetite?',
                'options': <Map<String, String>>[],
              },
              'result': <String, dynamic>{'reportId': 'report-final'},
            },
          ),
        ],
      );

      var didNavigate = false;
      await _pumpQuestionPage(
        tester,
        scanSession: scanSession,
        remoteSource: remoteSource,
        onNavigate: (_) async => didNavigate = true,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('scan_question_option_good')));
      await tester.pumpAndSettle();

      expect(didNavigate, isFalse);
      expect(find.text('How have you been sleeping?'), findsOneWidget);
      expect(find.text('体质问卷题目数据不完整，请稍后重试。'), findsOneWidget);
    },
  );

  testWidgets(
    'completed result keeps original report id and stores questionnaire result',
    (tester) async {
      final scanSession = _buildScanSession();
      final remoteSource = _RecordingPhysiqueQuestionRemoteSource(
        <PhysiqueQuestionEnvelope>[
          const PhysiqueQuestionEnvelope(
            code: 0,
            data: <String, dynamic>{
              'next': <String, dynamic>{
                'id': 11,
                'question': 'How have you been sleeping?',
                'options': <Map<String, String>>[
                  <String, String>{'value': 'good', 'text': 'Good'},
                ],
              },
            },
          ),
          const PhysiqueQuestionEnvelope(
            code: 0,
            data: <String, dynamic>{
              'result': <String, dynamic>{
                'reportId': 'question-result-report',
                'phyType': 'Qi deficiency',
                'physiqueResults': <Map<String, Object>>[
                  <String, Object>{
                    'id': '2',
                    'name': 'Qi deficiency',
                    'score': 82,
                  },
                ],
              },
            },
          ),
        ],
      );

      String? navigatedReportId;
      await _pumpQuestionPage(
        tester,
        scanSession: scanSession,
        remoteSource: remoteSource,
        onNavigate: (reportId) async => navigatedReportId = reportId,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('scan_question_option_good')));
      await tester.pumpAndSettle();

      expect(navigatedReportId, 'report-123');
      expect(
        scanSession.questionCompletionResult?['reportId'],
        'question-result-report',
      );
      expect(
        scanSession.questionCompletionResult?['physiqueResults'],
        isNotEmpty,
      );
    },
  );

  testWidgets(
    'answer submission retries transient not-ready failure before advancing',
    (tester) async {
      final scanSession = _buildScanSession();
      final remoteSource = _QueuePhysiqueQuestionRemoteSource(<Object>[
        const PhysiqueQuestionEnvelope(
          code: 0,
          data: <String, dynamic>{
            'next': <String, dynamic>{
              'id': 11,
              'question': 'How have you been sleeping?',
              'options': <Map<String, String>>[
                <String, String>{'value': 'good', 'text': 'Good'},
              ],
              'currentIndex': 1,
              'totalCount': 2,
            },
          },
        ),
        const ScanUploadException(
          stage: 'physique_question',
          path: '/api/v1/saas/physiques/next-question',
          message: 'Report is generating',
          statusCode: 404,
          messageKey: 'physique.report_generating',
        ),
        const PhysiqueQuestionEnvelope(
          code: 0,
          data: <String, dynamic>{
            'next': <String, dynamic>{
              'id': 12,
              'question': 'How is your appetite?',
              'options': <Map<String, String>>[
                <String, String>{'value': 'normal', 'text': 'Normal'},
              ],
              'currentIndex': 2,
              'totalCount': 2,
            },
          },
        ),
      ]);

      await _pumpQuestionPage(
        tester,
        scanSession: scanSession,
        remoteSource: remoteSource,
        onNavigate: (_) async {},
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('scan_question_option_good')));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('scan_question_submit_progress')),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 301));
      await tester.pumpAndSettle();

      expect(remoteSource.requests, hasLength(3));
      expect(remoteSource.requests.last.toJson()['answers'], <Object>[
        <String, dynamic>{
          'id': 11,
          'optionValues': <String>['good'],
        },
      ]);
      expect(find.text('How is your appetite?'), findsOneWidget);
      expect(find.text('How have you been sleeping?'), findsNothing);
    },
  );

  testWidgets(
    'answer submission retries transient param-invalid failure before advancing',
    (tester) async {
      final scanSession = _buildScanSession();
      final remoteSource = _QueuePhysiqueQuestionRemoteSource(<Object>[
        const PhysiqueQuestionEnvelope(
          code: 0,
          data: <String, dynamic>{
            'next': <String, dynamic>{
              'id': 11,
              'question': 'How have you been sleeping?',
              'options': <Map<String, String>>[
                <String, String>{'value': 'good', 'text': 'Good'},
              ],
              'currentIndex': 1,
              'totalCount': 2,
            },
          },
        ),
        const ScanUploadException(
          stage: 'physique_question',
          path: '/api/v1/saas/physiques/next-question',
          message: '请求参数不合法[1]',
          statusCode: 400,
          businessCode: 24043,
          messageKey: 'physique.param_invalid',
        ),
        const PhysiqueQuestionEnvelope(
          code: 0,
          data: <String, dynamic>{
            'next': <String, dynamic>{
              'id': 12,
              'question': 'How is your appetite?',
              'options': <Map<String, String>>[
                <String, String>{'value': 'normal', 'text': 'Normal'},
              ],
              'currentIndex': 2,
              'totalCount': 2,
            },
          },
        ),
      ]);

      await _pumpQuestionPage(
        tester,
        scanSession: scanSession,
        remoteSource: remoteSource,
        onNavigate: (_) async {},
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('scan_question_option_good')));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('scan_question_submit_progress')),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 301));
      await tester.pumpAndSettle();

      expect(remoteSource.requests, hasLength(3));
      expect(find.text('How is your appetite?'), findsOneWidget);
      expect(find.text('请求参数不合法[1]'), findsNothing);
    },
  );

  testWidgets('submitting the same question replaces the previous answer', (
    tester,
  ) async {
    final scanSession = _buildScanSession();
    scanSession.saveQuestionFlowSnapshot(
      const PhysiqueQuestionFlowSnapshot(
        requestContext: PhysiqueQuestionRequestContext(
          gender: 'F',
          phyCategory: 'tzpd',
        ),
        answers: <PhysiqueQuestionRequestAnswer>[
          PhysiqueQuestionRequestAnswer(id: 11, optionValues: <String>['old']),
        ],
        amenorrhea: null,
        question: PhysiqueQuestionPayload(
          raw: <String, dynamic>{},
          id: 11,
          title: 'How have you been sleeping?',
          options: <PhysiqueQuestionOption>[
            PhysiqueQuestionOption(value: 'good', label: 'Good'),
            PhysiqueQuestionOption(value: 'normal', label: 'Normal'),
          ],
          currentIndex: 1,
          totalCount: 2,
        ),
      ),
    );
    final remoteSource = _RecordingPhysiqueQuestionRemoteSource(
      <PhysiqueQuestionEnvelope>[
        const PhysiqueQuestionEnvelope(
          code: 0,
          data: <String, dynamic>{
            'next': <String, dynamic>{
              'id': 12,
              'question': 'How is your appetite?',
              'options': <Map<String, String>>[
                <String, String>{'value': 'normal', 'text': 'Normal'},
              ],
            },
          },
        ),
      ],
    );

    await _pumpQuestionPage(
      tester,
      scanSession: scanSession,
      remoteSource: remoteSource,
      onNavigate: (_) async {},
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('scan_question_option_normal')));
    await tester.pumpAndSettle();

    expect(remoteSource.requests, hasLength(1));
    expect(remoteSource.requests.single.toJson()['answers'], <Object>[
      <String, dynamic>{
        'id': 11,
        'optionValues': <String>['normal'],
      },
    ]);
    expect(find.text('How is your appetite?'), findsOneWidget);
  });
}
