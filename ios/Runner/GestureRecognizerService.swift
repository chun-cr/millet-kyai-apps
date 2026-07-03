import Foundation
import UIKit
import AVFoundation
import MediaPipeTasksVision
import Flutter

private func vectorAngle(_ v1: SIMD3<Double>, _ v2: SIMD3<Double>) -> Double {
    let dot = simd_dot(v1, v2)
    let mag1 = max(1e-6, simd_length(v1))
    let mag2 = max(1e-6, simd_length(v2))
    let cosValue = min(1.0, max(-1.0, dot / (mag1 * mag2)))
    return acos(cosValue) * 180 / .pi
}

private func pointDistance(_ a: NormalizedLandmark, _ b: NormalizedLandmark) -> Double {
    let dx = Double(a.x - b.x)
    let dy = Double(a.y - b.y)
    let dz = Double(a.z - b.z)
    return sqrt(dx * dx + dy * dy + dz * dz)
}

final class GestureStreamHandler: NSObject, FlutterStreamHandler {
    static let shared = GestureStreamHandler()

    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    func publish(payload: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(payload)
        }
    }
}

final class GestureRecognizerService: NSObject {
    static let shared = GestureRecognizerService()

    private static let openPalmScoreThreshold = 0.60
    private static let thumbAngleThreshold = 120.0
    private static let thumbIndexRatioThreshold = 1.03
    private static let thumbWristRatioThreshold = 1.02
    private static let fingerAngleThreshold = 145.0
    private static let minStraightDigits = 3

    private var recognizer: GestureRecognizer?
    private var consecutiveCount = 0

    private let workQueue = DispatchQueue(label: "com.example.stitch_diag_demo.gesturerecognizer")
    private var isInitializing = false
    private var isDetectionInFlight = false
    private var pendingSampleBuffer: CMSampleBuffer?
    private var latestImageSize: CGSize = .zero

    private override init() {
        super.init()
        print("GestureRecognizerService: init called")
        setupRecognizer()
    }

    private func setupRecognizer() {
        workQueue.async { [weak self] in
            guard let self = self, self.recognizer == nil, !self.isInitializing else {
                print("GestureRecognizerService: setupRecognizer skipped (recognizer=\(self?.recognizer != nil ? "exists" : "nil"), isInitializing=\(self?.isInitializing ?? false))")
                return
            }
            self.isInitializing = true
            
            guard let modelPath = ModelAssetLocator.pathInBundle(name: "gesture_recognizer", ext: "task") else {
                print("GestureRecognizerService: ❌ gesture_recognizer.task NOT FOUND in bundle")
                // Also check if the file exists via FileManager for diagnostics
                let bundlePath = Bundle.main.bundlePath
                print("GestureRecognizerService: main bundle path = \(bundlePath)")
                if let frameworks = Bundle.allFrameworks.first(where: { $0.bundlePath.contains("App.framework") }) {
                    print("GestureRecognizerService: App.framework path = \(frameworks.bundlePath)")
                    // List flutter_assets/assets/models/ contents for diagnostics
                    let modelsDir = frameworks.bundlePath + "/flutter_assets/assets/models"
                    if let contents = try? FileManager.default.contentsOfDirectory(atPath: modelsDir) {
                        print("GestureRecognizerService: models dir contents = \(contents)")
                    } else {
                        print("GestureRecognizerService: models dir not found or empty at \(modelsDir)")
                    }
                } else {
                    print("GestureRecognizerService: App.framework NOT FOUND in allFrameworks")
                }
                self.isInitializing = false
                return
            }

            print("GestureRecognizerService: ✅ Model found at: \(modelPath)")

            let options = GestureRecognizerOptions()
            options.runningMode = .liveStream
            options.numHands = 2
            options.minHandDetectionConfidence = 0.4
            options.minHandPresenceConfidence = 0.4
            options.minTrackingConfidence = 0.4
            options.gestureRecognizerLiveStreamDelegate = self
            options.baseOptions.modelAssetPath = modelPath

            do {
                self.recognizer = try GestureRecognizer(options: options)
                print("GestureRecognizerService: ✅ GestureRecognizer created successfully")
            } catch {
                self.recognizer = nil
                print("GestureRecognizerService: ❌ GestureRecognizer init FAILED: \(error)")
            }
            self.isInitializing = false
        }
    }

