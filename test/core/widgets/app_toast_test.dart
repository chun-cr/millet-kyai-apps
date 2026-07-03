import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/core/widgets/app_toast.dart';

void main() {
  testWidgets('showAppToast displays and hides the shared capsule toast', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showAppToast(
                context,
                'Saved successfully',
                kind: AppToastKind.success,
                duration: const Duration(milliseconds: 200),
              );
            });
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Saved successfully'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Saved successfully'), findsNothing);
  });
}
