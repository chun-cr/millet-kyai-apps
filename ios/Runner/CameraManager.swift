import AVFoundation
import UIKit

protocol CameraManagerDelegate: AnyObject {
    func didOutput(sampleBuffer: CMSampleBuffer)
}

final class CameraManager: NSObject {
    static let shared = CameraManager()
    weak var delegate: CameraManagerDelegate?

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.example.stitch_diag_demo.camera.session")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var configured = false
    private(set) var currentPosition: AVCaptureDevice.Position = .front
    private var photoCompletion: ((Result<UIImage, Error>) -> Void)?

    private enum CameraCaptureError: LocalizedError {
        case sessionNotRunning
        case previewLayerUnavailable
        case previewBoundsEmpty
        case captureInProgress
        case invalidGuideRect
        case captureDataUnavailable
        case decodeFailed
        case cropFailed
        case encodeFailed
        case persistFailed(Error)

        var errorDescription: String? {
            switch self {
            case .sessionNotRunning:
                return "Camera session is not running"
            case .previewLayerUnavailable:
                return "Preview layer is unavailable"
            case .previewBoundsEmpty:
                return "Preview layer bounds are empty"
            case .captureInProgress:
                return "A camera capture is already in progress"
            case .invalidGuideRect:
                return "Capture guide rect is invalid"
            case .captureDataUnavailable:
                return "Photo capture returned no image data"
            case .decodeFailed:
                return "Failed to decode captured photo"
            case .cropFailed:
                return "Failed to crop captured photo"
            case .encodeFailed:
                return "Failed to encode captured photo"
            case .persistFailed(let error):
                return "Failed to persist captured photo: \(error.localizedDescription)"
            }
        }
    }

    private override init() {
        super.init()
    }

    func attachPreview(to view: UIView) {
        let layer: AVCaptureVideoPreviewLayer
        if let existingLayer = self.previewLayer {
            layer = existingLayer
            if layer.superlayer != view.layer {
                layer.removeFromSuperlayer()
                view.layer.insertSublayer(layer, at: 0)
            }
        } else {
            layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            view.layer.insertSublayer(layer, at: 0)
            self.previewLayer = layer
        }
        layer.frame = view.bounds
    }

    func layoutPreview(in bounds: CGRect) {
        previewLayer?.frame = bounds
    }

    func toggleCamera() {
        let newPosition: AVCaptureDevice.Position = currentPosition == .front ? .back : .front
        startSession(isBackCamera: newPosition == .back)
    }

    func startSession(isBackCamera: Bool = false, completion: (() -> Void)? = nil) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            let desiredPosition: AVCaptureDevice.Position = isBackCamera ? .back : .front

            if self.configured && self.currentPosition != desiredPosition {
                self.session.stopRunning()
                self.configured = false
            }

            self.currentPosition = desiredPosition
            self.configureSessionIfNeeded()

            if self.session.isRunning {
                print("CameraManager: Session already running.")
                if let completion {
                    DispatchQueue.main.async { completion() }
                }
                return
            }

