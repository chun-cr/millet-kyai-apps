// 历史报告模块页面：`HistoryEntryResolver`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:millet_kyai_apps/core/di/injector.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/core/network/dio_client.dart';
import 'package:millet_kyai_apps/features/history/presentation/pages/history/history_loading_view.dart';
import 'package:millet_kyai_apps/features/history/presentation/pages/history/history_record.dart';
import 'package:millet_kyai_apps/features/history/presentation/pages/history/history_style.dart';
import 'package:millet_kyai_apps/features/report/data/sources/report_remote_source.dart';
import 'package:millet_kyai_apps/features/scan/data/models/scan_session.dart';
import 'package:millet_kyai_apps/features/scan/presentation/utils/scan_upload_tenant_context.dart';

class HistoryRecordsPage {
  const HistoryRecordsPage({required this.records, required this.hasMore});

  final List<DiagnosisRecord> records;
  final bool hasMore;

  factory HistoryRecordsPage.single(List<DiagnosisRecord> records) =>
      HistoryRecordsPage(records: records, hasMore: false);
}

typedef HistoryRecordsPageLoader =
    Future<HistoryRecordsPage> Function({
      required int pageNo,
      required int pageSize,
    });

typedef HistoryScreenBuilder =
    Widget Function(
      Key key,
      List<DiagnosisRecord> records, {
      required bool hasMore,
      required bool isLoadingMore,
      required VoidCallback? onLoadMore,
    });

class HistoryEntryResolver extends StatefulWidget {
  const HistoryEntryResolver({
    super.key,
    required this.initialRecords,
    required this.loadHistoryRecords,
    required this.loadHistoryRecordsPage,
    required this.buildHistoryScreen,
  });

  final List<DiagnosisRecord> initialRecords;
  final Future<List<DiagnosisRecord>> Function()? loadHistoryRecords;
  final HistoryRecordsPageLoader? loadHistoryRecordsPage;
  final HistoryScreenBuilder buildHistoryScreen;

  @override
  State<HistoryEntryResolver> createState() => _HistoryEntryResolverState();
}

class _HistoryEntryResolverState extends State<HistoryEntryResolver> {
  static const int _defaultPageSize = 20;

