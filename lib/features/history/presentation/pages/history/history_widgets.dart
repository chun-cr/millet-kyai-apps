// 历史报告模块页面：`HistoryWidgets`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:millet_kyai_apps/core/l10n/formatters.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/core/router/app_router.dart';
import 'package:millet_kyai_apps/features/history/presentation/pages/history/history_record.dart';
import 'package:millet_kyai_apps/features/history/presentation/pages/history/history_style.dart';
import 'package:millet_kyai_apps/features/report/presentation/pages/report/report_view_data.dart';

class HistorySectionTitle extends StatelessWidget {
  const HistorySectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 2.5,
          height: 16,
          decoration: BoxDecoration(
            color: historyGold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: historyGold,
          ),
        ),
      ],
    );
  }
}

class HistoryChartSectionCard extends StatelessWidget {
  const HistoryChartSectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HistorySectionTitle(title: title),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: historyCardBg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}

class HistoryRecordCard extends StatelessWidget {
  const HistoryRecordCard({super.key, required this.record});

  final DiagnosisRecord record;

  void _openReport(BuildContext context) {
    context.push(
      Uri(
        path: AppRoutes.reportAnalysis,
        queryParameters: <String, String>{'reportId': record.id},
      ).toString(),
      extra: ReportViewData.fromSummary(record.rawSummary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openReport(context),
      child: Container(
        decoration: BoxDecoration(
          color: historyCardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    const Color(0xFFFFF4E7).withValues(alpha: 0.16),
                    BlendMode.softLight,
                  ),
                  child: record.faceImageUrl.isEmpty
                      ? Container(
                          color: const Color(0xFFF6F1E7),
                          child: const Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: historyTextHint,
                            ),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: record.faceImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFF6F1E7),
                            child: const Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: historyTextHint,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFF6F1E7),
                            child: const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: historyTextHint,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: historyGreenStart.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              record.constitutionLabel,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: historyGreenEnd,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${record.score}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: historyDanger,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      formatIsoLikeDate(context, record.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: historyTextHint,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          record.isUnlocked
                              ? context.l10n.statusUnlocked
                              : context.l10n.statusLocked,
                          style: TextStyle(
                            fontSize: 12,
                            color: historyTextHint.withValues(alpha: 0.9),
                          ),
                        ),
                        const Spacer(),
                        if (!record.isUnlocked)
                          GestureDetector(
                            onTap: () => _openReport(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: historyDanger,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                context.l10n.actionUnlockNow,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: historyDanger,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
