import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:millet_kyai_apps/core/l10n/formatters.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/core/l10n/seasonal_context.dart';
import 'package:millet_kyai_apps/core/router/app_router.dart';
import 'package:millet_kyai_apps/features/history/presentation/pages/history/history_page.dart';
import 'package:millet_kyai_apps/features/profile/presentation/pages/profile_page.dart';

// ─── Design Tokens ────────────────────────────────────────────────
class AppColors {
  static const primary = Color(0xFF2D6A4F);
  static const primaryLight = Color(0xFF3D8A68);
  static const primaryMid = Color(0xFF0D7A5A);
  static const accent = Color(0xFF6B5B95);

  static const tcmGold = Color(0xFFC9A84C);
  static const tcmGoldLight = Color(0xFFFAF3E0);
  static const tcmGoldDark = Color(0xFF8B6914);

  static const softBg = Color(0xFFF4F1EB);
  static const cardBg = Color(0xFFFFFFFF);
  static const inputBg = Color(0xFFF9F7F2);

  static const textPrimary = Color(0xFF1E1810);
  static const textSecondary = Color(0xFF3A3028);
  static const textHint = Color(0xFFA09080);
  static const borderColor = Color(0x1A2D6A4F);

  // Hero 淡草本绿，顶浅底深
  static const heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFCFDFB), Color(0xFFEAF5EE), Color(0xFFD4E9DA)],
    stops: [0.0, 0.38, 1.0],
  );

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2F6B4F), Color(0xFF4FA276)],
  );
}

// ─── Entry Point ──────────────────────────────────────────────────
void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const _App());
}

class _App extends StatelessWidget {
  const _App();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.softBg,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      home: const MainShell(),
    );
  }
}

// ─── Main Shell ────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 3:
        return const ProfilePage();
      case 0:
      default:
        return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBg,
      body: _buildCurrentPage(),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 1) {
            context.push(AppRoutes.scan);
          } else if (i == 2) {
            context.push(AppRoutes.report);
          } else {
            setState(() => _currentIndex = i);
          }
        },
      ),
    );
  }
}

