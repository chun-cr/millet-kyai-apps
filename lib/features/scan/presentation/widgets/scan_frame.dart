// 扫描模块共享组件：`ScanFrame`。封装反复使用的界面结构与交互片段，减少页面重复代码。

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import 'scan_hint_chips.dart';
import 'dart:math' as math;

enum ScanState { idle, scanning, completed }
enum FrameShape { ellipse, rectangle }

class ScanFrame extends StatefulWidget {
  final FrameShape frameShape;
  final double frameWidth;
  final double frameHeight;
  final Color themeColor;
  final Gradient? themeGradient;
  final List<String> hints;
  final String titleText;
  final String bottomTextIdle;
  final String bottomTextScanning;
  final String bottomTextCompleted;
  final String startButtonLabel;
  final String nextRoute;
  final String nextButtonLabel;
  final String skipRoute;
  final bool showBuiltInFrame;
  final bool autoStart;
  final bool startEnabled;
  final VoidCallback? onStartPressed;
  final ScanState? stateOverride;
  final double? progressOverride;

  const ScanFrame({
    super.key,
    required this.frameShape,
    required this.frameWidth,
    required this.frameHeight,
    required this.themeColor,
    this.themeGradient,
    required this.hints,
    required this.titleText,
    required this.bottomTextIdle,
    required this.bottomTextScanning,
    required this.bottomTextCompleted,
    required this.startButtonLabel,
    required this.nextRoute,
    required this.nextButtonLabel,
    required this.skipRoute,
    this.showBuiltInFrame = true,
    this.autoStart = true,
    this.startEnabled = true,
    this.onStartPressed,
    this.stateOverride,
    this.progressOverride,
  });

  @override
  State<ScanFrame> createState() => _ScanFrameState();
}

class _ScanFrameState extends State<ScanFrame> with TickerProviderStateMixin {
  ScanState _state = ScanState.idle;
  
