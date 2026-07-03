// 报告模块页面：`ReportEntryResolver`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:millet_kyai_apps/core/di/injector.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/core/network/dio_client.dart';
import 'package:millet_kyai_apps/features/report/data/models/report_detail.dart';
import 'package:millet_kyai_apps/features/report/data/sources/report_remote_source.dart';
import 'package:millet_kyai_apps/features/report/presentation/pages/report/report_loading_view.dart';
import 'package:millet_kyai_apps/features/report/presentation/pages/report/report_view_data.dart';
import 'package:millet_kyai_apps/features/scan/presentation/utils/scan_upload_tenant_context.dart';

class ReportEntryResolver extends StatefulWidget {
  const ReportEntryResolver({
    super.key,
    required this.reportId,
    required this.loadReportViewData,
    this.loadConsultNavigate,
    required this.buildReportScreen,
  });

  final String? reportId;
  final Future<ReportViewData> Function(String reportId)? loadReportViewData;
  final Future<DiagnosisMaNavigate?> Function(ReportViewData viewData)?
  loadConsultNavigate;
  final Widget Function(Key key, ReportViewData viewData) buildReportScreen;

  @override
  State<ReportEntryResolver> createState() => _ReportEntryResolverState();
}

class _ReportEntryResolverState extends State<ReportEntryResolver> {
  Future<ReportViewData>? _viewDataFuture;
  DiagnosisMaNavigate? _consultNavigate;
  String? _consultNavigateForReportId;

  String? get _normalizedReportId {
    final value = widget.reportId?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  @override
  void initState() {
    super.initState();
    _viewDataFuture = _createViewDataFuture();
  }

  @override
  void didUpdateWidget(covariant ReportEntryResolver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reportId != widget.reportId ||
        oldWidget.loadReportViewData != widget.loadReportViewData ||
        oldWidget.loadConsultNavigate != widget.loadConsultNavigate) {
      _consultNavigate = null;
      _consultNavigateForReportId = null;
      _viewDataFuture = _createViewDataFuture();
    }
  }

  Future<ReportViewData>? _createViewDataFuture() {
    final reportId = _normalizedReportId;
    if (reportId == null) {
      return null;
    }
    return _loadLiveViewData(reportId);
  }

  Future<ReportViewData> _loadLiveViewData(String reportId) async {
    final loader = widget.loadReportViewData ?? _defaultLoadReportViewData;
    return loader(reportId);
  }

  Future<ReportViewData> _defaultLoadReportViewData(String reportId) async {
    final tenantContext = await tryLoadScanUploadTenantContext(
      context,
      initializeIfEmpty: true,
    );
    final source = ReportRemoteSource(getIt<DioClient>());
    final detail = await source.getReportDetail(
      reportId,
      topOrgId: tenantContext.topOrgId,
    );
    return ReportViewData.fromDetail(detail);
  }

  bool get _shouldLoadConsultNavigate => widget.loadConsultNavigate != null;

  void _scheduleConsultNavigateLoad(ReportViewData viewData) {
    if (!_shouldLoadConsultNavigate ||
        viewData.consultNavigate != null ||
        viewData.reportId == null ||
        _consultNavigateForReportId == viewData.reportId) {
      return;
    }

    _consultNavigateForReportId = viewData.reportId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _consultNavigateForReportId != viewData.reportId) {
        return;
      }
      unawaited(_loadConsultNavigate(viewData));
    });
  }

  Future<void> _loadConsultNavigate(ReportViewData viewData) async {
    final loader = widget.loadConsultNavigate;
    if (loader == null) {
      return;
    }
    DiagnosisMaNavigate? consultNavigate;
    try {
      consultNavigate = await loader(viewData);
    } catch (_) {
      return;
    }
    if (!mounted || _consultNavigateForReportId != viewData.reportId) {
      return;
    }
    if (consultNavigate == null) {
      return;
    }

    setState(() {
      _consultNavigate = consultNavigate;
    });
  }

  void _retry() {
    setState(() {
      _consultNavigate = null;
      _consultNavigateForReportId = null;
      _viewDataFuture = _createViewDataFuture();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportId = _normalizedReportId;
    if (reportId == null) {
      return widget.buildReportScreen(
        const ValueKey('report_mode_demo'),
        ReportViewData.demo(),
      );
    }

    return FutureBuilder<ReportViewData>(
      future: _viewDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const ReportLoadingView();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: const Color(0xFFF4F1EB),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  key: const ValueKey('report_error'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 44,
                      color: Color(0xFFC06A3A),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      key: const ValueKey('report_retry_button'),
                      onPressed: _retry,
                      child: Text(context.l10n.commonRetry),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final viewData = snapshot.requireData.copyWith(
          consultNavigate: _consultNavigate,
        );
        _scheduleConsultNavigateLoad(viewData);

        return widget.buildReportScreen(
          const ValueKey('report_mode_live'),
          viewData,
        );
      },
    );
  }
}
