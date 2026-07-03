import Foundation
import MediaPipeTasksVision

enum TongueDetectionEvaluator {
    // Use a symmetric outer-lip contour plus upper/lower lip centers.
    // The previous sparse set skewed to the subject's right side and biased
    // framing decisions, forcing users to move left before tongue upload started.
    private static let mouthIndices = [61, 146, 91, 181, 84, 17, 314, 405, 321, 375, 291, 13, 14]

    struct Result {
        let faceLandmarks: [[String: Double]]
        let mouthLandmarks: [[String: Double]]
        let mouthCenter: [String: Double]?
        let blendshapes: [String: Double]
        let imageWidth: Double
        let imageHeight: Double

        static let empty = Result(
            faceLandmarks: [],
            mouthLandmarks: [],
            mouthCenter: nil,
            blendshapes: [:],
            imageWidth: 0,
            imageHeight: 0
        )

        var payload: [String: Any] {
            [
                "faceLandmarks": faceLandmarks,
                "landmarks": faceLandmarks,
                "mouthLandmarks": mouthLandmarks,
                "mouthCenter": mouthCenter as Any,
                "blendshapes": blendshapes,
                "imageWidth": imageWidth,
                "imageHeight": imageHeight,
            ]
        }
    }

    static func evaluate(
        landmarks: [NormalizedLandmark]?,
        imageSize: CGSize,
        blendshapes: [String: Double] = [:]
    ) -> Result {
        guard let landmarks, !landmarks.isEmpty else {
            return .empty
        }

        let allLandmarks = landmarks.map {
            [
                "x": Double($0.x),
                "y": Double($0.y),
                "z": Double($0.z),
            ]
        }

        let mouthLandmarks = mouthIndices.compactMap { index -> [String: Double]? in
            guard landmarks.indices.contains(index) else {
                return nil
            }

            let landmark = landmarks[index]
            return [
                "x": Double(landmark.x),
                "y": Double(landmark.y),
                "z": Double(landmark.z),
            ]
        }

        guard !mouthLandmarks.isEmpty else {
            return Result(
                faceLandmarks: allLandmarks,
                mouthLandmarks: [],
                mouthCenter: nil,
                blendshapes: blendshapes,
                imageWidth: Double(imageSize.width),
                imageHeight: Double(imageSize.height)
            )
        }

        let center: [String: Double]
        if let leftCorner = landmarks[safe: 61],
           let rightCorner = landmarks[safe: 291],
           let upperLip = landmarks[safe: 13],
           let lowerLip = landmarks[safe: 14] {
            center = [
                "x": (Double(leftCorner.x) + Double(rightCorner.x)) / 2.0,
                "y": (Double(upperLip.y) + Double(lowerLip.y)) / 2.0,
                "z": (Double(upperLip.z) + Double(lowerLip.z)) / 2.0,
            ]
        } else {
            center = [
                "x": mouthLandmarks.map { $0["x"] ?? 0 }.reduce(0, +) / Double(mouthLandmarks.count),
                "y": mouthLandmarks.map { $0["y"] ?? 0 }.reduce(0, +) / Double(mouthLandmarks.count),
                "z": mouthLandmarks.map { $0["z"] ?? 0 }.reduce(0, +) / Double(mouthLandmarks.count),
            ]
        }

        return Result(
            faceLandmarks: allLandmarks,
            mouthLandmarks: mouthLandmarks,
            mouthCenter: center,
            blendshapes: blendshapes,
            imageWidth: Double(imageSize.width),
            imageHeight: Double(imageSize.height)
        )
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
