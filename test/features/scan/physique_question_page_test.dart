import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/core/network/dio_client.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_me_entity.dart';
import 'package:millet_kyai_apps/features/scan/data/models/physique_question_models.dart';
import 'package:millet_kyai_apps/features/scan/data/models/scan_session.dart';
import 'package:millet_kyai_apps/features/scan/data/models/scan_upload_result.dart';
import 'package:millet_kyai_apps/features/scan/data/sources/physique_question_remote_source.dart';
import 'package:millet_kyai_apps/features/scan/presentation/pages/physique_question_page.dart';
import 'package:millet_kyai_apps/features/share/domain/entities/app_id_mapping_entity.dart';
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

Future<void> _pumpQuestionPage(
  WidgetTester tester, {
  required ScanSession scanSession,
  required _RecordingPhysiqueQuestionRemoteSource remoteSource,
  required Future<void> Function(String? reportId) onNavigate,
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
        physiqueCategoryOverride: 'PHY-TEST',
        profileLoader: (_) async => const ProfileMeEntity(
          realName: '测试用户',
          phone: '13800000000',
          gender: 'female',
        ),
        appIdMappingLoader: (_) async =>
            const AppIdMappingEntity(topOrgId: '100', clinicId: '200'),
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
      'analysisResult': <String, dynamic>{},
      'tongueReport': <String, dynamic>{
        'reportId': 'report-123',
        'id': 789,
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
              'title': '最近睡眠怎么样？',
              'options': <Map<String, String>>[
                <String, String>{'optionValue': 'good', 'optionName': '挺好'},
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
    'answer submission sends accumulated answers and navigates with final report id',
    (tester) async {
      final scanSession = _buildScanSession();
      final remoteSource = _RecordingPhysiqueQuestionRemoteSource(
        <PhysiqueQuestionEnvelope>[
          const PhysiqueQuestionEnvelope(
            code: 0,
            data: <String, dynamic>{
              'question': <String, dynamic>{
                'id': 11,
                'title': '最近睡眠怎么样？',
                'options': <Map<String, String>>[
                  <String, String>{'optionValue': 'good', 'optionName': '挺好'},
                  <String, String>{'optionValue': 'normal', 'optionName': '一般'},
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

      expect(remoteSource.requests, hasLength(1));
      expect(remoteSource.requests.first.toJson(), <String, dynamic>{
        'gender': 'F',
        'phyCategory': 'PHY-TEST',
        'age': 29,
        'clinicId': 200,
        'medicalCaseId': 456,
        'name': '测试用户',
        'phone': '13800000000',
        'tongueReportId': 789,
        'topOrgId': 100,
      });

      await tester.tap(
        find.byKey(const ValueKey('scan_question_option_normal')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('scan_question_submit_button')),
      );
      await tester.pumpAndSettle();

      expect(remoteSource.requests, hasLength(2));
      expect(remoteSource.requests.last.toJson(), <String, dynamic>{
        'gender': 'F',
        'phyCategory': 'PHY-TEST',
        'age': 29,
        'clinicId': 200,
        'medicalCaseId': 456,
        'name': '测试用户',
        'phone': '13800000000',
        'tongueReportId': 789,
        'topOrgId': 100,
        'answers': <Map<String, dynamic>>[
          <String, dynamic>{'id': 11, 'optionValue': 'normal'},
        ],
      });
      expect(navigatedReportId, 'report-final');
    },
  );
}
