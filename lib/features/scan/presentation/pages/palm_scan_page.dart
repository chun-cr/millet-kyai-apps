// 扫描模块页面：`PalmScanPage`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

// ═══════════════════════════════════════════════════════════════════
// 修复说明（重做 UI 以匹配全站风格，并修复 ScanFrame 布局崩溃）
//
// UI 架构：三层分割
//   顶部引导卡  → 步骤指示器 + 标题 + 中医说明
//   中间拍摄区  → 相机预览 + 手掌轮廓引导
//   底部提示卡  → Tips + 操作按钮 + 跳过
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/logger.dart';
import '../../data/models/scan_session.dart';
import '../../data/sources/scan_remote_source.dart';
import '../services/palm_frame_renderer.dart';
import '../services/palm_scan_status_bridge.dart';
import '../services/scan_capture_bridge.dart';
import '../utils/scan_capture_geometry.dart';
import '../utils/scan_debug_error_dialog.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/hand_landmark_overlay.dart';
import '../widgets/scan_step_indicator.dart';

// ── 颜色（手掌用偏紫的藤萝色，兼容米色背景）
const _kAccent = Color(0xFF6B5B95); // 沉稳紫（主色）
const _kAccentLight = Color(0xFF9B8EF0); // 亮紫色（点缀）
const _kBgColor = Color(0xFFF4F1EB); // 宣纸米色

enum PalmScanState { idle, scanning, uploading, completed }

enum PalmScanFeedbackStage {
  waitingPermission,
  detecting,
  handDetected,
  readyToHold,
  completed,
}

@visibleForTesting
const Duration palmScanHoldDuration = Duration(milliseconds: 800);

@visibleForTesting
bool shouldRenderPalmOverlay({
  required List<Offset> handLandmarks,
  required Size? imageSize,
}) {
  return handLandmarks.length >= 21 &&
      imageSize != null &&
      imageSize.width > 0 &&
      imageSize.height > 0;
}

@visibleForTesting
bool shouldShowPalmHint({
  required bool handPresent,
  required List<Offset> handLandmarks,
  required Size? imageSize,
}) {
  return handPresent &&
      shouldRenderPalmOverlay(
        handLandmarks: handLandmarks,
        imageSize: imageSize,
      );
}

@visibleForTesting
bool isPalmHoldEligible({
  required bool handPresent,
  required bool readyToScan,
  required bool isFramed,
  required bool pauseAutoScanUntilReset,
}) {
  return handPresent && readyToScan && isFramed && !pauseAutoScanUntilReset;
}

@visibleForTesting
bool shouldTrackPalmHold({
  required bool holdInProgress,
  required bool handPresent,
  required bool readyToScan,
  required bool isFramed,
  required bool isRelaxedFramed,
  required bool pauseAutoScanUntilReset,
}) {
  if (pauseAutoScanUntilReset || !handPresent) {
    return false;
  }

  if (holdInProgress) {
    return readyToScan;
  }

  return isPalmHoldEligible(
    handPresent: handPresent,
    readyToScan: readyToScan,
    isFramed: isRelaxedFramed,
    pauseAutoScanUntilReset: pauseAutoScanUntilReset,
  );
}

@visibleForTesting
bool isPalmFramedForUploadBounds({
  required Rect bounds,
  required Rect guideRect,
  required bool allowHoldDrift,
}) {
  final area = normalizedRectArea(bounds);
  final minArea = allowHoldDrift ? 0.04 : 0.05;
  final maxArea = allowHoldDrift ? 0.40 : 0.32;
  final guideInsetFactor = allowHoldDrift ? 0.0 : 0.02;

  return area >= minArea &&
      area <= maxArea &&
      isNormalizedBoundsInsideGuide(
        bounds: bounds,
        guideRect: guideRect,
        guideInsetFactor: guideInsetFactor,
      );
}

@visibleForTesting
PalmScanFeedbackStage resolvePalmScanFeedbackStage({
  required bool hasPermission,
  required bool isMonitoring,
  required bool handPresent,
  required bool readyToScan,
  required PalmScanState scanState,
}) {
  if (!hasPermission) {
    return PalmScanFeedbackStage.waitingPermission;
  }
  if (scanState == PalmScanState.completed) {
    return PalmScanFeedbackStage.completed;
  }
  if (readyToScan) {
    return PalmScanFeedbackStage.readyToHold;
  }
  if (handPresent) {
    return PalmScanFeedbackStage.handDetected;
  }
  if (isMonitoring) {
    return PalmScanFeedbackStage.detecting;
  }
  return PalmScanFeedbackStage.waitingPermission;
}

