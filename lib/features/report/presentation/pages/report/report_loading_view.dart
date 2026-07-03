// 报告模块页面：`ReportLoadingView`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

import 'package:flutter/material.dart';
import 'package:millet_kyai_apps/core/widgets/app_skeleton.dart';

class ReportLoadingView extends StatelessWidget {
  const ReportLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EB),
      body: SafeArea(
        bottom: false,
        child: AppShimmer(
          child: KeyedSubtree(
            key: const ValueKey('report_loading'),
            child: CustomScrollView(
              physics: const NeverScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _ReportTopBarSkeleton(),
                        SizedBox(height: 18),
                        _ReportHeroSkeleton(),
                        SizedBox(height: 18),
                        _ReportTabBarSkeleton(),
                        SizedBox(height: 18),
                        _ReportSectionSkeleton(
                          titleWidth: 132,
                          cardHeight: 180,
                        ),
                        SizedBox(height: 18),
                        _ReportSectionSkeleton(
                          titleWidth: 148,
                          cardHeight: 240,
                        ),
                        SizedBox(height: 18),
                        _ReportSectionSkeleton(
                          titleWidth: 120,
                          cardHeight: 156,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportTopBarSkeleton extends StatelessWidget {
  const _ReportTopBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [SkeletonCircle(size: 44), Spacer(), SkeletonCircle(size: 44)],
    );
  }
}

class _ReportHeroSkeleton extends StatelessWidget {
  const _ReportHeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE7DBCC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLine(width: 170, height: 12),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 320;
              if (stacked) {
                return const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonCircle(size: 112),
                    SizedBox(height: 18),
                    _ReportHeroTextSkeleton(),
                  ],
                );
              }

              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonCircle(size: 112),
                  SizedBox(width: 18),
                  Expanded(child: _ReportHeroTextSkeleton()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReportHeroTextSkeleton extends StatelessWidget {
  const _ReportHeroTextSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonLine(width: 162, height: 30),
        SizedBox(height: 12),
        SkeletonLine(width: 124),
        SizedBox(height: 10),
        SkeletonLine(width: double.infinity),
        SizedBox(height: 8),
        SkeletonLine(width: double.infinity),
        SizedBox(height: 8),
        SkeletonLine(width: 176),
      ],
    );
  }
}

class _ReportTabBarSkeleton extends StatelessWidget {
  const _ReportTabBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EB),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x1A2D6A4F)),
      ),
      child: Row(
        children: const [
          Expanded(child: SkeletonLine(height: 14)),
          SizedBox(width: 12),
          Expanded(child: SkeletonLine(height: 14)),
          SizedBox(width: 12),
          Expanded(child: SkeletonLine(height: 14)),
          SizedBox(width: 12),
          Expanded(child: SkeletonLine(height: 14)),
        ],
      ),
    );
  }
}

class _ReportSectionSkeleton extends StatelessWidget {
  const _ReportSectionSkeleton({
    required this.titleWidth,
    required this.cardHeight,
  });

  final double titleWidth;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonLine(width: titleWidth, height: 18),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SkeletonBlock(
            height: cardHeight,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ],
    );
  }
}