// ─── Bottom Navigation ─────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded),
    (Icons.document_scanner_outlined, Icons.document_scanner),
    (Icons.assignment_outlined, Icons.assignment_rounded),
    (Icons.person_outline, Icons.person_rounded),
  ];

  String _labelForIndex(BuildContext context, int index) {
    final l10n = context.l10n;
    switch (index) {
      case 0:
        return l10n.bottomNavHome;
      case 1:
        return l10n.bottomNavScan;
      case 2:
        return l10n.bottomNavReport;
      case 3:
        return l10n.bottomNavProfile;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.07),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: List.generate(_items.length, (i) {
              final selected = currentIndex == i;
              final label = _labelForIndex(context, i);

              // 中央 FAB 扫描按钮
              if (i == 1) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Transform.translate(
                      offset: const Offset(0, -10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2D6A4F), Color(0xFF5BB88A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF2D6A4F,
                                  ).withValues(alpha: 0.28),
                                  blurRadius: 16,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.document_scanner_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            selected ? _items[i].$2 : _items[i].$1,
                            key: ValueKey(selected),
                            size: 22,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: selected ? 14 : 0,
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Home Page ─────────────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _scoreController;
  late Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scoreAnim = CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOutCubic,
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _scoreController.forward();
    });
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _handleScanReveal() async {
    if (!mounted) return;
    await context.push(AppRoutes.scan);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -16),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.softBg,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _HomeBgPainter()),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildQuickScan(),
                          const SizedBox(height: 20),
                          _buildLastReport(),
                          const SizedBox(height: 20),
                          _buildFunctionGrid(),
                          const SizedBox(height: 20),
                          _buildHealthTips(),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sliver App Bar ──────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 228,
      pinned: true,
      backgroundColor: AppColors.softBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 14, top: 8, bottom: 8),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: AppColors.primary,
            size: 17,
          ),
        ),
      ],
      flexibleSpace: _HeroFlexibleSpace(
        collapsedHeader: const _CollapsedHeader(),
        greeting: _buildGreeting(),
        scoreRing: _buildScoreRing(),
      ),
    );
  }

  Widget _buildGreeting() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.person,
                size: 22,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeGreetingMorning(l10n.profileDisplayName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.homeGreetingQuestion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.homeStatusSummary(l10n.homeBalancedConstitution, 3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              Icons.eco_outlined,
              size: 12,
              color: AppColors.primaryMid.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                l10n.homeSuggestion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreRing() {
    return AnimatedBuilder(
      animation: _scoreAnim,
      builder: (context, child) =>
          _TcmConstitutionBadge(progress: _scoreAnim.value),
    );
  }

  // ── Quick Scan ──────────────────────────────────────────────────
  Widget _buildQuickScan() {
    final l10n = context.l10n;
    final scans = [
      (
        l10n.homeQuickScanFaceTitle,
        l10n.homeQuickScanFaceSub,
        const Color(0xFF2D6A4F),
        Icons.face_retouching_natural_outlined,
      ),
      (
        l10n.homeQuickScanTongueTitle,
        l10n.homeQuickScanTongueSub,
        const Color(0xFF0D7A5A),
        Icons.sentiment_satisfied_alt_outlined,
      ),
      (
        l10n.homeQuickScanPalmTitle,
        l10n.homeQuickScanPalmSub,
        const Color(0xFF6B5B95),
        Icons.back_hand_outlined,
      ),
    ];

    return _SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionIconBox(
                icon: Icons.visibility_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.homeQuickScanTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _TcmTag(label: l10n.homeQuickScanTag, color: AppColors.tcmGold),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(scans.length, (i) {
              final s = scans[i];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < scans.length - 1 ? 8 : 0),
                  child: _ScanEntryTile(
                    label: s.$1,
                    sub: s.$2,
                    color: s.$3,
                    icon: s.$4,
                    onTap: () {
                      if (i == 0) context.push(AppRoutes.scanFace);
                      if (i == 1) context.push(AppRoutes.scanTongue);
                      if (i == 2) context.push(AppRoutes.scanPalm);
                    },
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          _MorphingScanCTA(onMorphCompleted: _handleScanReveal),
        ],
      ),
    );
  }

  // ── Last Report ─────────────────────────────────────────────────
  Widget _buildLastReport() {
    return _LastReportCard();
  }

  // ── Function Grid ───────────────────────────────────────────────
  Widget _buildFunctionGrid() {
    final l10n = context.l10n;
    final items = [
      (
        Icons.biotech_outlined,
        l10n.homeFunctionConstitution,
        const Color(0xFFE8F5EE),
      ),
      (
        Icons.spa_outlined,
        l10n.homeFunctionMeridianTherapy,
        const Color(0xFFE4F7F1),
      ),
      (
        Icons.restaurant_menu_outlined,
        l10n.homeFunctionDietAdvice,
        const Color(0xFFFAF3E0),
      ),
      (
        Icons.self_improvement_outlined,
        l10n.homeFunctionMentalWellness,
        const Color(0xFFF0EDF8),
      ),
      (
        Icons.wb_sunny_outlined,
        l10n.homeFunctionSeasonalCare,
        const Color(0xFFFAEDE7),
      ),
      (
        Icons.history_outlined,
        l10n.homeFunctionHistory,
        const Color(0xFFF1EEE6),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.homeFunctionNavTitle),
        const SizedBox(height: 12),
        GridView.count(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: items
              .map(
                (item) => _FunctionCell(
                  icon: item.$1,
                  label: item.$2,
                  bgColor: item.$3,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  // ── Health Tips ─────────────────────────────────────────────────
  Widget _buildHealthTips() {
    final l10n = context.l10n;
    final seasonalTag = l10n.seasonalTagLabel(SeasonalContext.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionTitle(title: l10n.homeTodayCareTitle),
            const SizedBox(width: 8),
            Flexible(
              child: _TcmTag(label: seasonalTag, color: AppColors.tcmGold),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                l10n.homeTodayCareCount,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _HealthTipCard(
          tag: l10n.homeTipDietTag,
          wuxing: l10n.homeTipDietWuxing,
          wuxingColor: Color(0xFFD4A04A),
          tagColor: Color(0xFF0D7A5A),
          tip: l10n.homeTipDietBody,
          icon: Icons.restaurant_outlined,
        ),
        const SizedBox(height: 10),
        _HealthTipCard(
          tag: l10n.homeTipRoutineTag,
          wuxing: l10n.homeTipRoutineWuxing,
          wuxingColor: Color(0xFF4A7FA8),
          tagColor: Color(0xFF2D6A4F),
          tip: l10n.homeTipRoutineBody,
          icon: Icons.bedtime_outlined,
        ),
      ],
    );
  }
}

// ─── Hero Flexible Space ───────────────────────────────────────────
class _HeroFlexibleSpace extends StatelessWidget {
  final Widget collapsedHeader;
  final Widget greeting;
  final Widget scoreRing;

  const _HeroFlexibleSpace({
    required this.collapsedHeader,
    required this.greeting,
    required this.scoreRing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const expandedH = 228.0;
        final collapsedH = kToolbarHeight + MediaQuery.of(context).padding.top;

        // progress: 1.0 = 完全展开，0.0 = 完全收起
        final progress =
            ((constraints.maxHeight - collapsedH) / (expandedH - collapsedH))
                .clamp(0.0, 1.0);

        // ── 派生动画曲线 ──────────────────────────────────────────
        // Hero 整体：在 progress 0.3 到 1.0 区间淡入
        final heroOpacity = ((progress - 0.3) / 0.7).clamp(0.0, 1.0);

        // greeting 向上飞出：progress 0 到 0.5 区间，向下偏移 12px
        final greetingSlide = (1.0 - (progress / 0.5).clamp(0.0, 1.0)) * 12.0;
        final greetingOpacity = (progress / 0.6).clamp(0.0, 1.0);

        // scoreRing 轻微缩放 + 淡出：progress 0 到 0.6
        final ringScale = 0.88 + 0.12 * (progress / 0.6).clamp(0.0, 1.0);
        final ringOpacity = (progress / 0.6).clamp(0.0, 1.0);

        // 收起态标题：progress 0 到 0.3 淡入，从下方 6px 滑入
        final collapsedOpacity = ((0.3 - progress) / 0.3).clamp(0.0, 1.0);
        final collapsedSlide = (1.0 - collapsedOpacity) * 6.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            // 兜底背景色（始终存在）
            const ColoredBox(color: AppColors.softBg),

            // Hero 展开区域
            Opacity(
              opacity: heroOpacity,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.heroGradient,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _HeroBgPainter()),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 46, 22, 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // greeting：向上位移 + 淡入
                              Expanded(
                                child: Transform.translate(
                                  offset: Offset(0, greetingSlide),
                                  child: Opacity(
                                    opacity: greetingOpacity,
                                    child: SingleChildScrollView(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      child: greeting,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // scoreRing：缩放 + 淡入
                              Transform.scale(
                                scale: ringScale,
                                child: Opacity(
                                  opacity: ringOpacity,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: scoreRing,
                                  ),
                                ),
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

            // 收起态品牌标题：从下方滑入 + 淡入
            Positioned(
              left: 20,
              bottom: 14,
              child: Opacity(
                opacity: collapsedOpacity,
                child: Transform.translate(
                  offset: Offset(0, collapsedSlide),
                  child: collapsedHeader,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Hero Background Painter ──────────────────────────────────────
class _HeroBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * 0.85, -20),
      110,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35),
    );
    canvas.drawCircle(
      Offset(-20, size.height * 0.9),
      80,
      Paint()
        ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.07)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
    );
    final cx = size.width - 30.0;
    final cy = size.height * 0.52;
    const r = 62.0;
    final p = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), r, p);
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.82,
      p..color = const Color(0xFF2D6A4F).withValues(alpha: 0.055),
    );
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        Offset(cx + math.cos(a) * r * 0.82, cy + math.sin(a) * r * 0.82),
        Offset(cx + math.cos(a) * r, cy + math.sin(a) * r),
        Paint()
          ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.09)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Home Body Background Painter ─────────────────────────────────
class _HomeBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final g = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.02)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), g);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), g);
    }
    final seal = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(size.width - 14, 48), 44, seal);
    canvas.drawCircle(Offset(size.width - 14, 48), 34, seal);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Collapsed Header ─────────────────────────────────────────────
class _CollapsedHeader extends StatelessWidget {
  const _CollapsedHeader();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1D5E40), Color(0xFF3DAB78)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 1.2,
                  ),
                ),
              ),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          context.l10n.homeCollapsedTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// TCM Constitution Badge（浅色 Hero 版）
