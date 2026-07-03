// 扫描模块展示层工具：`ScanDebugErrorDialog`。负责承载展示层通用的计算、映射或调试辅助逻辑。

import 'package:flutter/material.dart';

import '../../data/sources/scan_remote_source.dart';
import '../services/scan_capture_bridge.dart';

Future<void> showScanDebugErrorDialog(
  BuildContext context, {
  required String title,
  required Object error,
}) {
  final description = switch (error) {
    ScanUploadException value => value.debugDescription,
    ScanCaptureException value => value.debugDescription,
    _ => error.toString(),
  };

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: SelectableText(
          description,
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    ),
  );
}
