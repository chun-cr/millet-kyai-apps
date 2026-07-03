// 舌诊扫描页。
// 保留现有扫描与上传逻辑，只整理页面结构与样式相关实现。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/scan_session.dart';
import '../../data/models/scan_upload_result.dart';
import '../../data/sources/scan_remote_source.dart';
import '../services/scan_capture_bridge.dart';
import '../services/tongue_scan_status_bridge.dart';
import '../utils/scan_capture_geometry.dart';
import '../utils/scan_debug_error_dialog.dart';
import '../utils/scan_upload_tenant_context.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/scan_step_indicator.dart';

// 扫描状态枚举。
enum ScanState { idle, scanning, uploading, completed }

/// 只有“检测到伸舌 + 已确认伸舌 + 嘴部在框内”同时成立时，才允许开始计时。
bool isTongueHoldEligible({
  required bool protrusionCandidate,
  required bool protrusionConfirmed,
  required bool isFramed,
  required bool pauseAutoScanUntilReset,
}) {
  return protrusionCandidate &&
      protrusionConfirmed &&
      isFramed &&
      !pauseAutoScanUntilReset;
}

bool shouldKeepTongueHoldAlive({
  required bool protrusionCandidate,
  required bool protrusionConfirmed,
}) {
  return protrusionCandidate || protrusionConfirmed;
}

@visibleForTesting
/// 进入 hold 后允许短暂依赖 candidate/confirmed 保活，减少检测抖动带来的误重置。
bool shouldTrackTongueHold({
  required bool holdInProgress,
  required bool protrusionCandidate,
  required bool protrusionConfirmed,
  required bool isFramed,
  required bool pauseAutoScanUntilReset,
}) {
  if (!isFramed || pauseAutoScanUntilReset) {
    return false;
  }

  if (holdInProgress) {
    return shouldKeepTongueHoldAlive(
      protrusionCandidate: protrusionCandidate,
      protrusionConfirmed: protrusionConfirmed,
    );
  }

  return isTongueHoldEligible(
    protrusionCandidate: protrusionCandidate,
    protrusionConfirmed: protrusionConfirmed,
    isFramed: isFramed,
    pauseAutoScanUntilReset: pauseAutoScanUntilReset,
  );
}

@visibleForTesting
bool shouldShowTongueProgressFeedback({
  required ScanState scanState,
  required bool holdEligible,
}) {
  return scanState == ScanState.uploading ||
      scanState == ScanState.completed ||
      (scanState == ScanState.scanning && holdEligible);
}

@visibleForTesting
/// 视觉检测偶尔会丢一两帧，这里给一个极短宽限期，避免进度条频繁清零。
bool isTongueHoldAliveWithinGrace({
  required bool holdAliveNow,
  required bool holdInProgress,
  required DateTime? lastHoldAliveAt,
  required Duration gracePeriod,
  DateTime? now,
}) {
  if (holdAliveNow) {
    return true;
  }

  if (!holdInProgress || lastHoldAliveAt == null) {
    return false;
  }

  final referenceTime = now ?? DateTime.now();
  return referenceTime.difference(lastHoldAliveAt) <= gracePeriod;
}

/// 返回当前阻塞自动抓拍的原因，顺序同时作为 UI 提示优先级。
List<String> describeTongueScanBlockers({
  required bool mouthPresent,
  required bool protrusionCandidate,
  required bool protrusionConfirmed,
  required bool isFramed,
  required bool pauseAutoScanUntilReset,
}) {
  if (!mouthPresent) {
    return const ['mouth_missing'];
  }

  final blockers = <String>[];
  if (!protrusionConfirmed) {
    blockers.add(
      protrusionCandidate ? 'protrusion_unconfirmed' : 'protrusion_missing',
    );
  }
  if (!isFramed) {
    blockers.add('framing_failed');
  }
  if (pauseAutoScanUntilReset) {
    blockers.add('paused_after_failure');
  }

  return blockers.isEmpty ? const ['hold_ready'] : blockers;
}

