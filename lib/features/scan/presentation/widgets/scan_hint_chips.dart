// 扫描模块共享组件：`ScanHintChips`。封装反复使用的界面结构与交互片段，减少页面重复代码。

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ScanHintChips extends StatelessWidget {
  final List<String> hints;

  const ScanHintChips({super.key, required this.hints});

  static const _fallbackIcons = [
    Icons.wb_sunny_outlined,
    Icons.face_outlined,
    Icons.accessibility_new_outlined,
    Icons.sentiment_satisfied_alt_outlined,
    Icons.back_hand_outlined,
  ];

  IconData _getIconForIndex(int index) {
    if (index < _fallbackIcons.length) {
      return _fallbackIcons[index];
    }
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: List.generate(hints.length, (index) {
        final hint = hints[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.softBg,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: AppColors.borderColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIconForIndex(index),
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                hint,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
