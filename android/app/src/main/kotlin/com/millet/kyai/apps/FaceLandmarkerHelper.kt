package com.millet.kyai.apps

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.components.containers.Category
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarkerResult

data class FaceLandmarkerDetection(
    val detected: Boolean,
    val generationId: Long,
    val landmarks: List<Map<String, Double>>,
    val blendshapes: Map<String, Double>,
    val imageWidth: Int,
    val imageHeight: Int,
    val mouthLandmarks: List<Map<String, Double>>,
    val mouthCenter: Map<String, Double>?,
) {
    fun toEventPayload(
        timestampMs: Long,
        isBackCamera: Boolean,
        mirrored: Boolean,
    ): Map<String, Any?> {
        return mapOf(
            "detected" to detected,
            "generationId" to generationId,
            "timestampMs" to timestampMs,
            "isBackCamera" to isBackCamera,
            "mirrored" to mirrored,
            "landmarks" to landmarks,
            "blendshapes" to blendshapes,
            "imageWidth" to imageWidth,
            "imageHeight" to imageHeight,
            "mouthLandmarks" to mouthLandmarks,
            "mouthCenter" to mouthCenter,
        )
    }
}

class FaceLandmarkerHelper(private val context: Context) {
    companion object {
        private const val TAG = "FaceLandmarkerHelper"
        private const val MIN_DETECTION_CONFIDENCE = 0.5f
        private const val MIN_PRESENCE_CONFIDENCE = 0.5f
        private const val MIN_TRACKING_CONFIDENCE = 0.5f
    }

    private var landmarker: FaceLandmarker? = null

    init {
        setupLandmarker()
    }

    private fun setupLandmarker() {
        landmarker = createLandmarker(Delegate.GPU)
            ?: createLandmarker(Delegate.CPU)
            ?: run {
                Log.e(
                    TAG,
                    "Unable to initialize face landmarker with either GPU or CPU delegate.",
                )
                null
            }
    }

    private fun createLandmarker(delegate: Delegate): FaceLandmarker? {
        return try {
            val baseOptionsBuilder = BaseOptions.builder()
                .setModelAssetPath("face_landmarker.task")
                .setDelegate(delegate)

            val optionsBuilder = FaceLandmarker.FaceLandmarkerOptions.builder()
                .setBaseOptions(baseOptionsBuilder.build())
                .setMinFaceDetectionConfidence(MIN_DETECTION_CONFIDENCE)
                .setMinFacePresenceConfidence(MIN_PRESENCE_CONFIDENCE)
                .setMinTrackingConfidence(MIN_TRACKING_CONFIDENCE)
                .setNumFaces(1)
                .setOutputFaceBlendshapes(true)
                .setRunningMode(RunningMode.VIDEO)

            FaceLandmarker.createFromOptions(context, optionsBuilder.build())
        } catch (error: Exception) {
            null
        }
    }

    fun detect(bitmap: Bitmap, generationId: Long): FaceLandmarkerDetection {
        val activeLandmarker = landmarker ?: return emptyDetection(
            generationId = generationId,
            imageWidth = bitmap.width,
            imageHeight = bitmap.height,
        )

        return try {
            val mpImage = BitmapImageBuilder(bitmap).build()
            val result = activeLandmarker.detectForVideo(mpImage, generationId)
            buildDetection(
                result = result,
                fallbackGenerationId = generationId,
                imageWidth = bitmap.width,
                imageHeight = bitmap.height,
            )
        } catch (error: Exception) {
            Log.e(TAG, "Face landmark detection failed for generation=$generationId.", error)
            emptyDetection(
                generationId = generationId,
                imageWidth = bitmap.width,
                imageHeight = bitmap.height,
            )
        }
    }

    private fun buildDetection(
        result: FaceLandmarkerResult?,
        fallbackGenerationId: Long,
        imageWidth: Int,
        imageHeight: Int,
    ): FaceLandmarkerDetection {
        val resolvedGenerationId = result?.timestampMs() ?: fallbackGenerationId
        val firstFaceLandmarks = result?.faceLandmarks()?.firstOrNull()
        val landmarks = firstFaceLandmarks?.map { landmark: NormalizedLandmark ->
            mapOf(
                "x" to landmark.x().toDouble(),
                "y" to landmark.y().toDouble(),
                "z" to landmark.z().toDouble(),
            )
        } ?: emptyList()

        val blendshapes = if (result?.faceBlendshapes()?.isPresent == true) {
            val categories: List<Category>? = result.faceBlendshapes().get().firstOrNull()
            categories?.associate { category: Category ->
                category.categoryName() to category.score().toDouble()
            } ?: emptyMap()
        } else {
            emptyMap()
        }

        val tongueData = TongueDetectionUtils.evaluateTongue(firstFaceLandmarks)
        return FaceLandmarkerDetection(
            detected = !firstFaceLandmarks.isNullOrEmpty(),
            generationId = resolvedGenerationId,
            landmarks = landmarks,
            blendshapes = blendshapes,
            imageWidth = imageWidth,
            imageHeight = imageHeight,
            mouthLandmarks = tongueData.mouthLandmarks,
            mouthCenter = tongueData.mouthCenter,
        )
    }

    private fun emptyDetection(
        generationId: Long,
        imageWidth: Int,
        imageHeight: Int,
    ): FaceLandmarkerDetection {
        return FaceLandmarkerDetection(
            detected = false,
            generationId = generationId,
            landmarks = emptyList(),
            blendshapes = emptyMap(),
            imageWidth = imageWidth,
            imageHeight = imageHeight,
            mouthLandmarks = emptyList(),
            mouthCenter = null,
        )
    }

    fun close() {
        landmarker?.close()
        landmarker = null
    }
}
