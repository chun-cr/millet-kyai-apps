import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:millet_kyai_apps/core/di/injector.dart';
import 'package:millet_kyai_apps/core/network/dio_client.dart';
import 'package:millet_kyai_apps/features/report/data/models/report_detail.dart';
import 'package:millet_kyai_apps/features/report/data/sources/report_remote_source.dart';
import 'package:millet_kyai_apps/features/report/presentation/pages/report/report_view_data.dart';
import 'package:millet_kyai_apps/features/scan/data/models/scan_session.dart';
import 'package:millet_kyai_apps/features/scan/presentation/utils/scan_upload_tenant_context.dart';
import 'package:millet_kyai_apps/features/share/presentation/providers/share_referral_provider.dart';

class HomeLatestReportData {
  const HomeLatestReportData({required this.summary, required this.detail});

  final DiagnosisReportSummary summary;
  final DiagnosisReportDetail detail;

  String get reportId =>
      detail.id.trim().isNotEmpty ? detail.id.trim() : summary.id.trim();

  ReportViewData get viewData => ReportViewData.fromDetail(detail);
}

final homeLatestReportSummaryProvider = FutureProvider<DiagnosisReportSummary?>(
  (ref) async {
    initInjector();
    final tenantContext = await _loadTenantContext(ref);
    return ReportRemoteSource(getIt<DioClient>()).getLatestReport(
      source: ScanSession.reportSource,
      topOrgId: tenantContext.topOrgId,
    );
  },
);

final homeLatestReportProvider = FutureProvider<HomeLatestReportData?>((
  ref,
) async {
  final summary = await ref.watch(homeLatestReportSummaryProvider.future);
  if (summary == null) {
    return null;
  }

  final reportId = summary.id.trim();
  if (reportId.isEmpty) {
    throw const FormatException('Latest report did not include a report id.');
  }
  initInjector();
  final tenantContext = await _loadTenantContext(ref);
  final detail = await ReportRemoteSource(
    getIt<DioClient>(),
  ).getReportDetail(reportId, topOrgId: tenantContext.topOrgId);
  return HomeLatestReportData(summary: summary, detail: detail);
});

Future<ScanUploadTenantContext> _loadTenantContext(Ref ref) async {
  try {
    var state = await ref.watch(shareReferralControllerProvider.future);
    var context = resolveScanUploadTenantContext(
      state.appIdMapping.isEmpty ? null : state.appIdMapping,
    );
    if (!context.isEmpty) {
      return context;
    }

    state = await ref
        .read(shareReferralControllerProvider.notifier)
        .initializeAfterAuth();
    context = resolveScanUploadTenantContext(
      state.appIdMapping.isEmpty ? null : state.appIdMapping,
    );
    return context;
  } on Object {
    return const ScanUploadTenantContext();
  }
}
