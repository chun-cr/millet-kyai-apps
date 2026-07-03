package com.millet.kyai.apps

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.SystemClock
import android.util.Log
import androidx.camera.core.ImageProxy
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.gesturerecognizer.GestureRecognizer
import com.google.mediapipe.tasks.vision.gesturerecognizer.GestureRecognizerResult
import kotlin.math.acos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

class GestureRecognizerHelper(private val context: Context) {
    companion object {
        private const val TAG = "GestureRecognizerHelper"
        private const val OPEN_PALM_SCORE_THRESHOLD = 0.60
        private const val THUMB_ANGLE_THRESHOLD = 110.0
        private const val THUMB_INDEX_RATIO_THRESHOLD = 1.00
        private const val THUMB_WRIST_RATIO_THRESHOLD = 1.00
        private const val FINGER_ANGLE_THRESHOLD = 136.0
        private const val MIN_STRAIGHT_FINGERS = 3
    }

    private var recognizer: GestureRecognizer? = null

    private var lastGestureName: String? = null
    private var consecutiveCount = 0

    init {
        setupRecognizer()
    }

    private fun setupRecognizer() {
        recognizer = createRecognizer(Delegate.GPU)
            ?: createRecognizer(Delegate.CPU)
            ?: run {
                Log.e(
                    TAG,
                    "Unable to initialize gesture recognizer with either GPU or CPU delegate.",
                )
                null
            }
    }

    private fun createRecognizer(delegate: Delegate): GestureRecognizer? {
        return try {
            val baseOptionsBuilder = BaseOptions.builder()
                .setModelAssetPath("gesture_recognizer.task")
                .setDelegate(delegate)

            val options = GestureRecognizer.GestureRecognizerOptions.builder()
                .setBaseOptions(baseOptionsBuilder.build())
                .setRunningMode(RunningMode.VIDEO)
                .setNumHands(2)

            GestureRecognizer.createFromOptions(context, options.build())
        } catch (_: Exception) {
            null
        }
    }

    fun detect(imageProxy: ImageProxy, callback: (Map<String, Any?>) -> Unit) {
        var bitmap: Bitmap? = null
        var rotatedBitmap: Bitmap? = null

        try {
            bitmap = imageProxy.toRgbBitmap()
            rotatedBitmap = rotateBitmap(
                source = bitmap,
                rotationDegrees = imageProxy.imageInfo.rotationDegrees,
            )
            val mpImage = BitmapImageBuilder(rotatedBitmap).build()
            val timestampMs = SystemClock.elapsedRealtimeNanos() / 1_000_000L
            val result = recognizer?.recognizeForVideo(mpImage, timestampMs)
            callback(buildResultPayload(result, mpImage))
        } catch (error: Exception) {
            Log.e(TAG, "Gesture recognition failed.", error)
            callback(
                emptyResultPayload(
                    imageWidth = rotatedBitmap?.width ?: bitmap?.width ?: 0,
                    imageHeight = rotatedBitmap?.height ?: bitmap?.height ?: 0,
                ),
            )
        } finally {
            rotatedBitmap?.let { rotated ->
                if (!rotated.isRecycled) {
                    rotated.recycle()
                }
            }
            bitmap?.let { original ->
                if (original !== rotatedBitmap && !original.isRecycled) {
                    original.recycle()
                }
            }
        }
    }

