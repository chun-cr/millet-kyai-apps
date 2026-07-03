// 通用 Toast 展示能力。统一封装提示浮层的展示、关闭和样式约定。

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

enum AppToastKind { success, error, info }

final AppToastController _appToastController = AppToastController();

void showAppToast(
  BuildContext context,
  String message, {
  AppToastKind kind = AppToastKind.error,
  Duration duration = const Duration(seconds: 3),
  double bottomOffset = 28,
}) {
  _appToastController.show(
    context,
    message,
    kind: kind,
    duration: duration,
    bottomOffset: bottomOffset,
  );
}

void hideAppToast() {
  _appToastController.hide();
}

class AppToastController {
  OverlayEntry? _entry;
  Timer? _timer;

  void show(
    BuildContext context,
    String message, {
    AppToastKind kind = AppToastKind.error,
    Duration duration = const Duration(seconds: 3),
    double bottomOffset = 28,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return;
    }

    hide();
    final entry = OverlayEntry(
      builder: (_) => AppToast(
        message: message,
        kind: kind,
        bottomOffset: bottomOffset,
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(duration, hide);
  }

  void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  void dispose() {
    hide();
  }
}

class AppToast extends StatefulWidget {
  const AppToast({
    super.key,
    required this.message,
    required this.kind,
    required this.bottomOffset,
  });

  final String message;
  final AppToastKind kind;
  final double bottomOffset;

  @override
  State<AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<AppToast> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = math.max(
      mediaQuery.viewInsets.bottom + 16,
      mediaQuery.padding.bottom + widget.bottomOffset,
    );
    final theme = _themeFor(widget.kind);
    final maxWidth = math.min(mediaQuery.size.width - 32, 320.0);

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomInset,
      child: IgnorePointer(
        child: AnimatedSlide(
          offset: _visible ? Offset.zero : const Offset(0, 0.35),
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Material(
                  color: Colors.transparent,
                  child: DecoratedBox(
                    key: ValueKey('app_toast_${widget.kind.name}'),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: theme.borderColor, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor,
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: theme.iconBackgroundColor,
                                shape: BoxShape.circle,
                              ),
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: Icon(
                                  theme.icon,
                                  size: 16,
                                  color: theme.accentColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                widget.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textColor,
                                  height: 1.35,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _AppToastTheme _themeFor(AppToastKind kind) {
    return switch (kind) {
      AppToastKind.error => const _AppToastTheme(
        backgroundColor: Color(0xFF302B28),
        borderColor: Color(0xFF433C37),
        iconBackgroundColor: Color(0xFFFFF1E8),
        accentColor: Color(0xFFD07B49),
        textColor: Color(0xFFFFFBF7),
        shadowColor: Color(0x33161210),
        icon: Icons.info_outline_rounded,
      ),
      AppToastKind.success => const _AppToastTheme(
        backgroundColor: Color(0xFF302B28),
        borderColor: Color(0xFF433C37),
        iconBackgroundColor: Color(0xFFFFE8EE),
        accentColor: Color(0xFFE55A79),
        textColor: Color(0xFFFFFBF7),
        shadowColor: Color(0x33161210),
        icon: Icons.check_rounded,
      ),
      AppToastKind.info => const _AppToastTheme(
        backgroundColor: Color(0xFF302B28),
        borderColor: Color(0xFF433C37),
        iconBackgroundColor: Color(0xFFE7F0FF),
        accentColor: Color(0xFF6A9FF8),
        textColor: Color(0xFFFFFBF7),
        shadowColor: Color(0x33161210),
        icon: Icons.info_outline_rounded,
      ),
    };
  }
}

class _AppToastTheme {
  const _AppToastTheme({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconBackgroundColor,
    required this.accentColor,
    required this.textColor,
    required this.shadowColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color iconBackgroundColor;
  final Color accentColor;
  final Color textColor;
  final Color shadowColor;
  final IconData icon;
}
