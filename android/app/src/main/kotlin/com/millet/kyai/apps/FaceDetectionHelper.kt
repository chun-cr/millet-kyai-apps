package com.millet.kyai.apps

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import androidx.camera.core.ImageProxy
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facedetector.FaceDetector
import com.google.mediapipe.tasks.vision.facedetector.FaceDetectorResult

class FaceDetectionHelper(private val context: Context) {
    private var detector: FaceDetector? = null
    private var resultCallback: ((Map<String, Any?>) -> Unit)? = null

    init {
        setupDetector()
    }

    private fun setupDetector() {
        val baseOptionsBuilder = BaseOptions.builder()
            .setModelAssetPath("face_detection_short_range.tflite")
            .setDelegate(Delegate.GPU)

        val optionsBuilder = FaceDetector.FaceDetectorOptions.builder()
            .setBaseOptions(baseOptionsBuilder.build())
            .setMinDetectionConfidence(0.7f)
            .setRunningMode(RunningMode.LIVE_STREAM)
            .setResultListener { result: FaceDetectorResult, _: MPImage ->
                val hasFace = result.detections().isNotEmpty()
                resultCallback?.invoke(
                    mapOf(
                        "detected" to hasFace,
                    )
                )
            }

        detector = FaceDetector.createFromOptions(context, optionsBuilder.build())
    }

    fun detect(imageProxy: ImageProxy, callback: (Map<String, Any?>) -> Unit) {
        resultCallback = callback
        val bitmap = imageProxy.toRgbBitmap()
        val matrix = Matrix().apply { postRotate(imageProxy.imageInfo.rotationDegrees.toFloat()) }
        val rotatedBitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)

        val mpImage = BitmapImageBuilder(rotatedBitmap).build()
        detector?.detectAsync(mpImage, System.currentTimeMillis())
    }
}
