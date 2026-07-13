// 扫描失败的用户提示。详细错误只进入日志，页面只展示可行动的简短提示。

import 'package:flutter/widgets.dart';

import '../../../../core/widgets/app_toast.dart';
import '../../data/sources/scan_remote_source.dart';
import '../services/scan_capture_bridge.dart';

enum ScanFailureStage { face, tongue, palm }

void showScanFailureToast(
  BuildContext context, {
  required ScanFailureStage stage,
  required Object error,
}) {
  showAppToast(
    context,
    scanFailureUserMessage(stage: stage, error: error),
    kind: AppToastKind.info,
  );
}

String scanFailureUserMessage({
  required ScanFailureStage stage,
  required Object error,
}) {
  if (error is ScanUploadException) {
    if (error.isAuthenticationFailure) {
      return '登录状态已失效，请重新登录后再试。';
    }
    if (stage == ScanFailureStage.palm && _isMissingPalmReportId(error)) {
      return '舌诊报告生成失败，请重新扫描。';
    }
  }

  if (error is ScanCaptureException) {
    return '拍摄失败，请重新扫描。';
  }

  return switch (stage) {
    ScanFailureStage.face => '人脸上传失败，请重新扫描。',
    ScanFailureStage.tongue => '舌诊上传失败，请重新扫描。',
    ScanFailureStage.palm => '手掌上传失败，请重新扫描。',
  };
}

bool _isMissingPalmReportId(ScanUploadException error) {
  return error.stage == 'palm' && error.message.contains('报告ID缺失');
}
