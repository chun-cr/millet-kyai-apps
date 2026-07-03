package com.millet.kyai.apps

import com.google.mediapipe.tasks.components.containers.NormalizedLandmark

object TongueDetectionUtils {
    // Use a symmetric outer-lip contour plus upper/lower lip centers.
    // The previous sparse set skewed to the subject's right side and biased
    // framing decisions, forcing users to move left before tongue upload started.
    private val mouthIndices = listOf(61, 146, 91, 181, 84, 17, 314, 405, 321, 375, 291, 13, 14)

    data class TongueResult(
        val mouthLandmarks: List<Map<String, Double>>,
        val mouthCenter: Map<String, Double>?,
    )

    fun evaluateTongue(
        landmarks: List<NormalizedLandmark>?,
    ): TongueResult {
        if (landmarks.isNullOrEmpty()) {
            return TongueResult(emptyList(), null)
        }

        val mouthLandmarks = mouthIndices.mapNotNull { index ->
            landmarks.getOrNull(index)?.let { landmark ->
                mapOf(
                    "x" to landmark.x().toDouble(),
                    "y" to landmark.y().toDouble(),
                    "z" to landmark.z().toDouble(),
                )
            }
        }

        val leftCorner = landmarks.getOrNull(61)
        val rightCorner = landmarks.getOrNull(291)
        val upperLip = landmarks.getOrNull(13)
        val lowerLip = landmarks.getOrNull(14)

        val center = if (
            leftCorner != null &&
            rightCorner != null &&
            upperLip != null &&
            lowerLip != null
        ) {
            mapOf(
                "x" to ((leftCorner.x().toDouble() + rightCorner.x().toDouble()) / 2.0),
                "y" to ((upperLip.y().toDouble() + lowerLip.y().toDouble()) / 2.0),
                "z" to ((upperLip.z().toDouble() + lowerLip.z().toDouble()) / 2.0),
            )
        } else {
            mouthLandmarks.takeIf { it.isNotEmpty() }?.let { points ->
                val avgX = points.map { it["x"] ?: 0.0 }.average()
                val avgY = points.map { it["y"] ?: 0.0 }.average()
                val avgZ = points.map { it["z"] ?: 0.0 }.average()
                mapOf("x" to avgX, "y" to avgY, "z" to avgZ)
            }
        }

        return TongueResult(
            mouthLandmarks = mouthLandmarks,
            mouthCenter = center,
        )
    }
}
