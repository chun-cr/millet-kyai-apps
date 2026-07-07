import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/core/widgets/app_error_fallback.dart';

void main() {
  testWidgets('renders friendly fallback content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppErrorFallback(
            title: '页面出了点问题',
            message: '请稍后重试',
            details: 'debug details',
          ),
        ),
      ),
    );

    expect(find.text('页面出了点问题'), findsOneWidget);
    expect(find.text('请稍后重试'), findsOneWidget);
    expect(find.text('debug details'), findsOneWidget);
  });

  testWidgets('route error page exposes home action', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppRouteErrorPage(error: 'boom')),
    );

    expect(find.text('返回首页'), findsOneWidget);
    expect(find.text('当前页面暂时无法打开，请返回首页后重试。'), findsOneWidget);
  });
}
