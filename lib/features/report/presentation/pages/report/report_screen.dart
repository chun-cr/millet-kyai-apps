part of 'report_page.dart';

const _kReportMaskEnabled = false;
const _kReportTabBarHeight = 48.0;
const _kReportCompactWidthBreakpoint = 430.0;
const _kReportHeaderJoinRadius = 32.0;
const _kReportHeroBottomFillColor = Color(0xFFD7EADF);
// Keep the tab bar visually close to the disclaimer without starving tall hero content.
const _kHeroBottomPaddingCompact = 0.0;
const _kHeroBottomPaddingRegular = 0.0;
const _kHeroTopPaddingCompact = 50.0;
const _kHeroTopPaddingRegular = 58.0;
const _kHeroContentDisclaimerGapCompact = 2.0;
const _kHeroContentDisclaimerGapRegular = 4.0;
const _kHeroMeasurementSlackCompact = 12.0;
const _kHeroMeasurementSlackRegular = 16.0;
const _kHeroMinExpandedDeltaCompact = 8.0;
const _kHeroMinExpandedDeltaRegular = 18.0;

enum _ReportPhysiqueAnalysisStatus { demo, loading, loaded, empty, failed }

class _ReportPhysiqueAnalysisState {
  const _ReportPhysiqueAnalysisState._(this.status, [this.data]);

  const _ReportPhysiqueAnalysisState.demo()
    : this._(_ReportPhysiqueAnalysisStatus.demo);

  const _ReportPhysiqueAnalysisState.loading()
    : this._(_ReportPhysiqueAnalysisStatus.loading);

  const _ReportPhysiqueAnalysisState.loaded(ReportPhysiqueAnalysisData data)
    : this._(_ReportPhysiqueAnalysisStatus.loaded, data);

  const _ReportPhysiqueAnalysisState.empty()
    : this._(_ReportPhysiqueAnalysisStatus.empty);

  const _ReportPhysiqueAnalysisState.failed()
    : this._(_ReportPhysiqueAnalysisStatus.failed);

  final _ReportPhysiqueAnalysisStatus status;
  final ReportPhysiqueAnalysisData? data;
}

class _ReportScreen extends StatefulWidget {
  const _ReportScreen({
    super.key,
    required this.viewData,
    required this.loadReportShareQrCode,
    required this.addReportSymptom,
    required this.deleteReportSymptom,
  });

  final ReportViewData viewData;
  final ReportShareQrCodeLoader loadReportShareQrCode;
  final ReportAddSymptomAction addReportSymptom;
  final ReportDeleteSymptomAction deleteReportSymptom;

  @override
  State<_ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<_ReportScreen>
    with TickerProviderStateMixin {
  static const _tabColors = <Color>[
    Color(0xFF2D6A4F),
    Color(0xFF6B5B95),
    Color(0xFFC9A84C),
    Color(0xFF0D7A5A),
  ];

  late TabController _tabController;
  late AnimationController _heroScoreCtrl;
  late Animation<double> _heroScoreAnim;
  Timer? _heroScoreTimer;
  ReportUnlockService? _reportUnlockService;
  Future<ReportPhysiqueAnalysisData?>? _physiqueAnalysisFuture;
  String? _physiqueAnalysisSignature;

  int _currentTab = 0;
  final Set<int> _visitedTabs = <int>{0};
  bool _isUnlocked = !_kReportMaskEnabled;
  bool _shareLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this)
      ..addListener(_handleTabChanged);

