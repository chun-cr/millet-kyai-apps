part of '../report_page.dart';

class _ReportHeroSpace extends StatelessWidget {
  const _ReportHeroSpace({
    required this.viewData,
    required this.scoreAnim,
    required this.expandedHeight,
  });

  final ReportViewData viewData;
  final Animation<double> scoreAnim;
  final double expandedHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final compact = _isCompactReportWidth(constraints.maxWidth);
        final collapsedHeight = kToolbarHeight + mediaQuery.padding.top;
        final heroBottomInset = compact
            ? _kHeroBottomPaddingCompact
            : _kHeroBottomPaddingRegular;
        final expandRange = math.max(expandedHeight - collapsedHeight, 1.0);
        final progress =
            ((constraints.maxHeight - collapsedHeight) / expandRange).clamp(
              0.0,
              1.0,
            );
        final eased = Curves.easeOutCubic.transform(progress);
        final expandedOpacity = Curves.easeOut.transform(eased);

        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFFF4F1EB)),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFCF8),
                    Color(0xFFF5F1E8),
                    Color(0xFFE9F4EC),
                    _kReportHeroBottomFillColor,
                  ],
                  stops: [0.0, 0.22, 0.62, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -56,
                    right: -18,
                    child: _HeroGlowOrb(
                      size: compact ? 132 : 176,
                      colors: const [
                        Color(0x66FFFFFF),
                        Color(0x33F3E8C8),
                        Color(0x00F3E8C8),
                      ],
                    ),
                  ),
                  Positioned(
                    left: -48,
                    bottom: 12,
                    child: _HeroGlowOrb(
                      size: compact ? 120 : 164,
                      colors: const [
                        Color(0x4486C5A0),
                        Color(0x1686C5A0),
                        Color(0x0086C5A0),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 48,
                    top: compact ? 86 : 112,
                    child: _HeroGlowOrb(
                      size: compact ? 72 : 96,
                      colors: const [
                        Color(0x26D2B57C),
                        Color(0x08D2B57C),
                        Color(0x00D2B57C),
                      ],
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      // 顶部 padding 收紧，与估算函数保持一致
                      padding: compact
                          ? EdgeInsets.fromLTRB(
                              18,
                              _kHeroTopPaddingCompact,
                              18,
                              heroBottomInset,
                            )
                          : EdgeInsets.fromLTRB(
                              24,
                              _kHeroTopPaddingRegular,
                              24,
                              heroBottomInset,
                            ),
                      child: LayoutBuilder(
                        builder: (context, _) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              Column(
                                children: [
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: Opacity(
                                      opacity: expandedOpacity,
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - eased)),
                                        child: _HeroContentCard(
                                          viewData: viewData,
                                          scoreAnim: scoreAnim,
                                          maxWidth: constraints.maxWidth,
                                          compact: compact,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReportHeaderTitle extends StatelessWidget {
  const _ReportHeaderTitle({required this.viewData});

  final ReportViewData viewData;

  @override
  Widget build(BuildContext context) {
    final settings = context
        .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    final collapseProgress = settings == null
        ? 0.0
        : ((settings.maxExtent - settings.currentExtent) /
                  math.max(settings.maxExtent - settings.minExtent, 1.0))
              .clamp(0.0, 1.0)
              .toDouble();
    final reportTimeOpacity = 1.0 - collapseProgress;
    final collapsedTitleOpacity = collapseProgress;
    final reportTimeText = _heroHeaderMetaText(viewData);

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  key: const ValueKey('report_header_time'),
                  opacity: reportTimeOpacity,
                  child: Text(
                    reportTimeText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: Color(0xFF5E6B62),
                    ),
                  ),
                ),
                Opacity(
                  key: const ValueKey('report_header_collapsed_title'),
                  opacity: collapsedTitleOpacity,
                  child: Text(
                    context.l10n.reportHeaderCollapsedTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E1810),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroContentCard extends StatelessWidget {
  const _HeroContentCard({
    required this.viewData,
    required this.scoreAnim,
    required this.maxWidth,
    required this.compact,
  });

  final ReportViewData viewData;
  final Animation<double> scoreAnim;
  final double maxWidth;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final stacked = _shouldStackHeroContent(maxWidth);
    final stackedContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          child: Padding(
            padding: EdgeInsets.only(bottom: compact ? 10 : 20),
            child: _HeroScoreColumn(
              viewData: viewData,
              scoreAnim: scoreAnim,
              compact: compact,
            ),
          ),
        ),
        _HeroInfoColumn(viewData: viewData, compact: compact),
      ],
    );
    final rowContent = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroScoreColumn(
          viewData: viewData,
          scoreAnim: scoreAnim,
          compact: compact,
        ),
        SizedBox(width: compact ? 16 : 22),
        Expanded(
          child: _HeroInfoColumn(viewData: viewData, compact: compact),
        ),
      ],
    );
    final primaryContent = stacked ? stackedContent : rowContent;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        primaryContent,
        SizedBox(height: _heroContentDisclaimerGap(compact)),
        _HeroDisclaimerText(compact: compact),
      ],
    );

    // 无卡片容器，内容直接铺在渐变背景上
    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (compact && constraints.maxHeight < 220) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: content,
            );
          }

          return content;
        },
      ),
    );
  }
}

