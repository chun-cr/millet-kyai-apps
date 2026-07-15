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