const _kAccent = Color(0xFF0D7A5A); // 主强调色
const _kAccentLight = Color(0xFF3DAB78);
const _kBgColor = Color(0xFFF4F1EB); // 宣纸米色

class TongueScanPage extends StatefulWidget {
  const TongueScanPage({super.key});
  @override
  State<TongueScanPage> createState() => _TongueScanPageState();
}

class _TongueScanPageState extends State<TongueScanPage>
    with TickerProviderStateMixin {
  final TongueScanStatusBridge _statusBridge = TongueScanStatusBridge();
  late final ScanRemoteSource _scanRemoteSource;
  late final ScanSession _scanSession;
  final ScanCaptureBridge _captureBridge = ScanCaptureBridge();
  static const Duration _requiredHoldDuration = Duration(seconds: 2);
  static const Duration _holdInterruptionGracePeriod = Duration(
    milliseconds: 300,
  );
  static const Duration _postSuccessDelay = Duration(milliseconds: 450);
  static const Alignment _tongueGuideAlignment = Alignment(0, 0.32);
  static const double _tongueGuideWidth = 138;
  static const double _tongueGuideHeight = 164;

  late AnimationController _scanCtrl;
  late Animation<double> _scanAnim;
  late AnimationController _breatheCtrl;
  late Animation<double> _breatheAnim;
  StreamSubscription<TongueScanStatus>? _statusSubscription;
  Timer? _holdTimer;
  DateTime? _lastHoldAliveAt;
  TongueScanStatus _latestStatus = const TongueScanStatus(
    mouthLandmarkCount: 0,
  );

  bool _hasPermission = false;
  bool _cameraReady = false;
  bool _mouthPresent = false;
  bool _holdEligible = false;
  bool _stopMonitoringOnDispose = true;
  bool _pauseAutoScanUntilReset = false;
  double _scanProgress = 0;
  ScanState _scanState = ScanState.idle;
  Size _cameraViewportSize = Size.zero;
  String _mouthDirection = ''; // 方向提示

  Rect get _tongueGuideRectNormalized => buildNormalizedGuideRect(
    _cameraViewportSize,
    alignment: _tongueGuideAlignment,
    guideWidth: _tongueGuideWidth,
    guideHeight: _tongueGuideHeight,
  );

  Rect _tongueAnalysisRectForStatus(TongueScanStatus status) {
    return buildTongueAnalysisRect(
      guideRect: _tongueGuideRectNormalized,
      faceBounds: normalizedBoundingRect(status.faceLandmarks),
      mouthBounds: normalizedBoundingRect(status.mouthLandmarks),
      mouthCenter: status.mouthCenter,
    );
  }

  ScanCaptureGuide _captureGuideFromRect(Rect rect) {
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
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _scanAnim = Tween<double>(
      begin: 0.1,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));

    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _breatheAnim = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut));

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _requestPermission();
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (!status.isGranted) {
      return;
    }
    setState(() {
      _hasPermission = true;
      _scanState = ScanState.scanning;
      _mouthPresent = false;
      _holdEligible = false;
      _pauseAutoScanUntilReset = false;
      _scanProgress = 0;
      _mouthDirection = '';
      _latestStatus = const TongueScanStatus(mouthLandmarkCount: 0);
    });
    await _startMonitoringWhenReady();
  }

  Future<void> _startScan() async {
    if (!_hasPermission) {
      await _requestPermission();
      return;
    }
    _cancelHoldTracking(resetProgress: true);
    if (!mounted) return;
    setState(() {
      _scanState = ScanState.scanning;
      _mouthPresent = false;
      _holdEligible = false;
      _pauseAutoScanUntilReset = false;
      _mouthDirection = '';
      _latestStatus = const TongueScanStatus(mouthLandmarkCount: 0);
    });
    await _startMonitoringWhenReady();
  }

  Future<void> _startMonitoringWhenReady() async {
    if (!_cameraReady) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) {
        return;
      }
      setState(() => _cameraReady = true);

      final completer = Completer<void>();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          if (mounted) {
            await _subscribeAndStartMonitoring();
          }
          completer.complete();
        } on Object catch (error, stackTrace) {
          completer.completeError(error, stackTrace);
        }
      });
      await completer.future;
      return;
    }

    await _subscribeAndStartMonitoring();
  }

  Future<void> _subscribeAndStartMonitoring() async {
    await _statusSubscription?.cancel();
    _statusSubscription = _statusBridge.statusStream().listen(
      _handleStatusUpdate,
    );
    await _statusBridge.startMonitoring();
  }

  bool _isTongueFramedForUpload(TongueScanStatus status) {
    final guideRect = _tongueGuideRectNormalized;
    final bounds = normalizedBoundingRect(status.mouthLandmarks);
    final center = status.mouthCenter ?? bounds?.center;

    return bounds != null &&
        center != null &&
        guideRect != Rect.zero &&
        guideRect.contains(center) &&
        isNormalizedBoundsInsideGuide(
          bounds: bounds,
          guideRect: guideRect,
          guideInsetFactor: 0.02,
        );
  }

  void _handleStatusUpdate(TongueScanStatus status) {
    if (!mounted || _scanState == ScanState.uploading) return;
    _latestStatus = status;
    final isFramed = _isTongueFramedForUpload(status);
    final readyToCapture = status.protrusionConfirmed && isFramed;
    if (_pauseAutoScanUntilReset && !readyToCapture) {
      _pauseAutoScanUntilReset = false;
    }
    final canHold = isTongueHoldEligible(
      protrusionCandidate: status.protrusionCandidate,
      protrusionConfirmed: status.protrusionConfirmed,
      isFramed: isFramed,
      pauseAutoScanUntilReset: _pauseAutoScanUntilReset,
    );
    final holdAlive = shouldTrackTongueHold(
      holdInProgress: _holdTimer != null,
      protrusionCandidate: status.protrusionCandidate,
      protrusionConfirmed: status.protrusionConfirmed,
      isFramed: isFramed,
      pauseAutoScanUntilReset: _pauseAutoScanUntilReset,
    );
    final holdSignalActive =
        canHold || _isTongueHoldAliveWithinGrace(holdAliveNow: holdAlive);
    final direction = (status.mouthPresent && !canHold)
        ? _computeMouthDirection(status.mouthCenter)
        : '';

    setState(() {
      _mouthPresent = status.mouthPresent;
      _holdEligible = holdSignalActive;
      _mouthDirection = direction;
    });
    if (_scanState != ScanState.scanning) {
      return;
    }
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
  }

  void _logTongueUploadResponse(ScanTongueUploadResult response) {
    AppLogger.log(
      'Tongue upload response '
      'missingTongue=${response.missingTongue} '
      'reportId=${response.reportId.isEmpty ? "empty" : response.reportId} '
      'imageUrl=${response.imageUrl.isEmpty ? "empty" : response.imageUrl} '
      'analysisResult=${response.analysisResult} '
      'tongueReport=${response.tongueReport} '
      'raw=${response.data}',
    );
  }

  void _logTongueCaptureDiagnostics({
    required Rect analysisRect,
    required ScanCaptureResult capture,
  }) {
    String fixed(double value, [int digits = 3]) =>
        value.toStringAsFixed(digits);

    String formatRect(Rect rect) {
      return '[${fixed(rect.left)},${fixed(rect.top)},${fixed(rect.width)},${fixed(rect.height)}]';
    }

    final normalizedCropLeft = capture.sourceWidth <= 0
        ? 0.0
        : capture.cropLeft / capture.sourceWidth;
    final normalizedCropTop = capture.sourceHeight <= 0
        ? 0.0
        : capture.cropTop / capture.sourceHeight;
    final normalizedCropWidth = capture.sourceWidth <= 0
        ? 0.0
        : capture.cropWidth / capture.sourceWidth;
    final normalizedCropHeight = capture.sourceHeight <= 0
        ? 0.0
        : capture.cropHeight / capture.sourceHeight;
    final cropAspect = capture.cropHeight <= 0
        ? 0.0
        : capture.cropWidth / capture.cropHeight;
    final cropAreaRatio = (normalizedCropWidth * normalizedCropHeight).clamp(
      0.0,
      1.0,
    );

    AppLogger.log(
      'Tongue capture local '
      'stage=${capture.stage} '
      'source=${capture.sourceWidth.toStringAsFixed(0)}x${capture.sourceHeight.toStringAsFixed(0)} '
      'cropPx=[${capture.cropLeft.toStringAsFixed(1)},${capture.cropTop.toStringAsFixed(1)},${capture.cropWidth.toStringAsFixed(1)},${capture.cropHeight.toStringAsFixed(1)}] '
      'cropNorm=[${fixed(normalizedCropLeft)},${fixed(normalizedCropTop)},${fixed(normalizedCropWidth)},${fixed(normalizedCropHeight)}] '
      'cropAspect=${fixed(cropAspect)} '
      'cropArea=${fixed(cropAreaRatio)} '
      'analysisRect=${formatRect(analysisRect)} '
      'sourcePath=${capture.sourcePath} '
      'croppedPath=${capture.croppedPath} '
      'framePath=${capture.framePath}',
    );
  }

  /// 根据口部中心（归一化坐标 0~1）计算偏移方向。
  String _computeMouthDirection(Offset? center) {
    if (center == null) return '';
    final l10n = context.l10n;
    const threshold = 0.12;
    final dx = center.dx - 0.5;
    final dy = center.dy - 0.5;
    if (dx.abs() < threshold && dy.abs() < threshold) return '';
    if (dx.abs() >= dy.abs()) {
      return dx > 0 ? l10n.scanMoveLeft : l10n.scanMoveRight;
    } else {
      return dy > 0 ? l10n.scanMoveUp : l10n.scanMoveDown;
    }
  }

  bool _isTongueHoldAliveWithinGrace({required bool holdAliveNow}) {
    if (holdAliveNow) {
      _lastHoldAliveAt = DateTime.now();
      return true;
    }

    return isTongueHoldAliveWithinGrace(
      holdAliveNow: false,
      holdInProgress: _holdTimer != null,
      lastHoldAliveAt: _lastHoldAliveAt,
      gracePeriod: _holdInterruptionGracePeriod,
    );
  }

  void _startHoldTracking() {
    if (_holdTimer != null || _scanState != ScanState.scanning) return;
    _lastHoldAliveAt = DateTime.now();
    final stopwatch = Stopwatch()..start();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || _scanState != ScanState.scanning) {
        timer.cancel();
        _holdTimer = null;
        return;
      }
      final progress =
          stopwatch.elapsedMilliseconds / _requiredHoldDuration.inMilliseconds;
      if (progress >= 1) {
        timer.cancel();
        _holdTimer = null;
        unawaited(_captureAndUploadTongue());
        return;
      }
      setState(() => _scanProgress = mapHoldProgressToVisualProgress(progress));
    });
  }

  Future<void> _captureAndUploadTongue() async {
    if (!mounted || _scanState == ScanState.uploading) {
      return;
    }
    final providerContainer = ProviderScope.containerOf(context, listen: false);

    setState(() {
      _scanState = ScanState.uploading;
      _scanProgress = 0.65;
    });
    _lastHoldAliveAt = null;

    try {
      final analysisRect = _tongueAnalysisRectForStatus(_latestStatus);
      final capture = await _captureBridge.capture(
        target: ScanCaptureTarget.tongue,
        guide: _captureGuideFromRect(analysisRect),
        generationId: _latestStatus.generationId,
        landmarks: _latestStatus.faceLandmarks.isEmpty
            ? null
            : _latestStatus.faceLandmarks,
        analysisImageSize: _latestStatus.analysisImageSize == Size.zero
            ? null
            : _latestStatus.analysisImageSize,
        isBackCamera: _latestStatus.isBackCamera,
        mirrored: _latestStatus.mirrored,
        timestampMs: _latestStatus.timestampMs,
      );
      if (!mounted) {
        return;
      }

      _logTongueCaptureDiagnostics(
        analysisRect: analysisRect,
        capture: capture,
      );

      setState(() => _scanProgress = 0.68);

      final faceUpload = _scanSession.faceUpload;
      if (faceUpload == null) {
        throw StateError('缺少面诊结果，请重新开始扫描。');
      }
      final uploadTenantContext =
          await loadScanUploadTenantContextFromContainer(providerContainer);
      if (!mounted) {
        return;
      }
      AppLogger.log(
        'Tongue upload tenant context: '
        '${describeScanUploadTenantContext(uploadTenantContext)}',
      );

      final tongueUpload = await _scanRemoteSource.uploadTongue(
        imageFilePath: capture.croppedPath,
        faceUpload: faceUpload,
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

      _logTongueUploadResponse(tongueUpload);

      if (tongueUpload.missingTongue) {
        _pauseAutoScanUntilReset = true;
        _cancelHoldTracking(resetProgress: true);
        setState(() {
          _scanState = ScanState.scanning;
        });
        showAppToast(context, '未检测到清晰舌象，请重新扫描。', kind: AppToastKind.info);
        return;
      }

      if (tongueUpload.reportId.isEmpty) {
        throw StateError('舌诊接口未返回 reportId。');
      }

      _scanSession.saveTongueUpload(tongueUpload);
      setState(() {
        _scanState = ScanState.completed;
        _scanProgress = 1;
      });
      await _navigateToPalmScan();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _pauseAutoScanUntilReset = true;
      _cancelHoldTracking(resetProgress: true);
      setState(() {
        _scanState = ScanState.scanning;
      });
      await showScanDebugErrorDialog(
        context,
        title: context.l10n.scanTongueUploadFailedTitle,
        error: error,
      );
    }
  }

  Future<void> _navigateToPalmScan() async {
    await Future<void>.delayed(_postSuccessDelay);
    if (!mounted) return;
    _stopMonitoringOnDispose = false;
    _statusSubscription?.cancel();
    _statusSubscription = null;
    await _statusBridge.stopMonitoring();
    if (!mounted) return;
    context.pushReplacement(AppRoutes.scanPalm);
  }

  void _cancelHoldTracking({required bool resetProgress}) {
    _holdTimer?.cancel();
    _holdTimer = null;
    _lastHoldAliveAt = null;
    if (resetProgress && mounted) {
      setState(() => _scanProgress = 0);
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _scanCtrl.dispose();
    _breatheCtrl.dispose();
    _statusSubscription?.cancel();
    _statusSubscription = null;
    if (_stopMonitoringOnDispose) {
      unawaited(_statusBridge.stopMonitoring());
    }
    super.dispose();
  }

  String get _statusLabel {
    final l10n = context.l10n;
    if (_scanState == ScanState.completed) return l10n.scanTongueCompleted;
    if (!_hasPermission) return l10n.scanCameraPermissionRequired;
    if (_scanState == ScanState.idle) return l10n.scanTongueTapToStart;
    if (_scanState == ScanState.uploading) return l10n.scanScanning;
    if (_holdEligible) return l10n.scanTongueDetectedHold;
    if (_mouthPresent) return l10n.scanTongueMouthDetected;
    return l10n.scanTongueAlignHint;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgColor,
      body: Stack(
        children: [
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
          // 椤舵爮
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
                  child: Center(child: ScanStepIndicator(currentStep: 1)),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.flip_camera_ios,
                    size: 22,
                    color: Color(0xFF3A3028),
                  ),
                  tooltip: l10n.scanToggleCamera,
                  onPressed: _hasPermission && _scanState != ScanState.uploading
                      ? () {
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
          // 标题行。
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F7F1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kAccent.withValues(alpha: 0.15)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.sentiment_satisfied_alt_outlined,
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
                              '2',
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
                            l10n.scanTongueTitle,
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
                              l10n.scanTongueTag,
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
                        l10n.scanTongueSubtitle,
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
              color: const Color(0xFFE4F7F1).withValues(alpha: 0.6),
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
                  l10n.scanTongueDetail,
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

  Widget _buildCameraArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        _cameraViewportSize = constraints.biggest;
        final cx = constraints.maxWidth / 2;
        final tongueFrameAlignmentY = _tongueGuideAlignment.y;
        // 将圆形相机视口略微下移，给口鼻区域留出更自然的位置。
        final cy = constraints.maxHeight / 2 + constraints.maxHeight * 0.03;
        // 缩小圆形半径。
        final radius = constraints.maxWidth * 0.36;

        return Stack(
          children: [
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
                              color: _kAccentLight.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            Positioned.fill(
              child: _CircleMask(
                center: Offset(cx, cy),
                radius: radius,
                bgColor: _kBgColor,
              ),
            ),
            Align(
              alignment: Alignment(0, tongueFrameAlignmentY),
              child: _buildTongueFrame(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTongueFrame() {
    const frameW = 138.0;
    const frameH = 164.0;
    final isActive = _scanState == ScanState.scanning;
    final isCompleted = _scanState == ScanState.completed;
    final isAligned = _holdEligible;

    final outerColor = const Color(0xFF7EC8A0);
    final innerColor = (isCompleted || isAligned)
        ? const Color(0xFF4CAF50)
        : const Color(0xFFE55D5D);

    return SizedBox(
      width: frameW,
      height: frameH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 外层容错轮廓。用于给用户更宽松的对齐参考区，避免轻微抖动就被判定为失败。
          Positioned.fill(
            child: CustomPaint(
              painter: _BionicTonguePainter(
                color: outerColor.withValues(alpha: 0.6),
                strokeWidth: 1.0,
                fillColor: outerColor.withValues(alpha: 0.05),
                scale: 1.06,
              ),
            ),
          ),

          Positioned.fill(
            child: AnimatedBuilder(
              animation: _breatheAnim,
              builder: (context, child) {
                final opacity = (!isAligned && !isCompleted)
                    ? _breatheAnim.value
                    : 1.0;
                final haloProgress = isCompleted ? 1.0 : 0.0;

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: haloProgress.toDouble()),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, haloVal, _) {
                    return Opacity(
                      opacity: opacity,
                      child: CustomPaint(
                        painter: _BionicTonguePainter(
                          color: innerColor,
                          strokeWidth: 1.5,
                          scale: 0.92,
                          drawNodes: isAligned || isCompleted,
                          nodeSize: (isAligned && !isCompleted) ? 6.0 : 4.0,
                          haloOpacity: haloVal,
                          haloColor: const Color(0xFF7EC8A0),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 扫描线。只在扫描过程中移动，用来强化“正在采集中”的视觉反馈。
          AnimatedBuilder(
            animation: _scanAnim,
            builder: (context, child) => Positioned(
              top: _scanAnim.value * frameH,
              left: 14,
              right: 14,
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      innerColor.withValues(alpha: isActive ? 0.85 : 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 进度条（底部）
          if (shouldShowTongueProgressFeedback(
            scanState: _scanState,
            holdEligible: _holdEligible,
          ))
            Positioned(
              bottom: -66,
              left: frameW * 0.2,
              right: frameW * 0.2,
              child: _ScanProgressBar(progress: _scanProgress),
            ),

          // 状态气泡
          Positioned(
            bottom: -48,
            left: -40,
            right: -40,
            child: Center(
              child: _mouthDirection.isNotEmpty && !_holdEligible
                  ? _TongueDirectionPill(direction: _mouthDirection)
                  : _StatusPill(
                      label: _statusLabel,
                      detected:
                          _holdEligible || (_scanState == ScanState.completed),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard() {
    final l10n = context.l10n;
    final bool canStart =
        _hasPermission &&
        _scanState != ScanState.scanning &&
        _scanState != ScanState.uploading;
    final bool isCompleted = _scanState == ScanState.completed;
    final primaryButtonLabel =
        (_scanState == ScanState.scanning || _scanState == ScanState.uploading)
        ? l10n.scanScanning
        : isCompleted
        ? l10n.scanTongueCompleted
        : l10n.scanTongueStartButton;

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
          // 提示行。集中展示光线、饮食和舌面姿态等采集前注意事项。
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
                  icon: Icons.no_food_outlined,
                  label: l10n.scanTongueTipNoColoredFood,
                ),
                _TipItem(
                  icon: Icons.waves_outlined,
                  label: l10n.scanTongueTipTongueFlat,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _kAccent.withValues(alpha: 0.08)),
          // 按钮区。负责承载开始扫描和完成后的主要动作入口。
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              children: [
                _buildPrimaryButton(
                  label: primaryButtonLabel,
                  enabled: canStart && !isCompleted,
                  onTap: () => unawaited(_startScan()),
                  isNext: isCompleted,
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
    VoidCallback? onTap,
    bool isNext = false,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  colors: isNext
                      ? const [Color(0xFF1D5E40), _kAccent, _kAccentLight]
                      : const [Color(0xFF1D5E40), _kAccent, _kAccentLight],
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

class _ScanProgressBar extends StatelessWidget {
  final double progress;
  const _ScanProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Container(
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFE88080).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      FractionallySizedBox(
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE88080), Color(0xFFFF6B6B)],
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE88080).withValues(alpha: 0.5),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

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
          color: const Color(0xFFE4F7F1),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF0D7A5A).withValues(alpha: 0.15),
          ),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF0D7A5A)),
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
            ? const Color(0xFFE88080).withValues(alpha: 0.5)
            : const Color(0xFF0D7A5A).withValues(alpha: 0.25),
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
      style: TextStyle(
        color: detected
            ? const Color(0xFFE88080)
            : const Color(0xFF3A3028).withValues(alpha: 0.6),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
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

class _CircleMask extends StatelessWidget {
  final Offset center;
  final double radius;
  final Color bgColor;

  const _CircleMask({
    required this.center,
    required this.radius,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CircleMaskPainter(
        center: center,
        radius: radius,
        bgColor: bgColor,
      ),
    );
  }
}

class _CircleMaskPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color bgColor;

  _CircleMaskPainter({
    required this.center,
    required this.radius,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final maskPath = Path.combine(
      PathOperation.difference,
      fullPath,
      circlePath,
    );
    canvas.drawPath(maskPath, Paint()..color = bgColor); // 不透明边缘遮罩
  }

  @override
  bool shouldRepaint(_CircleMaskPainter old) =>
      old.center != center || old.radius != radius;
}

class _BionicTonguePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final Color? fillColor;
  final double scale;
  final bool drawNodes;
  final double nodeSize;
  final double haloOpacity;
  final Color haloColor;

  _BionicTonguePainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.fillColor,
    this.scale = 1.0,
    this.drawNodes = false,
    this.nodeSize = 4.0,
    this.haloOpacity = 0.0,
    this.haloColor = Colors.transparent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);
    canvas.translate(-cx, -cy);

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, h * 0.12);
    path.cubicTo(w * 0.65, h * 0.05, w * 0.85, h * 0.05, w * 0.9, h * 0.25);
    path.cubicTo(w * 0.95, h * 0.5, w * 0.9, h * 0.75, w * 0.75, h * 0.9);
    path.cubicTo(w * 0.6, h * 1.0, w * 0.4, h * 1.0, w * 0.25, h * 0.9);
    path.cubicTo(w * 0.1, h * 0.75, w * 0.05, h * 0.5, w * 0.1, h * 0.25);
    path.cubicTo(w * 0.15, h * 0.05, w * 0.35, h * 0.05, w * 0.5, h * 0.12);
    path.close();

    if (haloOpacity > 0) {
      final haloPaint = Paint()
        ..color = haloColor.withValues(alpha: haloOpacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawPath(path, haloPaint);
    }

    if (fillColor != null) {
      canvas.drawPath(path, Paint()..color = fillColor!);
    }

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    if (drawNodes) {
      final nodePaint = Paint()..color = color;
      final nodes = [
        Offset(w * 0.18, h * 0.18),
        Offset(w * 0.82, h * 0.18),
        Offset(w * 0.2, h * 0.8),
        Offset(w * 0.8, h * 0.8),
      ];
      for (final pt in nodes) {
        canvas.drawCircle(pt, nodeSize, nodePaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BionicTonguePainter old) => true;
}

class _TongueDirectionPill extends StatelessWidget {
  final String direction;
  const _TongueDirectionPill({required this.direction});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(direction),
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
          direction,
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
