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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/layout/app_layout.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/logger.dart';
import '../../data/models/scan_session.dart';
import '../../data/sources/physique_question_remote_source.dart';
import '../../data/sources/scan_remote_source.dart';
import '../services/physique_question_flow_controller.dart';
import '../services/palm_frame_renderer.dart';
import '../services/palm_scan_status_bridge.dart';
import '../services/scan_capture_bridge.dart';
import '../utils/scan_capture_geometry.dart';
import '../utils/scan_failure_feedback.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/hand_landmark_overlay.dart';
import '../widgets/scan_step_indicator.dart';
import '../widgets/scan_status_button.dart';

part 'palm_scan/palm_scan_logic.dart';
part 'palm_scan/palm_scan_widgets.dart';

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
  bool _handPresent = false;
  bool _readyToScan = false;
  bool _handStraight = false;
  String _gestureName = '';
  bool _isTransitioning = false;
  bool _pauseAutoScanUntilReset = false;
  PalmScanState _scanState = PalmScanState.idle;
  List<Offset> _handLandmarks = const [];
  Size? _imageSize;
  Size _cameraViewportSize = Size.zero;
  String _palmHint = ''; // 距离 / 方向提示

  bool get _shouldRenderHandOverlay => shouldRenderPalmOverlay(
    handLandmarks: _handLandmarks,
    imageSize: _imageSize,
  );

  Size get _palmGuideSize => AppLayoutMetrics.of(context).scanGuideSize(
    _cameraViewportSize,
    baseWidth: _palmGuideWidth,
    baseHeight: _palmGuideHeight,
    maxHeightFraction: 0.70,
  );

  Rect get _palmGuideRectNormalized => buildNormalizedGuideRect(
    _cameraViewportSize,
    alignment: _palmGuideAlignment,
    guideWidth: _palmGuideSize.width,
    guideHeight: _palmGuideSize.height,
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
        _scanState = PalmScanState.scanning;
        _handPresent = false;
        _readyToScan = false;
        _handStraight = false;
        _gestureName = '';
        _pauseAutoScanUntilReset = false;
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
          _gestureName = status.normalizedGestureName;
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
            _cancelHoldTracking();
          }
          return;
        }

        if (canHold) {
          _startHoldTracking();
        } else {
          _cancelHoldTracking();
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

      if (stopwatch.elapsedMilliseconds >=
          _requiredHoldDuration.inMilliseconds) {
        timer.cancel();
        _holdTimer = null;
        unawaited(_captureAndUploadPalm());
        return;
      }
    });
  }

  void _cancelHoldTracking() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _lastHoldAliveAt = null;
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
    });
    _lastHoldAliveAt = null;

    try {
      final uploadReportId = _scanSession.reportId?.trim();
      if (uploadReportId == null || uploadReportId.isEmpty) {
        throw const ScanUploadException(
          stage: 'palm',
          path: '/api/v1/saas/mobile/ai/diagnosis/upload/hand',
          message: '报告ID缺失，无法上传手诊。',
        );
      }

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

      final handFrameFilePath = await _buildPalmFrameUploadPath(
        capture: capture,
        captureGuideRect: captureGuideRect,
        normalizedLandmarks: captureLandmarks,
        mirrored: mirrored,
      );
      if (!mounted) {
        return;
      }

      await _scanRemoteSource.uploadPalm(
        handFilePath: capture.croppedPath,
        handFrameFilePath: handFrameFilePath,
        reportId: uploadReportId,
      );

      if (!mounted) {
        return;
      }

      _scanSession.saveReportId(uploadReportId);
      setState(() {
        _scanState = PalmScanState.completed;
      });
      await _navigateToQuestionnaireAfterPreparing();
    } on Object catch (error, stackTrace) {
      AppLogger.log('Palm scan submission failed: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      _pauseAutoScanUntilReset = true;
      _cancelHoldTracking();
      setState(() {
        _scanState = PalmScanState.scanning;
      });
      showScanFailureToast(context, stage: ScanFailureStage.palm, error: error);
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

  PhysiqueQuestionFlowController _buildQuestionFlowController(
    ProviderContainer providerContainer,
  ) {
    return PhysiqueQuestionFlowController(
      remoteSource: PhysiqueQuestionRemoteSource(getIt<DioClient>()),
      scanSession: _scanSession,
      profileLoader: () =>
          loadPhysiqueQuestionProfileFromContainer(providerContainer),
    );
  }

  Future<void> _prepareQuestionnaireBeforeNavigation() async {
    final providerContainer = ProviderScope.containerOf(context, listen: false);
    final controller = _buildQuestionFlowController(providerContainer);
    final existingPrefetch = _scanSession.questionPrefetchFuture;
    if (existingPrefetch != null) {
      try {
        await existingPrefetch;
        return;
      } on Object catch (error, stackTrace) {
        _scanSession.clearQuestionPrefetch();
        AppLogger.network(
          'Question prefetch before palm completion failed; retrying: '
          '$error\n$stackTrace',
        );
      }
    }

    try {
      await controller.ensureFirstQuestion(allowReadinessRetry: true);
    } on Object catch (error, stackTrace) {
      AppLogger.network(
        'Question prefetch before questionnaire navigation failed: '
        '$error\n$stackTrace',
      );
    }
  }

  Future<void> _navigateToQuestionnaireAfterPreparing() async {
    AppLogger.network(
      'Palm scan completed; navigating to questionnaire with context: '
      'reportId=${_scanSession.reportId?.trim().isNotEmpty == true ? _scanSession.reportId : "null"} '
      'tongueReportId=${_scanSession.tongueReportId ?? "null"} '
      'medicalCaseId=${_scanSession.medicalCaseId ?? "null"} '
      'gender=${_scanSession.detectedGender.isEmpty ? "empty" : _scanSession.detectedGender} '
      'age=${_scanSession.detectedAge ?? "null"} '
      'tenantId=${_scanSession.tenantId ?? "null"} '
      'storeId=${_scanSession.storeId ?? "null"}',
    );
    await _prepareQuestionnaireBeforeNavigation();
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
    if (_gestureName == 'Open_Palm' && !_handStraight) {
      return l10n.scanPalmOpenDetectedStraighten;
    }
    if (_handPresent) {
      return l10n.scanPalmStretchOpen;
    }
    return l10n.scanPalmAlignHint;
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
    final guideSize = _palmGuideSize;
    final frameW = guideSize.width;
    final frameH = guideSize.height;
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
              child: _scanState == PalmScanState.scanning && !_readyToScan
                  ? (_palmHint.isNotEmpty &&
                            !(_gestureName == 'Open_Palm' && !_handStraight)
                        ? _PalmDirectionPill(hint: _palmHint)
                        : _StatusPill(
                            label: _statusText(),
                            detected: _handPresent,
                          ))
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 底部提示卡 ─────────────────────────────────────────────────────

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
                  label: _scanState == PalmScanState.uploading
                      ? l10n.scanUploading
                      : _scanState == PalmScanState.completed
                      ? l10n.scanPalmViewingReportSoon
                      : l10n.scanScanning,
                  enabled: false,
                  busy:
                      _scanState == PalmScanState.scanning ||
                      _scanState == PalmScanState.uploading,
                  completed: _scanState == PalmScanState.completed,
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
    required bool busy,
    required bool completed,
    required VoidCallback onTap,
  }) {
    return ScanStatusButton(
      label: label,
      enabled: enabled,
      busy: busy,
      completed: completed,
      prominent: completed,
      onTap: onTap,
      accent: _kAccent,
      accentLight: _kAccentLight,
      accentDark: const Color(0xFF4B3E75),
    );
  }
}