    func start() {
        print("GestureRecognizerService: start() called")
        setupRecognizer()
        consecutiveCount = 0
    }

    func stop() {
        print("GestureRecognizerService: stop() called")
        consecutiveCount = 0
        pendingSampleBuffer = nil
        isDetectionInFlight = false
        publishDetected(false, handStraight: false, name: "", score: 0, landmarks: [], imageSize: latestImageSize)
    }

    private var frameCount = 0

    private func handleResult(result: GestureRecognizerResult?) {
        frameCount += 1

        guard let result = result else {
            if frameCount % 30 == 0 {
                print("GestureRecognizerService: handleResult called with nil result (frame #\(frameCount))")
            }
            publishDetected(false, handStraight: false, name: "", score: 0, landmarks: [], imageSize: latestImageSize)
            return
        }

        let gesture = result.gestures.first?.first
        let gestureName = gesture?.categoryName ?? ""
        let score = Double(gesture?.score ?? 0)
        let normalizedGestureName = normalizeGestureName(gestureName)

        var landmarks: [[String: Double]] = []
        if let firstHand = result.landmarks.first {
            for lm in firstHand {
                landmarks.append([
                    "x": Double(lm.x),
                    "y": Double(lm.y),
                    "z": Double(lm.z)
                ])
            }
        }

        // Debug logging every 30 frames
        if frameCount % 30 == 0 {
            print("GestureRecognizerService: frame #\(frameCount) — gestures=\(result.gestures.count), landmarks=\(result.landmarks.count), name=\(gestureName), score=\(score), landmarkPoints=\(landmarks.count)")
        }

        let detectedByModel = normalizedGestureName == "OPENPALM" && score >= Self.openPalmScoreThreshold
        let handStraight = isStraightPalmByLandmarks(result.landmarks.first)
        let isOpenPalm = detectedByModel || handStraight
        if isOpenPalm {
            consecutiveCount += 1
        } else {
            consecutiveCount = 0
            publishDetected(false, handStraight: handStraight, name: gestureName, score: score, landmarks: landmarks, imageSize: latestImageSize)
            return
        }

        let detected = consecutiveCount >= 3
        let finalScore = detectedByModel ? score : (handStraight ? 0.75 : score)
        publishDetected(detected, handStraight: handStraight, name: "Open_Palm", score: finalScore, landmarks: landmarks, imageSize: latestImageSize)
    }

    private func isStraightPalmByLandmarks(_ landmarks: [NormalizedLandmark]?) -> Bool {
        guard let landmarks, landmarks.count >= 21 else { return false }

        let straightDigits = [
            isThumbExtended(landmarks),
            isFingerExtended(landmarks, mcp: 5, pip: 6, dip: 7, tip: 8),
            isFingerExtended(landmarks, mcp: 9, pip: 10, dip: 11, tip: 12),
            isFingerExtended(landmarks, mcp: 13, pip: 14, dip: 15, tip: 16),
            isFingerExtended(landmarks, mcp: 17, pip: 18, dip: 19, tip: 20),
        ].filter { $0 }.count

        return straightDigits >= Self.minStraightDigits
    }

    private func isThumbExtended(_ landmarks: [NormalizedLandmark]) -> Bool {
        let thumbAngle = angleBetween(
            landmarks[1],
            landmarks[2],
            landmarks[3],
            landmarks[4]
        )

        let tipToIndexMcp = pointDistance(landmarks[4], landmarks[5])
        let ipToIndexMcp = pointDistance(landmarks[3], landmarks[5])
        let tipToWrist = pointDistance(landmarks[4], landmarks[0])
        let mcpToWrist = pointDistance(landmarks[2], landmarks[0])

        return thumbAngle > Self.thumbAngleThreshold &&
            tipToIndexMcp > ipToIndexMcp * Self.thumbIndexRatioThreshold &&
            tipToWrist > mcpToWrist * Self.thumbWristRatioThreshold
    }

    private func isFingerExtended(
        _ landmarks: [NormalizedLandmark],
        mcp: Int,
        pip: Int,
        dip: Int,
        tip: Int
    ) -> Bool {
        let angle = angleBetween(
            landmarks[mcp],
            landmarks[pip],
            landmarks[dip],
            landmarks[tip]
        )
        return angle > Self.fingerAngleThreshold
    }

