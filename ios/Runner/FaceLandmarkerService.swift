import Foundation
import UIKit
import AVFoundation
import MediaPipeTasksVision

protocol FaceLandmarkerServiceDelegate: AnyObject {
    // Normalized landmarks (0-1) + blendshapes for Flutter payload
    func faceLandmarkerService(
        _ service: FaceLandmarkerService,
        didUpdate landmarks: [[String: Double]],
        blendshapes: [String: Double],
        tongueResult: TongueDetectionEvaluator.Result,
        imageSize: CGSize
    )
}

final class FaceLandmarkerService: NSObject {
    private var faceLandmarker: FaceLandmarker?
    private var latestImageSize: CGSize = .zero
    weak var delegate: FaceLandmarkerServiceDelegate?

    private let workQueue = DispatchQueue(label: "com.example.stitch_diag_demo.facelandmarker")
    private var isInitializing = false
    private var isDetectionInFlight = false
    private var pendingSampleBuffer: CMSampleBuffer?

    override init() {
        super.init()
    }

    func start() {
        setupLandmarker()
    }

    private func setupLandmarker() {
        workQueue.async { [weak self] in
            guard let self = self, self.faceLandmarker == nil, !self.isInitializing else { return }
            self.isInitializing = true
            
            guard let modelPath = ModelAssetLocator.pathInBundle(name: "face_landmarker", ext: "task") else {
                assertionFailure("Missing face_landmarker.task in app bundle. Add it under assets/models/ and rebuild.")
                self.isInitializing = false
                return
            }

            let options = FaceLandmarkerOptions()
            options.runningMode = .liveStream
            options.numFaces = 1
            options.minFaceDetectionConfidence = 0.5
            options.minFacePresenceConfidence = 0.5
            options.minTrackingConfidence = 0.5
            options.faceLandmarkerLiveStreamDelegate = self
            options.outputFaceBlendshapes = true
            options.baseOptions.modelAssetPath = modelPath

            self.faceLandmarker = try? FaceLandmarker(options: options)
            self.isInitializing = false
        }
    }

    func detectAsync(sampleBuffer: CMSampleBuffer) {
        workQueue.async { [weak self] in
            guard let self = self else { return }

            if self.faceLandmarker == nil {
                self.setupLandmarker()
                return
            }

            self.pendingSampleBuffer = sampleBuffer
            self.processPendingSampleBufferIfNeeded()
        }
    }

    private func imageOrientationForCurrentDevice() -> UIImage.Orientation {
        // Since CameraManager already sets connection.videoOrientation = .portrait,
        // the buffer is delivered upright.
        // If mirroring is done by AVFoundation, we just pass .up.
        return .up
    }

    private func processPendingSampleBufferIfNeeded() {
        guard !isDetectionInFlight,
              let faceLandmarker = faceLandmarker,
              let sampleBuffer = pendingSampleBuffer else { return }

        pendingSampleBuffer = nil
        isDetectionInFlight = true

        let orientation = imageOrientationForCurrentDevice()
        guard let image = try? MPImage(sampleBuffer: sampleBuffer, orientation: orientation) else {
            isDetectionInFlight = false
            return
        }

        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            latestImageSize = CGSize(
                width: CVPixelBufferGetWidth(pixelBuffer),
                height: CVPixelBufferGetHeight(pixelBuffer)
            )
        }

        let timestampMs = Self.timestampInMilliseconds(for: sampleBuffer)
        do {
            try faceLandmarker.detectAsync(
                image: image,
                timestampInMilliseconds: timestampMs
            )
        } catch {
            print("FaceLandmarkerService: ❌ detectAsync threw: \(error)")
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

    func close() {
        faceLandmarker = nil
        pendingSampleBuffer = nil
        isDetectionInFlight = false
        isInitializing = false
    }
}

extension FaceLandmarkerService: FaceLandmarkerLiveStreamDelegate {
    func faceLandmarker(_ faceLandmarker: FaceLandmarker, didFinishDetection result: FaceLandmarkerResult?, timestampInMilliseconds: Int, error: Error?) {
        workQueue.async { [weak self] in
            guard let self = self else { return }
            self.isDetectionInFlight = false
            self.processPendingSampleBufferIfNeeded()
        }

        if let error = error {
            print("FaceLandmarker error: \(error)")
        }

        var landmarks: [[String: Double]] = []
        if let firstFace = result?.faceLandmarks.first {
            for lm in firstFace {
                landmarks.append([
                    "x": Double(lm.x),
                    "y": Double(lm.y),
                    "z": Double(lm.z)
                ])
            }
        }

        let blendshapes = result?.faceBlendshapes.first?.categories.reduce(into: [String: Double]()) { dict, category in
            dict[category.categoryName ?? ""] = Double(category.score)
        } ?? [:]

        let tongueResult = TongueDetectionEvaluator.evaluate(
            landmarks: result?.faceLandmarks.first,
            imageSize: latestImageSize,
            blendshapes: blendshapes
        )

        delegate?.faceLandmarkerService(
            self,
            didUpdate: landmarks,
            blendshapes: blendshapes,
            tongueResult: tongueResult,
            imageSize: latestImageSize
        )
    }
}
