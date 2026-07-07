import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../router/app_router.dart';
import '../utils/logger.dart';
import '../widgets/app_error_fallback.dart';

void installGlobalErrorHandling() {
  final previousFlutterErrorHandler = FlutterError.onError;

  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error(
      'FlutterError: ${details.exceptionAsString()}\n${details.stack ?? StackTrace.empty}',
    );
    if (previousFlutterErrorHandler != null) {
      previousFlutterErrorHandler(details);
    } else {
      FlutterError.presentError(details);
    }
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    AppLogger.error('PlatformDispatcher error: $error\n$stack');
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    AppLogger.error(
      'ErrorWidget fallback: ${details.exceptionAsString()}\n${details.stack ?? StackTrace.empty}',
    );
    return AppErrorFallback(
      title: '页面出了点问题',
      message: '请返回首页后重试，若仍有问题请稍后再试。',
      details: kDebugMode ? details.exceptionAsString() : null,
      primaryActionLabel: '返回首页',
      onPrimaryAction: _safeGoHome,
    );
  };
}

void reportZoneError(Object error, StackTrace stackTrace) {
  AppLogger.error('Zone error: $error\n$stackTrace');
}

void _safeGoHome() {
  try {
    appRouter.go(AppRoutes.home);
  } catch (error, stackTrace) {
    AppLogger.error('Go home from fallback failed: $error\n$stackTrace');
  }
}
