import 'package:flutter/material.dart';

class ScanStatusButton extends StatefulWidget {
  const ScanStatusButton({
    super.key,
    required this.label,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    this.enabled = false,
    this.busy = false,
    this.prominent = false,
    this.completed = false,
    this.onTap,
  });

  final String label;
  final bool enabled;
  final bool busy;
  final bool prominent;
  final bool completed;
  final VoidCallback? onTap;
  final Color accent;
  final Color accentLight;
  final Color accentDark;

  @override
  State<ScanStatusButton> createState() => _ScanStatusButtonState();
}

class _ScanStatusButtonState extends State<ScanStatusButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _activityController;

  @override
  void initState() {
    super.initState();
    _activityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _syncActivity();
  }

  @override
  void didUpdateWidget(covariant ScanStatusButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncActivity();
  }

  @override
  void dispose() {
    _activityController.dispose();
    super.dispose();
  }

  void _syncActivity() {
    if (widget.busy) {
      if (!_activityController.isAnimating) {
        _activityController.repeat();
      }
    } else if (_activityController.isAnimating) {
      _activityController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final emphasized =
        widget.enabled || widget.busy || widget.prominent || widget.completed;
    final foreground = emphasized ? Colors.white : const Color(0xFF8F887F);
    final borderRadius = BorderRadius.circular(16);

    return Semantics(
      button: widget.onTap != null,
      enabled: widget.enabled,
      label: widget.label,
      liveRegion: widget.busy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          height: 58,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: emphasized ? null : const Color(0xFFE7E2DB),
            gradient: emphasized
                ? LinearGradient(
                    colors: [
                      widget.accentDark,
                      widget.accent,
                      widget.accentLight,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: borderRadius,
            border: Border.all(
              color: emphasized
                  ? Colors.white.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.5),
            ),
            boxShadow: emphasized
                ? [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.34),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (emphasized)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              if (widget.busy && !MediaQuery.of(context).disableAnimations)
                _ActivityStrip(controller: _activityController),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.busy) ...[
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(foreground),
                          backgroundColor: foreground.withValues(alpha: 0.22),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ] else if (widget.completed) ...[
                      Icon(Icons.check_circle_rounded, color: foreground),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
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

class _ActivityStrip extends StatelessWidget {
  const _ActivityStrip({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SizedBox(
        height: 3,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final trackWidth = constraints.maxWidth;
                final barWidth = trackWidth * 0.42;
                final left =
                    (trackWidth + barWidth) * controller.value - barWidth;

                return Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    Positioned(
                      left: left,
                      width: barWidth,
                      top: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: 0.85),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
