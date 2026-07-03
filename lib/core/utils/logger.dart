// 轻量日志封装。为诊断密集型页面和服务提供统一的调试输出入口。

import 'package:flutter/foundation.dart';

enum AppLogCategory { general, network }

class AppLogger {
  static const String _mode = String.fromEnvironment(
    'APP_LOG_MODE',
    defaultValue: 'network',
  );

  static void log(
    String message, {
    AppLogCategory category = AppLogCategory.general,
  }) {
    if (!_shouldLog(category)) {
      return;
    }
    debugPrintSynchronously('[AppLogger][${category.name}] $message');
  }

  static void network(String message) {
    log(message, category: AppLogCategory.network);
  }

  static bool _shouldLog(AppLogCategory category) {
    switch (_mode.toLowerCase()) {
      case 'none':
        return false;
      case 'all':
        return true;
      case 'general':
        return category == AppLogCategory.general;
      case 'network':
      default:
        return category == AppLogCategory.network;
    }
  }
}