class _HeroScoreColumn extends StatelessWidget {
  const _HeroScoreColumn({
    required this.viewData,
    required this.scoreAnim,
    required this.compact,
  });

  final ReportViewData viewData;
  final Animation<double> scoreAnim;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scoreAnim,
      builder: (context, child) {
        final animatedScore = scoreAnim.value;
        final score = (viewData.overallScore * animatedScore).round();
        final outerSize = compact ? 104.0 : 124.0;
        final ringSize = compact ? 86.0 : 104.0;

        return SizedBox(
          width: compact ? 108 : 128,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: outerSize,
                height: outerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.58),
                  border: Border.all(
                    color: const Color(0xFFE4D8C6).withValues(alpha: 0.82),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF698873).withValues(alpha: 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: SizedBox(
                    width: ringSize,
                    height: ringSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: Size(ringSize, ringSize),
                          painter: _ScoreRingPainter(
                            progress:
                                animatedScore * (viewData.overallScore / 100),
                            strokeWidth: compact ? 7 : 8,
                            trackColor: const Color(
                              0xFF2D6A4F,
                            ).withValues(alpha: 0.12),
                            colors: const [
                              Color(0xFF2D6A4F),
                              Color(0xFF67A879),
                              Color(0xFFD5B46A),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$score',
                              style: TextStyle(
                                fontSize: compact ? 28 : 34,
                                fontWeight: FontWeight.w800,
                                height: 1,
                                color: const Color(0xFF2D6A4F),
                              ),
                            ),
                            SizedBox(height: compact ? 2 : 4),
                            Text(
                              '健康分',
                              style: TextStyle(
                                fontSize: compact ? 10 : 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(
                                  0xFF2D6A4F,
                                ).withValues(alpha: 0.84),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (viewData.hasHeroImages) ...[
                SizedBox(height: compact ? 10 : 14),
                TextButton(
                  key: const ValueKey('report_hero_view_images_button'),
                  onPressed: () =>
                      _showHeroImagesDialog(context, viewData.heroImageUrls),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2D6A4F),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    _heroViewImagesLabel(),
                    style: TextStyle(
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationThickness: 1.5,
                      color: const Color(0xFF2D6A4F),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HeroInfoColumn extends StatelessWidget {
  const _HeroInfoColumn({required this.viewData, required this.compact});

  final ReportViewData viewData;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final primaryConstitution =
        viewData.primaryConstitution?.trim().isNotEmpty == true
        ? viewData.primaryConstitution!.trim()
        : '平和体质';
    final therapySummary =
        viewData.heroTherapySummary?.trim().isNotEmpty == true
        ? viewData.heroTherapySummary!.trim()
        : viewData.summary?.trim().isNotEmpty == true
        ? viewData.summary!.trim()
        : '结合饮食、作息与情志调理，保持稳定节律。';
    final tongueSummary = viewData.heroTongueSymptoms
        .where((item) => item.trim().isNotEmpty)
        .join('，');
    final secondaryConstitutions = viewData.heroSecondaryConstitutions
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          primaryConstitution,
          key: const ValueKey('report_hero_primary_constitution'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 24 : 30,
            fontWeight: FontWeight.w800,
            height: 1.08,
            letterSpacing: 0.2,
            color: const Color(0xFF6B4E32),
          ),
        ),
        if (secondaryConstitutions.isNotEmpty) ...[
          // 主体质 → 次体质标签，统一间距
          SizedBox(height: compact ? 4 : 10),
          Wrap(
            spacing: compact ? 6 : 8,
            runSpacing: compact ? 6 : 8,
            children: [
              for (final item in secondaryConstitutions)
                _HeroTagChip(label: item, compact: compact),
            ],
          ),
        ],
        if (viewData.heroSkinAge != null) ...[
          // 次体质标签 → 肤龄，统一间距
          SizedBox(height: compact ? 4 : 10),
          _HeroAgeBadge(
            key: const ValueKey('report_hero_age_badge'),
            ageLabel: _heroAgeLabel(),
            age: viewData.heroSkinAge!,
            compact: compact,
          ),
        ],
        if (tongueSummary.isNotEmpty) ...[
          // 肤龄 → 舌相，统一间距
          SizedBox(height: compact ? 4 : 10),
          _HeroInfoLine(
            key: const ValueKey('report_hero_tongue_line'),
            label: _heroTongueLabel(),
            value: tongueSummary,
            compact: compact,
          ),
        ],
        // 舌相 → 调理，统一间距
        SizedBox(height: compact ? 4 : 10),
        _HeroInfoLine(
          key: const ValueKey('report_hero_therapy_line'),
          label: _heroTherapyLabel(),
          value: therapySummary,
          compact: compact,
        ),
      ],
    );
  }
}

class _HeroDisclaimerText extends StatelessWidget {
  const _HeroDisclaimerText({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        _heroDisclaimer(),
        key: const ValueKey('report_hero_disclaimer'),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          height: 1.5,
          color: const Color(0xFF6F665A).withValues(alpha: 0.82),
        ),
      ),
    );
  }
}

class _ReportTabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ReportTabBarHeaderDelegate({
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _ReportTabBarHeaderDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}

class _HeroChromeButton extends StatelessWidget {
  const _HeroChromeButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFFCF8).withValues(alpha: 0.80),
              border: Border.all(
                color: const Color(0xFFE4D8C6).withValues(alpha: 0.85),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B4E32).withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF3E352B)),
          ),
        ),
      ),
    );
  }
}