class _TcmConstitutionBadge extends StatelessWidget {
  final double progress;
  const _TcmConstitutionBadge({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(80, 80),
                  painter: _ScoreRingPainter(
                    progress: progress * 0.86,
                    trackColor: AppColors.primary.withValues(alpha: 0.12),
                    progressStart: const Color(0xFF2D6A4F),
                    progressEnd: const Color(0xFF7EC8A0),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(86 * progress).round()}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      context.l10n.homeHealthScoreLabel,
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.primaryMid,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Text(
              context.l10n.homeBalancedConstitution,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.homeBalanceState,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: AppColors.textHint.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Score Ring Painter ────────────────────────────────────────────
class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressStart;
  final Color progressEnd;

  const _ScoreRingPainter({
    required this.progress,
    this.trackColor = const Color(0x30FFFFFF),
    this.progressStart = const Color(0xFF7EC8A0),
    this.progressEnd = const Color(0xFFFFFFFF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const sw = 5.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..shader = LinearGradient(
          colors: [progressStart, progressEnd],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) => old.progress != progress;
}

class _MorphingScanCTA extends StatefulWidget {
  final Future<void> Function() onMorphCompleted;

  const _MorphingScanCTA({required this.onMorphCompleted});

  @override
  State<_MorphingScanCTA> createState() => _MorphingScanCTAState();
}

class _MorphingScanCTAState extends State<_MorphingScanCTA>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _pressed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _pressed = false;
    });

    HapticFeedback.lightImpact();

    try {
      await _controller.forward().orCancel;
      await widget.onMorphCompleted();
    } on TickerCanceled {
      return;
    } finally {
      if (mounted) {
        _controller.reset();
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _busy ? null : (_) => setState(() => _pressed = true),
      onTapUp: _busy ? null : (_) => setState(() => _pressed = false),
      onTapCancel: _busy ? null : () => setState(() => _pressed = false),
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _pressed && !_busy ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final morph = Curves.easeInOutCubic.transform(_controller.value);
            final textOpacity = (1 - (_controller.value * 1.8)).clamp(0.0, 1.0);
            final circleOpacity = ((_controller.value - 0.28) / 0.22).clamp(
              0.0,
              1.0,
            );
            final shadowFactor = _pressed && !_busy ? 0.58 : (1 - 0.35 * morph);

            return LayoutBuilder(
              builder: (context, constraints) {
                final fullWidth = constraints.maxWidth;
                final width = 48 + (fullWidth - 48) * (1 - morph);
                final radius = 14 + (24 - 14) * morph;

                return Center(
                  child: Container(
                    width: width,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        const Color(0xFF5F9878),
                        const Color(0xFFF4F1EB),
                        morph,
                      ),
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                        color:
                            Color.lerp(
                              Colors.transparent,
                              const Color(0xFFD8CFC0),
                              morph,
                            ) ??
                            Colors.transparent,
                        width: morph > 0.02 ? 1.2 : 0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color.lerp(
                            const Color(0xFF5F9878),
                            const Color(0xFFCFC3B1),
                            morph,
                          )!.withValues(alpha: 0.18 * shadowFactor),
                          blurRadius: 18 * shadowFactor,
                          spreadRadius: 0.5 * shadowFactor,
                          offset: Offset(0, 6 * shadowFactor),
                        ),
                        BoxShadow(
                          color: Color.lerp(
                            const Color(0xFFB9D8C4),
                            const Color(0xFFF7F1E6),
                            morph,
                          )!.withValues(alpha: 0.1 * shadowFactor),
                          blurRadius: 8 * shadowFactor,
                          offset: Offset(0, 1 * shadowFactor),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: textOpacity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_circle_outline,
                                color: Color(0xFFFDFCF8),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  context.l10n.homeStartFullScan,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFDFCF8),
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Opacity(
                          opacity: circleOpacity,
                          child: _XuanPaperCircle(progress: morph),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _XuanPaperCircle extends StatelessWidget {
  final double progress;

  const _XuanPaperCircle({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _XuanPaperCirclePainter(progress: progress)),
    );
  }
}

class _XuanPaperCirclePainter extends CustomPainter {
  final double progress;

  const _XuanPaperCirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFD8CFC0).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * ((progress - 0.25) / 0.75).clamp(0.0, 1.0),
      false,
      Paint()
        ..color = const Color(0xFFB8A78C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _XuanPaperCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ─── Scan Entry Tile ───────────────────────────────────────────────
class _ScanEntryTile extends StatefulWidget {
  final String label;
  final String sub;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ScanEntryTile({
    required this.label,
    required this.sub,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_ScanEntryTile> createState() => _ScanEntryTileState();
}

class _ScanEntryTileState extends State<_ScanEntryTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(widget.icon, size: 22, color: widget.color),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: widget.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.sub,
                style: TextStyle(
                  fontSize: 10,
                  color: widget.color.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Last Report Card（重构后：极简呼吸感）
class _LastReportCard extends StatelessWidget {
  const _LastReportCard();

  @override
  Widget build(BuildContext context) {
    final latestRecord = [...DiagnosisRecord.sampleRecords]
      ..sort((a, b) => b.date.compareTo(a.date));
    final record = latestRecord.first;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.history),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      formatShortDate(context, record.date),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.history),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 2,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '${context.l10n.commonViewAll} >',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    record.constitutionType.label(context),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Text(
                    context.l10n.homeLastReportInsight,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.76),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                decoration: BoxDecoration(
                  color: AppColors.inputBg.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 2,
                        decoration: BoxDecoration(
                          color: AppColors.tcmGold.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.l10n.homeLastReportSummary,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.75,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _CompactScore(
                    label: context.l10n.metricFaceDiagnosis,
                    score: 86,
                  ),
                  SizedBox(width: 18),
                  _CompactScore(
                    label: context.l10n.metricTongueDiagnosis,
                    score: 72,
                  ),
                  SizedBox(width: 18),
                  _CompactScore(
                    label: context.l10n.metricPalmDiagnosis,
                    score: 80,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 配合上述卡片的新组件：三栏横向细线评分
class _CompactScore extends StatelessWidget {
  final String label;
  final int score;

  const _CompactScore({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              width: double.infinity,
              height: 8,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EFE9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: score / 100,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: const [
                            Color(0xFFDCEEE1),
                            Color(0xFFAFD3BB),
                            Color(0xFF76AC88),
                          ],
                          stops: [0.0, 0.58, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF76AC88,
                            ).withValues(alpha: 0.14),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
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
}

// ─── Function Cell ─────────────────────────────────────────────────
class _FunctionCell extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  const _FunctionCell({
    required this.icon,
    required this.label,
    required this.bgColor,
  });
  @override
  State<_FunctionCell> createState() => _FunctionCellState();
}

class _FunctionCellState extends State<_FunctionCell> {
  bool _pressed = false;
  Color _darken(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.38).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _darken(widget.bgColor);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {},
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.bgColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(widget.icon, size: 21, color: iconColor),
              ),
              const SizedBox(height: 7),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Health Tip Card ───────────────────────────────────────────────
class _HealthTipCard extends StatelessWidget {
  final String tag;
  final String wuxing;
  final Color wuxingColor;
  final Color tagColor;
  final String tip;
  final IconData icon;

  const _HealthTipCard({
    required this.tag,
    required this.wuxing,
    required this.wuxingColor,
    required this.tagColor,
    required this.tip,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: tagColor.withValues(alpha: 0.028),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Column(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tagColor,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 72,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: tagColor.withValues(alpha: 0.16),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, size: 18, color: tagColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${context.l10n.commonFiveElements}·$wuxing',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: wuxingColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tip,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary.withValues(alpha: 0.92),
                        height: 1.72,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared Small Widgets ──────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.tcmGold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _TcmTag extends StatelessWidget {
  final String label;
  final Color color;
  const _TcmTag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color == AppColors.tcmGold
            ? AppColors.tcmGoldLight
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SectionIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _SectionIconBox({required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

class _SectionShell extends StatelessWidget {
  final Widget child;
  const _SectionShell({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.07),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ScoreBar extends StatefulWidget {
  final String label;
  final double score;
  final Color color;
  const _ScoreBar({
    required this.label,
    required this.score,
    required this.color,
  });
  @override
  State<_ScoreBar> createState() => _ScoreBarState();
}

class _ScoreBarState extends State<_ScoreBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
              AnimatedBuilder(
                animation: _a,
                builder: (context, child) => Text(
                  '${(widget.score * _a.value * 100).round()}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _a,
            builder: (context, child) => ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: widget.score * _a.value,
                backgroundColor: widget.color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