    _heroScoreCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _heroScoreAnim = CurvedAnimation(
      parent: _heroScoreCtrl,
      curve: Curves.easeOutCubic,
    );
    _heroScoreTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        _heroScoreCtrl.forward();
      }
    });

    if (_kReportMaskEnabled) {
      _reportUnlockService = ReportUnlockService();
      _reportUnlockService!.state.addListener(_handleUnlockStateChanged);
      _initializeUnlockState();
    }
    _syncPhysiqueAnalysisFuture();
  }

  Future<void> _initializeUnlockState() async {
    await _reportUnlockService?.initialize();
  }

  void _handleTabChanged() {
    final nextTab = _tabController.index;
    if (_currentTab == nextTab && _visitedTabs.contains(nextTab)) {
      return;
    }
    setState(() {
      _currentTab = nextTab;
      _visitedTabs.add(nextTab);
    });
  }

  void _handleUnlockStateChanged() {
    if (!mounted) {
      return;
    }
    final next = _reportUnlockService?.state.value;
    if (next == null) {
      return;
    }
    setState(() {
      _isUnlocked = next.isUnlocked;
    });
  }

  @override
  void didUpdateWidget(covariant _ReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewData != widget.viewData) {
      _syncPhysiqueAnalysisFuture();
    }
  }

  @override
  void dispose() {
    _heroScoreTimer?.cancel();
    final reportUnlockService = _reportUnlockService;
    if (reportUnlockService != null) {
      reportUnlockService.state.removeListener(_handleUnlockStateChanged);
      unawaited(reportUnlockService.dispose());
    }
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _heroScoreCtrl.dispose();
    super.dispose();
  }

  Future<void> _handlePurchase() async {
    await _reportUnlockService?.purchase();
  }

  Future<void> _handleRestore() async {
    await _reportUnlockService?.restore();
  }

  Future<void> _handleUnlock() async {
    final reportUnlockService = _reportUnlockService;
    if (!_kReportMaskEnabled || reportUnlockService == null) {
      return;
    }
    await _showReportUnlockSheet(
      context,
      unlockStateListenable: reportUnlockService.state,
      onPurchase: _handlePurchase,
      onRestore: _handleRestore,
    );
  }

  void _handleBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    final container = ProviderScope.containerOf(context, listen: false);
    container
      ..invalidate(homeLatestReportSummaryProvider)
      ..invalidate(homeLatestReportProvider);
    context.go(AppRoutes.home);
  }

  void _navigateToTab(int index) {
    if (_tabController.index == index) {
      return;
    }
    _tabController.animateTo(index);
  }

  Future<void> _handleShare() async {
    if (_shareLoading) {
      return;
    }

    final reportId = widget.viewData.reportId?.trim() ?? '';
    if (reportId.isEmpty) {
      _showReportShareToast(
        _reportShareMissingIdMessage(context),
        kind: AppToastKind.info,
      );
      return;
    }

    _shareLoading = true;
    try {
      final shareQrCode = await widget.loadReportShareQrCode(reportId);
      if (!mounted) {
        return;
      }
      if (!shareQrCode.hasDisplayableImage &&
          shareQrCode.copyValue.trim().isEmpty) {
        _showReportShareToast(
          _reportShareEmptyMessage(context),
          kind: AppToastKind.info,
        );
      } else {
        await _showReportShareDialog(context, shareQrCode);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showReportShareToast(_reportShareFailedMessage(context));
    } finally {
      _shareLoading = false;
    }
  }

  void _showReportShareToast(
    String message, {
    AppToastKind kind = AppToastKind.error,
  }) {
    showAppToast(context, message, kind: kind);
  }

  double _heroExpandedHeight(BuildContext context) =>
      _estimateHeroExpandedHeight(context, widget.viewData);

  void _syncPhysiqueAnalysisFuture() {
    final signature = _physiqueAnalysisQuerySignature(widget.viewData);
    if (signature == null) {
      _physiqueAnalysisFuture = null;
      _physiqueAnalysisSignature = null;
      return;
    }
    if (_physiqueAnalysisSignature == signature) {
      return;
    }
    _physiqueAnalysisSignature = signature;
    _physiqueAnalysisFuture = _loadPhysiqueAnalysis(widget.viewData);
  }

  String? _physiqueAnalysisQuerySignature(ReportViewData viewData) {
    if (!viewData.isLive) {
      return null;
    }
    final physiqueId = _dominantPhysiqueId(viewData);
    if (physiqueId == null) {
      return null;
    }
    return [
      viewData.reportId?.trim() ?? '',
      viewData.token?.trim() ?? '',
      physiqueId.toString(),
    ].join('|');
  }

  Future<ReportPhysiqueAnalysisData?> _loadPhysiqueAnalysis(
    ReportViewData viewData,
  ) async {
    final physiqueId = _dominantPhysiqueId(viewData);
    if (physiqueId == null) {
      return null;
    }
    final payload = await ReportRemoteSource(
      getIt<DioClient>(),
    ).getPhysiqueAnalysis(physiqueId);
    if (payload == null) {
      return null;
    }
    final analysis = ReportPhysiqueAnalysisData.fromJson(payload);
    return analysis.hasDisplayableContent ? analysis : null;
  }

  _ReportPhysiqueAnalysisState _resolvePhysiqueAnalysisState(
    AsyncSnapshot<ReportPhysiqueAnalysisData?> snapshot,
  ) {
    if (!widget.viewData.isLive) {
      return const _ReportPhysiqueAnalysisState.demo();
    }
    if (_physiqueAnalysisFuture == null) {
      return const _ReportPhysiqueAnalysisState.empty();
    }
    if (snapshot.connectionState != ConnectionState.done) {
      return const _ReportPhysiqueAnalysisState.loading();
    }
    if (snapshot.hasError) {
      return const _ReportPhysiqueAnalysisState.failed();
    }
    final data = snapshot.data;
    if (data == null || !data.hasDisplayableContent) {
      return const _ReportPhysiqueAnalysisState.empty();
    }
    return _ReportPhysiqueAnalysisState.loaded(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EB),
      body: NestedScrollView(
        physics: const ClampingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverHeader(innerBoxIsScrolled),
          _buildTabBarHeader(),
        ],
        body: FutureBuilder<ReportPhysiqueAnalysisData?>(
          future: _physiqueAnalysisFuture,
          builder: (context, snapshot) {
            final physiqueAnalysisState = _resolvePhysiqueAnalysisState(
              snapshot,
            );
            return TabBarView(
              controller: _tabController,
              children: [
                _Tab1Overview(
                  viewData: widget.viewData,
                  scoreAnim: _heroScoreAnim,
                  isUnlocked: _isUnlocked,
                  onUnlock: _handleUnlock,
                  onNavigateToTab: _navigateToTab,
                  addReportSymptom: widget.addReportSymptom,
                  deleteReportSymptom: widget.deleteReportSymptom,
                ),
                _Tab2Constitution(
                  viewData: widget.viewData,
                  physiqueAnalysisState: physiqueAnalysisState,
                  isUnlocked: _isUnlocked,
                  onUnlock: _handleUnlock,
                ),
                _Tab3Therapy(
                  viewData: widget.viewData,
                  physiqueAnalysisState: physiqueAnalysisState,
                  isUnlocked: _isUnlocked,
                  onUnlock: _handleUnlock,
                ),
                _Tab4Advice(
                  viewData: widget.viewData,
                  physiqueAnalysisState: physiqueAnalysisState,
                  isUnlocked: _isUnlocked,
                  onUnlock: _handleUnlock,
                  shouldLoadRecommendations: _visitedTabs.contains(3),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverHeader(bool _) {
    final heroExpandedHeight = _heroExpandedHeight(context);

    return SliverAppBar(
      expandedHeight: heroExpandedHeight,
      pinned: true,
      centerTitle: true,
      titleSpacing: 0,
      title: _ReportHeaderTitle(viewData: widget.viewData),
      backgroundColor: const Color(0xFFF4F1EB),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: _HeroChromeButton(
          key: const ValueKey('report_back_button'),
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: _handleBack,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _HeroChromeButton(
            key: const ValueKey('report_share_button'),
            icon: Icons.share_outlined,
            onTap: _handleShare,
          ),
        ),
      ],
      flexibleSpace: _ReportHeroSpace(
        viewData: widget.viewData,
        scoreAnim: _heroScoreAnim,
        expandedHeight: heroExpandedHeight,
      ),
    );
  }

  Widget _buildTabBarHeader() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _ReportTabBarHeaderDelegate(
        height: _kReportTabBarHeight,
        child: _buildTabBar(),
      ),
    );
  }

  Widget _buildTabBar() {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final isScrollableTabs = languageCode != 'zh';
    final tabs = [
      l10n.reportTabOverview,
      l10n.reportTabConstitution,
      l10n.reportTabTherapy,
      l10n.reportTabAdvice,
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(color: _kReportHeroBottomFillColor),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Color(0xFFF4F1EB),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(_kReportHeaderJoinRadius),
              topRight: Radius.circular(_kReportHeaderJoinRadius),
            ),
            border: Border(
              bottom: BorderSide(color: Color(0x1A2D6A4F), width: 1),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: isScrollableTabs,
            labelPadding: isScrollableTabs
                ? const EdgeInsets.symmetric(horizontal: 14)
                : const EdgeInsets.symmetric(horizontal: 10),
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            labelColor: _tabColors[_currentTab],
            unselectedLabelColor: const Color(0xFFA09080),
            indicatorColor: _tabColors[_currentTab],
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            tabs: List.generate(
              tabs.length,
              (i) => Tab(
                height: 46,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_currentTab == i)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _tabColors[i],
                        ),
                      ),
                    Flexible(
                      child: Text(
                        tabs[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
