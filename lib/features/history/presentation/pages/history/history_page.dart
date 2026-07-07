// 历史报告模块页面：`HistoryPage`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

import 'package:flutter/material.dart';
import 'package:millet_kyai_apps/features/history/presentation/pages/history/history_entry_resolver.dart';
import 'package:millet_kyai_apps/features/history/presentation/pages/history/history_record.dart';
import 'package:millet_kyai_apps/features/history/presentation/pages/history/history_screen.dart';

export 'history_record.dart';
export 'history_entry_resolver.dart'
    show HistoryRecordsPage, HistoryRecordsPageLoader;

class HistoryReportPage extends StatelessWidget {
  const HistoryReportPage({
    super.key,
    this.records = const <DiagnosisRecord>[],
    this.loadHistoryRecords,
    this.loadHistoryRecordsPage,
  });

  final List<DiagnosisRecord> records;
  final Future<List<DiagnosisRecord>> Function()? loadHistoryRecords;
  final HistoryRecordsPageLoader? loadHistoryRecordsPage;

  @override
  Widget build(BuildContext context) {
    return HistoryEntryResolver(
      initialRecords: records,
      loadHistoryRecords: loadHistoryRecords,
      loadHistoryRecordsPage: loadHistoryRecordsPage,
      buildHistoryScreen:
          (
            key,
            resolvedRecords, {
            required hasMore,
            required isLoadingMore,
            required onLoadMore,
          }) => HistoryReportScreen(
            key: key,
            records: resolvedRecords,
            hasMore: hasMore,
            isLoadingMore: isLoadingMore,
            onLoadMore: onLoadMore,
          ),
    );
  }
}
