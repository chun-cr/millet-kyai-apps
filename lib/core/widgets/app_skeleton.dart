// 通用骨架屏组件集合。封装加载中的占位结构，减少各页面重复绘制骨架布局。

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

const _kSkeletonBaseColor = Color(0xFFE5DED4);
const _kSkeletonHighlightColor = Color(0xFFF7F1E9);
const _kSkeletonFillColor = Colors.white;

class AppShimmer extends StatelessWidget {
  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor = _kSkeletonBaseColor,
    this.highlightColor = _kSkeletonHighlightColor,
  });

  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
    this.color = _kSkeletonFillColor,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final Color color;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : borderRadius,
      ),
    );
  }
}

class SkeletonLine extends StatelessWidget {
  const SkeletonLine({
    super.key,
    this.width,
    this.height = 12,
    this.borderRadius = const BorderRadius.all(Radius.circular(999)),
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return SkeletonBlock(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SkeletonBlock(width: size, height: size, shape: BoxShape.circle);
  }
}
