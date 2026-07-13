// 舌诊扫描页。
// 保留现有扫描与上传逻辑，只整理页面结构与样式相关实现。

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/layout/app_layout.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/scan_session.dart';
import '../../data/models/scan_upload_result.dart';
import '../../data/sources/physique_question_remote_source.dart';
import '../../data/sources/scan_remote_source.dart';
import '../services/physique_question_flow_controller.dart';
import '../services/scan_capture_bridge.dart';
import '../services/tongue_scan_status_bridge.dart';
import '../utils/scan_capture_geometry.dart';
import '../utils/scan_failure_feedback.dart';
import '../utils/scan_upload_tenant_context.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/scan_step_indicator.dart';
import '../widgets/scan_status_button.dart';

part 'tongue_scan/tongue_scan_logic.dart';
part 'tongue_scan/tongue_scan_widgets.dart';

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
  ScanState _scanState = ScanState.idle;
  Size _cameraViewportSize = Size.zero;
  String _mouthDirection = ''; // 方向提示

  Size get _tongueGuideSize => AppLayoutMetrics.of(context).scanGuideSize(
    _cameraViewportSize,
    baseWidth: _tongueGuideWidth,
    baseHeight: _tongueGuideHeight,
    tabletPortraitScale: 1.18,
    tabletLandscapeScale: 1.28,
    maxHeightFraction: 0.46,
  );

  Rect get _tongueGuideRectNormalized => buildNormalizedGuideRect(
    _cameraViewportSize,
    alignment: _tongueGuideAlignment,
    guideWidth: _tongueGuideSize.width,
    guideHeight: _tongueGuideSize.height,
  );

  Rect _tongueAnalysisRectForStatus(TongueScanStatus status) {
    final faceBounds = _normalizedViewportBoundsForPoints(
      status.faceLandmarks,
      status,
    );
    final mouthBounds = _normalizedViewportBoundsForPoints(
      status.mouthLandmarks,
      status,
    );
    final mouthCenter =
        _normalizedViewportOffsetFromAnalysis(status.mouthCenter, status) ??
        mouthBounds?.center;
    return buildTongueAnalysisRect(
      guideRect: _tongueGuideRectNormalized,
      faceBounds: faceBounds,
      mouthBounds: mouthBounds,
      mouthCenter: mouthCenter,
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

  Rect? _normalizedViewportBoundsForPoints(
    List<Offset> points,
    TongueScanStatus status,
  ) {
    final bounds = normalizedBoundingRect(points);
    return _normalizedViewportRectFromAnalysis(bounds, status);
  }

  Rect? _normalizedViewportRectFromAnalysis(
    Rect? analysisRect,
    TongueScanStatus status,
  ) {
    if (analysisRect == null ||
        analysisRect == Rect.zero ||
        _cameraViewportSize.width <= 0 ||
        _cameraViewportSize.height <= 0) {
      return null;
    }

    final viewportRect = mapNormalizedRectToViewport(
      normalizedRect: analysisRect,
      viewportSize: _cameraViewportSize,
      imageSize: status.analysisImageSize,
      mirrored: status.mirrored == true,
    );
    if (viewportRect == Rect.zero) {
      return null;
    }

    return Rect.fromLTRB(
      viewportRect.left / _cameraViewportSize.width,
      viewportRect.top / _cameraViewportSize.height,
      viewportRect.right / _cameraViewportSize.width,
      viewportRect.bottom / _cameraViewportSize.height,
    );
  }

  Offset? _normalizedViewportOffsetFromAnalysis(
    Offset? analysisPoint,
    TongueScanStatus status,
  ) {
    if (analysisPoint == null) {
      return null;
    }

    final mappedRect = _normalizedViewportRectFromAnalysis(
      Rect.fromCenter(center: analysisPoint, width: 0.001, height: 0.001),
      status,
    );
    return mappedRect?.center;
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
    _cancelHoldTracking();
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
    final bounds = _normalizedViewportBoundsForPoints(
      status.mouthLandmarks,
      status,
    );
    final center =
        _normalizedViewportOffsetFromAnalysis(status.mouthCenter, status) ??
        bounds?.center;

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
        ? _computeMouthDirection(
            _normalizedViewportOffsetFromAnalysis(status.mouthCenter, status),
          )
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
        _cancelHoldTracking();
      }
      return;
    }
    if (canHold) {
      _startHoldTracking();
    } else {
      _cancelHoldTracking();
    }
  }

  void _logTongueUploadResponse(ScanTongueUploadResult response) {
    AppLogger.log(
      'Tongue upload response summary: '
      'stage=tongue '
      'path=/api/v1/saas/mobile/ai/diagnosis/upload '
      'analysisSuccess=${response.analysisSucceeded} '
      'hasTongue=${response.hasDetectedTongue} '
      'tongueReportSuccess=${response.tongueReportSucceeded} '
      'tongueReportIdEmpty=${response.reportId.isEmpty} '
      'imageId=${response.imageId.isEmpty ? "empty" : response.imageId} '
      'requestId=${response.requestId.isEmpty ? "empty" : response.requestId}',
    );
  }

  Future<void> _stopMonitoringBeforeTongueUpload() async {
    await _statusSubscription?.cancel();
    _statusSubscription = null;
    try {
      await _statusBridge.stopMonitoring();
    } on Object catch (error) {
      AppLogger.network('Tongue monitoring stop before upload failed: $error');
    }
  }

  Future<void> _resumeMonitoringAfterTongueUploadFailure() async {
    if (!mounted || _scanState != ScanState.scanning) {
      return;
    }
    try {
      await _subscribeAndStartMonitoring();
    } on Object catch (error) {
      AppLogger.network('Tongue monitoring resume after upload failed: $error');
    }
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
    });
  }

  Future<void> _captureAndUploadTongue() async {
    if (!mounted || _scanState == ScanState.uploading) {
      return;
    }
    final providerContainer = ProviderScope.containerOf(context, listen: false);

    setState(() {
      _scanState = ScanState.uploading;
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
        preferVisibleRegion: true,
      );
      if (!mounted) {
        return;
      }

      _logTongueCaptureDiagnostics(
        analysisRect: analysisRect,
        capture: capture,
      );

      await _stopMonitoringBeforeTongueUpload();
      if (!mounted) {
        return;
      }

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
      _scanSession.saveTenantContext(
        tenantId: uploadTenantContext.tenantId,
        topOrgId: uploadTenantContext.topOrgId,
        storeId: uploadTenantContext.storeId,
        clinicId: uploadTenantContext.clinicId,
      );

      final tongueUpload = await _scanRemoteSource.uploadTongue(
        imageFilePath: capture.croppedPath,
        faceUpload: faceUpload,
        tenantId: uploadTenantContext.tenantId,
        topOrgId: uploadTenantContext.topOrgId,
        storeId: uploadTenantContext.storeId,
        clinicId: uploadTenantContext.clinicId,
      );

      if (!mounted) {
        return;
      }

      _logTongueUploadResponse(tongueUpload);

      if (tongueUpload.analysisFailed) {
        _pauseAutoScanUntilReset = true;
        _cancelHoldTracking();
        setState(() {
          _scanState = ScanState.scanning;
        });
        showAppToast(context, '舌诊分析失败，请重新扫描。', kind: AppToastKind.info);
        await _resumeMonitoringAfterTongueUploadFailure();
        return;
      }

      if (tongueUpload.missingTongue) {
        _pauseAutoScanUntilReset = true;
        _cancelHoldTracking();
        setState(() {
          _scanState = ScanState.scanning;
        });
        showAppToast(context, '未检测到清晰舌象，请重新扫描。', kind: AppToastKind.info);
        await _resumeMonitoringAfterTongueUploadFailure();
        return;
      }

      if (!tongueUpload.hasGeneratedReport) {
        AppLogger.log(
          'Tongue report generation failed; stopping before palm scan. '
          'analysisSuccess=${tongueUpload.analysisSucceeded} '
          'hasTongue=${tongueUpload.hasDetectedTongue} '
          'tongueReportSuccess=${tongueUpload.tongueReportSucceeded} '
          'tongueReportIdEmpty=${tongueUpload.reportId.isEmpty} '
          'imageId=${tongueUpload.imageId.isEmpty ? "empty" : tongueUpload.imageId} '
          'requestId=${tongueUpload.requestId.isEmpty ? "empty" : tongueUpload.requestId} '
          'medicalCaseId=${tongueUpload.medicalCaseId ?? "empty"} '
          'hasContinuationContext=${tongueUpload.hasContinuationContext}',
        );
        _pauseAutoScanUntilReset = true;
        _cancelHoldTracking();
        setState(() {
          _scanState = ScanState.scanning;
        });
        showAppToast(context, '舌诊报告生成失败，请重新扫描。', kind: AppToastKind.info);
        await _resumeMonitoringAfterTongueUploadFailure();
        return;
      }

      _scanSession.saveTongueUpload(tongueUpload);
      unawaited(_prefetchQuestionnaireFirstQuestion(providerContainer));
      setState(() {
        _scanState = ScanState.completed;
      });
      await _navigateToPalmScan();
    } on Object catch (error, stackTrace) {
      AppLogger.log('Tongue scan submission failed: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      _pauseAutoScanUntilReset = true;
      _cancelHoldTracking();
      setState(() {
        _scanState = ScanState.scanning;
      });
      await _resumeMonitoringAfterTongueUploadFailure();
      if (!mounted) {
        return;
      }
      showScanFailureToast(
        context,
        stage: ScanFailureStage.tongue,
        error: error,
      );
    }
  }

  Future<void> _prefetchQuestionnaireFirstQuestion(
    ProviderContainer providerContainer,
  ) async {
    try {
      final controller = PhysiqueQuestionFlowController(
        remoteSource: PhysiqueQuestionRemoteSource(getIt<DioClient>()),
        scanSession: _scanSession,
        profileLoader: () =>
            loadPhysiqueQuestionProfileFromContainer(providerContainer),
      );
      await controller.ensureFirstQuestion(allowReadinessRetry: false);
    } on Object catch (error, stackTrace) {
      _scanSession.clearQuestionPrefetch();
      AppLogger.network(
        'Question prefetch after tongue upload failed: $error\n$stackTrace',
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

  void _cancelHoldTracking() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _lastHoldAliveAt = null;
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
    if (!_hasPermission) return l10n.scanCameraPermissionRequired;
    if (_mouthDirection.isNotEmpty) return _mouthDirection;
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
        final cy = constraints.maxHeight / 2 + constraints.maxHeight * 0.03;
        final radius = math.min(
          constraints.maxWidth * 0.36,
          constraints.maxHeight * 0.48,
        );
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
    final guideSize = _tongueGuideSize;
    final frameW = guideSize.width;
    final frameH = guideSize.height;
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

          // 状态气泡
          Positioned(
            bottom: -48,
            left: -40,
            right: -40,
            child: Center(
              child: _mouthDirection.isNotEmpty && !_holdEligible
                  ? _TongueDirectionPill(direction: _mouthDirection)
                  : (_scanState == ScanState.scanning &&
                            !_holdEligible &&
                            (_mouthPresent || !_hasPermission)
                        ? _StatusPill(
                            label: _statusLabel,
                            detected: _mouthPresent,
                          )
                        : const SizedBox.shrink()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard() {
    final l10n = context.l10n;
    final layout = AppLayoutMetrics.of(context);
    final sideInset = layout.centeredHorizontalInset(
      MediaQuery.sizeOf(context).width,
      maxContentWidth: layout.scanPanelMaxWidth,
      minHorizontalPadding: 16,
    );
    final bool canStart =
        _hasPermission &&
        _scanState != ScanState.scanning &&
        _scanState != ScanState.uploading;
    final bool isCompleted = _scanState == ScanState.completed;
    final primaryButtonLabel = _scanState == ScanState.uploading
        ? l10n.scanUploading
        : _scanState == ScanState.scanning
        ? l10n.scanScanning
        : isCompleted
        ? l10n.scanTongueCompleted
        : l10n.scanTongueStartButton;

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
                  busy:
                      _scanState == ScanState.scanning ||
                      _scanState == ScanState.uploading,
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
    required bool busy,
    VoidCallback? onTap,
    bool isNext = false,
  }) {
    return ScanStatusButton(
      label: label,
      enabled: enabled,
      busy: busy,
      completed: isNext,
      prominent: isNext,
      onTap: onTap,
      accent: _kAccent,
      accentLight: _kAccentLight,
      accentDark: const Color(0xFF1D5E40),
    );
  }
}
