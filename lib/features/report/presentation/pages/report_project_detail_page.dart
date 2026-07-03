// 报告模块页面：`ReportProjectDetailPage`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

import 'package:flutter/material.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/features/report/presentation/models/report_project_data.dart';

class ReportProjectDetailPage extends StatelessWidget {
  const ReportProjectDetailPage({super.key, required this.project});

  final ReportProjectData project;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.reportProjectDetailTitle),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(project.consultNote)));
            },
            style: FilledButton.styleFrom(
              backgroundColor: project.color,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              l10n.reportProjectDetailActionButton,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _ProjectDetailHero(project: project),
          const SizedBox(height: 16),
          _ProjectDetailCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProjectDetailHeader(
                  title: l10n.reportProjectDetailRecommendationTitle,
                  color: project.color,
                ),
                const SizedBox(height: 12),
                Text(
                  project.description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.7,
                    color: const Color(0xFF3A3028).withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ProjectDetailChip(
                      label: project.type,
                      color: project.color,
                    ),
                    _ProjectDetailChip(
                      label: project.tag,
                      color: project.color,
                    ),
                    _ProjectDetailChip(
                      label: l10n.reportProjectDetailReportLinked,
                      color: project.color,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ProjectDetailCard(
            child: Column(
              children: [
                _ProjectDetailRow(
                  title: l10n.reportProjectDetailDurationTitle,
                  body: project.durationNote,
                  color: project.color,
                  icon: Icons.schedule_outlined,
                ),
                const SizedBox(height: 14),
                _ProjectDetailRow(
                  title: l10n.reportProjectDetailServiceTitle,
                  body: project.serviceNote,
                  color: project.color,
                  icon: Icons.health_and_safety_outlined,
                ),
                const SizedBox(height: 14),
                _ProjectDetailRow(
                  title: l10n.reportProjectDetailConsultTitle,
                  body: project.consultNote,
                  color: project.color,
                  icon: Icons.support_agent_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectDetailHero extends StatelessWidget {
  const _ProjectDetailHero({required this.project});

  final ReportProjectData project;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            project.color.withValues(alpha: 0.06),
            project.color.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: project.color.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              l10n.reportProjectDetailHeroBadge,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: project.color,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(project.icon, color: project.color, size: 34),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1810),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      project.type,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: project.color.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      project.durationNote,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: project.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectDetailCard extends StatelessWidget {
  const _ProjectDetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _ProjectDetailHeader extends StatelessWidget {
  const _ProjectDetailHeader({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E1810),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectDetailChip extends StatelessWidget {
  const _ProjectDetailChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}

class _ProjectDetailRow extends StatelessWidget {
  const _ProjectDetailRow({
    required this.title,
    required this.body,
    required this.color,
    required this.icon,
  });

  final String title;
  final String body;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1810),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: const Color(0xFF3A3028).withValues(alpha: 0.66),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
