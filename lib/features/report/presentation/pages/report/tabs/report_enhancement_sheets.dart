part of '../report_page.dart';

Future<String?> _showLongTextEditorSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String hintText,
  required String actionLabel,
  required IconData icon,
  required Color color,
}) {
  return _showReportEnhancementSheet<String>(
    context,
    title: title,
    subtitle: subtitle,
    icon: icon,
    color: color,
    child: _LongTextEditorContent(
      hintText: hintText,
      actionLabel: actionLabel,
      color: color,
    ),
  );
}

Future<void> _showLockedStatusSheet(
  BuildContext context, {
  required Map<String, dynamic> payload,
}) {
  final status =
      _firstNonEmptyText(payload, const ['lockedStatus', 'status', 'state']) ??
      '未知状态';
  final isUnlocked =
      status.toLowerCase().contains('unlock') ||
      status.contains('已解锁') ||
      status == '0' ||
      status.toLowerCase() == 'false';

  return _showReportEnhancementSheet<void>(
    context,
    title: '权益状态',
    subtitle: '服务端 locked-status 已读取，下面展示关键状态和完整字段。',
    icon: isUnlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
    color: isUnlocked ? const Color(0xFF0D7A5A) : const Color(0xFFC9A84C),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusHeroCard(
          title: isUnlocked ? '报告当前可查看' : '报告可能仍受限',
          value: status,
          icon: isUnlocked
              ? Icons.verified_user_outlined
              : Icons.lock_clock_rounded,
          color: isUnlocked ? const Color(0xFF0D7A5A) : const Color(0xFFC9A84C),
        ),
        const SizedBox(height: 14),
        _ReportFactGrid(
          facts: _buildFacts(
            payload,
            excludeKeys: const {'lockedStatus', 'status', 'state'},
          ),
        ),
        _RawPayloadBlock(payload: payload),
      ],
    ),
  );
}

Future<void> _showSurveyHistorySheet(
  BuildContext context, {
  required List<DiagnosisReportSummary> history,
}) {
  return _showReportEnhancementSheet<void>(
    context,
    title: '历史版本',
    subtitle: '按检测时间整理历史报告，后续可继续接对比入口。',
    icon: Icons.history_rounded,
    color: const Color(0xFF6B5B95),
    child: history.isEmpty
        ? const _ReportEmptyVisual(
            title: '暂无历史报告',
            message: '当前 reportId 没有返回历史版本。',
          )
        : Column(
            children: [
              for (var i = 0; i < history.length; i++)
                _HistoryTimelineItem(
                  item: history[i],
                  isLast: i == history.length - 1,
                ),
            ],
          ),
  );
}

Future<void> _showChatResultSheet(
  BuildContext context, {
  required Map<String, dynamic> payload,
}) {
  final summary = _firstNonEmptyText(payload, const [
    'summary',
    'conclusion',
    'result',
    'answer',
    'content',
    'message',
    'text',
  ]);

  return _showReportEnhancementSheet<void>(
    context,
    title: 'AI 问答结论',
    subtitle: '优先展示可阅读结论，其他字段收进详情。',
    icon: Icons.chat_bubble_outline_rounded,
    color: const Color(0xFFB96A3A),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary == null)
          const _ReportEmptyVisual(
            title: '没有可直接展示的结论',
            message: '接口返回里暂未识别到 summary、conclusion、answer 等字段。',
          )
        else
          _NarrativeBlock(
            title: '结论摘要',
            body: summary,
            icon: Icons.psychology_alt_outlined,
            color: const Color(0xFFB96A3A),
          ),
        const SizedBox(height: 14),
        _ReportFactGrid(
          facts: _buildFacts(
            payload,
            excludeKeys: const {
              'summary',
              'conclusion',
              'result',
              'answer',
              'content',
              'message',
              'text',
            },
          ),
        ),
        _RawPayloadBlock(payload: payload),
      ],
    ),
  );
}

Future<void> _showDownloadTokenSheet(
  BuildContext context, {
  required Map<String, dynamic> payload,
}) {
  final token = _firstNonEmptyText(payload, const [
    'token',
    'downloadToken',
    'shareToken',
    'accessToken',
  ]);
  final url = _firstNonEmptyText(payload, const [
    'url',
    'downloadUrl',
    'shareUrl',
    'landingUrl',
  ]);

  return _showReportEnhancementSheet<void>(
    context,
    title: '下载令牌',
    subtitle: '下载/分享能力已生成，常用字段可直接复制。',
    icon: Icons.file_download_outlined,
    color: const Color(0xFFD4794A),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (token == null && url == null)
          const _ReportEmptyVisual(
            title: '没有识别到令牌字段',
            message: '接口返回存在，但暂未命中 token 或 url 类字段。',
          )
        else ...[
          if (token != null)
            _CopyValueCard(
              title: 'Token',
              value: token,
              color: const Color(0xFFD4794A),
            ),
          if (token != null && url != null) const SizedBox(height: 10),
          if (url != null)
            _CopyValueCard(
              title: '链接',
              value: url,
              color: const Color(0xFF4A7FA8),
            ),
        ],
        const SizedBox(height: 14),
        _ReportFactGrid(
          facts: _buildFacts(
            payload,
            excludeKeys: const {
              'token',
              'downloadToken',
              'shareToken',
              'accessToken',
              'url',
              'downloadUrl',
              'shareUrl',
              'landingUrl',
            },
          ),
        ),
        _RawPayloadBlock(payload: payload),
      ],
    ),
  );
}

Future<T?> _showReportEnhancementSheet<T>(
  BuildContext context, {
  required String title,
  required String subtitle,
  required IconData icon,
  required Color color,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _ReportSheetShell(
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
        child: child,
      );
    },
  );
}

class _ReportSheetShell extends StatelessWidget {
  const _ReportSheetShell({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final size = MediaQuery.sizeOf(context);

    return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 660,
                maxHeight: size.height * 0.9,
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F5EF),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 34,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A3028).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(icon, color: color, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E1810),
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.45,
                                    color: const Color(
                                      0xFF3A3028,
                                    ).withValues(alpha: 0.58),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                            color: const Color(
                              0xFF3A3028,
                            ).withValues(alpha: 0.72),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE8DED0)),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 160.ms)
        .slideY(begin: 0.04, duration: 200.ms, curve: Curves.easeOutCubic);
  }
}

class _LongTextEditorContent extends StatefulWidget {
  const _LongTextEditorContent({
    required this.hintText,
    required this.actionLabel,
    required this.color,
  });

  final String hintText;
  final String actionLabel;
  final Color color;

  @override
  State<_LongTextEditorContent> createState() => _LongTextEditorContentState();
}

class _LongTextEditorContentState extends State<_LongTextEditorContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _controller.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.color.withValues(alpha: 0.12)),
          ),
          child: TextField(
            controller: _controller,
            minLines: 5,
            maxLines: 8,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.newline,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Color(0xFF1E1810),
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                fontSize: 13,
                height: 1.55,
                color: const Color(0xFF3A3028).withValues(alpha: 0.38),
              ),
              border: InputBorder.none,
              isCollapsed: true,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                '内容会写回后端接口，当前页不强制刷新报告详情。',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.45,
                  color: const Color(0xFF3A3028).withValues(alpha: 0.48),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: canSubmit
                  ? () => Navigator.of(context).pop(_controller.text.trim())
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: widget.color,
                foregroundColor: Colors.white,
                disabledBackgroundColor: widget.color.withValues(alpha: 0.22),
                minimumSize: const Size(112, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(widget.actionLabel),
            ),
          ],
        ),
      ],
    );
  }
}
