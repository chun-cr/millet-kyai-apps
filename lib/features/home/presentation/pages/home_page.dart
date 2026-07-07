import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:millet_kyai_apps/core/layout/app_layout.dart';
import 'package:millet_kyai_apps/core/l10n/formatters.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/core/l10n/seasonal_context.dart';
import 'package:millet_kyai_apps/core/router/app_router.dart';
import 'package:millet_kyai_apps/features/history/presentation/pages/history/history_page.dart';
import 'package:millet_kyai_apps/features/profile/presentation/pages/profile_page.dart';

part 'home/home_hero_widgets.dart';
part 'home/home_scan_widgets.dart';
part 'home/home_report_widgets.dart';
part 'home/home_function_widgets.dart';
part 'home/home_tip_widgets.dart';
part 'home/home_shared_widgets.dart';

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
    final layout = AppLayoutMetrics.of(context);
    final useNavigationRail = layout.isTabletLandscape;

    void handleDestinationTap(int index) {
      if (index == 1) {
        context.push(AppRoutes.scan);
      } else if (index == 2) {
        context.push(AppRoutes.report);
      } else {
        setState(() => _currentIndex = index);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.softBg,
      body: useNavigationRail
          ? Row(
              children: [
                _TabletNavigationRail(
                  currentIndex: _currentIndex,
                  onTap: handleDestinationTap,
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: _buildCurrentPage()),
              ],
            )
          : _buildCurrentPage(),
      bottomNavigationBar: useNavigationRail
          ? null
          : _BottomNav(
              currentIndex: _currentIndex,
              onTap: handleDestinationTap,
            ),
    );
  }
}

class _TabletNavigationRail extends StatelessWidget {
  const _TabletNavigationRail({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

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
    return SafeArea(
      right: false,
      child: NavigationRail(
        backgroundColor: Colors.white,
        selectedIndex: currentIndex,
        minWidth: 84,
        groupAlignment: -0.72,
        labelType: NavigationRailLabelType.all,
        selectedIconTheme: const IconThemeData(color: AppColors.primary),
        unselectedIconTheme: const IconThemeData(color: AppColors.textHint),
        selectedLabelTextStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        destinations: List.generate(_BottomNav._items.length, (index) {
          final item = _BottomNav._items[index];
          return NavigationRailDestination(
            icon: Icon(item.$1),
            selectedIcon: Icon(item.$2),
            label: Text(_labelForIndex(context, index)),
          );
        }),
        onDestinationSelected: onTap,
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
    final layout = AppLayoutMetrics.of(context);

    return Scaffold(
      backgroundColor: AppColors.softBg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: layout.contentMaxWidth),
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
                          padding: EdgeInsets.fromLTRB(
                            layout.isPhone ? 20 : 28,
                            28,
                            layout.isPhone ? 20 : 28,
                            32,
                          ),
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
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 760 ? 6 : 3;
            final aspectRatio = crossAxisCount == 6 ? 0.95 : 1.1;

            return GridView.count(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: aspectRatio,
              children: items
                  .map(
                    (item) => _FunctionCell(
                      icon: item.$1,
                      label: item.$2,
                      bgColor: item.$3,
                    ),
                  )
                  .toList(),
            );
          },
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
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              _HealthTipCard(
                tag: l10n.homeTipDietTag,
                wuxing: l10n.homeTipDietWuxing,
                wuxingColor: const Color(0xFFD4A04A),
                tagColor: const Color(0xFF0D7A5A),
                tip: l10n.homeTipDietBody,
                icon: Icons.restaurant_outlined,
              ),
              _HealthTipCard(
                tag: l10n.homeTipRoutineTag,
                wuxing: l10n.homeTipRoutineWuxing,
                wuxingColor: const Color(0xFF4A7FA8),
                tagColor: const Color(0xFF2D6A4F),
                tip: l10n.homeTipRoutineBody,
                icon: Icons.bedtime_outlined,
              ),
            ];

            if (constraints.maxWidth < 720) {
              return Column(
                children: [cards[0], const SizedBox(height: 10), cards[1]],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ─── Hero Flexible Space ───────────────────────────────────────────
