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
    this.initialViewData,
    required this.loadReportViewData,
    this.loadConsultNavigate,
    required this.buildReportScreen,
  });

  final String? reportId;
  final ReportViewData? initialViewData;
  final Future<ReportViewData> Function(String reportId)? loadReportViewData;
  final Future<DiagnosisMaNavigate?> Function(ReportViewData viewData)?
  loadConsultNavigate;
  final Widget Function(Key key, ReportViewData viewData) buildReportScreen;

  @override
  State<ReportEntryResolver> createState() => _ReportEntryResolverState();
}

class _ReportEntryResolverState extends State<ReportEntryResolver> {
  Future<ReportViewData>? _viewDataFuture;
  ReportViewData? _lastViewData;
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
    _lastViewData = _initialViewDataForCurrentReport();
    _viewDataFuture = _createViewDataFuture();
  }

  @override
  void didUpdateWidget(covariant ReportEntryResolver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reportId != widget.reportId ||
        oldWidget.initialViewData != widget.initialViewData ||
        oldWidget.loadReportViewData != widget.loadReportViewData ||
        oldWidget.loadConsultNavigate != widget.loadConsultNavigate) {
      _consultNavigate = null;
      _consultNavigateForReportId = null;
      _lastViewData = _initialViewDataForCurrentReport();
      _viewDataFuture = _createViewDataFuture();
    }
  }

  ReportViewData? _initialViewDataForCurrentReport() {
    final initialViewData = widget.initialViewData;
    if (initialViewData == null) {
      return null;
    }

    final reportId = _normalizedReportId;
    final initialReportId = initialViewData.reportId?.trim();
    if (reportId != null &&
        initialReportId != null &&
        initialReportId.isNotEmpty &&
        initialReportId != reportId) {
      return null;
    }
    return initialViewData;
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

  Widget _buildErrorState({Key? key, Object? error, VoidCallback? onRetry}) {
    final message = error == null ? '报告数据缺失，无法加载诊断报告。' : error.toString();
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EB),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            key: key ?? const ValueKey('report_error'),
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 44,
                color: Color(0xFFC06A3A),
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF3A3028).withValues(alpha: 0.76),
                  fontSize: 13,
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                FilledButton(
                  key: const ValueKey('report_retry_button'),
                  onPressed: onRetry,
                  child: Text(context.l10n.commonRetry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldKeepInitialQuestionData(ReportViewData liveViewData) {
    final currentViewData = _lastViewData;
    return currentViewData?.includeQuestions == true &&
        liveViewData.includeQuestions != true;
  }

  @override
  Widget build(BuildContext context) {
    final reportId = _normalizedReportId;
    if (reportId == null) {
      return _buildErrorState(
        key: const ValueKey('report_missing_report_id'),
        error: '报告ID缺失，无法加载诊断报告。',
      );
    }

    return FutureBuilder<ReportViewData>(
      future: _viewDataFuture,
      builder: (context, snapshot) {
        ReportViewData? viewData;
        if (snapshot.hasData) {
          final liveViewData = snapshot.requireData;
          if (_shouldKeepInitialQuestionData(liveViewData)) {
            viewData = _lastViewData;
          } else {
            _lastViewData = liveViewData;
            viewData = liveViewData;
          }
        } else {
          viewData = _lastViewData;
        }

        if (viewData == null &&
            snapshot.connectionState != ConnectionState.done) {
          return const ReportLoadingView();
        }

        if (viewData == null && (snapshot.hasError || !snapshot.hasData)) {
          return _buildErrorState(
            error: snapshot.error ?? '报告数据缺失，无法加载诊断报告。',
            onRetry: _retry,
          );
        }

        final resolvedViewData = viewData!.copyWith(
          consultNavigate: _consultNavigate,
        );
        _scheduleConsultNavigateLoad(resolvedViewData);

        return widget.buildReportScreen(
          const ValueKey('report_mode_live'),
          resolvedViewData,
        );
      },
    );
  }
}
