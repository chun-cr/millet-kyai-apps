import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppDeviceClass { phone, tabletPortrait, tabletLandscape }

class AppLayoutMetrics {
  const AppLayoutMetrics._({
    required this.size,
    required this.safePadding,
    required this.orientation,
    required this.deviceClass,
  });

  final Size size;
  final EdgeInsets safePadding;
  final Orientation orientation;
  final AppDeviceClass deviceClass;

  static const double tabletShortestSide = 600;
  static const double phoneContentMaxWidth = double.infinity;
  static const double tabletPortraitContentMaxWidth = 720;
  static const double tabletLandscapeContentMaxWidth = 980;

  static AppLayoutMetrics of(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final isTablet = size.shortestSide >= tabletShortestSide;
    final orientation = mediaQuery.orientation;
    final deviceClass = !isTablet
        ? AppDeviceClass.phone
        : orientation == Orientation.landscape
        ? AppDeviceClass.tabletLandscape
        : AppDeviceClass.tabletPortrait;

    return AppLayoutMetrics._(
      size: size,
      safePadding: mediaQuery.padding,
      orientation: orientation,
      deviceClass: deviceClass,
    );
  }

  bool get isPhone => deviceClass == AppDeviceClass.phone;

  bool get isTablet => !isPhone;

  bool get isTabletLandscape => deviceClass == AppDeviceClass.tabletLandscape;

  double get pageHorizontalPadding => switch (deviceClass) {
    AppDeviceClass.phone => 16,
    AppDeviceClass.tabletPortrait => 24,
    AppDeviceClass.tabletLandscape => 32,
  };

  double get contentMaxWidth => switch (deviceClass) {
    AppDeviceClass.phone => phoneContentMaxWidth,
    AppDeviceClass.tabletPortrait => tabletPortraitContentMaxWidth,
    AppDeviceClass.tabletLandscape => tabletLandscapeContentMaxWidth,
  };

  double get formMaxWidth => switch (deviceClass) {
    AppDeviceClass.phone => 390,
    AppDeviceClass.tabletPortrait => 420,
    AppDeviceClass.tabletLandscape => 430,
  };

  double get scanPanelMaxWidth => switch (deviceClass) {
    AppDeviceClass.phone => double.infinity,
    AppDeviceClass.tabletPortrait => 640,
    AppDeviceClass.tabletLandscape => 680,
  };

  double get scanGuideContentMaxWidth => switch (deviceClass) {
    AppDeviceClass.phone => double.infinity,
    AppDeviceClass.tabletPortrait => 720,
    AppDeviceClass.tabletLandscape => 1040,
  };

  double get scanGuideBottomMaxWidth => switch (deviceClass) {
    AppDeviceClass.phone => double.infinity,
    AppDeviceClass.tabletPortrait => 520,
    AppDeviceClass.tabletLandscape => 560,
  };

  Size scanGuideSize(
    Size viewportSize, {
    required double baseWidth,
    required double baseHeight,
    double tabletPortraitScale = 1.12,
    double tabletLandscapeScale = 1.18,
    double maxWidthFraction = 0.72,
    double maxHeightFraction = 0.68,
  }) {
    if (isPhone ||
        viewportSize.width <= 0 ||
        viewportSize.height <= 0 ||
        baseWidth <= 0 ||
        baseHeight <= 0) {
      return Size(baseWidth, baseHeight);
    }

    final targetScale = isTabletLandscape
        ? tabletLandscapeScale
        : tabletPortraitScale;
    final widthScale = viewportSize.width * maxWidthFraction / baseWidth;
    final heightScale = viewportSize.height * maxHeightFraction / baseHeight;
    final scale = math.min(targetScale, math.min(widthScale, heightScale));

    return Size(baseWidth * scale, baseHeight * scale);
  }

  double centeredHorizontalInset(
    double viewportWidth, {
    double? maxContentWidth,
    double? minHorizontalPadding,
  }) {
    final minPadding = minHorizontalPadding ?? pageHorizontalPadding;
    final maxWidth = maxContentWidth ?? contentMaxWidth;
    if (!maxWidth.isFinite) {
      return minPadding;
    }
    return math.max(minPadding, (viewportWidth - maxWidth) / 2);
  }
}

class AppOrientationGate extends StatefulWidget {
  const AppOrientationGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppOrientationGate> createState() => _AppOrientationGateState();
}

class _AppOrientationGateState extends State<AppOrientationGate>
    with WidgetsBindingObserver {
  List<DeviceOrientation>? _lastOrientations;

  bool get _supportsOrientationPreference {
    if (kIsWeb) {
      return false;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _schedulePreferenceUpdate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedulePreferenceUpdate();
  }

  void _schedulePreferenceUpdate() {
    if (!_supportsOrientationPreference || !mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _applyOrientationPreference();
      }
    });
  }

  void _applyOrientationPreference() {
    final metrics = AppLayoutMetrics.of(context);
    final orientations = metrics.isTablet
        ? const <DeviceOrientation>[
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]
        : const <DeviceOrientation>[
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ];

    if (listEquals(_lastOrientations, orientations)) {
      return;
    }
    _lastOrientations = orientations;
    SystemChrome.setPreferredOrientations(orientations);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class AppResponsiveListView extends StatelessWidget {
  const AppResponsiveListView({
    super.key,
    required this.children,
    this.physics,
    this.topPadding = 20,
    this.bottomPadding = 32,
    this.minHorizontalPadding,
    this.maxContentWidth,
  });

  final List<Widget> children;
  final ScrollPhysics? physics;
  final double topPadding;
  final double bottomPadding;
  final double? minHorizontalPadding;
  final double? maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = AppLayoutMetrics.of(context);
        final sidePadding = layout.centeredHorizontalInset(
          constraints.maxWidth,
          maxContentWidth: maxContentWidth,
          minHorizontalPadding: minHorizontalPadding,
        );

        return ListView(
          physics: physics,
          padding: EdgeInsets.fromLTRB(
            sidePadding,
            topPadding,
            sidePadding,
            bottomPadding,
          ),
          children: children,
        );
      },
    );
  }
}
