// 历史报告模块页面：`HistoryLoadingView`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

import 'package:flutter/material.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/core/widgets/app_skeleton.dart';
import 'package:millet_kyai_apps/features/history/presentation/pages/history/history_style.dart';

class HistoryLoadingView extends StatelessWidget {
  const HistoryLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: historyPageBg,
      appBar: AppBar(
        backgroundColor: historyPageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.historyReportTitle,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: historyTextPrimary,
            letterSpacing: 0.4,
          ),
        ),
        actions: [
          IconButton(
            onPressed: null,
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: historyTextPrimary,
            ),
          ),
        ],
      ),
      body: AppShimmer(
        child: KeyedSubtree(
          key: const ValueKey('history_loading'),
          child: CustomScrollView(
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
                    const _HistoryLoadingSection(cardHeight: 236),
                    const SizedBox(height: 24),
                    const _HistoryLoadingSection(cardHeight: 236),
                    const SizedBox(height: 24),
                    const SkeletonLine(width: 132, height: 18),
                    const SizedBox(height: 12),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 278,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, index) => const _HistoryLoadingCard(),
                    childCount: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryLoadingSection extends StatelessWidget {
  const _HistoryLoadingSection({required this.cardHeight});

  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLine(width: 110, height: 16),
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
          child: SkeletonBlock(
            height: cardHeight,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }
}

class _HistoryLoadingCard extends StatelessWidget {
  const _HistoryLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBlock(height: 136, borderRadius: BorderRadius.circular(14)),
            const SizedBox(height: 12),
            const SkeletonLine(width: 92),
            const SizedBox(height: 10),
            const SkeletonLine(width: 58),
            const Spacer(),
            const SkeletonLine(width: 84),
            const SizedBox(height: 8),
            Row(
              children: const [
                SkeletonLine(width: 52),
                Spacer(),
                SkeletonLine(width: 72),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