    private fun rotateBitmap(source: Bitmap, rotationDegrees: Int): Bitmap {
        if (rotationDegrees == 0) {
            return source
        }

        val matrix = Matrix().apply { postRotate(rotationDegrees.toFloat()) }
        return Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, true)
    }

    private fun buildResultPayload(
        result: GestureRecognizerResult?,
        mpImage: MPImage,
    ): Map<String, Any?> {
        val gesture = result?.gestures()?.firstOrNull()?.firstOrNull()
        val gestureName = gesture?.categoryName() ?: ""
        val score = gesture?.score()?.toDouble() ?: 0.0
        val normalizedGestureName = normalizeGestureName(gestureName)

        val handLandmarks = result?.landmarks()?.firstOrNull()
        val landmarks = handLandmarks?.map { lm: NormalizedLandmark ->
            mapOf("x" to lm.x().toDouble(), "y" to lm.y().toDouble(), "z" to lm.z().toDouble())
        } ?: emptyList<Map<String, Double>>()

        val detectedByModel =
            normalizedGestureName == "OPENPALM" && score >= OPEN_PALM_SCORE_THRESHOLD
        val handStraight = isStraightPalmByLandmarks(handLandmarks)
        val detected = detectedByModel || handStraight
        val finalName = if (detected) "Open_Palm" else gestureName
        val finalScore = if (detectedByModel) score else if (handStraight) 0.75 else score

        return mapOf(
            "gestureDetected" to debounce(finalName, detected),
            "handStraight" to handStraight,
            "gestureName" to finalName,
            "score" to finalScore,
            "handLandmarks" to landmarks,
            "imageWidth" to mpImage.width.toDouble(),
            "imageHeight" to mpImage.height.toDouble(),
        )
    }

    private fun emptyResultPayload(
        imageWidth: Int,
        imageHeight: Int,
    ): Map<String, Any?> {
        lastGestureName = null
        consecutiveCount = 0
        return mapOf(
            "gestureDetected" to false,
            "handStraight" to false,
            "gestureName" to "",
            "score" to 0.0,
            "handLandmarks" to emptyList<Map<String, Double>>(),
            "imageWidth" to imageWidth.toDouble(),
            "imageHeight" to imageHeight.toDouble(),
        )
    }

    private fun debounce(gestureName: String, detected: Boolean): Boolean {
        if (!detected) {
            lastGestureName = null
            consecutiveCount = 0
            return false
        }

        if (gestureName == lastGestureName) {
            consecutiveCount += 1
        } else {
            lastGestureName = gestureName
            consecutiveCount = 1
        }

        return consecutiveCount >= 3
    }

    private fun isStraightPalmByLandmarks(landmarks: List<NormalizedLandmark>?): Boolean {
        if (landmarks == null || landmarks.size < 21) return false

        val thumbExtended = isThumbExtended(landmarks)
        val straightFingers = listOf(
            isFingerExtended(landmarks, 5, 6, 7, 8),
            isFingerExtended(landmarks, 9, 10, 11, 12),
            isFingerExtended(landmarks, 13, 14, 15, 16),
            isFingerExtended(landmarks, 17, 18, 19, 20),
        ).count { it }

        // Allow one slightly curled finger, but keep obviously bent palms out.
        return straightFingers == 4 ||
            (straightFingers >= MIN_STRAIGHT_FINGERS && thumbExtended)
    }

    private fun isThumbExtended(landmarks: List<NormalizedLandmark>): Boolean {
        val thumbAngle = angleBetween(
            landmarks[1],
            landmarks[2],
            landmarks[3],
            landmarks[4],
        )

        val tipToIndexMcp = distance(landmarks[4], landmarks[5])
        val ipToIndexMcp = distance(landmarks[3], landmarks[5])
        val tipToWrist = distance(landmarks[4], landmarks[0])
        val mcpToWrist = distance(landmarks[2], landmarks[0])

        return thumbAngle > THUMB_ANGLE_THRESHOLD &&
            tipToIndexMcp > ipToIndexMcp * THUMB_INDEX_RATIO_THRESHOLD &&
            tipToWrist > mcpToWrist * THUMB_WRIST_RATIO_THRESHOLD
    }

    private fun isFingerExtended(
        landmarks: List<NormalizedLandmark>,
        mcp: Int,
        pip: Int,
        dip: Int,
        tip: Int,
    ): Boolean {
        val angle = angleBetween(
            landmarks[mcp],
            landmarks[pip],
            landmarks[dip],
            landmarks[tip],
        )
        return angle > FINGER_ANGLE_THRESHOLD
    }

    private fun angleBetween(
        a: NormalizedLandmark,
        b: NormalizedLandmark,
        c: NormalizedLandmark,
        d: NormalizedLandmark,
    ): Double {
        val v1 = floatArrayOf(a.x() - b.x(), a.y() - b.y(), a.z() - b.z())
        val v2 = floatArrayOf(c.x() - b.x(), c.y() - b.y(), c.z() - b.z())
        val v3 = floatArrayOf(d.x() - c.x(), d.y() - c.y(), d.z() - c.z())

        val angle1 = vectorAngle(v1, v2)
        val angle2 = vectorAngle(v2, v3)
        return (angle1 + angle2) / 2
    }

    private fun vectorAngle(v1: FloatArray, v2: FloatArray): Double {
        val dot = (v1[0] * v2[0]) + (v1[1] * v2[1]) + (v1[2] * v2[2])
        val mag1 = sqrt(v1[0] * v1[0] + v1[1] * v1[1] + v1[2] * v1[2])
        val mag2 = sqrt(v2[0] * v2[0] + v2[1] * v2[1] + v2[2] * v2[2])
        val denom = max(1e-6, (mag1 * mag2).toDouble())
        val cos = min(1.0, max(-1.0, dot / denom))
        return Math.toDegrees(acos(cos))
    }

    private fun distance(a: NormalizedLandmark, b: NormalizedLandmark): Double {
        val dx = (a.x() - b.x()).toDouble()
        val dy = (a.y() - b.y()).toDouble()
        val dz = (a.z() - b.z()).toDouble()
        return sqrt(dx * dx + dy * dy + dz * dz)
    }

    private fun normalizeGestureName(name: String): String {
        return name.uppercase().replace(Regex("[^A-Z]"), "")
    }

    fun close() {
        recognizer?.close()
        recognizer = null
        lastGestureName = null
        consecutiveCount = 0
    }
}
