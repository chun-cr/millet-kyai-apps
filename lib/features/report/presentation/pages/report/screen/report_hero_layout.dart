part of '../report_page.dart';

double _estimateHeroExpandedHeight(
  BuildContext context,
  ReportViewData viewData,
) {
  final mediaQuery = MediaQuery.of(context);
  final compact = _isCompactReportWidth(mediaQuery.size.width);
  final horizontalPadding = compact ? 18.0 : 24.0;
  // 收紧顶部 padding，减少 Hero 与 AppBar 按钮之间的空隙
  final topPadding = compact
      ? _kHeroTopPaddingCompact
      : _kHeroTopPaddingRegular;
  final bottomPadding = compact
      ? _kHeroBottomPaddingCompact
      : _kHeroBottomPaddingRegular;
  final heroBottomInset = bottomPadding;
  final contentWidth = math.max(
    mediaQuery.size.width - horizontalPadding * 2,
    1.0,
  );
  final contentHeight = _estimateHeroContentHeight(
    context,
    viewData: viewData,
    maxWidth: contentWidth,
    compact: compact,
    stackedOverride: _shouldStackHeroContent(mediaQuery.size.width),
  );
  final contentGapCompensation = -_heroContentDisclaimerGap(compact);
  final measurementSlack = compact
      ? _kHeroMeasurementSlackCompact
      : _kHeroMeasurementSlackRegular;
  final expandedHeight =
      mediaQuery.padding.top +
      topPadding +
      contentHeight +
      // 内容区与 disclaimer 之间的间距
      _heroContentDisclaimerGap(compact) +
      contentGapCompensation +
      heroBottomInset +
      measurementSlack;
  final collapsedHeight = kToolbarHeight + mediaQuery.padding.top;

  return math.max(
    expandedHeight,
    collapsedHeight +
        (compact
            ? _kHeroMinExpandedDeltaCompact
            : _kHeroMinExpandedDeltaRegular),
  );
}

double _heroContentDisclaimerGap(bool compact) => compact
    ? _kHeroContentDisclaimerGapCompact
    : _kHeroContentDisclaimerGapRegular;

bool _shouldStackHeroContent(double maxWidth) => maxWidth < 360;

bool _isCompactReportWidth(double width) =>
    width <= _kReportCompactWidthBreakpoint;

String _heroHeaderMetaText(ReportViewData viewData) =>
    '${_heroTimestampPrefix()}: ${_formatHeroDate(viewData.recordedAt)}';

double _estimateHeroContentHeight(
  BuildContext context, {
  required ReportViewData viewData,
  required double maxWidth,
  required bool compact,
  bool? stackedOverride,
}) {
  final stacked = stackedOverride ?? _shouldStackHeroContent(maxWidth);
  final scoreHeight = _estimateHeroScoreHeight(
    context,
    hasImages: viewData.hasHeroImages,
    compact: compact,
  );
  final infoWidth = stacked
      ? maxWidth
      : math.max(
          maxWidth - (compact ? 108.0 : 128.0) - (compact ? 16.0 : 22.0),
          1.0,
        );
  final infoHeight = _estimateHeroInfoHeight(
    context,
    viewData: viewData,
    maxWidth: infoWidth,
    compact: compact,
  );

  final primaryContentHeight = stacked
      ? scoreHeight + (compact ? 10.0 : 20.0) + infoHeight
      : math.max(scoreHeight, infoHeight);
  final disclaimerHeight = _estimateHeroDisclaimerHeight(
    context,
    maxWidth: maxWidth,
    compact: compact,
  );

  return primaryContentHeight +
      _heroContentDisclaimerGap(compact) +
      disclaimerHeight;
}

double _estimateHeroScoreHeight(
  BuildContext context, {
  required bool hasImages,
  required bool compact,
}) {
  final outerSize = compact ? 104.0 : 124.0;
  if (!hasImages) {
    return outerSize;
  }

  return outerSize +
      (compact ? 10.0 : 14.0) +
      _measureHeroTextHeight(
        context,
        text: _heroViewImagesLabel(),
        style: TextStyle(
          fontSize: compact ? 13 : 14,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
          decorationThickness: 1.5,
          color: const Color(0xFF2D6A4F),
        ),
        maxWidth: compact ? 108 : 128,
      );
}

