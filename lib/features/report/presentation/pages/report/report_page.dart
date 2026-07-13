import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:millet_kyai_apps/core/di/injector.dart';
import 'package:millet_kyai_apps/core/layout/app_layout.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/core/l10n/seasonal_context.dart';
import 'package:millet_kyai_apps/core/network/dio_client.dart';
import 'package:millet_kyai_apps/core/router/app_router.dart';
import 'package:millet_kyai_apps/core/widgets/app_toast.dart';
import 'package:millet_kyai_apps/features/report/data/models/report_detail.dart';
import 'package:millet_kyai_apps/features/report/data/sources/report_remote_source.dart';
import 'package:millet_kyai_apps/features/report/application/report_unlock_service.dart';
import 'package:millet_kyai_apps/features/report/presentation/models/report_project_data.dart';
import 'package:millet_kyai_apps/features/report/presentation/models/report_product_data.dart';
import 'package:millet_kyai_apps/features/report/presentation/pages/report/report_entry_resolver.dart';
import 'package:millet_kyai_apps/features/report/presentation/pages/report/report_view_data.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';

export 'report_view_data.dart';
export 'package:millet_kyai_apps/features/report/data/models/report_detail.dart';

part 'report_screen.dart';
part 'screen/report_hero_layout.dart';
part 'screen/report_hero_widgets.dart';
part 'screen/report_hero_helpers.dart';
part 'screen/report_share_dialog.dart';
part 'widgets/report_shared_widgets.dart';
part 'widgets/report_health_radar_widgets.dart';
part 'widgets/report_risk_widgets.dart';
part 'widgets/report_unlock_widgets.dart';
part 'widgets/report_recommendation_widgets.dart';
part 'report_painters.dart';
part 'tabs/overview_tab.dart';
part 'tabs/constitution_tab.dart';
part 'tabs/therapy_acupoints.dart';
part 'tabs/therapy_tab.dart';
part 'tabs/advice_tab.dart';

typedef ReportAddSymptomAction =
    Future<void> Function({
      required String reportId,
      required String symptomId,
      required String symptomName,
      required String recommendType,
    });

typedef ReportDeleteSymptomAction =
    Future<void> Function({
      required String reportId,
      required String symptomId,
      required String recommendType,
    });

typedef ReportShareQrCodeLoader =
    Future<DiagnosisReportShareQrCode> Function(String reportId);

Future<void> _persistReportSymptomAdd({
  required String reportId,
  required String symptomId,
  required String symptomName,
  required String recommendType,
}) async {
  final parsedReportId = int.tryParse(reportId.trim());
  final parsedSymptomId = int.tryParse(symptomId.trim());
  if (parsedReportId == null || parsedSymptomId == null) {
    return;
  }
  await ReportRemoteSource(getIt<DioClient>()).addReportSymptom(
    reportId: parsedReportId,
    symptomId: parsedSymptomId,
    symptomName: symptomName,
    recommendType: recommendType,
  );
}

Future<void> _persistReportSymptomDelete({
  required String reportId,
  required String symptomId,
  required String recommendType,
}) async {
  final parsedReportId = int.tryParse(reportId.trim());
  final parsedSymptomId = int.tryParse(symptomId.trim());
  if (parsedReportId == null || parsedSymptomId == null) {
    return;
  }
  await ReportRemoteSource(getIt<DioClient>()).deleteReportSymptom(
    reportId: parsedReportId,
    symptomId: parsedSymptomId,
    recommendType: recommendType,
  );
}

class ReportPage extends StatelessWidget {
  const ReportPage({
    super.key,
    this.reportId,
    this.initialViewData,
    this.loadReportViewData,
    this.loadConsultNavigate,
    this.addReportSymptom,
    this.deleteReportSymptom,
    this.loadReportShareQrCode,
  });

  final String? reportId;
  final ReportViewData? initialViewData;
  final Future<ReportViewData> Function(String reportId)? loadReportViewData;
  final Future<DiagnosisMaNavigate?> Function(ReportViewData viewData)?
  loadConsultNavigate;
  final ReportAddSymptomAction? addReportSymptom;
  final ReportDeleteSymptomAction? deleteReportSymptom;
  final ReportShareQrCodeLoader? loadReportShareQrCode;

  @override
  Widget build(BuildContext context) {
    return ReportEntryResolver(
      reportId: reportId,
      initialViewData: initialViewData,
      loadReportViewData: loadReportViewData,
      loadConsultNavigate: loadConsultNavigate,
      buildReportScreen: (key, viewData) => _ReportScreen(
        key: key,
        viewData: viewData,
        loadReportShareQrCode:
            loadReportShareQrCode ??
            (reportId) => ReportRemoteSource(
              getIt<DioClient>(),
            ).getReportShareQrCode(reportId),
        addReportSymptom: addReportSymptom ?? _persistReportSymptomAdd,
        deleteReportSymptom: deleteReportSymptom ?? _persistReportSymptomDelete,
      ),
    );
  }
}
