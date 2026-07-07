part of '../home_page.dart';

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
