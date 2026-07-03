// 认证模块共享组件：`AuthTopToast`。封装反复使用的界面结构与交互片段，减少页面重复代码。

import 'package:flutter/material.dart';
import 'package:millet_kyai_apps/core/widgets/app_toast.dart';

enum AuthTopToastKind { success, error }

class AuthTopToastController {
  final AppToastController _controller = AppToastController();

  void show(
    BuildContext context,
    String message, {
    AuthTopToastKind kind = AuthTopToastKind.error,
    Duration duration = const Duration(seconds: 3),
    double bottomOffset = 28,
  }) {
    _controller.show(
      context,
      message,
      kind: switch (kind) {
        AuthTopToastKind.success => AppToastKind.success,
        AuthTopToastKind.error => AppToastKind.error,
      },
      duration: duration,
      bottomOffset: bottomOffset,
    );
  }

  void hide() {
    _controller.hide();
  }

  void dispose() {
    _controller.dispose();
  }
}