@visibleForTesting
bool shouldShowPalmProgressFeedback({
  required PalmScanState scanState,
  required bool readyToScan,
}) {
  return scanState == PalmScanState.uploading ||
      scanState == PalmScanState.completed ||
      (scanState == PalmScanState.scanning && readyToScan);
}

@visibleForTesting
List<Offset> remapPalmLandmarksToCaptureGuide({
  required Iterable<Offset> normalizedLandmarks,
  required Rect guideRect,
}) {
  if (guideRect.isEmpty || guideRect.width <= 0 || guideRect.height <= 0) {
    return const <Offset>[];
  }

  return normalizedLandmarks
      .map((point) {
        final dx = (point.dx - guideRect.left) / guideRect.width;
        final dy = (point.dy - guideRect.top) / guideRect.height;
        return Offset(dx, dy);
      })
      .toList(growable: false);
}

class PalmScanPage extends StatefulWidget {
  const PalmScanPage({super.key});
  @override
  State<PalmScanPage> createState() => _PalmScanPageState();
}

class _PalmScanPageState extends State<PalmScanPage>
    with SingleTickerProviderStateMixin {
  final PalmScanStatusBridge _statusBridge = PalmScanStatusBridge();
  late final ScanRemoteSource _scanRemoteSource;
  late final ScanSession _scanSession;
  final ScanCaptureBridge _captureBridge = ScanCaptureBridge();
  static const Duration _requiredHoldDuration = palmScanHoldDuration;
  static const Duration _holdInterruptionGracePeriod = Duration(
    milliseconds: 300,
  );
  static const Duration _postSuccessDelay = Duration(milliseconds: 450);
  static const Alignment _palmGuideAlignment = Alignment(0, -0.18);
  static const double _palmGuideWidth = 244;
  static const double _palmGuideHeight = 322;
  late AnimationController _scanCtrl;
  late Animation<double> _scanAnim;
  StreamSubscription<PalmScanStatus>? _statusSubscription;
  Timer? _holdTimer;
  DateTime? _lastHoldAliveAt;

  bool _hasPermission = false;
  bool _isBackCamera = true;
  bool _isMonitoring = false;
  bool _handPresent = false;
  bool _readyToScan = false;
  bool _handStraight = false;
  String _gestureName = '';
  bool _isTransitioning = false;
  bool _pauseAutoScanUntilReset = false;
  double _scanProgress = 0;
  PalmScanState _scanState = PalmScanState.idle;
  List<Offset> _handLandmarks = const [];
  Size? _imageSize;
  Size _cameraViewportSize = Size.zero;
  String _palmHint = ''; // 距离 / 方向提示

  bool get _shouldRenderHandOverlay => shouldRenderPalmOverlay(
    handLandmarks: _handLandmarks,
    imageSize: _imageSize,
  );

  Rect get _palmGuideRectNormalized => buildNormalizedGuideRect(
    _cameraViewportSize,
    alignment: _palmGuideAlignment,
    guideWidth: _palmGuideWidth,
    guideHeight: _palmGuideHeight,
  );

  ScanCaptureGuide get _palmCaptureGuide {
    final rect = buildPalmCaptureRect(
      guideRect: _palmGuideRectNormalized,
      handBounds: normalizedBoundingRect(_handLandmarks),
    );
    return ScanCaptureGuide(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
    );
  }

  @override
  void initState() {
    super.initState();
    initInjector();
    _scanRemoteSource = ScanRemoteSource(getIt<DioClient>());
    _scanSession = getIt<ScanSession>();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanAnim = Tween<double>(
      begin: 0.1,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _requestPermissionAndStart();
    });
  }

  Future<void> _requestPermissionAndStart() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
        _isMonitoring = true;
        _scanState = PalmScanState.scanning;
        _handPresent = false;
        _readyToScan = false;
        _handStraight = false;
        _gestureName = '';
        _pauseAutoScanUntilReset = false;
        _scanProgress = 0;
      });
      _statusSubscription?.cancel();
      _statusSubscription = _statusBridge.statusStream().listen((status) {
        if (!mounted) return;
        final strictlyFramed = _isPalmFramedForUpload(
          status,
          allowHoldDrift: false,
        );
        final relaxedFramed = _isPalmFramedForUpload(
          status,
          allowHoldDrift: true,
        );
        final strictReadyToCapture = status.readyToScan && strictlyFramed;
        if (_pauseAutoScanUntilReset && !strictReadyToCapture) {
          _pauseAutoScanUntilReset = false;
        }
        if (_scanState == PalmScanState.uploading) return;
        final canHold = shouldTrackPalmHold(
          holdInProgress: false,
          handPresent: status.handPresent,
          readyToScan: status.readyToScan,
          isFramed: strictlyFramed,
          isRelaxedFramed: relaxedFramed,
          pauseAutoScanUntilReset: _pauseAutoScanUntilReset,
        );
        final holdAlive = shouldTrackPalmHold(
          holdInProgress: _holdTimer != null,
          handPresent: status.handPresent,
          readyToScan: status.readyToScan,
          isFramed: strictlyFramed,
          isRelaxedFramed: relaxedFramed,
          pauseAutoScanUntilReset: _pauseAutoScanUntilReset,
        );
        final holdSignalActive =
            canHold ||
            (_holdTimer != null && _isPalmHoldAliveWithinGrace(holdAlive));
        setState(() {
          final nextImageSize = Size(status.imageWidth, status.imageHeight);
          _handPresent = status.handPresent;
          _readyToScan = holdSignalActive;
          _handStraight = status.handStraight;
          _gestureName = status.gestureName;
          _handLandmarks = status.landmarks;
          _imageSize = nextImageSize;
          _palmHint =
              shouldShowPalmHint(
                handPresent: status.handPresent,
                handLandmarks: status.landmarks,
                imageSize: nextImageSize,
              )
              ? _computePalmHint(status.landmarks)
              : '';
        });

        if (_scanState != PalmScanState.scanning) return;
        if (_holdTimer != null) {
          if (!holdSignalActive) {
            _cancelHoldTracking(resetProgress: true);
          }
          return;
        }

        if (canHold) {
          _startHoldTracking();
        } else {
          _cancelHoldTracking(resetProgress: true);
        }
      });
      unawaited(_statusBridge.startMonitoring());
    }
  }

  bool _isPalmFramedForUpload(
    PalmScanStatus status, {
    required bool allowHoldDrift,
  }) {
    final bounds = normalizedBoundingRect(status.landmarks);
    if (bounds == null) {
      return false;
    }

    return isPalmFramedForUploadBounds(
      bounds: bounds,
      guideRect: _palmGuideRectNormalized,
      allowHoldDrift: allowHoldDrift,
    );
  }

  bool _isPalmHoldAliveWithinGrace(bool holdAliveNow) {
    if (holdAliveNow) {
      _lastHoldAliveAt = DateTime.now();
      return true;
    }

    if (_holdTimer == null) {
      return false;
    }

    final lastHoldAliveAt = _lastHoldAliveAt;
    if (lastHoldAliveAt == null) {
      return false;
    }

    return DateTime.now().difference(lastHoldAliveAt) <=
        _holdInterruptionGracePeriod;
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _holdTimer?.cancel();
    // 只有彻底销毁时（如返回主页）才发指令停止，跳转时不发
    unawaited(_statusBridge.stopMonitoring());
    _scanCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigateToQuestionnaire() async {
    if (_isTransitioning || !mounted) return;
    _isTransitioning = true;
    _holdTimer?.cancel();
    _holdTimer = null;
    _statusSubscription?.cancel();
    _statusSubscription = null;
    _scanCtrl.stop();
    // 手掌是最后一步，这里可以考虑发停止
    unawaited(_statusBridge.stopMonitoring());
    context.go(AppRoutes.scanQuestionnaire);
  }

  void _startHoldTracking() {
    if (_holdTimer != null || _scanState != PalmScanState.scanning) return;
    _lastHoldAliveAt = DateTime.now();
    final stopwatch = Stopwatch()..start();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || _scanState != PalmScanState.scanning) {
        timer.cancel();
        _holdTimer = null;
        return;
      }

      final progress =
          stopwatch.elapsedMilliseconds / _requiredHoldDuration.inMilliseconds;
      if (progress >= 1) {
        timer.cancel();
        _holdTimer = null;
        unawaited(_captureAndUploadPalm());
        return;
      }

      setState(() => _scanProgress = mapHoldProgressToVisualProgress(progress));
    });
  }

  void _cancelHoldTracking({required bool resetProgress}) {
    _holdTimer?.cancel();
    _holdTimer = null;
    _lastHoldAliveAt = null;
    if (resetProgress && mounted) {
      setState(() => _scanProgress = 0);
    }
  }

  Future<void> _captureAndUploadPalm() async {
    if (!mounted || _scanState == PalmScanState.uploading) {
      return;
    }

    final captureGuide = _palmCaptureGuide;
    final captureGuideRect = Rect.fromLTWH(
      captureGuide.left,
      captureGuide.top,
      captureGuide.width,
      captureGuide.height,
    );
    final captureLandmarks = List<Offset>.unmodifiable(_handLandmarks);
    final captureImageSize = _imageSize;
    final mirrored = !_isBackCamera;

    setState(() {
      _scanState = PalmScanState.uploading;
      _scanProgress = 0.65;
    });
    _lastHoldAliveAt = null;

    try {
      final capture = await _captureBridge.capture(
        target: ScanCaptureTarget.palm,
        guide: captureGuide,
        landmarks: captureLandmarks,
        analysisImageSize:
            captureImageSize == null || captureImageSize == Size.zero
            ? null
            : captureImageSize,
        isBackCamera: _isBackCamera,
        mirrored: mirrored,
      );
      if (!mounted) {
        return;
      }

      setState(() => _scanProgress = 0.68);
      final handFrameFilePath = await _buildPalmFrameUploadPath(
        capture: capture,
        captureGuideRect: captureGuideRect,
        normalizedLandmarks: captureLandmarks,
        mirrored: mirrored,
      );
      if (!mounted) {
        return;
      }

      final reportId = _scanSession.reportId;
      if (reportId == null || reportId.isEmpty) {
        throw StateError('缺少 reportId，请重新开始扫描。');
      }

      await _scanRemoteSource.uploadPalm(
        handFilePath: capture.croppedPath,
        handFrameFilePath: handFrameFilePath,
        reportId: reportId,
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

      _scanSession.saveReportId(reportId);
      setState(() {
        _isMonitoring = false;
        _scanState = PalmScanState.completed;
        _scanProgress = 1;
      });
      await _navigateToQuestionnaireAfterDelay();
    } on Object catch (error, stackTrace) {
      AppLogger.log('Palm scan submission failed: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      _pauseAutoScanUntilReset = true;
      _cancelHoldTracking(resetProgress: true);
      setState(() {
        _scanState = PalmScanState.scanning;
      });
      await showScanDebugErrorDialog(context, title: '手掌上传失败', error: error);
    }
  }

  Future<String> _buildPalmFrameUploadPath({
    required ScanCaptureResult capture,
    required Rect captureGuideRect,
    required List<Offset> normalizedLandmarks,
    required bool mirrored,
  }) async {
    final overlayLandmarks = remapPalmLandmarksToCaptureGuide(
      normalizedLandmarks: normalizedLandmarks,
      guideRect: captureGuideRect,
    );
    final overlayImageSize = Size(capture.cropWidth, capture.cropHeight);
    AppLogger.log(
      'Rendering palm frame landmark overlay: '
      'landmarks=${overlayLandmarks.length}, '
      'mirrored=$mirrored, '
      'overlaySize=${capture.cropWidth.toStringAsFixed(0)}x'
      '${capture.cropHeight.toStringAsFixed(0)}',
    );
    return renderPalmFrameFile(
      sourceImagePath: capture.croppedPath,
      normalizedLandmarks: overlayLandmarks,
      analysisImageSize: overlayImageSize,
      mirrored: mirrored,
      targetMaxBytes: 450 * 1024,
    );
  }

  Future<void> _navigateToQuestionnaireAfterDelay() async {
    await Future<void>.delayed(_postSuccessDelay);
    await _navigateToQuestionnaire();
  }

  /// 根据手部 21 个 landmark 的包围盒大小判断距离，并检测中心偏移。
  /// 归一化坐标 (0~1).小 = 太远，大 = 太近。
  String _computePalmHint(List<Offset> lm) {
    if (lm.isEmpty) return '';
    final l10n = context.l10n;
    double minX = 1, maxX = 0, minY = 1, maxY = 0;
    for (final p in lm) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    final bboxW = maxX - minX;
    final bboxH = maxY - minY;
    final bboxArea = bboxW * bboxH;
    // 面积闾值：对觓线占自归一化画幅的比例
    if (bboxArea < 0.04) return l10n.scanPalmMoveCloser;
    if (bboxArea > 0.40) return l10n.scanPalmMoveFarther;
    // 居中检测
    final cx = (minX + maxX) / 2;
    final cy = (minY + maxY) / 2;
    const threshold = 0.15;
    final dx = cx - 0.5;
    final dy = cy - 0.5;
    if (dx.abs() >= dy.abs() && dx.abs() > threshold) {
      return dx > 0 ? l10n.scanMoveLeft : l10n.scanMoveRight;
    } else if (dy.abs() > threshold) {
      return dy > 0 ? l10n.scanMoveUp : l10n.scanMoveDown;
    }
    return '';
  }

  // ── 文案 ─────────────────────────────────────────────────────────

  String _statusText() {
    final l10n = context.l10n;
    if (!_hasPermission) return l10n.scanPalmWaitingPermission;
    if (_scanState == PalmScanState.completed) return l10n.scanPalmCompleted;
    if (_scanState == PalmScanState.uploading) return l10n.scanScanning;
    if (_readyToScan) return l10n.scanPalmReadyHold;
    if (_gestureName == 'Open_Palm' && !_handStraight) {
      return l10n.scanPalmOpenDetectedStraighten;
    }
    final localizedGesture = _localizedGestureName(_gestureName);
    if (localizedGesture.isNotEmpty) {
      return l10n.scanPalmDetectedGesture(localizedGesture);
    }
    if (_handPresent) {
      return l10n.scanPalmStretchOpen;
    }
    if (_isMonitoring) {
      return l10n.scanPalmAlignHint;
    }
    return l10n.scanPalmAlignHint;
  }

  String _localizedGestureName(String rawName) {
    final l10n = context.l10n;
    switch (rawName) {
      case 'Open_Palm':
        return l10n.scanGestureOpenPalm;
      case 'Closed_Fist':
        return l10n.scanGestureClosedFist;
      case 'Victory':
        return l10n.scanGestureVictory;
      case 'Thumb_Up':
        return l10n.scanGestureThumbUp;
      case 'Thumb_Down':
        return l10n.scanGestureThumbDown;
      case 'Pointing_Up':
        return l10n.scanGesturePointingUp;
      case 'ILoveYou':
        return l10n.scanGestureILoveYou;
      default:
        return rawName;
    }
  }

  // ─── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgColor,
      body: Stack(
        children: [
          // 背景画卷
          Positioned.fill(child: CustomPaint(painter: _BgPainter())),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildTopGuideCard(),
                Expanded(child: _buildCameraArea()),
                _buildBottomCard(),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 顶部引导卡 ─────────────────────────────────────────────────────

  Widget _buildTopGuideCard() {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kAccent.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
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
                  onPressed: () {
                    unawaited(_statusBridge.stopMonitoring());
                    context.pop();
                  },
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                const Expanded(
                  child: Center(child: ScanStepIndicator(currentStep: 2)),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.flip_camera_ios,
                    size: 22,
                    color: Color(0xFF3A3028),
                  ),
                  tooltip: l10n.scanToggleCamera,
                  onPressed:
                      _hasPermission && _scanState != PalmScanState.uploading
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
          Divider(height: 1, color: _kAccent.withValues(alpha: 0.08)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F0F7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kAccent.withValues(alpha: 0.15)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.pan_tool_outlined,
                        size: 26,
                        color: _kAccent,
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: const BoxDecoration(
                            color: _kAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '3',
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
                            l10n.scanPalmTitle,
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
                              color: _kAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              l10n.scanPalmTag,
                              style: TextStyle(
                                fontSize: 10,
                                color: _kAccent,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.scanPalmSubtitle,
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F0F7).withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 12,
                  color: _kAccent.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.scanPalmDetail,
                  style: TextStyle(
                    fontSize: 11,
                    color: _kAccent.withValues(alpha: 0.75),
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

  // ─── 中间拍摄区 ─────────────────────────────────────────────────────

  Widget _buildCameraArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        _cameraViewportSize = constraints.biggest;
        return Stack(
          children: [
            Positioned.fill(
              child: const CameraPreviewWidget(
                key: ValueKey('palm_camera_preview'),
              ),
            ),
            Positioned.fill(
              child: _shouldRenderHandOverlay
                  ? HandLandmarkOverlay(
                      normalizedLandmarks: _handLandmarks,
                      imageSize: _imageSize,
                      mirrored: !_isBackCamera,
                    )
                  : const SizedBox.shrink(),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _kBgColor.withValues(alpha: 0.55),
                      Colors.transparent,
                      Colors.transparent,
                      _kBgColor.withValues(alpha: 0.55),
                    ],
                    stops: const [0.0, 0.18, 0.78, 1.0],
                  ),
                ),
              ),
            ),
            Align(alignment: _palmGuideAlignment, child: _buildPalmFrame()),
          ],
        );
      },
    );
  }

  Widget _buildPalmFrame() {
    const frameW = 244.0;
    const frameH = 322.0;
    final highlightColor =
        (_readyToScan || _scanState == PalmScanState.completed)
        ? _kAccentLight
        : _kAccent.withValues(alpha: 0.45);

    return SizedBox(
      width: frameW,
      height: frameH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -10,
            left: -10,
            right: -10,
            bottom: -10,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: _kAccent.withValues(alpha: 0.03),
              ),
            ),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _TiltedPalmGuidePainter(
                  color: highlightColor,
                  accentColor: _kAccentLight,
                  isAligned:
                      _readyToScan || _scanState == PalmScanState.completed,
                  progress: _scanProgress,
                  scanLineT: _scanAnim.value,
                  handPresent: _shouldRenderHandOverlay,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -16,
            left: -40,
            right: -40,
            child: Center(
              child:
                  shouldShowPalmProgressFeedback(
                    scanState: _scanState,
                    readyToScan: _readyToScan,
                  )
                  ? _PalmHoldFeedback(
                      label: _scanState == PalmScanState.completed
                          ? context.l10n.scanPalmCompleted
                          : _scanState == PalmScanState.uploading
                          ? context.l10n.scanScanning
                          : context.l10n.scanPalmReadyHold,
                      progress: _scanProgress,
                    )
                  : (_palmHint.isNotEmpty &&
                            !(_gestureName == 'Open_Palm' && !_handStraight)
                        ? _PalmDirectionPill(hint: _palmHint)
                        : _StatusPill(
                            label: _statusText(),
                            detected:
                                _readyToScan ||
                                _scanState == PalmScanState.completed,
                          )),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 底部提示卡 ─────────────────────────────────────────────────────

  Widget _buildBottomCard() {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kAccent.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                  icon: Icons.pan_tool_outlined,
                  label: l10n.scanPalmTipFlatten,
                ),
                _TipItem(
                  icon: Icons.do_not_touch_outlined,
                  label: l10n.scanTipKeepSteady,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _kAccent.withValues(alpha: 0.08)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              children: [
                _buildPrimaryButton(
                  label: _scanState == PalmScanState.completed
                      ? l10n.scanPalmViewingReportSoon
                      : l10n.scanScanning,
                  enabled: false,
                  onTap: _navigateToQuestionnaire,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF4B3E75), _kAccent, _kAccentLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: enabled ? null : const Color(0xFFE0DDD8),
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: _kAccent.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? Colors.white : const Color(0xFF9A9590),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ── 共用小组件 ─────────────────────────────────────────────────────────────

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TipItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F0F7),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF6B5B95).withValues(alpha: 0.15),
          ),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF6B5B95)),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: const Color(0xFF3A3028).withValues(alpha: 0.6),
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool detected;
  const _StatusPill({required this.label, required this.detected});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: detected
            ? const Color(0xFF6B5B95).withValues(alpha: 0.5)
            : const Color(0xFF6B5B95).withValues(alpha: 0.25),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: detected
            ? const Color(0xFF6B5B95)
            : const Color(0xFF3A3028).withValues(alpha: 0.6),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

