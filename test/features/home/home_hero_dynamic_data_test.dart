import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/features/home/presentation/pages/home_page.dart';
import 'package:millet_kyai_apps/features/home/presentation/providers/home_hero_provider.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_me_entity.dart';
import 'package:millet_kyai_apps/features/profile/presentation/providers/profile_repository_provider.dart';
import 'package:millet_kyai_apps/features/report/data/models/report_detail.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';

void main() {
  testWidgets('home hero shows the user and latest report data', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 920));
    final recordedAt = DateTime.now()
        .subtract(const Duration(days: 2))
        .toIso8601String();
    final summary = DiagnosisReportSummary(
      id: 'report-1',
      testTime: recordedAt,
      healthScore: 82,
      physiqueName: 'Qi deficiency',
      imageUrl: '',
      faceImageUrl: '',
      lockedStatus: '1',
      deepPredicts: DiagnosisDeepPredicts(
        categoryProbabilities: const [],
        predictions: const [],
        diseases: const [],
        raw: const {},
      ),
      raw: const {},
    );
    final detail = DiagnosisReportDetail.fromJson({
      'id': 'report-1',
      'testTime': recordedAt,
      'healthScore': 82,
      'analysisResult': {
        'tz': {
          'id': '2',
          'name': 'Qi deficiency',
          'score': 86,
          'solutions': 'Strengthen qi and keep a regular routine.',
        },
        'tzData': [
          {'id': '2', 'name': 'Qi deficiency', 'score': 86},
          {'id': '1', 'name': '平和体质', 'score': 54},
          {'id': '5', 'name': 'Dampness', 'score': 32},
        ],
        'result': [
          {
            'name': 'Constitution assessment',
            'result': 'Your qi needs consistent support.',
          },
        ],
      },
      'faceAnalysisResult': const <String, dynamic>{},
      'handAnalysisResult': const <String, dynamic>{},
      'tzpdAnalysisResult': const <String, dynamic>{},
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileMeProvider.overrideWith(
            (ref) async => const ProfileMeEntity(nickname: 'Amin'),
          ),
          homeLatestReportSummaryProvider.overrideWith((ref) async => summary),
          homeLatestReportProvider.overrideWith(
            (ref) async =>
                HomeLatestReportData(summary: summary, detail: detail),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const HomePage(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 1400));

    expect(find.textContaining('Amin'), findsOneWidget);
    expect(find.text('Qi deficiency'), findsNWidgets(3));
    expect(find.text('平和质'), findsOneWidget);
    expect(find.text('平和体质'), findsNothing);
    expect(find.text('82'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home_constitution_radar')),
      findsOneWidget,
    );
    expect(find.text('View Full Report'), findsOneWidget);
    expect(find.text('Compare Past Reports'), findsOneWidget);
    expect(tester.widget<Text>(find.text('View Full Report')).maxLines, 1);
    expect(tester.widget<Text>(find.text('Compare Past Reports')).maxLines, 1);
    expect(find.text('Today’s Wellness'), findsNothing);
    expect(
      find.byKey(const ValueKey('home_latest_report_split')),
      findsOneWidget,
    );

    await tester.binding.setSurfaceSize(const Size(600, 844));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('home_latest_report_split')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(const Size(414, 896));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('home_latest_report_split')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('home_latest_report_split')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(const Size(360, 800));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('home_latest_report_stacked')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('home shows the latest summary before report detail finishes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(600, 844));
    final detailCompleter = Completer<HomeLatestReportData?>();
    final summary = DiagnosisReportSummary(
      id: 'report-progressive',
      testTime: DateTime.now().toIso8601String(),
      healthScore: 78,
      physiqueName: '气虚体质',
      imageUrl: '',
      faceImageUrl: '',
      lockedStatus: '1',
      deepPredicts: DiagnosisDeepPredicts(
        categoryProbabilities: const [],
        predictions: const [],
        diseases: const [],
        raw: const {},
      ),
      raw: const {},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileMeProvider.overrideWith(
            (ref) async => const ProfileMeEntity(nickname: 'Amin'),
          ),
          homeLatestReportSummaryProvider.overrideWith((ref) async => summary),
          homeLatestReportProvider.overrideWith(
            (ref) => detailCompleter.future,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const HomePage(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const ValueKey('home_latest_report_card')),
      findsOneWidget,
    );
    expect(find.text('气虚质'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home_latest_report_detail_loading')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home_latest_report_loading')),
      findsNothing,
    );
    expect(find.text('Checked today'), findsOneWidget);
    expect(find.text('Checked 0 days ago'), findsNothing);
    expect(find.text('气虚体质 · Checked today'), findsOneWidget);
    expect(find.textContaining('0 days ago'), findsNothing);

    detailCompleter.complete(null);
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });
}
