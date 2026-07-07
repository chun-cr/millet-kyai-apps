part of '../report_page.dart';

class _ReportEnhancementSection extends StatelessWidget {
  const _ReportEnhancementSection({
    required this.isLoading,
    required this.reportId,
    required this.primaryConstitution,
    required this.isLive,
    required this.onSaveSelfDescription,
    required this.onLoadLockedStatus,
    required this.onLoadSurveyHistory,
    required this.onLoadChatResult,
    required this.onCreateDownloadToken,
  });

  final bool isLoading;
  final String? reportId;
  final String? primaryConstitution;
  final bool isLive;
  final VoidCallback onSaveSelfDescription;
  final VoidCallback onLoadLockedStatus;
  final VoidCallback onLoadSurveyHistory;
  final VoidCallback onLoadChatResult;
  final VoidCallback onCreateDownloadToken;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ReportEnhancementAction(
        icon: Icons.edit_note_rounded,
        title: '用户自述',
        eyebrow: '编辑',
        subtitle: '把用户主动补充的症状和诉求写入报告上下文。',
        badge: '可保存',
        color: const Color(0xFF4A7FA8),
        onTap: onSaveSelfDescription,
      ),
      _ReportEnhancementAction(
        icon: Icons.lock_open_rounded,
        title: '权益状态',
        eyebrow: '状态',
        subtitle: '读取 locked-status，确认报告当前锁定/解锁状态。',
        badge: '服务端',
        color: const Color(0xFFC9A84C),
        onTap: onLoadLockedStatus,
      ),
      _ReportEnhancementAction(
        icon: Icons.history_rounded,
        title: '历史版本',
        eyebrow: '记录',
        subtitle: '把历史报告从原始列表变成时间线。',
        badge: '可追溯',
        color: const Color(0xFF6B5B95),
        onTap: onLoadSurveyHistory,
      ),
      _ReportEnhancementAction(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'AI 问答结论',
        eyebrow: '摘要',
        subtitle: '读取 chat-result，并优先展示结论和关键字段。',
        badge: 'AI',
        color: const Color(0xFFB96A3A),
        onTap: onLoadChatResult,
      ),
      _ReportEnhancementAction(
        icon: Icons.file_download_outlined,
        title: '下载令牌',
        eyebrow: '分享',
        subtitle: '生成下载/分享 token，并提供复制入口。',
        badge: 'Token',
        color: const Color(0xFFD4794A),
        onTap: onCreateDownloadToken,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FloatingSectionTitle(
          title: '报告增强',
          accentColor: Color(0xFF4A7FA8),
        ),
        const SizedBox(height: 12),
        _ReportEnhancementHeader(
          reportId: reportId,
          primaryConstitution: primaryConstitution,
          isLive: isLive,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final spacing = constraints.maxWidth >= 560 ? 10.0 : 0.0;
            final tileWidth = constraints.maxWidth >= 560
                ? (constraints.maxWidth - spacing) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: spacing,
              runSpacing: 10,
              children: [
                for (var i = 0; i < actions.length; i++)
                  SizedBox(
                    width: tileWidth,
                    child: _ReportActionTile(
                      action: actions[i],
                      enabled: !isLoading,
                      index: i,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReportEnhancementHeader extends StatelessWidget {
  const _ReportEnhancementHeader({
    required this.reportId,
    required this.primaryConstitution,
    required this.isLive,
  });

  final String? reportId;
  final String? primaryConstitution;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF1F7F8), Color(0xFFFFF8EA)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF4A7FA8).withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF4A7FA8,
                          ).withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF4A7FA8),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '把接口能力变成可操作模块',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E1810),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '先在建议页内完成可视化承接，后续再逐个细化业务流。',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: const Color(
                              0xFF3A3028,
                            ).withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ReportMetaChip(
                    icon: Icons.tag_rounded,
                    label: '报告',
                    value: _nonEmpty(reportId) ?? '待识别',
                    color: const Color(0xFF4A7FA8),
                  ),
                  _ReportMetaChip(
                    icon: Icons.local_florist_outlined,
                    label: '体质',
                    value: _nonEmpty(primaryConstitution) ?? '未命中',
                    color: const Color(0xFF2D6A4F),
                  ),
                  _ReportMetaChip(
                    icon: Icons.cloud_done_outlined,
                    label: '数据',
                    value: isLive ? '实时报告' : '演示数据',
                    color: isLive
                        ? const Color(0xFF0D7A5A)
                        : const Color(0xFFC9A84C),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 220.ms)
        .slideY(begin: 0.04, duration: 220.ms, curve: Curves.easeOutCubic);
  }
}

class _ReportMetaChip extends StatelessWidget {
  const _ReportMetaChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label $value',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3A3028).withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportEnhancementAction {
  const _ReportEnhancementAction({
    required this.icon,
    required this.title,
    required this.eyebrow,
    required this.subtitle,
    required this.badge,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String eyebrow;
  final String subtitle;
  final String badge;
  final Color color;
  final VoidCallback onTap;
}

class _ReportActionTile extends StatelessWidget {
  const _ReportActionTile({
    required this.action,
    required this.enabled,
    required this.index,
  });

  final _ReportEnhancementAction action;
  final bool enabled;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = action.color;
    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? action.onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: enabled ? 0.14 : 0.07),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: enabled ? 0.055 : 0.025),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 116),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: enabled ? 0.1 : 0.04),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          action.icon,
                          size: 21,
                          color: color.withValues(alpha: enabled ? 0.96 : 0.36),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              action.eyebrow,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: color.withValues(alpha: 0.82),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              action.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E1810),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          action.badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    action.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: const Color(0xFF3A3028).withValues(alpha: 0.58),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        enabled ? '打开模块' : '处理中',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color.withValues(alpha: enabled ? 0.9 : 0.42),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: color.withValues(alpha: enabled ? 0.9 : 0.42),
                      ),
                      const Spacer(),
                      if (!enabled)
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color.withValues(alpha: 0.58),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return content
        .animate(delay: (index * 35).ms)
        .fadeIn(duration: 220.ms)
        .slideY(begin: 0.05, duration: 220.ms, curve: Curves.easeOutCubic);
  }
}