  List<DiagnosisRecord> _records = const <DiagnosisRecord>[];
  final Set<String> _pendingFaceImageRecordIds = <String>{};
  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  Object? _loadError;
  int _nextPageNo = 1;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _resetStateAndLoad();
  }

  @override
  void didUpdateWidget(covariant HistoryEntryResolver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRecords != widget.initialRecords ||
        oldWidget.loadHistoryRecords != widget.loadHistoryRecords ||
        oldWidget.loadHistoryRecordsPage != widget.loadHistoryRecordsPage) {
      setState(_resetStateAndLoad);
    }
  }

  void _resetStateAndLoad() {
    _loadGeneration += 1;
    _pendingFaceImageRecordIds.clear();
    _isLoadingMore = false;
    _loadError = null;
    _nextPageNo = 1;

    if (widget.initialRecords.isNotEmpty) {
      _records = List<DiagnosisRecord>.from(widget.initialRecords);
      _isInitialLoading = false;
      _hasMore = false;
      return;
    }

    _records = const <DiagnosisRecord>[];
    _isInitialLoading = true;
    _hasMore = false;
    unawaited(_loadPage(pageNo: 1, append: false, generation: _loadGeneration));
  }

  Future<void> _loadPage({
    required int pageNo,
    required bool append,
    required int generation,
  }) async {
    try {
      final page = await _loadHistoryPage(pageNo);
      if (!mounted || generation != _loadGeneration) {
        return;
      }

      setState(() {
        _records = append
            ? _mergeRecords(_records, page.records)
            : page.records;
        _isInitialLoading = false;
        _isLoadingMore = false;
        _hasMore = page.hasMore;
        _loadError = null;
        _nextPageNo = pageNo + 1;
      });
      _scheduleFaceImageResolution(page.records, generation);
    } catch (error) {
      if (!mounted || generation != _loadGeneration) {
        return;
      }

      setState(() {
        _isInitialLoading = false;
        _isLoadingMore = false;
        if (!append) {
          _loadError = error;
        }
      });
    }
  }

  Future<HistoryRecordsPage> _loadHistoryPage(int pageNo) async {
    final pageLoader = widget.loadHistoryRecordsPage;
    if (pageLoader != null) {
      return pageLoader(pageNo: pageNo, pageSize: _defaultPageSize);
    }

    final recordsLoader = widget.loadHistoryRecords;
    if (recordsLoader != null) {
      if (pageNo > 1) {
        return const HistoryRecordsPage(
          records: <DiagnosisRecord>[],
          hasMore: false,
        );
      }
      final records = await recordsLoader();
      return HistoryRecordsPage.single(records);
    }

    return _defaultLoadHistoryPage(pageNo);
  }

  Future<HistoryRecordsPage> _defaultLoadHistoryPage(int pageNo) async {
    final tenantContext = await tryLoadScanUploadTenantContext(
      context,
      initializeIfEmpty: true,
    );
    final summariesPage = await ReportRemoteSource(getIt<DioClient>())
        .getReportsPage(
          source: ScanSession.reportSource,
          topOrgId: tenantContext.topOrgId,
          pageNo: pageNo,
          pageSize: _defaultPageSize,
          resolveFaceImages: false,
        );

    return HistoryRecordsPage(
      records: summariesPage.items.map(DiagnosisRecord.fromSummary).toList(),
      hasMore: summariesPage.hasMore,
    );
  }

  List<DiagnosisRecord> _mergeRecords(
    List<DiagnosisRecord> current,
    List<DiagnosisRecord> incoming,
  ) {
    final merged = List<DiagnosisRecord>.from(current);
    final indexById = <String, int>{
      for (var index = 0; index < merged.length; index++)
        merged[index].id: index,
    };

    for (final record in incoming) {
      final existingIndex = indexById[record.id];
      if (existingIndex != null) {
        merged[existingIndex] = record;
        continue;
      }
      indexById[record.id] = merged.length;
      merged.add(record);
    }
    return merged;
  }

  bool get _usesDefaultHistoryLoader =>
      widget.loadHistoryRecordsPage == null &&
      widget.loadHistoryRecords == null;

  void _scheduleFaceImageResolution(
    List<DiagnosisRecord> records,
    int generation,
  ) {
    if (!_usesDefaultHistoryLoader) {
      return;
    }

    final candidates = <DiagnosisRecord>[];
    for (final record in records) {
      final id = record.id.trim();
      if (id.isEmpty ||
          record.faceImageUrl.trim().isNotEmpty ||
          _pendingFaceImageRecordIds.contains(id)) {
        continue;
      }
      _pendingFaceImageRecordIds.add(id);
      candidates.add(record);
    }

    if (candidates.isEmpty) {
      return;
    }

    unawaited(_resolveFaceImages(candidates, generation));
  }

  Future<void> _resolveFaceImages(
    List<DiagnosisRecord> records,
    int generation,
  ) async {
    final resolvedRecordsById = <String, DiagnosisRecord>{};
    try {
      final tenantContext = await tryLoadScanUploadTenantContext(
        context,
        initializeIfEmpty: true,
      );
      final source = ReportRemoteSource(getIt<DioClient>());

      for (final record in records) {
        if (!mounted || generation != _loadGeneration) {
          return;
        }

        final id = record.id.trim();
        try {
          final detail = await source.getReportDetail(
            id,
            topOrgId: tenantContext.topOrgId,
          );
          final faceImageUrl = detail.faceAnalysisResult.imageUrl.trim();
          if (faceImageUrl.isEmpty) {
            continue;
          }
          resolvedRecordsById[id] = DiagnosisRecord.fromSummary(
            record.rawSummary.copyWith(faceImageUrl: faceImageUrl),
          );
        } catch (_) {
          // Missing preview images should never block the history list itself.
        }
      }
    } catch (_) {
      return;
    } finally {
      for (final record in records) {
        _pendingFaceImageRecordIds.remove(record.id.trim());
      }
    }

    if (!mounted ||
        generation != _loadGeneration ||
        resolvedRecordsById.isEmpty) {
      return;
    }

    setState(() {
      _records = _records
          .map((record) => resolvedRecordsById[record.id] ?? record)
          .toList(growable: false);
    });
  }

  void _retry() {
    setState(_resetStateAndLoad);
  }

  void _loadMore() {
    if (_isInitialLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    final pageNo = _nextPageNo;
    final generation = _loadGeneration;
    setState(() => _isLoadingMore = true);
    unawaited(_loadPage(pageNo: pageNo, append: true, generation: generation));
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const HistoryLoadingView();
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: historyPageBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              key: const ValueKey('history_error'),
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 44,
                  color: Color(0xFFC06A3A),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const ValueKey('history_retry_button'),
                  onPressed: _retry,
                  child: Text(context.l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.buildHistoryScreen(
      widget.initialRecords.isNotEmpty
          ? const ValueKey('history_records_provided')
          : const ValueKey('history_records_loaded'),
      _records,
      hasMore: _hasMore,
      isLoadingMore: _isLoadingMore,
      onLoadMore: _hasMore ? _loadMore : null,
    );
  }
}
