part of '../report_page.dart';

class _Tab4Advice extends StatefulWidget {
  final bool isUnlocked;
  final Future<void> Function() onUnlock;
  final ReportViewData viewData;

  const _Tab4Advice({
    required this.isUnlocked,
    required this.onUnlock,
    required this.viewData,
  });

  @override
  State<_Tab4Advice> createState() => _Tab4AdviceState();
}

class _Tab4AdviceState extends State<_Tab4Advice> {
  late Future<List<ReportProjectData>> _backendProjectsFuture;
  late Future<List<ReportProductData>> _backendProductsFuture;

  bool get _isUnlocked => widget.isUnlocked;
  Future<void> Function() get _onUnlock => widget.onUnlock;
  ReportViewData get _viewData => widget.viewData;

  @override
  void initState() {
    super.initState();
    _backendProjectsFuture = _loadBackendProjects();
    _backendProductsFuture = _loadBackendProducts();
  }

  @override
  void didUpdateWidget(covariant _Tab4Advice oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldReloadProjects =
        _projectQuerySignature(oldWidget.viewData) !=
        _projectQuerySignature(widget.viewData);
    final shouldReloadProducts =
        _productQuerySignature(oldWidget.viewData) !=
        _productQuerySignature(widget.viewData);
    if (!shouldReloadProjects && !shouldReloadProducts) {
      return;
    }

    setState(() {
      if (shouldReloadProjects) {
        _backendProjectsFuture = _loadBackendProjects();
      }
      if (shouldReloadProducts) {
        _backendProductsFuture = _loadBackendProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        _FloatingSectionTitle(title: l10n.reportAdviceDietTitle),
        const SizedBox(height: 10),
        _Lockable(
          isUnlocked: _isUnlocked,
          lockTitle: l10n.reportUnlockDietAdviceTitle,
          onUnlock: _onUnlock,
          child: _buildDietAdviceContent(context),
        ),
        const SizedBox(height: 16),
        _buildReportEnhancementPanel(context),
        const SizedBox(height: 16),
        _buildProjectRecommendations(context),
        const SizedBox(height: 16),
        _buildProductRecommendations(context),
      ],
    );
  }

  // ── 舌象详解 ─────────────────────────────────────────────────────
  // ignore: unused_element
  Widget _buildTongueAnalysisContent(BuildContext context) {
    final l10n = context.l10n;
    final features = [
      (
        l10n.reportAdviceTongueFeatureColor,
        l10n.reportAdviceTongueFeatureColorValue,
        l10n.reportAdviceTongueFeatureColorDesc,
        const Color(0xFF2D6A4F),
      ),
      (
        l10n.reportAdviceTongueFeatureShape,
        l10n.reportAdviceTongueFeatureShapeValue,
        l10n.reportAdviceTongueFeatureShapeDesc,
        const Color(0xFF6B5B95),
      ),
      (
        l10n.reportAdviceTongueFeatureCoatingColor,
        l10n.reportAdviceTongueFeatureCoatingColorValue,
        l10n.reportAdviceTongueFeatureCoatingColorDesc,
        const Color(0xFF4A7FA8),
      ),
      (
        l10n.reportAdviceTongueFeatureTexture,
        l10n.reportAdviceTongueFeatureTextureValue,
        l10n.reportAdviceTongueFeatureTextureDesc,
        const Color(0xFFC9A84C),
      ),
      (
        l10n.reportAdviceTongueFeatureTeethMarks,
        l10n.reportAdviceTongueFeatureTeethMarksValue,
        l10n.reportAdviceTongueFeatureTeethMarksDesc,
        const Color(0xFFD4794A),
      ),
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF0D7A5A).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF0D7A5A).withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4F7F1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.sentiment_satisfied_alt_outlined,
                        size: 40,
                        color: const Color(0xFF0D7A5A).withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.reportAdviceTongueScoreLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFA09080),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text(
                              '72',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0D7A5A),
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '/ 100',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(
                                  0xFF3A3028,
                                ).withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.reportAdviceTongueScoreSummary,
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(
                              0xFF3A3028,
                            ).withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: Text(
                      f.$1,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: f.$4,
                      ),
                    ),
                  ),
                  Text(
                    '|',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: f.$4.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    f.$2,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E1810),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '— ${f.$3}',
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF3A3028).withValues(alpha: 0.5),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 饮食建议 ─────────────────────────────────────────────────────
  Widget _buildDietAdviceContent(BuildContext context) {
    final l10n = context.l10n;
    final recommended = [
      (
        l10n.reportAdviceFoodShanyao,
        l10n.reportAdviceFoodShanyaoDesc,
        const Color(0xFF2D6A4F),
      ),
      (
        l10n.reportAdviceFoodYiyiren,
        l10n.reportAdviceFoodYiyirenDesc,
        const Color(0xFF0D7A5A),
      ),
      (
        l10n.reportAdviceFoodHongzao,
        l10n.reportAdviceFoodHongzaoDesc,
        const Color(0xFFD4794A),
      ),
      (
        l10n.reportAdviceFoodBiandou,
        l10n.reportAdviceFoodBiandouDesc,
        const Color(0xFF4A7FA8),
      ),
      (
        l10n.reportAdviceFoodDangshen,
        l10n.reportAdviceFoodDangshenDesc,
        const Color(0xFFC9A84C),
      ),
      (
        l10n.reportAdviceFoodFuling,
        l10n.reportAdviceFoodFulingDesc,
        const Color(0xFF6B5B95),
      ),
    ];

    final avoid = [
      l10n.reportAdviceAvoidColdFood,
      l10n.reportAdviceAvoidGreasy,
      l10n.reportAdviceAvoidSpicy,
      l10n.reportAdviceAvoidSweet,
      l10n.reportAdviceAvoidAlcohol,
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(
            l10n.reportAdviceDietIntro,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF3A3028).withValues(alpha: 0.55),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D6A4F),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                l10n.reportAdviceDietRecommendedTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1810),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recommended
                .map((r) => _FoodChip(name: r.$1, desc: r.$2, color: r.$3))
                .toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFB05A5A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                l10n.reportAdviceDietAvoidTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1810),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: avoid
                .map(
                  (a) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B6914).withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '·',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8B6914),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          a,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8B6914),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF3E0),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: const Color(0xFFC9A84C).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.restaurant,
                      size: 13,
                      color: Color(0xFFC9A84C),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.reportAdviceDietRecipeTitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8B6914),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  l10n.reportAdviceDietRecipeBody,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF8B6914).withValues(alpha: 0.8),
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 产品推荐 ─────────────────────────────────────────────────────
  Widget _buildProjectRecommendations(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<List<ReportProjectData>>(
      future: _backendProjectsFuture,
      builder: (context, snapshot) {
        final backendProjects = snapshot.data ?? const <ReportProjectData>[];
        final projects = backendProjects.isNotEmpty
            ? backendProjects
            : (_viewData.isLive
                  ? const <ReportProjectData>[]
                  : buildReportProjects(l10n));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FloatingSectionTitle(
              title: l10n.reportAdviceProjectsTitle,
              accentColor: const Color(0xFFB96A3A),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 10),
              child: Text(
                l10n.reportAdviceProjectsSubtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFFA09080).withValues(alpha: 0.8),
                ),
              ),
            ),
            if (projects.isEmpty)
              _buildAdviceEmptyState(
                message: l10n.reportAdviceProjectsEmpty,
                color: const Color(0xFFB96A3A),
              )
            else
              ...projects.map(
                (project) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ProjectCard(project: project),
                ),
              ),
            _buildAdviceDisclaimer(
              message: l10n.reportAdviceProjectsDisclaimer,
              color: const Color(0xFFB96A3A),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductRecommendations(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<List<ReportProductData>>(
      future: _backendProductsFuture,
      builder: (context, snapshot) {
        final backendProducts = snapshot.data ?? const <ReportProductData>[];
        final products = backendProducts.isNotEmpty
            ? backendProducts
            : (_viewData.isLive
                  ? const <ReportProductData>[]
                  : buildReportProducts(l10n));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FloatingSectionTitle(title: l10n.reportAdviceProductsTitle),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 10),
              child: Text(
                l10n.reportAdviceProductsSubtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFFA09080).withValues(alpha: 0.8),
                ),
              ),
            ),
            if (products.isEmpty)
              _buildAdviceEmptyState(
                message: l10n.reportAdviceProductsEmpty,
                color: const Color(0xFF2D6A4F),
              )
            else
              ...products.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ProductCard(product: p),
                ),
              ),
            _buildAdviceDisclaimer(
              message: l10n.reportAdviceProductsDisclaimer,
              color: const Color(0xFF2D6A4F),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdviceEmptyState({
    required String message,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.inbox_outlined, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: const Color(0xFF3A3028).withValues(alpha: 0.62),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceDisclaimer({
    required String message,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.08), width: 1),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 11,
          color: const Color(0xFF3A3028).withValues(alpha: 0.45),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildReportEnhancementPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FloatingSectionTitle(
          title: '报告增强',
          accentColor: Color(0xFF4A7FA8),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          borderColor: const Color(0xFF4A7FA8).withValues(alpha: 0.12),
          shadowColor: const Color(0xFF4A7FA8).withValues(alpha: 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '这些能力已接入后端接口，可在当前报告上下文中直接查看或保存。',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.55,
                  color: const Color(0xFF3A3028).withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: 12),
              _ReportActionTile(
                icon: Icons.edit_note_rounded,
                title: '保存用户自述',
                subtitle: '写入 self/description，补全报告编辑入口。',
                color: const Color(0xFF4A7FA8),
                enabled: !_reportActionLoading,
                onTap: _handleSaveSelfDescription,
              ),
              _ReportActionTile(
                icon: Icons.spa_outlined,
                title: '读取调理方案',
                subtitle: '按体质、年龄、性别动态加载 therapy 接口。',
                color: const Color(0xFF2D6A4F),
                enabled: !_reportActionLoading,
                onTap: _handleLoadTherapies,
              ),
              _ReportActionTile(
                icon: Icons.lock_open_rounded,
                title: '刷新锁定状态',
                subtitle: '调用 locked-status，确认服务端权益状态。',
                color: const Color(0xFFC9A84C),
                enabled: !_reportActionLoading,
                onTap: _handleLoadLockedStatus,
              ),
              _ReportActionTile(
                icon: Icons.history_rounded,
                title: '历史版本',
                subtitle: '查询当前 Survey report 历史版本。',
                color: const Color(0xFF6B5B95),
                enabled: !_reportActionLoading,
                onTap: _handleLoadSurveyHistory,
              ),
              _ReportActionTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'AI 问答结论',
                subtitle: '读取 chat-result 并展示返回摘要。',
                color: const Color(0xFF0D7A5A),
                enabled: !_reportActionLoading,
                onTap: _handleLoadChatResult,
              ),
              _ReportActionTile(
                icon: Icons.file_download_outlined,
                title: '生成下载令牌',
                subtitle: '创建下载/分享 token，便于后续落地页使用。',
                color: const Color(0xFFD4794A),
                enabled: !_reportActionLoading,
                onTap: _handleCreateDownloadToken,
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _reportActionLoading = false;

  int? get _numericReportId => int.tryParse(_viewData.reportId?.trim() ?? '');

  Future<void> _runReportAction(Future<void> Function() action) async {
    if (_reportActionLoading) {
      return;
    }
    setState(() => _reportActionLoading = true);
    try {
      await action();
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppToast(context, '接口调用失败，请稍后重试。', kind: AppToastKind.error);
    } finally {
      if (mounted) {
        setState(() => _reportActionLoading = false);
      }
    }
  }

  Future<void> _handleSaveSelfDescription() async {
    final reportId = _numericReportId;
    if (reportId == null) {
      showAppToast(context, '当前报告缺少数字 reportId，无法保存自述。');
      return;
    }

    final text = await _showTextInputDialog(
      title: '用户自述',
      hintText: '例如：最近睡眠偏浅、饭后胃胀，想重点调理脾胃。',
    );
    if (text == null) {
      return;
    }

    await _runReportAction(() async {
      await ReportRemoteSource(
        getIt<DioClient>(),
      ).saveReportSelfDescription(reportId: reportId, selfDescription: text);
      if (!mounted) {
        return;
      }
      showAppToast(context, '自述已保存。', kind: AppToastKind.success);
    });
  }

  Future<void> _handleLoadTherapies() async {
    await _runReportAction(() async {
      final therapies = await ReportRemoteSource(getIt<DioClient>())
          .getPhysiqueTherapies(
            token: _viewData.token,
            age: _viewData.age,
            sex: _viewData.sex,
            physiqueIds: _collectNumericIds(
              _viewData.constitutionScores.map((item) => item.id),
            ),
          );
      if (!mounted) {
        return;
      }
      await _showPayloadDialog(
        title: '调理方案',
        payload: {'therapies': therapies},
      );
    });
  }

  Future<void> _handleLoadLockedStatus() async {
    final reportId = _numericReportId;
    if (reportId == null) {
      showAppToast(context, '当前报告缺少数字 reportId，无法查询锁定状态。');
      return;
    }

    await _runReportAction(() async {
      final payload = await ReportRemoteSource(
        getIt<DioClient>(),
      ).getSurveyReportLockedStatus(reportId);
      if (!mounted) {
        return;
      }
      await _showPayloadDialog(title: '锁定状态', payload: payload);
    });
  }

  Future<void> _handleLoadSurveyHistory() async {
    final reportId = _numericReportId;
    if (reportId == null) {
      showAppToast(context, '当前报告缺少数字 reportId，无法查询历史版本。');
      return;
    }

    await _runReportAction(() async {
      final history = await ReportRemoteSource(
        getIt<DioClient>(),
      ).getSurveyReportHistory(reportId);
      if (!mounted) {
        return;
      }
      await _showPayloadDialog(
        title: '历史版本',
        payload: {
          'items': history
              .map(
                (item) => {
                  'id': item.id,
                  'testTime': item.testTime,
                  'healthScore': item.healthScore,
                  'physiqueName': item.physiqueName,
                  'lockedStatus': item.lockedStatus,
                },
              )
              .toList(growable: false),
        },
      );
    });
  }

  Future<void> _handleLoadChatResult() async {
    final reportId = _numericReportId;
    if (reportId == null) {
      showAppToast(context, '当前报告缺少数字 reportId，无法读取 AI 问答结论。');
      return;
    }

    await _runReportAction(() async {
      final payload = await ReportRemoteSource(
        getIt<DioClient>(),
      ).getSurveyReportChatResult(reportId);
      if (!mounted) {
        return;
      }
      await _showPayloadDialog(title: 'AI 问答结论', payload: payload);
    });
  }

  Future<void> _handleCreateDownloadToken() async {
    final reportId = _numericReportId;
    if (reportId == null) {
      showAppToast(context, '当前报告缺少数字 reportId，无法生成下载令牌。');
      return;
    }

    await _runReportAction(() async {
      final payload = await ReportRemoteSource(
        getIt<DioClient>(),
      ).createSurveyReportDownloadToken(reportId);
      if (!mounted) {
        return;
      }
      await _showPayloadDialog(title: '下载令牌', payload: payload);
    });
  }

  Future<String?> _showTextInputDialog({
    required String title,
    required String hintText,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(hintText: hintText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result == null || result.trim().isEmpty) {
      return null;
    }
    return result.trim();
  }

  Future<void> _showPayloadDialog({
    required String title,
    required Object payload,
  }) async {
    const encoder = JsonEncoder.withIndent('  ');
    final text = encoder.convert(payload);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          backgroundColor: const Color(0xFFF8F5EF),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 10, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E1810),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      text,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: Color(0xFF3A3028),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<ReportProjectData>> _loadBackendProjects() async {
    if (!_viewData.isLive) {
      return const <ReportProjectData>[];
    }

    try {
      final source = ReportRemoteSource(getIt<DioClient>());
      final rawProjects = await source.getPhysiqueProjects(
        token: _viewData.token,
        topOrgId: _viewData.tenantId,
        age: _viewData.age,
        sex: _viewData.sex,
        physiqueIds: _collectNumericIds(
          _viewData.constitutionScores.map((item) => item.id),
        ),
      );
      if (rawProjects.isEmpty) {
        return const <ReportProjectData>[];
      }
      return rawProjects
          .asMap()
          .entries
          .map(
            (entry) =>
                ReportProjectData.fromBackend(entry.value, index: entry.key),
          )
          .toList(growable: false);
    } catch (_) {
      return const <ReportProjectData>[];
    }
  }

  Future<List<ReportProductData>> _loadBackendProducts() async {
    try {
      final source = ReportRemoteSource(getIt<DioClient>());
      final rawProducts = await source.getPhysiqueProducts(
        token: _viewData.token,
        topOrgId: _viewData.tenantId,
        clinicId: _viewData.storeId,
        physiqueIds: _collectNumericIds(
          _viewData.constitutionScores.map((item) => item.id),
        ),
        symptomIds: _collectNumericIds([
          ..._viewData.healthRadarClassicSymptoms.map((item) => item.id),
          ..._viewData.healthRadarDeepSymptoms.map((item) => item.id),
        ]),
      );
      if (rawProducts.isEmpty) {
        return const <ReportProductData>[];
      }
      return rawProducts
          .asMap()
          .entries
          .map(
            (entry) =>
                ReportProductData.fromBackend(entry.value, index: entry.key),
          )
          .toList(growable: false);
    } catch (_) {
      return const <ReportProductData>[];
    }
  }

  String _projectQuerySignature(ReportViewData viewData) {
    return [
      viewData.reportId?.trim() ?? '',
      viewData.token?.trim() ?? '',
      viewData.tenantId?.trim() ?? '',
      viewData.age?.toString() ?? '',
      viewData.sex?.trim() ?? '',
      ...viewData.constitutionScores.map((item) => item.id.trim()),
    ].join('|');
  }

  String _productQuerySignature(ReportViewData viewData) {
    return [
      viewData.reportId?.trim() ?? '',
      viewData.token?.trim() ?? '',
      viewData.tenantId?.trim() ?? '',
      viewData.storeId?.trim() ?? '',
      ...viewData.constitutionScores.map((item) => item.id.trim()),
      ...viewData.healthRadarClassicSymptoms.map((item) => item.id.trim()),
      ...viewData.healthRadarDeepSymptoms.map((item) => item.id.trim()),
    ].join('|');
  }

  List<int> _collectNumericIds(Iterable<String> values) {
    final resolved = <int>[];
    for (final value in values) {
      final parsed = int.tryParse(value.trim());
      if (parsed == null || parsed <= 0 || resolved.contains(parsed)) {
        continue;
      }
      resolved.add(parsed);
    }
    return resolved;
  }
}

// ══════════════════════════════════════════════════════════════════
//  Shared Sub-widgets
// ══════════════════════════════════════════════════════════════════

/// 卡片容器
class _ReportActionTile extends StatelessWidget {
  const _ReportActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: enabled ? 0.055 : 0.025),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: color.withValues(alpha: enabled ? 0.92 : 0.35),
                  ),
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
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.45,
                          color: const Color(
                            0xFF3A3028,
                          ).withValues(alpha: 0.58),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: color.withValues(alpha: enabled ? 0.72 : 0.26),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
