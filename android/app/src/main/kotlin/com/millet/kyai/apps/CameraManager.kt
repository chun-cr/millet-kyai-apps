package com.millet.kyai.apps

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.graphics.Rect
import android.os.SystemClock
import android.util.Log
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors

data class PreparedFaceFrame(
    val generationId: Long,
    val timestampMs: Long,
    val bitmap: Bitmap,
    val imageWidth: Int,
    val imageHeight: Int,
    val isBackCamera: Boolean,
    val mirrored: Boolean,
)

class CameraManager(private val context: Context) {
    companion object {
        private const val TAG = "CameraManager"
    }

    var mode: String = "none"
    private var cameraProviderFuture = ProcessCameraProvider.getInstance(context)
    private var analysisUseCase: ImageAnalysis? = null
    private var preview: Preview? = null
    private var imageCapture: ImageCapture? = null
    private var listener: ((ImageProxy) -> Unit)? = null
    private var lastPreviewView: androidx.camera.view.PreviewView? = null
    private val backgroundExecutor = Executors.newSingleThreadExecutor()
    private val faceSnapshots = FaceCaptureSnapshotStore<Bitmap>()

    private var currentSelector: CameraSelector? = null
    private var isCameraToggled = false

    fun hasCameraPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            android.Manifest.permission.CAMERA,
        ) == android.content.pm.PackageManager.PERMISSION_GRANTED
    }

    fun setListener(l: (ImageProxy) -> Unit) {
        listener = l
    }

    fun toggleCamera() {
        isCameraToggled = !isCameraToggled
        restartCamera()
    }

    private fun applyPreviewTransform() {
        // CameraX PreviewView already applies front-camera mirroring.
        lastPreviewView?.scaleX = 1f
    }

    fun startCamera() {
        cameraProviderFuture.addListener({
            try {
                val cameraProvider = cameraProviderFuture.get()
                val cameraSelector = if (mode == "gesture") {
                    if (isCameraToggled) {
                        CameraSelector.DEFAULT_FRONT_CAMERA
                    } else {
                        CameraSelector.DEFAULT_BACK_CAMERA
                    }
                } else {
                    if (isCameraToggled) {
                        CameraSelector.DEFAULT_BACK_CAMERA
                    } else {
                        CameraSelector.DEFAULT_FRONT_CAMERA
                    }
                }

                if (
                    currentSelector == cameraSelector &&
                    preview != null &&
                    cameraProvider.isBound(preview!!)
                ) {
                    applyPreviewTransform()
                    return@addListener
                }

                currentSelector = cameraSelector

                preview = Preview.Builder()
                    .setTargetResolution(android.util.Size(1280, 720))
                    .build()

                analysisUseCase = ImageAnalysis.Builder()
                    .setTargetResolution(android.util.Size(640, 480))
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                    .build()

                imageCapture = ImageCapture.Builder()
                    .setTargetResolution(android.util.Size(1280, 720))
                    .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
                    .build()

                analysisUseCase?.setAnalyzer(backgroundExecutor) { imageProxy ->
                    try {
                        listener?.invoke(imageProxy)
                    } finally {
                        imageProxy.close()
                    }
                }

                cameraProvider.unbindAll()
                cameraProvider.bindToLifecycle(
                    context as androidx.lifecycle.LifecycleOwner,
                    cameraSelector,
                    preview,
                    analysisUseCase,
                    imageCapture,
                )

                lastPreviewView?.let { previewView ->
                    preview?.setSurfaceProvider(previewView.surfaceProvider)
                    applyPreviewTransform()
                }
            } catch (error: Exception) {
                Log.e(TAG, "Start camera failed.", error)
            }
        }, ContextCompat.getMainExecutor(context))
    }

    fun stopCamera(resetToggle: Boolean = true) {
        try {
            val cameraProvider = cameraProviderFuture.get()
            cameraProvider.unbindAll()
            analysisUseCase = null
            preview = null
            imageCapture = null
            currentSelector = null
            clearFaceSnapshots()
            if (resetToggle) {
                isCameraToggled = false
            }
        } catch (_: Exception) {
        }
    }

    fun takePhoto(outputFile: File, onSuccess: (String) -> Unit, onError: (String) -> Unit) {
        val capture = imageCapture ?: run {
            onError("ImageCapture not ready")
            return
        }

        val outputOptions = ImageCapture.OutputFileOptions.Builder(outputFile).build()
        capture.takePicture(
            outputOptions,
            backgroundExecutor,
            object : ImageCapture.OnImageSavedCallback {
                override fun onImageSaved(outputFileResults: ImageCapture.OutputFileResults) {
                    onSuccess(outputFile.absolutePath)
                }

                override fun onError(exception: ImageCaptureException) {
                    onError(exception.message ?: "Capture failed")
                }
            },
        )
    }

    fun restartCamera() {
        stopCamera(resetToggle = false)
        startCamera()
    }

    fun setMirrorPreview(enabled: Boolean) {
        lastPreviewView?.let { previewView ->
            previewView.scaleX = if (enabled) -1f else 1f
        }
    }

    fun prepareFaceFrame(imageProxy: ImageProxy): PreparedFaceFrame {
        val rotatedBitmap = buildRotatedBitmap(imageProxy)
        val generationId = SystemClock.elapsedRealtimeNanos() / 1_000_000L
        val timestampMs = System.currentTimeMillis()
        val isBackCamera = isBackCameraSelected()
        return PreparedFaceFrame(
            generationId = generationId,
            timestampMs = timestampMs,
            bitmap = rotatedBitmap,
            imageWidth = rotatedBitmap.width,
            imageHeight = rotatedBitmap.height,
            isBackCamera = isBackCamera,
            mirrored = !isBackCamera,
        )
    }

    fun storeFaceSnapshot(snapshot: FaceCaptureSnapshot<Bitmap>) {
        val evictedSnapshots = faceSnapshots.put(snapshot)
        evictedSnapshots.forEach(::recycleSnapshot)
    }

    fun captureAcceptedFaceSnapshot(
        stage: String,
        request: AcceptedFaceCaptureRequest,
        onSuccess: (Map<String, Any>) -> Unit,
        onNoSnapshot: (String) -> Unit,
        onError: (String) -> Unit,
    ) {
        val snapshot = faceSnapshots.acquire(request.generationId)
        if (snapshot == null) {
            onNoSnapshot("No accepted face snapshot for generationId=${request.generationId}")
            return
        }

        backgroundExecutor.execute {
            try {
                val (acceptedSnapshot, validationError) = resolveAcceptedFaceCaptureSnapshot(
                    snapshot = snapshot,
                    request = request,
                )
                if (validationError != null || acceptedSnapshot == null) {
                    onNoSnapshot(
                        validationError?.message
                            ?: "Accepted face snapshot capture validation failed.",
                    )
                    return@execute
                }

                val cropRect = acceptedSnapshot.guideRect.toPixelRect(
                    width = acceptedSnapshot.analysisImageWidth,
                    height = acceptedSnapshot.analysisImageHeight,
                )
                val croppedBitmap = Bitmap.createBitmap(
                    acceptedSnapshot.frameSource,
                    cropRect.left,
                    cropRect.top,
                    cropRect.width(),
                    cropRect.height(),
                )
                val sourceBitmapForUpload = mirrorBitmapIfNeeded(
                    bitmap = acceptedSnapshot.frameSource,
                    mirrored = acceptedSnapshot.mirrored,
                )
                val croppedBitmapForUpload = mirrorBitmapIfNeeded(
                    bitmap = croppedBitmap,
                    mirrored = acceptedSnapshot.mirrored,
                )

                val fileTimestamp = acceptedSnapshot.timestampMs
                val sourceFile = File(context.cacheDir, "${stage}_source_$fileTimestamp.jpg")
                val cropFile = File(context.cacheDir, "${stage}_crop_$fileTimestamp.jpg")

                try {
                    saveBitmap(sourceBitmapForUpload, sourceFile)
                    saveBitmap(croppedBitmapForUpload, cropFile)
                } finally {
                    if (sourceBitmapForUpload !== acceptedSnapshot.frameSource &&
                        !sourceBitmapForUpload.isRecycled
                    ) {
                        sourceBitmapForUpload.recycle()
                    }
                    if (croppedBitmapForUpload !== croppedBitmap &&
                        !croppedBitmapForUpload.isRecycled
                    ) {
                        croppedBitmapForUpload.recycle()
                    }
                    if (!croppedBitmap.isRecycled) {
                        croppedBitmap.recycle()
                    }
                }

                onSuccess(
                    buildScanCapturePayload(
                        stage = stage,
                        sourcePath = sourceFile.absolutePath,
                        croppedPath = cropFile.absolutePath,
                        framePath = sourceFile.absolutePath,
                        sourceWidth = acceptedSnapshot.analysisImageWidth,
                        sourceHeight = acceptedSnapshot.analysisImageHeight,
                        cropLeft = cropRect.left,
                        cropTop = cropRect.top,
                        cropWidth = cropRect.width(),
                        cropHeight = cropRect.height(),
                    ),
                )
            } catch (error: Exception) {
                onError(error.message ?: "Accepted face snapshot capture failed")
            } finally {
                faceSnapshots.release(request.generationId).forEach(::recycleSnapshot)
            }
        }
    }

    fun captureVisibleRegion(
        stage: String,
        normalizedRect: RectFCompat,
        onSuccess: (Map<String, Any>) -> Unit,
        onError: (String) -> Unit,
    ) {
        val previewView = lastPreviewView ?: run {
            onError("PreviewView not ready")
            return
        }

        previewView.post {
            val previewBitmap = previewView.bitmap
            if (previewBitmap == null) {
                onError("Preview bitmap unavailable")
                return@post
            }

            backgroundExecutor.execute {
                try {
                    val cropRect = normalizedRect.toPixelRect(
                        width = previewBitmap.width,
                        height = previewBitmap.height,
                    )
                    val croppedBitmap = Bitmap.createBitmap(
                        previewBitmap,
                        cropRect.left,
                        cropRect.top,
                        cropRect.width(),
                        cropRect.height(),
                    )

                    val timestamp = System.currentTimeMillis()
                    val sourceFile = File(context.cacheDir, "${stage}_source_$timestamp.jpg")
                    val cropFile = File(context.cacheDir, "${stage}_crop_$timestamp.jpg")

                    saveBitmap(previewBitmap, sourceFile)
                    saveBitmap(croppedBitmap, cropFile)
                    croppedBitmap.recycle()

                    onSuccess(
                        buildScanCapturePayload(
                            stage = stage,
                            sourcePath = sourceFile.absolutePath,
                            croppedPath = cropFile.absolutePath,
                            framePath = sourceFile.absolutePath,
                            sourceWidth = previewBitmap.width,
                            sourceHeight = previewBitmap.height,
                            cropLeft = cropRect.left,
                            cropTop = cropRect.top,
                            cropWidth = cropRect.width(),
                            cropHeight = cropRect.height(),
                        ),
                    )
                } catch (error: Exception) {
                    onError(error.message ?: "Visible region capture failed")
                }
            }
        }
    }

    fun setPreviewView(previewView: androidx.camera.view.PreviewView) {
        lastPreviewView = previewView
        preview?.setSurfaceProvider(previewView.surfaceProvider)
        applyPreviewTransform()
    }

    fun attachPreview(previewView: androidx.camera.view.PreviewView) {
        setPreviewView(previewView)
    }

    private fun buildRotatedBitmap(imageProxy: ImageProxy): Bitmap {
        val bitmap = imageProxy.toRgbBitmap()
        val matrix = Matrix().apply {
            postRotate(imageProxy.imageInfo.rotationDegrees.toFloat())
        }
        val rotatedBitmap = Bitmap.createBitmap(
            bitmap,
            0,
            0,
            bitmap.width,
            bitmap.height,
            matrix,
            true,
        )
        if (rotatedBitmap !== bitmap && !bitmap.isRecycled) {
            bitmap.recycle()
        }
        return rotatedBitmap
    }

    private fun isBackCameraSelected(): Boolean {
        return if (mode == "gesture") {
            !isCameraToggled
        } else {
            isCameraToggled
        }
    }

    private fun clearFaceSnapshots() {
        faceSnapshots.clear().forEach(::recycleSnapshot)
    }

    private fun recycleSnapshot(snapshot: FaceCaptureSnapshot<Bitmap>) {
        val bitmap = snapshot.frameSource
        if (!bitmap.isRecycled) {
            bitmap.recycle()
        }
    }

    private fun saveBitmap(bitmap: Bitmap, file: File) {
        FileOutputStream(file).use { output ->
            if (!bitmap.compress(Bitmap.CompressFormat.JPEG, 92, output)) {
                throw IllegalStateException("Failed to write bitmap to ${file.absolutePath}")
            }
            output.flush()
        }
    }

    private fun mirrorBitmapIfNeeded(bitmap: Bitmap, mirrored: Boolean): Bitmap {
        if (!mirrored) {
            return bitmap
        }

        val matrix = Matrix().apply {
            preScale(-1f, 1f)
        }
        return Bitmap.createBitmap(
            bitmap,
            0,
            0,
            bitmap.width,
            bitmap.height,
            matrix,
            true,
        )
    }
}