class _ScanProgressBar extends StatelessWidget {
  final double progress;
  const _ScanProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Container(
        height: 4,
        decoration: BoxDecoration(
          color: _kAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      FractionallySizedBox(
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kAccent, _kAccentLight]),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: _kAccent.withValues(alpha: 0.45), blurRadius: 6),
            ],
          ),
        ),
      ),
    ],
  );
}

class _PalmHoldFeedback extends StatelessWidget {
  final String label;
  final double progress;

  const _PalmHoldFeedback({required this.label, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusPill(label: label, detected: true),
        const SizedBox(height: 8),
        SizedBox(width: 132, child: _ScanProgressBar(progress: progress)),
      ],
    );
  }
}

class _TiltedPalmGuidePainter extends CustomPainter {
  final Color color;
  final Color accentColor;
  final bool isAligned;
  final double progress;
  final double scanLineT;
  // 新增：检测到手掌时隐藏轮廓，避免与 landmark 线条交叠
  final bool handPresent;

  const _TiltedPalmGuidePainter({
    required this.color,
    required this.accentColor,
    required this.isAligned,
    required this.progress,
    required this.scanLineT,
    this.handPresent = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // SVG 路径已含真实坐标（viewBox 451×511），
    // _buildRightPalmUpPath 内部完成缩放居中，无需再做 translate/rotate

    // ── 仅在未检测到手掌时绘制引导轮廓
    if (!handPresent) {
      final glowPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      final outlinePaint = Paint()
        ..color = color.withValues(alpha: isAligned ? 0.95 : 0.72)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final palmPath = _buildRightPalmUpPath(size);
      canvas.drawPath(palmPath, glowPaint);
      canvas.drawPath(palmPath, outlinePaint);
    }

    // ── 扫描线（未检测到手时显示，表示系统正在检测）
    if (!handPresent) {
      final scanY =
          size.height * 0.05 + size.height * 0.90 * scanLineT.clamp(0.0, 1.0);
      final scanPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            accentColor.withValues(alpha: isAligned ? 0.80 : 0.45),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, scanY - 1, size.width, 2))
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(size.width * 0.08, scanY),
        Offset(size.width * 0.92, scanY),
        scanPaint,
      );
    }

    // ── 扫描进度条（底部居中）
    if (progress > 0) {
      final barW = size.width * 0.60;
      final barX = (size.width - barW) / 2;
      final barY = size.height * 0.92;
      final progressPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW * progress.clamp(0.0, 1.0), 6),
          const Radius.circular(3),
        ),
        progressPaint,
      );
    }
  }

  /// 右手手心朝上的轮廓路径
  /// 从 Figma 导出的真实右手手心朝上 SVG 轮廓
  /// 原始 viewBox: 451 × 511，缩放居中后适配 canvas
  Path _buildRightPalmUpPath(Size size) {
    final p = Path();
    p.moveTo(16.07, 243.27);
    p.cubicTo(6.61, 242.67, 5.64, 249.29, 5.64, 249.29);
    p.lineTo(1.09, 263.51);
    p.lineTo(6.61, 273.07);
    p.lineTo(49.70, 301.51);
    p.lineTo(95.54, 330.69);
    p.lineTo(142.11, 357.12);
    p.lineTo(166.71, 399.72);
    p.lineTo(195.11, 430.84);
    p.lineTo(228.41, 468.42);
    p.lineTo(277.76, 503.68);
    p.lineTo(316.77, 508.98);
    p.lineTo(342.86, 493.91);
    p.lineTo(376.01, 468.97);
    p.lineTo(402.01, 459.76);
    p.lineTo(428.97, 444.19);
    p.lineTo(444.29, 414.48);
    p.lineTo(448.46, 341.37);
    p.lineTo(448.22, 284.71);
    p.lineTo(439.55, 207.42);
    p.lineTo(436.81, 176.55);
    p.lineTo(441.52, 142.53);
    p.lineTo(446.07, 128.31);
    p.lineTo(449.51, 118.21);
    p.lineTo(445.50, 111.25);
    p.cubicTo(440.66, 106.37, 436.64, 104.84, 426.66, 104.74);
    p.cubicTo(418.59, 106.26, 414.86, 108.21, 410.14, 114.28);
    p.cubicTo(397.62, 124.95, 393.77, 131.26, 390.70, 142.89);
    p.lineTo(384.78, 186.88);
    p.lineTo(374.32, 245.08);
    p.lineTo(343.44, 217.70);
    p.lineTo(326.87, 189.02);
    p.lineTo(317.84, 173.37);
    p.lineTo(289.29, 109.87);
    p.lineTo(251.65, 44.66);
    p.lineTo(231.57, 9.89);
    p.lineTo(219.46, 2.97);
    p.cubicTo(210.05, -0.43, 205.43, 0.55, 198.05, 6.06);
    p.cubicTo(190.80, 11.15, 188.06, 15.14, 187.55, 26.04);
    p.lineTo(211.64, 67.77);
    p.lineTo(239.41, 125.91);
    p.lineTo(257.15, 166.68);
    p.lineTo(272.71, 193.63);
    p.cubicTo(271.34, 204.60, 266.66, 206.09, 254.44, 204.17);
    p.lineTo(205.76, 119.85);
    p.cubicTo(187.16, 98.42, 177.57, 83.93, 161.02, 56.42);
    p.lineTo(142.45, 24.25);
    p.cubicTo(136.99, 19.67, 132.73, 18.25, 121.37, 17.88);
    p.cubicTo(111.74, 18.59, 108.26, 21.17, 103.97, 27.92);
    p.cubicTo(99.02, 31.61, 98.34, 35.82, 101.57, 47.86);
    p.lineTo(128.67, 94.80);
    p.lineTo(155.78, 141.75);
    p.lineTo(180.87, 185.21);
    p.lineTo(207.47, 231.29);
    p.cubicTo(208.50, 231.91, 209.56, 242.96, 197.81, 242.67);
    p.lineTo(151.87, 189.21);
    p.lineTo(103.78, 130.04);
    p.cubicTo(103.78, 130.04, 84.30, 103.20, 79.36, 97.77);
    p.cubicTo(74.41, 92.34, 70.25, 91.69, 60.29, 94.87);
    p.lineTo(48.38, 106.39);
    p.cubicTo(48.38, 106.39, 46.44, 116.04, 47.08, 122.21);
    p.cubicTo(48.49, 135.85, 64.64, 152.63, 64.64, 152.63);
    p.cubicTo(86.32, 180.82, 98.14, 196.49, 115.64, 222.88);
    p.lineTo(167.73, 289.01);
    p.cubicTo(166.88, 299.41, 163.69, 303.42, 154.49, 308.25);
    p.cubicTo(116.94, 292.59, 95.40, 282.75, 53.88, 258.53);
    p.lineTo(32.40, 245.43);
    p.cubicTo(32.40, 245.43, 25.54, 243.87, 16.07, 243.27);
    p.close();

    // 缩放并居中到 canvas
    const svgW = 451.0;
    const svgH = 511.0;
    final scale = math.min(size.width / svgW, size.height / svgH) * 0.98;
    final offsetX = (size.width - svgW * scale) / 2;
    final offsetY = (size.height - svgH * scale) / 2;
    final m = Matrix4.identity()
      ..translateByDouble(offsetX, offsetY, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
    return p.transform(m.storage);
  }

  @override
  bool shouldRepaint(covariant _TiltedPalmGuidePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isAligned != isAligned ||
        oldDelegate.progress != progress ||
        oldDelegate.scanLineT != scanLineT ||
        oldDelegate.handPresent != handPresent;
  }
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final topPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(1.2, -0.8),
        radius: 0.9,
        colors: [
          const Color(0xFF2D6A4F).withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), topPaint);
    final bottomPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-1.1, 1.3),
        radius: 0.85,
        colors: [
          const Color(0xFF6B5B95).withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bottomPaint);
    final sealPaint = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(size.width - 20, 60), 52, sealPaint);
    canvas.drawCircle(Offset(size.width - 20, 60), 42, sealPaint);
    final gridPaint = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.025)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── 手绘画笔：手掌轮廓引导图 ─────────────────────────────────────────────────────

// ── 手掌方向/距离提示气泡 ─────────────────────────────────────────────────────

class _PalmDirectionPill extends StatelessWidget {
  final String hint;
  const _PalmDirectionPill({required this.hint});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(hint),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFF8C42).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8C42).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          hint,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
