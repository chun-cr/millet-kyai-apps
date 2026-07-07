part of '../home_page.dart';

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
