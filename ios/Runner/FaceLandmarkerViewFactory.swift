// ═══════════════════════════════════════════════════════════════════
// 修复：pendingCommand 残留导致摄像头启动后立刻被 stopFace 停掉
//
// 问题还原（console 日志证实）：
//   Session started isRunning=true
//   Stopping session...        ← 不该在这里出现
//   Session stopped.
//
//   1. 面部扫描页 pop → face/stopDetection 到来，currentView 已 nil
//      → pendingCommand = .stopFace  ← 这里种下祸根
//   2. 舌头扫描页进入 → create() 建新 view → applyPendingCommand
//      执行 .stopFace → 刚启动的摄像头被停掉
//   3. tongue/startDetection 随后到来，session 已停，重启后
//      出现 start/stop/start 竞争，最终黑屏
//
// 修复逻辑：
//   stop 命令永远不存入 pendingCommand
//   → view 已释放时 stop 毫无意义，直接丢弃
//   → 只有 start 命令才需要 pending，等新 view 就绪后执行
//   AppDelegate 里对应把 stopFace/stopTongue 改调 performStop()
// ═══════════════════════════════════════════════════════════════════

import AVFoundation
import Flutter
import UIKit

final class FaceScanStatusStreamHandler: NSObject, FlutterStreamHandler {
    static let shared = FaceScanStatusStreamHandler()
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events; return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil; return nil
    }
    func publish(payload: [String: Any]) {
        DispatchQueue.main.async { self.eventSink?(payload) }
    }
}

final class TongueDetectionStreamHandler: NSObject, FlutterStreamHandler {
    static let shared = TongueDetectionStreamHandler()
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events; return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil; return nil
    }
    func publish(payload: [String: Any]) {
        DispatchQueue.main.async { self.eventSink?(payload) }
    }
}

// ─── FaceLandmarkerViewFactory ────────────────────────────────────
final class FaceLandmarkerViewFactory: NSObject, FlutterPlatformViewFactory {
    static let shared = FaceLandmarkerViewFactory()

    private(set) weak var currentView: NativeFaceScanView?
    var pendingCommand: PendingDetectionCommand?
    // 最近一次 face stop 命中的 view。用于阻止 tongue start 误打到即将销毁的旧 view。
    private var blockedTongueStartViewId: ObjectIdentifier?

    // ★ 只保留 start 类命令，stop 命令不再进入 pending 队列
    enum PendingDetectionCommand {
        case startFace
        case startTongue
        case startGesture

        func apply(to view: NativeFaceScanView) {
            switch self {
            case .startFace:   view.startFaceDetection()
            case .startTongue: view.startTongueDetection()
            case .startGesture: view.startGestureDetection()
            }
        }
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        let platformView = NativeFaceScanPlatformView(frame: frame)
        currentView = platformView.nativeView
        applyPendingCommand(for: platformView.nativeView)
        return platformView
    }

    // start 命令入口：view 不存在时暂存
    func perform(_ command: PendingDetectionCommand) {
        DispatchQueue.main.async {
            if let view = self.currentView, view.window != nil {
                if case .startTongue = command,
                   self.blockedTongueStartViewId == ObjectIdentifier(view) {
                    // face -> tongue 跳转窗口内，若 currentView 仍是刚 stop 过的旧 face view，
                    // 则不要立刻执行，转为 pending，等待新 view attach 后再 apply。
                    self.pendingCommand = command
                    return
                }
                command.apply(to: view)
            } else {
                self.pendingCommand = command
            }
        }
    }

    // ★ stop 命令独立入口：view 不存在直接丢弃，不写入 pendingCommand
    func performStop(mode: String) {
        DispatchQueue.main.async {
            // 顺手清掉同类型的残留 start pending，防止 stop 之后
            // 新 view 进来把旧 start 重新触发
            if mode == "face" {
                if case .startFace = self.pendingCommand { self.pendingCommand = nil }
            } else if mode == "tongue" {
                if case .startTongue = self.pendingCommand { self.pendingCommand = nil }
            } else if mode == "gesture" {
                if case .startGesture = self.pendingCommand { self.pendingCommand = nil }
            }

            guard let view = self.currentView, view.window != nil else {
                print("FaceLandmarkerViewFactory: stop ignored, no active view")
                return
            }

            if mode == "face" {
                self.blockedTongueStartViewId = ObjectIdentifier(view)
                view.stopFaceDetection()
            } else if mode == "tongue" {
                view.stopTongueDetection()
            } else if mode == "gesture" {
                view.stopGestureDetection()
            }
        }
    }

