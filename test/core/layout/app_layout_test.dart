import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/core/layout/app_layout.dart';

void main() {
  Future<AppLayoutMetrics> pumpMetrics(
    WidgetTester tester, {
    required Size size,
  }) async {
    late AppLayoutMetrics metrics;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            metrics = AppLayoutMetrics.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return metrics;
  }

  testWidgets('classifies phones and keeps content unconstrained', (
    tester,
  ) async {
    final metrics = await pumpMetrics(tester, size: const Size(393, 852));

    expect(metrics.deviceClass, AppDeviceClass.phone);
    expect(metrics.isPhone, isTrue);
    expect(metrics.contentMaxWidth, double.infinity);
    expect(metrics.formMaxWidth, 390);
    expect(metrics.scanPanelMaxWidth, double.infinity);
    expect(
      metrics.scanGuideSize(
        const Size(390, 520),
        baseWidth: 210,
        baseHeight: 262,
      ),
      const Size(210, 262),
    );
  });

  testWidgets('classifies portrait tablets with wider form width', (
    tester,
  ) async {
    final metrics = await pumpMetrics(tester, size: const Size(768, 1024));

    expect(metrics.deviceClass, AppDeviceClass.tabletPortrait);
    expect(metrics.isTablet, isTrue);
    expect(metrics.contentMaxWidth, 720);
    expect(metrics.formMaxWidth, 420);
    expect(metrics.scanPanelMaxWidth, 640);

    final guideSize = metrics.scanGuideSize(
      const Size(768, 640),
      baseWidth: 210,
      baseHeight: 262,
    );
    expect(guideSize.width, closeTo(235.2, 0.01));
    expect(guideSize.height, closeTo(293.44, 0.01));
  });

  testWidgets('classifies landscape tablets and centers content', (
    tester,
  ) async {
    final metrics = await pumpMetrics(tester, size: const Size(1280, 800));

    expect(metrics.deviceClass, AppDeviceClass.tabletLandscape);
    expect(metrics.isTabletLandscape, isTrue);
    expect(metrics.contentMaxWidth, 980);
    expect(metrics.centeredHorizontalInset(1280), 150);
    expect(metrics.scanPanelMaxWidth, 680);

    final guideSize = metrics.scanGuideSize(
      const Size(1000, 560),
      baseWidth: 210,
      baseHeight: 262,
    );
    expect(guideSize.width, closeTo(247.8, 0.01));
    expect(guideSize.height, closeTo(309.16, 0.01));

    final heightConstrained = metrics.scanGuideSize(
      const Size(900, 300),
      baseWidth: 244,
      baseHeight: 322,
      maxHeightFraction: 0.70,
    );
    expect(heightConstrained.height, lessThanOrEqualTo(210));
  });
}
