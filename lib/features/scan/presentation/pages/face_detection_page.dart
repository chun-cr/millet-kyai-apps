// 扫描模块页面：`FaceDetectionPage`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/widgets/app_toast.dart';
import '../services/face_scan_status_bridge.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/face_landmark_overlay.dart';

class FaceDetectionPage extends StatefulWidget {
  const FaceDetectionPage({super.key});

  @override
  State<FaceDetectionPage> createState() => _FaceDetectionPageState();
}

class _FaceDetectionPageState extends State<FaceDetectionPage> {
  final FaceScanStatusBridge _bridge = FaceScanStatusBridge();
  StreamSubscription? _subscription;
  bool _hasPermission = false;
  List<Offset> _landmarks = const [];
  Size _imageSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndStart();
  }

  Future<void> _requestPermissionAndStart() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      if (mounted) setState(() => _hasPermission = true);
      _subscription = _bridge.landmarkStream().listen((payload) {
        if (!mounted) return;
        final landmarks = _extractNormalizedLandmarks(payload['landmarks']);
        final imageSize = _extractImageSize(payload);
        setState(() {
          _landmarks = landmarks;
          _imageSize = imageSize;
        });
      });
      await _bridge.startMonitoring();
    } else if (mounted) {
      showAppToast(
        context,
        context.l10n.scanFaceDetectionPermissionRequired,
        kind: AppToastKind.info,
      );
    }
  }

  List<Offset> _extractNormalizedLandmarks(dynamic landmarks) {
    if (landmarks is! List) return const [];
    return landmarks.map((e) {
      if (e is Map) {
        return Offset(
          (e['x'] as num?)?.toDouble() ?? 0,
          (e['y'] as num?)?.toDouble() ?? 0,
        );
      }
      return Offset.zero;
    }).toList();
  }

  Size _extractImageSize(Map<String, dynamic> payload) {
    final width = (payload['imageWidth'] as num?)?.toDouble() ?? 0;
    final height = (payload['imageHeight'] as num?)?.toDouble() ?? 0;
    return Size(width, height);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    unawaited(_bridge.stopMonitoring());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_hasPermission) const Positioned.fill(child: CameraPreviewWidget()),
          if (_hasPermission && defaultTargetPlatform == TargetPlatform.android)
            Positioned.fill(
              child: IgnorePointer(
                child: FaceLandmarkOverlay(
                  normalizedLandmarks: _landmarks,
                  imageSize: _imageSize,
                  mirrored: true,
                ),
              ),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

