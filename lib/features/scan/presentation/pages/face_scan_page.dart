import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/layout/app_layout.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_toast.dart';
import '../widgets/scan_step_indicator.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/face_landmark_overlay.dart';
import '../../data/models/scan_session.dart';
import '../../data/sources/scan_remote_source.dart';
import '../services/face_scan_status_bridge.dart';
import '../services/face_frame_mask_renderer.dart';
import '../services/scan_capture_bridge.dart';
import '../utils/scan_capture_geometry.dart';
import '../utils/scan_debug_error_dialog.dart';
import '../utils/scan_upload_tenant_context.dart';

part 'face_scan/face_scan_logic.dart';
part 'face_scan/face_scan_widgets.dart';

class FaceScanPage extends StatefulWidget {
  const FaceScanPage({super.key});
  @override
  State<FaceScanPage> createState() => _FaceScanPageState();
}

class _FaceScanPageState extends State<FaceScanPage>
    with SingleTickerProviderStateMixin {
  final FaceScanStatusBridge _statusBridge = FaceScanStatusBridge();
  late final ScanRemoteSource _scanRemoteSource;
  late final ScanSession _scanSession;
  final ScanCaptureBridge _captureBridge = ScanCaptureBridge();
  static const Alignment _faceGuideAlignment = Alignment(0, -0.25);
  static const double _faceGuideWidth = 210;
  static const double _faceGuideHeight = 262;

  bool _hasPermission = false;
  bool _isBackCamera = false;
  bool _cameraReady = false; // PlatformView 延迟创建标志
  bool _hasFaceDetected = false;
  bool _isScanning = false;
  bool _isSubmitting = false;
  bool _pauseAutoScanUntilReset = false;
  double _scanProgress = 0;
  bool _isTransitioning = false;
  bool _stopMonitoringOnDispose = true;

  Timer? _scanHoldTimer;
  StreamSubscription<Map<String, dynamic>>? _faceStatusSub;
  late AnimationController _scanLineCtrl;
  late Animation<double> _scanLineAnim;
  List<Offset> _normalizedLandmarks = const [];
  Size _sourceImageSize = Size.zero;
  Size _cameraViewportSize = Size.zero;
  AcceptedFaceSnapshot? _acceptedFaceSnapshot;
  int? _latestFaceGenerationId;
  int? _latestFaceTimestampMs;
  bool? _latestFaceMirrored;
  DateTime? _lastTrackedFaceAt;
  String? _lastFaceHoldDiagnosticsSignature;
  bool _autoStartScanCheckQueued = false;
  String _faceDirection = ''; // 位置引导文字（空 = 居中或无脸）

  Size get _faceGuideSize => AppLayoutMetrics.of(context).scanGuideSize(
    _cameraViewportSize,
    baseWidth: _faceGuideWidth,
    baseHeight: _faceGuideHeight,
    maxHeightFraction: 0.62,
  );

  Rect get _faceGuideRectNormalized => buildNormalizedGuideRect(
    _cameraViewportSize,
    alignment: _faceGuideAlignment,
    guideWidth: _faceGuideSize.width,
    guideHeight: _faceGuideSize.height,
  );

  Rect get _faceGuideRectOnViewport => buildViewportGuideRect(
    _cameraViewportSize,
    alignment: _faceGuideAlignment,
    guideWidth: _faceGuideSize.width,
    guideHeight: _faceGuideSize.height,
  );

  AcceptedFaceSnapshot? get _liveAcceptedFaceSnapshot =>
      buildAcceptedFaceSnapshot(
        guideRect: _faceGuideRectNormalized,
        normalizedLandmarks: _normalizedLandmarks,
        analysisImageSize: _sourceImageSize,
        isBackCamera: _isBackCamera,
        mirrored: _latestFaceMirrored,
        platform: defaultTargetPlatform,
        generationId: _latestFaceGenerationId,
        timestampMs: _latestFaceTimestampMs,
      );

  Rect? get _faceBoundsOnViewport {
    final normalizedBounds = normalizedBoundingRect(_normalizedLandmarks);
    if (normalizedBounds == null) {
      return null;
    }

    final viewportBounds = mapNormalizedRectToViewport(
      normalizedRect: normalizedBounds,
      viewportSize: _cameraViewportSize,
      imageSize: _sourceImageSize,
    );

    if (viewportBounds == Rect.zero) {
      return null;
    }

    return viewportBounds;
  }

  bool _isFaceFramedForUpload({required bool allowHoldDrift}) {
    final normalizedBounds = normalizedBoundingRect(_normalizedLandmarks);
    final viewportBounds = _faceBoundsOnViewport;
    if (normalizedBounds == null || viewportBounds == null) {
      return false;
    }
    return isFaceFramedForUploadBounds(
      bounds: viewportBounds,
      guideRect: _faceGuideRectOnViewport,
      area: normalizedRectArea(normalizedBounds),
      allowHoldDrift: allowHoldDrift,
    );
  }

  bool get _isFaceReadyToHold =>
      isFaceHoldEligible(
        hasPermission: _hasPermission,
        hasFaceDetected: _hasFaceDetected,
        isFramed: _isFaceFramedForUpload(allowHoldDrift: false),
      ) &&
      !_pauseAutoScanUntilReset;

  bool get _shouldAutoStartScan => shouldAutoStartFaceScan(
    platform: defaultTargetPlatform,
    hasPermission: _hasPermission,
    hasFaceDetected: _hasFaceDetected,
    isFramed: _isFaceFramedForUpload(allowHoldDrift: false),
    hasAcceptedSnapshot: _liveAcceptedFaceSnapshot != null,
    isScanning: _isScanning || _isSubmitting,
    isTransitioning: _isTransitioning,
  );

  String get _bottomStatusLabel {
    final l10n = context.l10n;
    if (!_hasPermission) {
      return l10n.scanCameraPermissionRequired;
    }
    if (_isSubmitting) {
      return l10n.scanUploading;
    }
    if (_isScanning) {
      return l10n.scanScanning;
    }
    if (_isFaceReadyToHold) {
      return l10n.scanFaceDetectedReady;
    }
    return l10n.scanFaceAlignInFrame;
  }

  bool get _bottomStatusHighlighted =>
      !_isScanning && !_isSubmitting && _isFaceReadyToHold;

  Duration get _requiredFaceScanHoldDuration =>
      faceScanHoldDurationForPlatform(defaultTargetPlatform);

  @override
  void initState() {
    super.initState();
    initInjector();
    _scanRemoteSource = ScanRemoteSource(getIt<DioClient>());
    _scanSession = getIt<ScanSession>()..reset();
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnim = Tween<double>(
      begin: 0.1,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut));

    // ── 关键修改：把"进入页面"和"启动相机 / 检测"拆开 ──
    // 第 1 拍：只做 UI 动画 + 路由切换动画
    // 第 2 拍（postFrameCallback）：申请权限
    // 等路由过渡动画结束后再创建 PlatformView & 启动检测
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _requestPermissionAndStart();
    });
  }

  Future<void> _requestPermissionAndStart() async {
    final status = await Permission.camera.request();
    if (!status.isGranted || !mounted) return;

    setState(() => _hasPermission = true);

    // 等待路由切换动画完成（默认 ~300ms），再创建 PlatformView
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    setState(() => _cameraReady = true);

    // 再等一帧，让 PlatformView 完成首次 layout 后再启动 CameraX / 检测
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      _faceStatusSub?.cancel();
      _faceStatusSub = _statusBridge.landmarkStream().listen((payload) {
        if (!mounted) return;
        final hasFace = _extractHasFace(payload);
        final landmarks = _extractNormalizedLandmarks(payload['landmarks']);
        final imageSize = _extractImageSize(payload);
        final generationId = _extractInt(payload['generationId']);
        final timestampMs = _extractInt(payload['timestampMs']);
        final eventBackCamera = _extractBool(payload['isBackCamera']);
        final mirrored = _extractBool(payload['mirrored']);
        final now = DateTime.now();
        final retainPreviousTracking = shouldRetainPreviousFaceTracking(
          holdInProgress: _isScanning,
          hasFaceDetected: hasFace,
          hasLandmarks: landmarks.isNotEmpty,
          timeSinceLastTrackedFace: _lastTrackedFaceAt == null
              ? transientFaceTrackingGraceDuration +
                    const Duration(milliseconds: 1)
              : now.difference(_lastTrackedFaceAt!),
        );
        if (hasFace && landmarks.isNotEmpty) {
          _lastTrackedFaceAt = now;
        }
        if (retainPreviousTracking) {
          return;
        }
        if (_pauseAutoScanUntilReset && !hasFace) {
          _pauseAutoScanUntilReset = false;
        }
        setState(() {
          _hasFaceDetected = hasFace;
          _normalizedLandmarks = landmarks;
          _sourceImageSize = imageSize;
          if (eventBackCamera != null) {
            _isBackCamera = eventBackCamera;
          }
          _latestFaceGenerationId = generationId;
          _latestFaceTimestampMs = timestampMs;
          _latestFaceMirrored = mirrored;
          _faceDirection = hasFace ? _computeFaceDirection(landmarks) : '';
        });
        if (_pauseAutoScanUntilReset && !_isFaceReadyToHold) {
          _pauseAutoScanUntilReset = false;
        }
        _logFaceHoldDiagnosticsIfNeeded();
        if (_isScanning && !_isSubmitting) {
          final keepHoldAlive = shouldKeepFaceHoldAlive(
            hasPermission: _hasPermission,
            hasFaceDetected: _hasFaceDetected,
            isFramed: _isFaceFramedForUpload(allowHoldDrift: false),
            isRelaxedFramed: _isFaceFramedForUpload(allowHoldDrift: true),
            holdInProgress: _scanHoldTimer != null,
          );
          if (_scanHoldTimer != null && !keepHoldAlive) {
            _cancelScanHold(resetProgress: true);
          }
          return;
        }
        if (_isSubmitting) {
          return;
        }
        if (!_pauseAutoScanUntilReset && _shouldAutoStartScan) {
          _startScan();
          return;
        }
        if (!_pauseAutoScanUntilReset &&
            !_isTransitioning &&
            _hasPermission &&
            _hasFaceDetected &&
            _normalizedLandmarks.isNotEmpty &&
            _sourceImageSize != Size.zero) {
          _queueDeferredAutoStartScanCheck();
        }
      });
      await _statusBridge.initialize();
      await _statusBridge.startMonitoring();
    });
  }

  void _startScan() {
    final canBeginScan = shouldBeginFaceScan(
      platform: defaultTargetPlatform,
      hasPermission: _hasPermission,
      hasFaceDetected: _hasFaceDetected,
      isFramed: _isFaceFramedForUpload(allowHoldDrift: false),
      isBusy: _isScanning || _isSubmitting,
      isTransitioning: _isTransitioning,
      isPaused: _pauseAutoScanUntilReset,
    );
    if (!mounted || !canBeginScan) {
      return;
    }
    _clearAcceptedFaceSnapshot();
    final acceptedSnapshot = _freezeAcceptedFaceSnapshot();
    if (acceptedSnapshot == null) {
      _pauseAutoScanUntilReset = true;
      _cancelScanHold(resetProgress: true);
      return;
    }
    setState(() {
      _isScanning = true;
      _scanProgress = _requiredFaceScanHoldDuration > Duration.zero ? 0 : 0.08;
    });
    if (_requiredFaceScanHoldDuration <= Duration.zero) {
      unawaited(_captureAndUploadFace());
      return;
    }

    final stopwatch = Stopwatch()..start();
    _scanHoldTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        _scanHoldTimer = null;
        return;
      }

      final keepHoldAlive = shouldKeepFaceHoldAlive(
        hasPermission: _hasPermission,
        hasFaceDetected: _hasFaceDetected,
        isFramed: _isFaceFramedForUpload(allowHoldDrift: false),
        isRelaxedFramed: _isFaceFramedForUpload(allowHoldDrift: true),
        holdInProgress: true,
      );
      if (!keepHoldAlive) {
        _cancelScanHold(resetProgress: true);
        return;
      }

      final progress =
          stopwatch.elapsedMilliseconds /
          _requiredFaceScanHoldDuration.inMilliseconds;
      if (progress >= 1) {
        timer.cancel();
        _scanHoldTimer = null;
        setState(() => _scanProgress = 0.08);
        unawaited(_captureAndUploadFace());
        return;
      }
      setState(() => _scanProgress = mapHoldProgressToVisualProgress(progress));
    });
  }

  void _cancelScanHold({required bool resetProgress}) {
    _scanHoldTimer?.cancel();
    _scanHoldTimer = null;
    if (!mounted) return;
    setState(() {
      _isScanning = false;
      if (resetProgress) {
        _scanProgress = 0;
      }
    });
  }

  Future<void> _captureAndUploadFace() async {
    if (_isSubmitting || !mounted) {
      return;
    }
    final providerContainer = ProviderScope.containerOf(context, listen: false);

    final acceptedSnapshot = _freezeAcceptedFaceSnapshot();
    if (acceptedSnapshot == null) {
      _pauseAutoScanUntilReset = true;
      _cancelScanHold(resetProgress: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _scanProgress = 0.65;
    });

    try {
      AppLogger.log(
        'Face capture request: generation=${acceptedSnapshot.generationId}, '
        'timestamp=${acceptedSnapshot.timestampMs}, '
        'mirrored=${acceptedSnapshot.mirrored}, '
        'backCamera=${acceptedSnapshot.isBackCamera}',
      );
      final capture = await _captureBridge.capture(
        target: ScanCaptureTarget.face,
        guide: acceptedSnapshot.toCaptureGuide(),
        generationId: acceptedSnapshot.generationId,
        landmarks: acceptedSnapshot.normalizedLandmarks,
        analysisImageSize: acceptedSnapshot.analysisImageSize,
        isBackCamera: acceptedSnapshot.isBackCamera,
        mirrored: acceptedSnapshot.mirrored,
        timestampMs: acceptedSnapshot.timestampMs,
        preferVisibleRegion: true,
      );
      if (!mounted) {
        return;
      }

      setState(() => _scanProgress = 0.68);
      final faceFrameUploadPath = await _buildFaceFrameUploadPath(
        capture,
        acceptedSnapshot,
      );
      if (!mounted) {
        return;
      }
      if (!hasRenderableFaceFrameUpload(
        normalizedLandmarks: acceptedSnapshot.normalizedLandmarks,
        sourceImagePath: capture.croppedPath,
        faceFrameFilePath: faceFrameUploadPath,
      )) {
        AppLogger.log(
          'Face frame upload rejected: '
          'landmarks=${acceptedSnapshot.normalizedLandmarks.length}, '
          'sourcePath=${capture.croppedPath}, '
          'framePath=$faceFrameUploadPath',
        );
        _pauseAutoScanUntilReset = true;
        _cancelScanHold(resetProgress: true);
        _clearAcceptedFaceSnapshot();
        setState(() {
          _isSubmitting = false;
        });
        showAppToast(
          context,
          context.l10n.scanFaceFrameRetryMessage,
          kind: AppToastKind.info,
        );
        return;
      }
      await _logFaceUploadFileSizes(
        faceFilePath: capture.croppedPath,
        faceFrameFilePath: faceFrameUploadPath,
      );
      final uploadTenantContext =
          await loadScanUploadTenantContextFromContainer(providerContainer);
      if (!mounted) {
        return;
      }
      AppLogger.log(
        'Face upload tenant context: '
        '${describeScanUploadTenantContext(uploadTenantContext)}',
      );

      final faceUpload = await _scanRemoteSource.uploadFace(
        faceFilePath: capture.croppedPath,
        faceFrameFilePath: faceFrameUploadPath,
        tenantId: uploadTenantContext.tenantId,
        topOrgId: uploadTenantContext.topOrgId,
        storeId: uploadTenantContext.storeId,
        clinicId: uploadTenantContext.clinicId,
        onSendProgress: (sent, total) {
          if (!mounted) {
            return;
          }
          final progress = total > 0 ? sent / total : (sent > 0 ? 0.5 : 0.0);
          setState(
            () => _scanProgress = mapUploadProgressToVisualProgress(progress),
          );
        },
      );

      if (!mounted) {
        return;
      }

      if (!faceUpload.hasSingleFace) {
        final message = faceUpload.faceNum > 1
            ? '检测到多张人脸，请重新扫描。'
            : '未检测到清晰人脸，请重新扫描。';
        _pauseAutoScanUntilReset = true;
        _cancelScanHold(resetProgress: true);
        _clearAcceptedFaceSnapshot();
        setState(() {
          _isSubmitting = false;
        });
        showAppToast(context, message, kind: AppToastKind.info);
        return;
      }

      _scanSession.saveFaceUpload(faceUpload);
      _clearAcceptedFaceSnapshot();
      setState(() => _scanProgress = 1);
      await Future<void>.delayed(faceScanPostSuccessDelay);
      if (!mounted) {
        return;
      }
      await _navigateToTongueScan();
    } on Object catch (error, stackTrace) {
      AppLogger.log('Face scan submission failed: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      _pauseAutoScanUntilReset = true;
      _cancelScanHold(resetProgress: true);
      _clearAcceptedFaceSnapshot();
      setState(() {
        _isSubmitting = false;
      });
      await showScanDebugErrorDialog(
        context,
        title: context.l10n.scanFaceUploadFailedTitle,
        error: error,
      );
    }
  }

  Future<String> _buildFaceFrameUploadPath(
    ScanCaptureResult capture,
    AcceptedFaceSnapshot acceptedSnapshot,
  ) async {
    final captureGuide = acceptedSnapshot.toCaptureGuide();
    final captureGuideRect = Rect.fromLTWH(
      captureGuide.left,
      captureGuide.top,
      captureGuide.width,
      captureGuide.height,
    );
    final maskLandmarks = remapLandmarksToCaptureGuide(
      normalizedLandmarks: acceptedSnapshot.normalizedLandmarks,
      guideRect: captureGuideRect,
    );
    final maskImageSize = Size(capture.cropWidth, capture.cropHeight);
    AppLogger.log(
      'Rendering face frame mask from accepted snapshot: '
      'generation=${acceptedSnapshot.generationId}, '
      'timestamp=${acceptedSnapshot.timestampMs}, '
      'mirrored=${acceptedSnapshot.mirrored}, '
      'maskLandmarks=${maskLandmarks.length}, '
      'maskSize=${capture.cropWidth.toStringAsFixed(0)}x'
      '${capture.cropHeight.toStringAsFixed(0)}',
    );
    return renderFaceFrameMaskFile(
      sourceImagePath: capture.croppedPath,
      normalizedLandmarks: maskLandmarks,
      analysisImageSize: maskImageSize,
      mirrored: acceptedSnapshot.mirrored,
      targetMaxBytes: 450 * 1024,
    );
  }

  Future<void> _logFaceUploadFileSizes({
    required String faceFilePath,
    required String faceFrameFilePath,
  }) async {
    final faceBytes = await _safeFileLength(faceFilePath);
    final frameBytes = await _safeFileLength(faceFrameFilePath);
    AppLogger.log(
      'Face upload file sizes: '
      'faceFile=${_describeFileSize(faceFilePath, faceBytes)}, '
      'faceFrameFile=${_describeFileSize(faceFrameFilePath, frameBytes)}',
    );
  }

  Future<int?> _safeFileLength(String path) async {
    try {
      return await File(path).length();
    } on FileSystemException {
      return null;
    }
  }

  String _describeFileSize(String path, int? bytes) {
    final fileName = path.split(Platform.pathSeparator).last;
    if (bytes == null) {
      return '$fileName(unavailable)';
    }
    return '$fileName(${_formatBytes(bytes)} / $bytes B)';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    final kilobytes = bytes / 1024;
    if (kilobytes < 1024) {
      return '${kilobytes.toStringAsFixed(1)} KB';
    }
    final megabytes = kilobytes / 1024;
    return '${megabytes.toStringAsFixed(2)} MB';
  }

  Future<void> _navigateToTongueScan() async {
    if (_isTransitioning || !mounted) return;
    _isTransitioning = true;
    _stopMonitoringOnDispose = false;
    _cancelScanHold(resetProgress: false);
    _clearAcceptedFaceSnapshot();
    await _faceStatusSub?.cancel();
    _faceStatusSub = null;
    if (!mounted) return;
    context.pushReplacement(AppRoutes.scanTongue);
  }

  @override
  void dispose() {
    _scanHoldTimer?.cancel();
    _faceStatusSub?.cancel();
    if (_stopMonitoringOnDispose) {
      unawaited(_statusBridge.stopMonitoring());
    }
    _scanLineCtrl.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EB),
      body: Stack(
        children: [
          // 米色背景纹理（与 scan_guide_page 一致）
          Positioned.fill(child: CustomPaint(painter: _BgPainter())),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── 顶部引导卡 ──
                _buildTopGuideCard(),
                // ── 中间拍摄区 ──
                Expanded(child: _buildCameraArea()),
                // ── 底部提示卡 ──
                _buildBottomCard(),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 顶部引导卡 ───────────────────────────────────────────────────────────

  Widget _buildTopGuideCard() {
    final l10n = context.l10n;
    final layout = AppLayoutMetrics.of(context);
    final sideInset = layout.centeredHorizontalInset(
      MediaQuery.sizeOf(context).width,
      maxContentWidth: layout.scanPanelMaxWidth,
      minHorizontalPadding: 16,
    );
    return Container(
      margin: EdgeInsets.fromLTRB(sideInset, 8, sideInset, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGreen.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: _kGreen.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 顶栏：返回 + 步骤指示器
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 16, 6),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: Color(0xFF3A3028),
                  ),
                  onPressed: _isScanning || _isSubmitting
                      ? null
                      : () {
                          unawaited(_statusBridge.stopMonitoring());
                          context.pop();
                        },
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                const Expanded(
                  child: Center(child: ScanStepIndicator(currentStep: 0)),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.flip_camera_ios,
                    size: 22,
                    color: Color(0xFF3A3028),
                  ),
                  tooltip: l10n.scanToggleCamera,
                  onPressed: _hasPermission && !_isSubmitting && !_isScanning
                      ? () {
                          setState(() => _isBackCamera = !_isBackCamera);
                          unawaited(_statusBridge.toggleCamera());
                        }
                      : null,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // 分隔线
          Divider(height: 1, color: _kGreen.withValues(alpha: 0.08)),
          // 标题内容
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Row(
              children: [
                // 图标
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kGreen.withValues(alpha: 0.15)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.face_retouching_natural_outlined,
                        size: 26,
                        color: _kGreen,
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: const BoxDecoration(
                            color: _kGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '1',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            l10n.scanFaceTitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1810),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _kGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              l10n.scanFaceTag,
                              style: TextStyle(
                                fontSize: 10,
                                color: _kGreen,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.scanFaceSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(
                            0xFF3A3028,
                          ).withValues(alpha: 0.58),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 底部说明条
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EE).withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 12,
                  color: _kGreen.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.scanFaceDetail,
                  style: TextStyle(
                    fontSize: 11,
                    color: _kGreen.withValues(alpha: 0.75),
                    letterSpacing: 0.2,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 中间拍摄区 ──────────────────────────────────────────────────────────

  Widget _buildCameraArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        _cameraViewportSize = constraints.biggest;
        return Stack(
          children: [
            // 相机预览：延迟到 _cameraReady 后才创建 PlatformView
            Positioned.fill(
              child: ClipRect(
                child: _cameraReady
                    ? const CameraPreviewWidget(
                        key: ValueKey('shared_camera_preview'),
                      )
                    : Container(
                        color: const Color(0xFF1A1A1A),
                        child: Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: _kGreenLight.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            if (defaultTargetPlatform == TargetPlatform.android &&
                _normalizedLandmarks.isNotEmpty)
              Positioned.fill(
                child: FaceLandmarkOverlay(
                  normalizedLandmarks: _normalizedLandmarks,
                  imageSize: _sourceImageSize,
                  mirrored: !_isBackCamera,
                ),
              ),
            // 渐变遮罩（上下淡出，融入米色背景）
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFF4F1EB).withValues(alpha: 0.55),
                      Colors.transparent,
                      Colors.transparent,
                      const Color(0xFFF4F1EB).withValues(alpha: 0.55),
                    ],
                    stops: const [0.0, 0.18, 0.78, 1.0],
                  ),
                ),
              ),
            ),
            // 椭圆扫描框（上移，让下半屏留给底部卡）
            Align(alignment: _faceGuideAlignment, child: _buildOvalFrame()),
          ],
        );
      },
    );
  }

  Widget _buildOvalFrame() {
    final l10n = context.l10n;
    final showReady = shouldShowFaceReadyStatus(
      hasPermission: _hasPermission,
      hasFaceDetected: _hasFaceDetected,
      faceDirection: _faceDirection,
    );
    final guideSize = _faceGuideSize;
    final frameW = guideSize.width;
    final frameH = guideSize.height;

    return SizedBox(
      width: frameW,
      height: frameH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 外发光晕
          Positioned(
            top: -10,
            left: -10,
            right: -10,
            bottom: -10,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _kGreen.withValues(alpha: 0.1),
                  width: 12,
                ),
              ),
            ),
          ),
          // 主椭圆框
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _hasFaceDetected
                      ? _kGreenLight
                      : _kGreen.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
            ),
          ),
          // 内圈细线
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            bottom: 10,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _kGreen.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
            ),
          ),
          // 四角装饰
          Positioned(
            top: -1,
            left: 24,
            child: _ScanCorner(color: _kGreenLight, top: true, left: true),
          ),
          Positioned(
            top: -1,
            right: 24,
            child: _ScanCorner(color: _kGreenLight, top: true, left: false),
          ),
          Positioned(
            bottom: -1,
            left: 24,
            child: _ScanCorner(color: _kGreenLight, top: false, left: true),
          ),
          Positioned(
            bottom: -1,
            right: 24,
            child: _ScanCorner(color: _kGreenLight, top: false, left: false),
          ),
          // 扫描线
          AnimatedBuilder(
            animation: _scanLineAnim,
            builder: (context, child) => Positioned(
              top: _scanLineAnim.value * frameH,
              left: 18,
              right: 18,
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      _kGreenLight.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 状态气泡（椭圆框正下方）
          Positioned(
            bottom: -48,
            left: -40,
            right: -40,
            child: Center(
              child: (_isScanning || _isSubmitting)
                  ? _HoldFeedback(
                      label: _isSubmitting
                          ? l10n.scanUploading
                          : l10n.scanKeepStill,
                      progress: _scanProgress,
                    )
                  : (_faceDirection.isNotEmpty
                        ? _DirectionPill(direction: _faceDirection)
                        : _StatusPill(
                            label: _hasPermission
                                ? (showReady
                                      ? l10n.scanFaceDetectedReady
                                      : l10n.scanFaceAlignInFrame)
                                : l10n.scanCameraPermissionRequired,
                            detected: showReady,
                          )),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 底部提示卡 ──────────────────────────────────────────────────────────

  Widget _buildBottomCard() {
    final l10n = context.l10n;
    final layout = AppLayoutMetrics.of(context);
    final sideInset = layout.centeredHorizontalInset(
      MediaQuery.sizeOf(context).width,
      maxContentWidth: layout.scanPanelMaxWidth,
      minHorizontalPadding: 16,
    );
    return Container(
      margin: EdgeInsets.fromLTRB(sideInset, 0, sideInset, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGreen.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: _kGreen.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tips 行
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TipItem(
                  icon: Icons.wb_sunny_outlined,
                  label: l10n.scanTipBrightLight,
                ),
                _TipItem(
                  icon: Icons.face_retouching_off,
                  label: l10n.scanFaceTipNoMakeup,
                ),
                _TipItem(
                  icon: Icons.remove_red_eye_outlined,
                  label: l10n.scanFaceTipLookForward,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _kGreen.withValues(alpha: 0.08)),
          // 按钮区
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              children: [
                _BottomStatusPrompt(
                  label: _bottomStatusLabel,
                  highlighted: _bottomStatusHighlighted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 工具方法 ───────────────────────────────────────────────────────────

  bool _extractHasFace(Map<String, dynamic> payload) {
    final detected = payload['detected'];
    if (detected is bool) return detected;
    final landmarks = payload['landmarks'];
    return landmarks is List && landmarks.isNotEmpty;
  }

  /// 根据鼻尖点（index 4）相对于归一化中心 (0.5, 0.5) 的偏移，返回方向提示文字。
  /// 已居中时返回空字符串。
  String _computeFaceDirection(List<Offset> landmarks) {
    if (landmarks.length <= 4) return '';
    final l10n = context.l10n;
    // MediaPipe FaceMesh 鼻尖点 index = 4（0-based）
    final nose = landmarks[4];
    const threshold = 0.12; // 超过 12% 中心偏移才提示
    final dx = nose.dx - 0.5; // 正 = 右，负 = 左
    final dy = nose.dy - 0.5; // 正 = 下，负 = 上
    final adx = dx.abs();
    final ady = dy.abs();
    if (adx < threshold && ady < threshold) return '';
    // 优先水平方向（镜像：画面中鼻子偏右表示需要向左）
    if (adx >= ady) {
      return dx > 0 ? l10n.scanMoveLeft : l10n.scanMoveRight;
    } else {
      return dy > 0 ? l10n.scanMoveUp : l10n.scanMoveDown;
    }
  }

  List<Offset> _extractNormalizedLandmarks(dynamic raw) {
    if (raw is! List) return const [];
    final points = <Offset>[];
    for (final item in raw) {
      if (item is Map) {
        final x = _asDouble(item['x']);
        final y = _asDouble(item['y']);
        if (x != null && y != null) points.add(Offset(x, y));
      }
    }
    return points;
  }

  Size _extractImageSize(Map<String, dynamic> payload) {
    final width = _asDouble(payload['imageWidth']);
    final height = _asDouble(payload['imageHeight']);
    if (width == null || height == null || width <= 0 || height <= 0) {
      return Size.zero;
    }
    return Size(width, height);
  }

  AcceptedFaceSnapshot? _freezeAcceptedFaceSnapshot() {
    final snapshot = latchAcceptedFaceSnapshot(
      currentLatchedSnapshot: _acceptedFaceSnapshot,
      nextSnapshot: _liveAcceptedFaceSnapshot,
    );
    if (snapshot == null) {
      return null;
    }
    if (!identical(snapshot, _acceptedFaceSnapshot)) {
      _acceptedFaceSnapshot = snapshot;
      AppLogger.log(
        'Latched accepted face snapshot: generation=${snapshot.generationId}, '
        'timestamp=${snapshot.timestampMs}, '
        'mirrored=${snapshot.mirrored}, '
        'landmarks=${snapshot.normalizedLandmarks.length}',
      );
    }
    return snapshot;
  }

  void _clearAcceptedFaceSnapshot() {
    _acceptedFaceSnapshot = null;
  }

  void _queueDeferredAutoStartScanCheck() {
    if (_autoStartScanCheckQueued || !mounted) {
      return;
    }

    _autoStartScanCheckQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoStartScanCheckQueued = false;
      if (!mounted ||
          _pauseAutoScanUntilReset ||
          _isScanning ||
          _isSubmitting) {
        return;
      }
      if (!_shouldAutoStartScan) {
        return;
      }

      AppLogger.log(
        'Face auto-start resumed after frame sync: '
        'ready=$_isFaceReadyToHold '
        'snapshot=${_liveAcceptedFaceSnapshot != null} '
        'viewport=${_cameraViewportSize.width.toStringAsFixed(0)}x'
        '${_cameraViewportSize.height.toStringAsFixed(0)}',
      );
      _startScan();
    });
  }

  void _logFaceHoldDiagnosticsIfNeeded() {
    if (!_hasPermission || _isScanning || _isSubmitting) {
      return;
    }

    final normalizedBounds = normalizedBoundingRect(_normalizedLandmarks);
    final viewportBounds = _faceBoundsOnViewport;
    final area = normalizedBounds == null
        ? 0.0
        : normalizedRectArea(normalizedBounds);
    final strictInsideGuide =
        viewportBounds != null &&
        isNormalizedBoundsInsideGuide(
          bounds: viewportBounds,
          guideRect: _faceGuideRectOnViewport,
          guideInsetFactor: _kFaceStrictGuideInsetFactor,
        );
    final blockers = <String>[
      if (!_hasFaceDetected) 'face_missing',
      if (_normalizedLandmarks.isEmpty) 'landmarks_missing',
      if (_sourceImageSize == Size.zero) 'source_size_missing',
      if (_cameraViewportSize == Size.zero) 'viewport_missing',
      if (_liveAcceptedFaceSnapshot == null) 'accepted_snapshot_missing',
      if (viewportBounds == null) 'viewport_bounds_missing',
      if (normalizedBounds != null && area < _kFaceStrictMinArea) 'too_small',
      if (normalizedBounds != null && area > _kFaceStrictMaxArea) 'too_large',
      if (viewportBounds != null && !strictInsideGuide) 'framing_failed',
      if (_pauseAutoScanUntilReset) 'paused_after_failure',
      if (_isTransitioning) 'transitioning',
      if (_isFaceReadyToHold) 'ready',
    ];
    final signature =
        '${blockers.join(",")}|'
        '${_sourceImageSize.width.round()}x${_sourceImageSize.height.round()}|'
        '${_cameraViewportSize.width.round()}x${_cameraViewportSize.height.round()}';
    if (_lastFaceHoldDiagnosticsSignature == signature) {
      return;
    }

    _lastFaceHoldDiagnosticsSignature = signature;
    AppLogger.log(
      'Face hold diagnostics: blockers=${blockers.join(",")} '
      'area=${area.toStringAsFixed(3)} '
      'guideViewport=${_formatRect(_faceGuideRectOnViewport)} '
      'boundsNormalized=${_formatRect(normalizedBounds)} '
      'boundsViewport=${_formatRect(viewportBounds)} '
      'source=${_sourceImageSize.width.toStringAsFixed(0)}x${_sourceImageSize.height.toStringAsFixed(0)} '
      'viewport=${_cameraViewportSize.width.toStringAsFixed(0)}x${_cameraViewportSize.height.toStringAsFixed(0)}',
    );
  }

  String _formatRect(Rect? rect) {
    if (rect == null || rect == Rect.zero) {
      return 'null';
    }
    return '[${rect.left.toStringAsFixed(3)},${rect.top.toStringAsFixed(3)},'
        '${rect.width.toStringAsFixed(3)},${rect.height.toStringAsFixed(3)}]';
  }

  bool? _extractBool(dynamic value) => value is bool ? value : null;

  int? _extractInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  double? _asDouble(dynamic v) => v is num ? v.toDouble() : null;
}