    private func angleBetween(
        _ a: NormalizedLandmark,
        _ b: NormalizedLandmark,
        _ c: NormalizedLandmark,
        _ d: NormalizedLandmark
    ) -> Double {
        let v1 = SIMD3<Double>(Double(a.x - b.x), Double(a.y - b.y), Double(a.z - b.z))
        let v2 = SIMD3<Double>(Double(c.x - b.x), Double(c.y - b.y), Double(c.z - b.z))
        let v3 = SIMD3<Double>(Double(d.x - c.x), Double(d.y - c.y), Double(d.z - c.z))

        let angle1 = vectorAngle(v1, v2)
        let angle2 = vectorAngle(v2, v3)
        return (angle1 + angle2) / 2
    }

    private func normalizeGestureName(_ name: String) -> String {
        return name.uppercased().replacingOccurrences(
            of: "[^A-Z]",
            with: "",
            options: .regularExpression
        )
    }

    private func publishDetected(_ detected: Bool, handStraight: Bool, name: String, score: Double, landmarks: [[String: Double]], imageSize: CGSize) {
        GestureStreamHandler.shared.publish(
            payload: [
                "gestureDetected": detected,
                "handStraight": handStraight,
                "gestureName": name,
                "score": score,
                "handLandmarks": landmarks,
                "imageWidth": Double(imageSize.width),
                "imageHeight": Double(imageSize.height)
            ]
        )
    }

    private func imageOrientationForCurrentDevice() -> UIImage.Orientation {
        let isFrontCamera = CameraManager.shared.currentPosition == .front
        // Force correct orientation for portrait-locked buffers from CameraManager
        return isFrontCamera ? .upMirrored : .up
    }

    private func processPendingSampleBufferIfNeeded() {
        guard !isDetectionInFlight,
              let recognizer = recognizer,
              let sampleBuffer = pendingSampleBuffer else { return }

        pendingSampleBuffer = nil
        isDetectionInFlight = true

        let orientation = imageOrientationForCurrentDevice()
        guard let image = try? MPImage(sampleBuffer: sampleBuffer, orientation: orientation) else {
            isDetectionInFlight = false
            return
        }

        latestImageSize = CGSize(width: image.width, height: image.height)

        let timestampMs = Self.timestampInMilliseconds(for: sampleBuffer)
        do {
            try recognizer.recognizeAsync(image: image, timestampInMilliseconds: timestampMs)
        } catch {
            print("GestureRecognizerService: ❌ recognizeAsync threw: \(error)")
            isDetectionInFlight = false
        }
    }


    private static func timestampInMilliseconds(for sampleBuffer: CMSampleBuffer) -> Int {
        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let seconds = CMTimeGetSeconds(presentationTime)
        if seconds.isFinite && seconds >= 0 {
            return Int(seconds * 1000)
        }
        return Int(Date().timeIntervalSince1970 * 1000)
    }
}

extension GestureRecognizerService {
    private static var detectLogCount = 0

    func detectAsync(sampleBuffer: CMSampleBuffer) {
        workQueue.async { [weak self] in
            guard let self = self else { return }

            GestureRecognizerService.detectLogCount += 1
            if GestureRecognizerService.detectLogCount % 60 == 1 {
                print("GestureRecognizerService: detectAsync frame #\(GestureRecognizerService.detectLogCount), recognizer=\(self.recognizer != nil ? "ready" : "nil"), isDetectionInFlight=\(self.isDetectionInFlight)")
            }

            if self.recognizer == nil {
                self.setupRecognizer()
                return
            }

            self.pendingSampleBuffer = sampleBuffer
            self.processPendingSampleBufferIfNeeded()
        }
    }
}

extension GestureRecognizerService: GestureRecognizerLiveStreamDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: GestureRecognizer,
        didFinishGestureRecognition result: GestureRecognizerResult?,
        timestampInMilliseconds: Int,
        error: Error?
    ) {
        workQueue.async { [weak self] in
            guard let self = self else { return }
            self.isDetectionInFlight = false
            self.processPendingSampleBufferIfNeeded()
        }

        if let error = error {
            print("GestureRecognizerService: ❌ delegate error: \(error)")
        }

        handleResult(result: result)
    }
}