  late AnimationController _scanLineController;
  late AnimationController _progressController;
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
       vsync: this, 
       duration: const Duration(milliseconds: 2000),
    );
    
    _progressController = AnimationController(
       vsync: this, 
       duration: const Duration(milliseconds: 4000),
    );
    
    _pulseController = AnimationController(
       vsync: this, 
       duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _progressController.addListener(() {
      setState(() {});
    });
    
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _state = ScanState.completed;
              _scanLineController.stop();
            });
          }
        });
      }
    });

    if (widget.autoStart && widget.stateOverride == null) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _state == ScanState.idle) {
          _startScanning();
        }
      });
    }

    _syncControlledAnimations();
  }

  @override
  void didUpdateWidget(covariant ScanFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControlledAnimations();
  }
  
  void _startScanning() {
    if (widget.stateOverride != null) {
      return;
    }

    setState(() {
      _state = ScanState.scanning;
    });
    _scanLineController.repeat(reverse: true);
    _progressController.forward();
  }

  ScanState get _effectiveState => widget.stateOverride ?? _state;

  double get _effectiveProgress =>
      (widget.progressOverride ?? _progressController.value).clamp(0.0, 1.0);

  void _syncControlledAnimations() {
    if (widget.stateOverride == null) {
      return;
    }

    if (_effectiveState == ScanState.scanning) {
      if (!_scanLineController.isAnimating) {
        _scanLineController.repeat(reverse: true);
      }
      return;
    }

    if (_scanLineController.isAnimating) {
      _scanLineController.stop();
    }
  }
  
  @override
  void dispose() {
    _scanLineController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        // 更合理的分配比例，如果总高度较小，优先保证底部 UI 空间
        final bottomHeight = totalHeight > 500 ? totalHeight * 0.45 : totalHeight * 0.68;
        final topHeight = totalHeight - bottomHeight;

        return Stack(
          children: [
            // Dark Area (Top)
            Positioned(
              top: 0, left: 0, right: 0,
              height: topHeight + 28, // Overlaps the bottom round corner slightly
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2D6FD4), Color(0xFF1DB896)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.titleText,
                      style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    if (widget.showBuiltInFrame) ...[
                      const SizedBox(height: 20),
                      _buildScannerVisual(),
                      const SizedBox(height: 20),
                    ] else
                      const SizedBox(height: 12),
                    Text(
                      _getBottomText(),
                      style: TextStyle(
                        fontSize: 12, 
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 14), // padding for overlap
                  ],
                ),
              ),
            ),
            
            // Light Area (Bottom)
            Positioned(
              bottom: 0, left: 0, right: 0,
              height: bottomHeight,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 16),
                child: Column(
                  children: [
                    ScanHintChips(hints: widget.hints),
                    const Spacer(),
                    if (_effectiveState == ScanState.scanning) ...[
                      _buildProgressBar(),
                      const SizedBox(height: 12),
                    ],
                    _buildMainButton(),
                    const SizedBox(height: 16),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => context.pushReplacement(widget.skipRoute),
                      child: Text(
                        context.l10n.scanSkipThisStep,
                        style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }
    );
  }
  
  String _getBottomText() {
    switch (_effectiveState) {
      case ScanState.idle: return widget.bottomTextIdle;
      case ScanState.scanning: return widget.bottomTextScanning;
      case ScanState.completed: return widget.bottomTextCompleted;
    }
  }

  Widget _buildScannerVisual() {
    final frameColor = _effectiveState == ScanState.completed 
        ? widget.themeColor 
        : Colors.white.withValues(alpha: 0.6);
        
    final rx = widget.frameShape == FrameShape.ellipse 
        ? widget.frameHeight / 2
        : 20.0;
        
    return SizedBox(
      width: widget.frameWidth,
      height: widget.frameHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final val = _pulseController.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: widget.frameWidth + 40 + (val * 10),
                    height: widget.frameHeight + 40 + (val * 10),
                    decoration: BoxDecoration(
                      borderRadius: widget.frameShape == FrameShape.ellipse 
                          ? BorderRadius.circular(math.max(widget.frameWidth, widget.frameHeight)) 
                          : BorderRadius.circular(rx + 20),
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                  Container(
                    width: widget.frameWidth + 20 + (val * 5),
                    height: widget.frameHeight + 20 + (val * 5),
                    decoration: BoxDecoration(
                      borderRadius: widget.frameShape == FrameShape.ellipse 
                          ? BorderRadius.circular(math.max(widget.frameWidth, widget.frameHeight)) 
                          : BorderRadius.circular(rx + 10),
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              );
            }
          ),
          
          // Dashed Border
          CustomPaint(
            size: Size(widget.frameWidth, widget.frameHeight),
            painter: _DashedFramePainter(
              color: frameColor,
              shape: widget.frameShape,
              radius: rx,
            ),
          ),
          
          // Corner brackets
          ..._buildCorners(),
          
          // Scan line
          if (_effectiveState == ScanState.scanning)
            AnimatedBuilder(
              animation: _scanLineController,
              builder: (context, child) {
                return Positioned(
                  top: _scanLineController.value * widget.frameHeight,
                  child: Container(
                    width: widget.frameWidth,
                    height: 2,
                    decoration: BoxDecoration(
                      color: widget.themeColor,
                      boxShadow: [
                        BoxShadow(
                          color: widget.themeColor.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              }
            ),
        ],
      ),
    );
  }
  
  List<Widget> _buildCorners() {
    final size = 20.0;
    return [
      Positioned(top: 0, left: 0, child: _CornerBracket(size: size, angle: 0)),
      Positioned(top: 0, right: 0, child: _CornerBracket(size: size, angle: math.pi / 2)),
      Positioned(bottom: 0, right: 0, child: _CornerBracket(size: size, angle: math.pi)),
      Positioned(bottom: 0, left: 0, child: _CornerBracket(size: size, angle: -math.pi / 2)),
    ];
  }
  
  Widget _buildProgressBar() {
    final progress = _effectiveProgress;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             Text(context.l10n.scanProgressLabel, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
             Text('${(progress * 100).toInt()}%', style: TextStyle(fontSize: 12, color: widget.themeColor, fontWeight: FontWeight.bold)),
           ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.borderColor,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.centerLeft,
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              return Container(
                width: constraints.maxWidth * progress,
                decoration: BoxDecoration(
                  color: widget.themeGradient == null ? widget.themeColor : null,
                  gradient: widget.themeGradient,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }
          ),
        ),
      ],
    );
  }
  
  Widget _buildMainButton() {
    String text;
    Color? bgColor;
    Gradient? gradient;
    VoidCallback? onPressed;
    
    if (_effectiveState == ScanState.idle) {
      text = widget.startButtonLabel;
      gradient = widget.themeGradient;
      bgColor = widget.themeGradient == null ? widget.themeColor : null;
      onPressed = widget.startEnabled
          ? () {
              widget.onStartPressed?.call();
              if (widget.stateOverride == null) {
                _startScanning();
              }
            }
          : null;
    } else if (_effectiveState == ScanState.scanning) {
      text = context.l10n.scanAnalyzingProgress((_effectiveProgress * 100).toInt());
      bgColor = AppColors.primary.withValues(alpha: 0.6);
      onPressed = null;
    } else {
      text = widget.nextButtonLabel;
      bgColor = widget.themeColor;
      onPressed = () => context.pushReplacement(widget.nextRoute);
    }
    
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: bgColor,
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: onPressed != null ? [
          BoxShadow(
            color: (bgColor ?? AppColors.primary).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _CornerBracket extends StatelessWidget {
  final double size;
  final double angle;
  const _CornerBracket({required this.size, required this.angle});
  
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: CustomPaint(
        size: Size(size, size),
        painter: _CornerPainter(),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedFramePainter extends CustomPainter {
  final Color color;
  final FrameShape shape;
  final double radius;
  
  _DashedFramePainter({required this.color, required this.shape, required this.radius});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
      
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    Path path;
    if (shape == FrameShape.ellipse) {
      path = Path()..addOval(rect);
    } else {
      path = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    }
    
    final dashPath = _dashPath(path, dashArray: [6, 4]);
    canvas.drawPath(dashPath, paint);
  }
  
  Path _dashPath(Path source, {required List<double> dashArray}) {
    final Path dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      int dashIndex = 0;
      while (distance < metric.length) {
        final double len = dashArray[dashIndex];
        if (draw) {
          dest.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        }
        distance += len;
        draw = !draw;
        dashIndex = (dashIndex + 1) % dashArray.length;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _DashedFramePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.shape != shape || oldDelegate.radius != radius;
  }
}