    func applyPendingCommand(for view: NativeFaceScanView) {
        DispatchQueue.main.async {
            guard self.currentView === view,
                  view.window != nil,
                  let command = self.pendingCommand else { return }
            self.pendingCommand = nil
            command.apply(to: view)
            if case .startTongue = command {
                self.blockedTongueStartViewId = nil
            }
        }
    }
}

// ─── NativeFaceScanPlatformView ───────────────────────────────────
final class NativeFaceScanPlatformView: NSObject, FlutterPlatformView {
    let nativeView: NativeFaceScanView
    init(frame: CGRect) {
        nativeView = NativeFaceScanView(frame: frame)
        super.init()
    }
    func view() -> UIView { nativeView }
}

// ─── NativeFaceScanView ───────────────────────────────────────────
final class NativeFaceScanView: UIView {
    private enum DetectionMode {
        case idle
        case face
        case tongue
        case gesture
    }

    private let cameraManager = CameraManager.shared
    private var faceLandmarkerService: FaceLandmarkerService?
    private let overlayView = FaceOverlayView()
    private var activeMode: DetectionMode = .idle
    private var pendingMode: DetectionMode?
    private var isTransitioning = false
    private var transitionTargetMode: DetectionMode?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        cameraManager.delegate = self
        overlayView.backgroundColor = .clear
        overlayView.isUserInteractionEnabled = false
        addSubview(overlayView)
        cameraManager.attachPreview(to: self)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        cameraManager.layoutPreview(in: bounds)
        overlayView.frame = bounds
        FaceLandmarkerViewFactory.shared.applyPendingCommand(for: self)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        FaceLandmarkerViewFactory.shared.applyPendingCommand(for: self)
    }

    func startFaceDetection() {
        transition(to: .face)
    }

    func stopFaceDetection() {
        stop(mode: .face)
    }

    func startTongueDetection() {
        transition(to: .tongue)
    }

    func stopTongueDetection() {
        stop(mode: .tongue)
    }

    func startGestureDetection() {
        transition(to: .gesture)
    }

    func stopGestureDetection() {
        stop(mode: .gesture)
    }

    func capturePhoto(onSuccess: @escaping (String) -> Void, onError: @escaping (String) -> Void) {
        cameraManager.capturePhoto { path in
            DispatchQueue.main.async {
                if let path = path {
                    onSuccess(path)
                } else {
                    onError("Photo capture failed")
                }
            }
        }
    }

    func captureVisibleRegion(
        stage: String,
        normalizedRect: CGRect,
        onSuccess: @escaping ([String: Any]) -> Void,
        onError: @escaping (String) -> Void
    ) {
        cameraManager.captureVisibleRegion(
            stage: stage,
            normalizedRect: normalizedRect,
            onSuccess: onSuccess,
            onError: onError
        )
    }

    private func stop(mode: DetectionMode) {
        if activeMode == mode {
            transition(to: .idle)
            return
        }

        if isTransitioning && transitionTargetMode == mode {
            pendingMode = .idle
        }
    }

    private func transition(to nextMode: DetectionMode) {
        DispatchQueue.main.async {
            if self.isTransitioning {
                self.pendingMode = nextMode
                return
            }
            if self.activeMode == nextMode {
                return
            }

            self.isTransitioning = true
            let currentMode = self.activeMode
            self.transitionTargetMode = nextMode
            self.activeMode = .idle
            self.deactivate(currentMode) {
                self.activate(nextMode)
            }
        }
    }

    private func deactivate(_ mode: DetectionMode, completion: @escaping () -> Void) {
        switch mode {
        case .idle:
            completion()

        case .face, .tongue:
            FaceScanStatusStreamHandler.shared.publish(payload: [
                "detected": false,
                "landmarks": [],
                "blendshapes": [:],
                "imageWidth": 0,
                "imageHeight": 0,
            ])
            TongueDetectionStreamHandler.shared.publish(
                payload: TongueDetectionEvaluator.Result.empty.payload)
            overlayView.draw(landmarks: [], imageSize: .zero)
            faceLandmarkerService?.close()
            faceLandmarkerService = nil
            completion()

        case .gesture:
            GestureRecognizerService.shared.stop()
            completion()
        }
    }

    private func activate(_ mode: DetectionMode) {
        switch mode {
        case .idle:
            print("CameraManager: transition -> idle, stopping session")
            cameraManager.stopSession { [weak self] in
                self?.finishTransition(to: .idle)
            }

        case .face, .tongue:
            let service = ensureFaceLandmarkerService()
            service.start()
            cameraManager.startSession(isBackCamera: false) { [weak self] in
                self?.finishTransition(to: mode)
            }

        case .gesture:
            overlayView.draw(landmarks: [], imageSize: .zero)
            GestureRecognizerService.shared.start()
            cameraManager.startSession(isBackCamera: true) { [weak self] in
                self?.finishTransition(to: .gesture)
            }
        }
    }

    private func finishTransition(to mode: DetectionMode) {
        activeMode = mode
        isTransitioning = false
        transitionTargetMode = nil

        if let next = pendingMode, next != mode {
            pendingMode = nil
            transition(to: next)
        } else {
            pendingMode = nil
        }
    }

    private func ensureFaceLandmarkerService() -> FaceLandmarkerService {
        if let existing = faceLandmarkerService {
            return existing
        }
        let service = FaceLandmarkerService()
        service.delegate = self
        faceLandmarkerService = service
        return service
    }

    deinit {
        faceLandmarkerService?.close()
        GestureRecognizerService.shared.stop()
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

extension UIImage {
    func normalizedImage() -> UIImage {
        if imageOrientation == .up {
            return self
        }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        format.opaque = false

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func cropped(toNormalizedRect normalizedRect: CGRect) -> UIImage? {
        guard let cgImage else {
            return nil
        }

        let pixelRect = CGRect(
            x: normalizedRect.origin.x * size.width * scale,
            y: normalizedRect.origin.y * size.height * scale,
            width: normalizedRect.width * size.width * scale,
            height: normalizedRect.height * size.height * scale
        ).integral

        guard
            pixelRect.width > 0,
            pixelRect.height > 0,
            let croppedCgImage = cgImage.cropping(to: pixelRect)
        else {
            return nil
        }

        return UIImage(
            cgImage: croppedCgImage,
            scale: scale,
            orientation: imageOrientation
        )
    }
}

extension NativeFaceScanView: CameraManagerDelegate {
    func didOutput(sampleBuffer: CMSampleBuffer) {
        switch activeMode {
        case .face, .tongue:
            faceLandmarkerService?.detectAsync(sampleBuffer: sampleBuffer)
        case .gesture:
            GestureRecognizerService.shared.detectAsync(sampleBuffer: sampleBuffer)
        case .idle:
            break
        }
    }
}

extension NativeFaceScanView: FaceLandmarkerServiceDelegate {
    func faceLandmarkerService(
        _ service: FaceLandmarkerService,
        didUpdate landmarks: [[String: Double]],
        blendshapes: [String: Double],
        tongueResult: TongueDetectionEvaluator.Result,
        imageSize: CGSize
    ) {
        let detected = !landmarks.isEmpty
        let facePayload: [String: Any] = [
            "detected": detected,
            "landmarks": landmarks,
            "blendshapes": blendshapes,
            "imageWidth": imageSize.width,
            "imageHeight": imageSize.height,
        ]
        if activeMode == .face {
            FaceScanStatusStreamHandler.shared.publish(payload: facePayload)
            let points = landmarks.map { CGPoint(x: $0["x"] ?? 0, y: $0["y"] ?? 0) }
            overlayView.draw(landmarks: points, imageSize: imageSize)
        } else {
            overlayView.draw(landmarks: [], imageSize: .zero)
        }
        if activeMode == .tongue {
            TongueDetectionStreamHandler.shared.publish(payload: tongueResult.payload)
        }
    }
}
