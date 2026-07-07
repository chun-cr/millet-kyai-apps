part of 'profile_page.dart';

// ══════════════════════════════════════════════════════════════════
// 洞察卡容器
// ══════════════════════════════════════════════════════════════════
class _ProfileSectionTitle extends StatelessWidget {
  final String title;
  const _ProfileSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: _kGold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kTextPrimary,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _BaselineSummary extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  final Color color;

  const _BaselineSummary({
    required this.label,
    required this.value,
    required this.note,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _kTextHint.withValues(alpha: 0.86),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          note,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: _kTextSecondary.withValues(alpha: 0.58),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ── 数据行（图标 + 标签 + 数值）──────────────────────────────────
class _StatLine extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;

  const _StatLine({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: _kTextHint),
          ),
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                  height: 1,
                ),
              ),
              TextSpan(
                text: unit,
                style: TextStyle(
                  fontSize: 10,
                  color: _kTextHint.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── BMI 状态条 ────────────────────────────────────────────────────
class _BmiBar extends StatelessWidget {
  final double bmi;
  const _BmiBar({required this.bmi});

  @override
  Widget build(BuildContext context) {
    // 18.5~24 正常区间，映射到 0~1
    final norm = ((bmi - 15) / 25).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BMI ${bmi.toStringAsFixed(1)}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                context.l10n.profileBmiNormal,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  color: _kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Stack(
          children: [
            // 轨道
            Container(
              height: 5,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // 进度
            FractionallySizedBox(
              widthFactor: norm,
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D6A4F), Color(0xFF7EC8A0)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// 体质点状时间轴
class _HealthSparkline extends StatelessWidget {
  const _HealthSparkline();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HealthSparklinePainter(),
      child: const SizedBox.expand(),
    );
  }
}

// 菜单行
class _MenuData {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final String? trailingText;
  final VoidCallback? onTap;

  const _MenuData({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    this.trailingText,
    this.onTap,
  });
}

class _MenuRow extends StatefulWidget {
  final _MenuData item;
  const _MenuRow({required this.item});

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.item.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        color: _pressed
            ? widget.item.color.withValues(alpha: 0.04)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(
              widget.item.icon,
              size: 18,
              color: widget.item.color.withValues(alpha: 0.86),
            ),
            const SizedBox(width: 12),
            // 文字
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.item.sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: _kTextHint.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.item.trailingText != null) ...[
              Text(
                widget.item.trailingText!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kTextHint.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(
              Icons.chevron_right,
              size: 18,
              color: _kPrimary.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Hero 背景装饰 Painter
// ══════════════════════════════════════════════════════════════════
class _ProfileHeroBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.18),
      86,
      Paint()
        ..color = const Color(0xFFB6DFCA).withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36),
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.42),
      62,
      Paint()
        ..color = const Color(0xFFC9A84C).withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _CabinData {
  final String title;
  final String detail;
  final IconData icon;
  final Color color;

  const _CabinData(this.title, this.detail, this.icon, this.color);
}

class _CabinCard extends StatelessWidget {
  final _CabinData item;
  const _CabinCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 18, color: item.color.withValues(alpha: 0.82)),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              item.detail,
              style: TextStyle(
                fontSize: 12,
                height: 1.55,
                color: _kTextSecondary.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${context.l10n.commonViewDetails} >',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: item.color.withValues(alpha: 0.76),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthSparklinePainter extends CustomPainter {
  static const _scores = [
    68.0,
    70.0,
    73.0,
    71.0,
    75.0,
    77.0,
    76.0,
    82.0,
    86.0,
    84.0,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final min = _scores.reduce((a, b) => a < b ? a : b);
    final max = _scores.reduce((a, b) => a > b ? a : b);
    final span = (max - min).clamp(1.0, double.infinity);

    final grid = Paint()
      ..color = _kDivider
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      grid,
    );

    final path = Path();
    for (var i = 0; i < _scores.length; i++) {
      final dx = size.width * i / (_scores.length - 1);
      final dy =
          size.height - ((_scores[i] - min) / span) * (size.height - 6) - 3;
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF2D6A4F), Color(0xFF7EC8A0)],
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final lastDx = size.width;
    final lastDy =
        size.height - ((_scores.last - min) / span) * (size.height - 6) - 3;
    canvas.drawCircle(Offset(lastDx, lastDy), 3.2, Paint()..color = _kPrimary);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
