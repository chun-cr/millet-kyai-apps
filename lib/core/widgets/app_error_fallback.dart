import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppErrorFallback extends StatelessWidget {
  const AppErrorFallback({
    super.key,
    required this.title,
    required this.message,
    this.details,
    this.primaryActionLabel,
    this.onPrimaryAction,
  });

  final String title;
  final String message;
  final String? details;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 280 || constraints.maxHeight < 220;
        final colorScheme = Theme.of(context).colorScheme;

        return Material(
          color: const Color(0xFFF6F7FB),
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(compact ? 16 : 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x120F172A),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(compact ? 16 : 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: compact ? 44 : 52,
                          height: compact ? 44 : 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4E8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFB45309),
                            size: 28,
                          ),
                        ),
                        SizedBox(height: compact ? 12 : 16),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: compact ? 16 : 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: compact ? 13 : 14,
                            height: 1.45,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                        if (details != null && details!.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                            ),
                            child: Text(
                              details!,
                              maxLines: 6,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                        if (onPrimaryAction != null &&
                            primaryActionLabel != null) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: onPrimaryAction,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(primaryActionLabel!),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AppRouteErrorPage extends StatelessWidget {
  const AppRouteErrorPage({super.key, this.error, this.onPrimaryAction});

  final Object? error;
  final VoidCallback? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: AppErrorFallback(
          title: '页面出了点问题',
          message: '当前页面暂时无法打开，请返回首页后重试。',
          details: kDebugMode && error != null ? error.toString() : null,
          primaryActionLabel: '返回首页',
          onPrimaryAction:
              onPrimaryAction ?? () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}
