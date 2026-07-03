// 报告模块页面：`OverviewTab`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

part of '../report_page.dart';

class _Tab1Overview extends StatelessWidget {
  final ReportViewData viewData;
  final Animation<double> scoreAnim;
  final bool isUnlocked;
  final Future<void> Function() onUnlock;
  final ValueChanged<int> onNavigateToTab;
  final ReportAddSymptomAction addReportSymptom;
  final ReportDeleteSymptomAction deleteReportSymptom;

  const _Tab1Overview({
    required this.viewData,
    required this.scoreAnim,
    required this.isUnlocked,
    required this.onUnlock,
    required this.onNavigateToTab,
    required this.addReportSymptom,
    required this.deleteReportSymptom,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (viewData.hasRiskIndexes) {
      children.add(_buildRiskSection());
      children.add(const SizedBox(height: 16));
    }
    if (viewData.hasHealthRadar) {
      children.add(_buildHealthRadarSection());
      children.add(const SizedBox(height: 16));
    }
    if (viewData.hasTongueAnalysis) {
      children.add(_buildTongueAnalysisSection());
      children.add(const SizedBox(height: 16));
    }
    children.addAll([
      _buildModuleEntries(context),
      const SizedBox(height: 16),
      _buildScanMeta(context),
    ]);

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: children,
    );
  }

  Widget _buildRiskSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RiskIndexSectionBlock(
          riskIndexes: viewData.riskIndexes,
          scoreAnim: scoreAnim,
          consultNavigate: viewData.consultNavigate,
        ),
      ],
    );
  }

  Widget _buildHealthRadarSection() {
    return _HealthRadarSectionBlock(
      viewData: viewData,
      addReportSymptom: addReportSymptom,
      deleteReportSymptom: deleteReportSymptom,
    );
  }

  Widget _buildTongueAnalysisSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          key: const ValueKey('report_overview_tongue_analysis_section'),
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFC9A84C),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                '舌象解析',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1810),
                ),
              ),
            ],
          ),
        ),
        ...viewData.tongueAnalysisItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildTongueAnalysisCard(item),
          ),
        ),
      ],
    );
  }

  Widget _buildTongueAnalysisCard(ReportTongueAnalysisItemData item) {
    return Container(
      key: ValueKey('report_overview_tongue_analysis_${item.key}'),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8C8BA), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB14545).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1810),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFB14545).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '警惕',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB14545),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildTongueAnalysisRow(label: '正常值', value: '正常'),
          _buildTongueAnalysisRow(
            label: '检测结果',
            value: item.resultText,
            highlight: true,
          ),
          _buildTongueAnalysisRow(label: '病理解析', value: item.pathologyText),
        ],
      ),
    );
  }

  Widget _buildTongueAnalysisRow({
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE9DDD3).withValues(alpha: 0.9),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3028).withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight
                    ? const Color(0xFFB14545)
                    : const Color(0xFF3A3028),
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleEntries(BuildContext context) {
    final l10n = context.l10n;
    final entries = [
      (
        Icons.biotech_outlined,
        l10n.reportOverviewModuleConstitutionTitle,
        l10n.reportOverviewModuleConstitutionSubtitle,
        const Color(0xFF6B5B95),
        1,
      ),
      (
        Icons.spa_outlined,
        l10n.reportOverviewModuleAcupointTitle,
        l10n.reportOverviewModuleAcupointSubtitle,
        const Color(0xFF2D6A4F),
        2,
      ),
      (
        Icons.restaurant_outlined,
        l10n.reportOverviewModuleDietTitle,
        l10n.reportOverviewModuleDietSubtitle,
        const Color(0xFF0D7A5A),
        3,
      ),
      (
        Icons.wb_sunny_outlined,
        l10n.reportOverviewModuleSeasonalTitle,
        l10n.reportOverviewModuleSeasonalSubtitle,
        const Color(0xFFC9A84C),
        2,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 2),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFC9A84C),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.reportOverviewModuleNavTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1810),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.5,
          children: entries.map((e) {
            return GestureDetector(
              onTap: () {
                if (!isUnlocked) {
                  unawaited(onUnlock());
                  return;
                }
                onNavigateToTab(e.$5);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: e.$4.withValues(alpha: 0.14),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: e.$4.withValues(alpha: 0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: e.$4.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(e.$1, size: 18, color: e.$4),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            e.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1810),
                            ),
                          ),
                          Text(
                            e.$3,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(
                                0xFF3A3028,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: e.$4.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScanMeta(BuildContext context) {
    final l10n = context.l10n;
    final metaSegments = [
      if (viewData.recordedAt != null) _formatHeroDate(viewData.recordedAt),
      if (viewData.source != null) viewData.source!,
    ];
    final scanMeta = metaSegments.isEmpty
        ? l10n.reportOverviewScanMetaDisclaimer
        : '${metaSegments.join(' · ')} · ${l10n.reportOverviewScanMetaDisclaimer}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2D6A4F).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 15,
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              scanMeta,
              style: TextStyle(
                fontSize: 11,
                color: const Color(0xFF3A3028).withValues(alpha: 0.5),
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