data class RectFCompat(
    val left: Double,
    val top: Double,
    val width: Double,
    val height: Double,
) {
    fun toPixelRect(width: Int, height: Int): Rect {
        val safeLeft = (left.coerceIn(0.0, 1.0) * width).toInt()
        val safeTop = (top.coerceIn(0.0, 1.0) * height).toInt()
        val safeRight = ((left + this.width).coerceIn(0.0, 1.0) * width).toInt()
        val safeBottom = ((top + this.height).coerceIn(0.0, 1.0) * height).toInt()

        val rect = Rect(
            safeLeft.coerceIn(0, width - 1),
            safeTop.coerceIn(0, height - 1),
            safeRight.coerceIn(1, width),
            safeBottom.coerceIn(1, height),
        )

        if (rect.width() <= 0 || rect.height() <= 0) {
            throw IllegalArgumentException("Invalid crop rect from normalized guide: $this")
        }

        return rect
    }
}

class CameraPreviewViewFactory(
    private val cameraManager: CameraManager,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return CameraPreviewView(context, cameraManager)
    }
}

class CameraPreviewView(
    context: Context,
    private val cameraManager: CameraManager,
) : PlatformView {
    private val previewView = androidx.camera.view.PreviewView(context)

    init {
        previewView.implementationMode =
            androidx.camera.view.PreviewView.ImplementationMode.COMPATIBLE
        cameraManager.attachPreview(previewView)
    }

    override fun getView(): android.view.View = previewView

    override fun dispose() {
        // No-op.
    }
}