double _estimateHeroInfoHeight(
  BuildContext context, {
  required ReportViewData viewData,
  required double maxWidth,
  required bool compact,
}) {
  final primaryConstitution =
      viewData.primaryConstitution?.trim().isNotEmpty == true
      ? viewData.primaryConstitution!.trim()
      : '暂无体质数据';
  final therapySummary = viewData.heroTherapySummary?.trim().isNotEmpty == true
      ? viewData.heroTherapySummary!.trim()
      : viewData.summary?.trim().isNotEmpty == true
      ? viewData.summary!.trim()
      : '暂无调理建议数据';
  final tongueSummary = viewData.heroTongueSymptoms
      .where((item) => item.trim().isNotEmpty)
      .join('，');
  final secondaryConstitutions = viewData.heroSecondaryConstitutions
      .where((item) => item.trim().isNotEmpty)
      .toList(growable: false);

  var height = _measureHeroTextHeight(
    context,
    text: primaryConstitution,
    style: TextStyle(
      fontSize: compact ? 24 : 30,
      fontWeight: FontWeight.w800,
      height: 1.08,
      letterSpacing: 0.2,
      color: const Color(0xFF6B4E32),
    ),
    maxWidth: maxWidth,
    maxLines: 2,
  );

  if (secondaryConstitutions.isNotEmpty) {
    // 主体质标题 → 次体质标签行间距，与 _HeroInfoColumn 保持一致
    height += compact ? 4.0 : 10.0;
    height += _estimateHeroChipWrapHeight(
      context,
      labels: secondaryConstitutions,
      maxWidth: maxWidth,
      compact: compact,
    );
  }

  if (viewData.heroSkinAge != null) {
    // 次体质标签 → 肤龄行间距
    height += compact ? 4.0 : 10.0;
    height += compact ? 30.0 : 36.0;
  }

  if (tongueSummary.isNotEmpty) {
    // 肤龄 → 舌相行间距
    height += compact ? 4.0 : 10.0;
    height += _estimateHeroInfoLineHeight(
      context,
      label: _heroTongueLabel(),
      value: tongueSummary,
      maxWidth: maxWidth,
      compact: compact,
    );
  }

  // 舌相 → 调理行间距
  height += compact ? 4.0 : 10.0;
  height += _estimateHeroInfoLineHeight(
    context,
    label: _heroTherapyLabel(),
    value: therapySummary,
    maxWidth: maxWidth,
    compact: compact,
  );

  return height;
}

double _estimateHeroDisclaimerHeight(
  BuildContext context, {
  required double maxWidth,
  required bool compact,
}) {
  return _measureHeroTextHeight(
    context,
    text: _heroDisclaimer(),
    style: TextStyle(
      fontSize: compact ? 10 : 11,
      height: 1.5,
      color: const Color(0xFF6F665A).withValues(alpha: 0.82),
    ),
    maxWidth: maxWidth,
  );
}

double _estimateHeroChipWrapHeight(
  BuildContext context, {
  required List<String> labels,
  required double maxWidth,
  required bool compact,
}) {
  if (labels.isEmpty) {
    return 0;
  }

  final chipStyle = TextStyle(
    fontSize: compact ? 11 : 12,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF356C49),
  );
  final horizontalPadding = compact ? 10.0 : 12.0;
  final verticalPadding = compact ? 5.0 : 7.0;
  final spacing = compact ? 6.0 : 8.0;
  final runSpacing = compact ? 6.0 : 8.0;
  final chipHeight =
      _measureHeroTextHeight(
        context,
        text: labels.first,
        style: chipStyle,
        maxWidth: maxWidth,
        maxLines: 1,
      ) +
      verticalPadding * 2;

  var rows = 1;
  var currentRowWidth = 0.0;
  for (final label in labels) {
    final chipWidth = math.min(
      _measureHeroTextWidth(context, text: label, style: chipStyle) +
          horizontalPadding * 2,
      maxWidth,
    );
    final nextWidth = currentRowWidth == 0
        ? chipWidth
        : currentRowWidth + spacing + chipWidth;
    if (currentRowWidth > 0 && nextWidth > maxWidth) {
      rows += 1;
      currentRowWidth = chipWidth;
      continue;
    }
    currentRowWidth = nextWidth;
  }

  return rows * chipHeight + (rows - 1) * runSpacing;
}

double _estimateHeroInfoLineHeight(
  BuildContext context, {
  required String label,
  required String value,
  required double maxWidth,
  required bool compact,
}) {
  final labelStyle = TextStyle(
    fontSize: compact ? 12 : 13,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF7C5F40),
  );
  final valueStyle = TextStyle(
    fontSize: compact ? 12.5 : 13.5,
    height: 1.6,
    color: const Color(0xFF3C342B).withValues(alpha: 0.84),
  );
  final labelWidth = _measureHeroTextWidth(
    context,
    text: '$label：',
    style: labelStyle,
  );
  final valueWidth = math.max(
    maxWidth - labelWidth - (compact ? 4.0 : 6.0),
    1.0,
  );
  final valueHeight = _measureHeroTextHeight(
    context,
    text: value,
    style: valueStyle,
    maxWidth: valueWidth,
  );
  final labelHeight = _measureHeroTextHeight(
    context,
    text: '$label：',
    style: labelStyle,
    maxWidth: labelWidth,
    maxLines: 1,
  );

  return math.max(labelHeight, valueHeight);
}

double _measureHeroTextHeight(
  BuildContext context, {
  required String text,
  required TextStyle style,
  required double maxWidth,
  int? maxLines,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: maxLines,
    ellipsis: maxLines == null ? null : '…',
  )..layout(maxWidth: math.max(maxWidth, 1.0));

  return painter.size.height;
}

double _measureHeroTextWidth(
  BuildContext context, {
  required String text,
  required TextStyle style,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();

  return painter.size.width;
}