            print("CameraManager: Starting session... (Position: \(self.currentPosition.rawValue))")
            self.session.startRunning()
            print("CameraManager: Session started isRunning=\(self.session.isRunning)")
            if let completion {
                DispatchQueue.main.async { completion() }
            }
        }
    }

    func stopSession(completion: (() -> Void)? = nil) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                print("CameraManager: Session already stopped.")
                if let completion {
                    DispatchQueue.main.async { completion() }
                }
                return
            }
            print("CameraManager: Stopping session...")
            self.session.stopRunning()
            print("CameraManager: Session stopped.")
            if let completion {
                DispatchQueue.main.async { completion() }
            }
        }
    }

    func capturePhoto(completion: @escaping (String?) -> Void) {
        captureStillImage { result in
            switch result {
            case .success(let image):
                let normalizedImage = image.normalizedImage()
                guard let imageData = normalizedImage.jpegData(compressionQuality: 0.92) else {
                    completion(nil)
                    return
                }

                let fileName = "tongue_\(Int(Date().timeIntervalSince1970)).jpg"
                let path = NSTemporaryDirectory() + fileName
                let url = URL(fileURLWithPath: path)

                do {
                    try imageData.write(to: url)
                    completion(path)
                } catch {
                    completion(nil)
                }
            case .failure:
                completion(nil)
            }
        }
    }

    func captureVisibleRegion(
        stage: String,
        normalizedRect: CGRect,
        onSuccess: @escaping ([String: Any]) -> Void,
        onError: @escaping (String) -> Void
    ) {
        DispatchQueue.main.async {
            let clampedRect = self.clampNormalizedRect(normalizedRect)
            guard !clampedRect.isEmpty else {
                onError(CameraCaptureError.invalidGuideRect.localizedDescription)
                return
            }
            guard let previewLayer = self.previewLayer else {
                onError(CameraCaptureError.previewLayerUnavailable.localizedDescription)
                return
            }

            let previewBounds = previewLayer.bounds
            guard previewBounds.width > 0, previewBounds.height > 0 else {
                onError(CameraCaptureError.previewBoundsEmpty.localizedDescription)
                return
            }

            let layerRect = CGRect(
                x: clampedRect.origin.x * previewBounds.width,
                y: clampedRect.origin.y * previewBounds.height,
                width: clampedRect.width * previewBounds.width,
                height: clampedRect.height * previewBounds.height
            )

            self.captureStillImage { result in
                switch result {
                case .success(let image):
                    let sourceImage = image.normalizedImage()
                    let captureRect = self.normalizedImageRect(
                        forLayerRect: layerRect,
                        previewBounds: previewBounds,
                        imageSize: sourceImage.size,
                        videoGravity: previewLayer.videoGravity
                    )
                    guard !captureRect.isEmpty else {
                        DispatchQueue.main.async {
                            onError(CameraCaptureError.cropFailed.localizedDescription)
                        }
                        return
                    }
                    guard let croppedImage = sourceImage.cropped(toNormalizedRect: captureRect) else {
                        DispatchQueue.main.async {
                            onError(CameraCaptureError.cropFailed.localizedDescription)
                        }
                        return
                    }
                    guard let sourceData = sourceImage.jpegData(compressionQuality: 0.92),
                          let cropData = croppedImage.jpegData(compressionQuality: 0.92) else {
                        DispatchQueue.main.async {
                            onError(CameraCaptureError.encodeFailed.localizedDescription)
                        }
                        return
                    }

                    let timestamp = Int(Date().timeIntervalSince1970 * 1000)
                    let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                    let sourceURL = tempDir.appendingPathComponent("\(stage)_source_\(timestamp).jpg")
                    let cropURL = tempDir.appendingPathComponent("\(stage)_crop_\(timestamp).jpg")
                    let pixelWidth = Double(sourceImage.cgImage?.width ?? Int(sourceImage.size.width * sourceImage.scale))
                    let pixelHeight = Double(sourceImage.cgImage?.height ?? Int(sourceImage.size.height * sourceImage.scale))

                    do {
                        try sourceData.write(to: sourceURL)
                        try cropData.write(to: cropURL)

                        let cropRect = CGRect(
                            x: captureRect.origin.x * pixelWidth,
                            y: captureRect.origin.y * pixelHeight,
                            width: captureRect.width * pixelWidth,
                            height: captureRect.height * pixelHeight
                        ).integral

                        DispatchQueue.main.async {
                            onSuccess([
                                "stage": stage,
                                "sourcePath": sourceURL.path,
                                "croppedPath": cropURL.path,
                                "framePath": sourceURL.path,
                                "sourceWidth": pixelWidth,
                                "sourceHeight": pixelHeight,
                                "cropLeft": cropRect.origin.x,
                                "cropTop": cropRect.origin.y,
                                "cropWidth": cropRect.size.width,
                                "cropHeight": cropRect.size.height,
                            ])
                        }
                    } catch {
                        DispatchQueue.main.async {
                            onError(CameraCaptureError.persistFailed(error).localizedDescription)
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        onError(error.localizedDescription)
                    }
                }
            }
        }
    }

    private func captureStillImage(completion: @escaping (Result<UIImage, Error>) -> Void) {
        sessionQueue.async {
            guard self.session.isRunning else {
                completion(.failure(CameraCaptureError.sessionNotRunning))
                return
            }
            guard self.photoCompletion == nil else {
                completion(.failure(CameraCaptureError.captureInProgress))
                return
            }

            self.photoCompletion = completion
            let settings = AVCapturePhotoSettings()
            self.configureConnection(self.photoOutput.connection(with: .video))
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    private func configureSessionIfNeeded() {
        guard !configured else { return }

        session.beginConfiguration()
        session.sessionPreset = .high

        defer {
            session.commitConfiguration()
        }

        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.currentPosition),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            return
        }

        session.addInput(input)

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        ]
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)

        session.addOutput(videoOutput)

        guard session.canAddOutput(photoOutput) else { return }
        session.addOutput(photoOutput)

        configureConnection(videoOutput.connection(with: .video))
        configured = true
    }

    private func configureConnection(_ connection: AVCaptureConnection?) {
        guard let connection else { return }
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = (currentPosition == .front)
        }
    }

    private func clampNormalizedRect(_ rect: CGRect) -> CGRect {
        let left = min(max(rect.minX, 0), 1)
        let top = min(max(rect.minY, 0), 1)
        let right = min(max(rect.maxX, 0), 1)
        let bottom = min(max(rect.maxY, 0), 1)

        guard right > left, bottom > top else {
            return .zero
        }

        return CGRect(x: left, y: top, width: right - left, height: bottom - top)
    }

    private func normalizedImageRect(
        forLayerRect layerRect: CGRect,
        previewBounds: CGRect,
        imageSize: CGSize,
        videoGravity: AVLayerVideoGravity
    ) -> CGRect {
        guard
            previewBounds.width > 0,
            previewBounds.height > 0,
            imageSize.width > 0,
            imageSize.height > 0
        else {
            return .zero
        }

        let widthScale = previewBounds.width / imageSize.width
        let heightScale = previewBounds.height / imageSize.height
        let scale: CGFloat

        switch videoGravity {
        case .resizeAspect:
            scale = min(widthScale, heightScale)
        case .resize:
            let rect = CGRect(
                x: layerRect.minX / previewBounds.width,
                y: layerRect.minY / previewBounds.height,
                width: layerRect.width / previewBounds.width,
                height: layerRect.height / previewBounds.height
            )
            return clampNormalizedRect(rect)
        default:
            scale = max(widthScale, heightScale)
        }

        guard scale > 0 else {
            return .zero
        }

        let displayedImageSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        let horizontalInset = (displayedImageSize.width - previewBounds.width) / 2
        let verticalInset = (displayedImageSize.height - previewBounds.height) / 2
        let imageRect = CGRect(
            x: (layerRect.minX + horizontalInset) / scale,
            y: (layerRect.minY + verticalInset) / scale,
            width: layerRect.width / scale,
            height: layerRect.height / scale
        )

        return clampNormalizedRect(
            CGRect(
                x: imageRect.minX / imageSize.width,
                y: imageRect.minY / imageSize.height,
                width: imageRect.width / imageSize.width,
                height: imageRect.height / imageSize.height
            )
        )
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        delegate?.didOutput(sampleBuffer: sampleBuffer)
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        sessionQueue.async {
            let completion = self.photoCompletion
            self.photoCompletion = nil

            if let error {
                completion?(.failure(error))
                return
            }
            guard let data = photo.fileDataRepresentation() else {
                completion?(.failure(CameraCaptureError.captureDataUnavailable))
                return
            }
            guard let image = UIImage(data: data) else {
                completion?(.failure(CameraCaptureError.decodeFailed))
                return
            }

            completion?(.success(image))
        }
    }
}
