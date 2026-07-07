part of '../report_page.dart';

// ignore_for_file: unused_element

class _RiskIndexSectionBlock extends StatelessWidget {
  final List<ReportRiskIndexData> riskIndexes;
  final Animation<double> scoreAnim;
  final DiagnosisMaNavigate? consultNavigate;

  const _RiskIndexSectionBlock({
    required this.riskIndexes,
    required this.scoreAnim,
    this.consultNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedConsultNavigate = consultNavigate;
    final visibleRiskIndexes = riskIndexes.take(4).toList(growable: false);
    if (visibleRiskIndexes.isEmpty) {
      return const SizedBox.shrink();
    }

    final warningRiskIndexes = riskIndexes
        .where((item) => item.isWarning)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FloatingSectionTitle(
          title: '风险指数',
          accentColor: Color(0xFFC57B08),
        ),
        const SizedBox(height: 6),
        _SectionCard(
          borderColor: const Color(0xFFF0E6DE),
          shadowColor: const Color(0x12000000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (warningRiskIndexes.isNotEmpty) ...[
                _RiskIndexTipCard(
                  warningRiskIndexes: warningRiskIndexes,
                  consultNavigate: resolvedConsultNavigate,
                  onConsultTap: resolvedConsultNavigate == null
                      ? null
                      : () => _showConsultNavigateDialog(
                          context,
                          resolvedConsultNavigate,
                        ),
                ),
                const SizedBox(height: 4),
              ],
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 380;
                  return GridView.builder(
                    primary: false,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: visibleRiskIndexes.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: compact ? 6 : 8,
                      crossAxisSpacing: compact ? 6 : 8,
                      mainAxisExtent: compact ? 162 : 164,
                    ),
                    itemBuilder: (context, index) => _RiskIndexCard(
                      item: visibleRiskIndexes[index],
                      anim: scoreAnim,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RiskIndexTipCard extends StatelessWidget {
  final List<ReportRiskIndexData> warningRiskIndexes;
  final DiagnosisMaNavigate? consultNavigate;
  final VoidCallback? onConsultTap;

  const _RiskIndexTipCard({
    required this.warningRiskIndexes,
    required this.consultNavigate,
    required this.onConsultTap,
  });

  @override
  Widget build(BuildContext context) {
    final highlightNames = warningRiskIndexes
        .map((item) => item.name)
        .where((item) => item.trim().isNotEmpty)
        .take(4)
        .toList(growable: false);

    final spans = <InlineSpan>[const TextSpan(text: '根据大数据，您的')];
    for (var i = 0; i < highlightNames.length; i++) {
      spans.add(
        TextSpan(
          text: highlightNames[i],
          style: const TextStyle(
            color: Color(0xFFE36A53),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      if (i < highlightNames.length - 1) {
        spans.add(const TextSpan(text: '、'));
      }
    }
    spans.add(
      const TextSpan(text: '风险偏高，检测前是否吃了有色饮料或者食物，如果是自然状态的检测结果，建议咨询健康顾问。'),
    );
    if (consultNavigate != null) {
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: GestureDetector(
              key: const ValueKey('report_risk_consult_button'),
              onTap: onConsultTap,
              child: const Text(
                '点击咨询',
                style: TextStyle(
                  color: Color(0xFFE36A53),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationThickness: 1.1,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      key: const ValueKey('report_risk_tip_card'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3D9D5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0B000000),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFE86E64),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF66584E),
                  height: 1.55,
                ),
                children: spans,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskIndexCard extends StatelessWidget {
  final ReportRiskIndexData item;
  final Animation<double> anim;

  const _RiskIndexCard({required this.item, required this.anim});

  @override
  Widget build(BuildContext context) {
    final palette = item.isWarning
        ? _kRiskWarningPalette
        : _kRiskAttentionPalette;

    return Container(
      key: ValueKey('report_risk_card_${item.name}'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1E7E0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: AnimatedBuilder(
        animation: anim,
        builder: (context, child) {
          final value = (item.displayProb * anim.value)
              .round()
              .clamp(0, 100)
              .toInt();
          final progress = (item.ringScore / 100) * anim.value;

          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(72, 72),
                      painter: _RiskIndexRingPainter(
                        progress: progress,
                        colors: palette.ringColors,
                      ),
                    ),
                    Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: palette.numberColor,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              _RiskStatusPill(item: item, palette: palette),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 32),
                child: Center(
                  child: Text(
                    item.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF54493F),
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RiskStatusPill extends StatelessWidget {
  final ReportRiskIndexData item;
  final _RiskCardPalette palette;

  const _RiskStatusPill({required this.item, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: palette.pillBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.pillBorder),
      ),
      child: Text(
        item.statusLabel,
        style: TextStyle(
          color: palette.pillText,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }
}

class _ConsultFallbackCard extends StatelessWidget {
  final DiagnosisMaNavigate consultNavigate;

  const _ConsultFallbackCard({required this.consultNavigate});

  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      if (consultNavigate.appId.trim().isNotEmpty)
        'AppId: ${consultNavigate.appId}',
      if (consultNavigate.path.trim().isNotEmpty)
        'Path: ${consultNavigate.path}',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9DDCF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.qr_code_2_rounded,
            size: 42,
            color: Color(0xFFC57B08),
          ),
          const SizedBox(height: 10),
          Text(
            consultNavigate.hasMiniProgram ? '当前版本不支持直接打开小程序' : '暂无二维码图片',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B5B4B),
              height: 1.5,
            ),
          ),
          if (lines.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              lines.join('\n'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8A7868),
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _showConsultNavigateDialog(
  BuildContext context,
  DiagnosisMaNavigate consultNavigate,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                consultNavigate.displayTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1810),
                ),
              ),
              const SizedBox(height: 16),
              if (consultNavigate.hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      consultNavigate.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          _ConsultFallbackCard(
                            consultNavigate: consultNavigate,
                          ),
                    ),
                  ),
                )
              else
                _ConsultFallbackCard(consultNavigate: consultNavigate),
              if (consultNavigate.hasImage) ...[
                const SizedBox(height: 10),
                const Text(
                  '长按图片识别二维码',
                  style: TextStyle(fontSize: 11, color: Color(0xFF8B7A69)),
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('关闭'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _RiskCardPalette {
  const _RiskCardPalette({
    required this.numberColor,
    required this.pillBackground,
    required this.pillBorder,
    required this.pillText,
    required this.ringColors,
  });

  final Color numberColor;
  final Color pillBackground;
  final Color pillBorder;
  final Color pillText;
  final List<Color> ringColors;
}

const _RiskCardPalette _kRiskWarningPalette = _RiskCardPalette(
  numberColor: Color(0xFFE24D43),
  pillBackground: Color(0xFFFBE7E5),
  pillBorder: Color(0xFFF1C5C0),
  pillText: Color(0xFFE35A4B),
  ringColors: [Color(0xFFF2B132), Color(0xFFE94B3F)],
);

const _RiskCardPalette _kRiskAttentionPalette = _RiskCardPalette(
  numberColor: Color(0xFF4E9A42),
  pillBackground: Color(0xFFF5ECD2),
  pillBorder: Color(0xFFE7D39C),
  pillText: Color(0xFFC39A2F),
  ringColors: [Color(0xFFF2B132), Color(0xFF4E9A42)],
);