class _HeroGlowOrb extends StatelessWidget {
  const _HeroGlowOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _HeroTagChip extends StatelessWidget {
  const _HeroTagChip({required this.label, required this.compact});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F2E8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFB9D6BF).withValues(alpha: 0.9),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF356C49),
        ),
      ),
    );
  }
}

class _HeroAgeBadge extends StatelessWidget {
  const _HeroAgeBadge({
    super.key,
    required this.ageLabel,
    required this.age,
    required this.compact,
  });

  final String ageLabel;
  final double age;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ageStr = _formatHeroAge(age);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$ageLabel：',
          style: TextStyle(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF7C5F40),
          ),
        ),
        SizedBox(width: compact ? 4 : 6),
        Container(
          width: compact ? 30 : 36,
          height: compact ? 30 : 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(
              color: const Color(0xFF3C342B).withValues(alpha: 0.75),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            ageStr,
            style: TextStyle(
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w700,
              height: 1,
              color: const Color(0xFF3C342B).withValues(alpha: 0.84),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroInfoLine extends StatelessWidget {
  const _HeroInfoLine({
    super.key,
    required this.label,
    required this.value,
    required this.compact,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label：',
          style: TextStyle(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF7C5F40),
          ),
        ),
        SizedBox(width: compact ? 4 : 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: compact ? 12.5 : 13.5,
              height: 1.6,
              color: const Color(0xFF3C342B).withValues(alpha: 0.84),
            ),
          ),
        ),
      ],
    );
  }
}
