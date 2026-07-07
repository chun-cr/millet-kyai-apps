package com.millet.kyai.apps

import android.content.Context
import androidx.camera.core.ImageProxy
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class FaceScanChannel(private val context: Context) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private var gestureEventSink: EventChannel.EventSink? = null
    private var tongueEventSink: EventChannel.EventSink? = null

    private val cameraManager = CameraManager(context)
    private var faceLandmarkerHelper: FaceLandmarkerHelper? = null
    private var gestureRecognizerHelper: GestureRecognizerHelper? = null

    companion object {
        private const val CHANNEL = "face/channel"
        private const val EVENTS = "face/landmarkStream"
        private const val GESTURE_EVENTS = "gesture/resultStream"
        private const val TONGUE_EVENTS = "tongue/detectionStream"
        private const val TONGUE_CAPTURE = "tongue/capture"

        private var instance: FaceScanChannel? = null

        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val channelInstance = FaceScanChannel(context)
            instance = channelInstance
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler(channelInstance)
            EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENTS)
                .setStreamHandler(channelInstance)
            EventChannel(flutterEngine.dartExecutor.binaryMessenger, GESTURE_EVENTS)
                .setStreamHandler(channelInstance.gestureStreamHandler)
            EventChannel(flutterEngine.dartExecutor.binaryMessenger, TONGUE_EVENTS)
                .setStreamHandler(channelInstance.tongueStreamHandler)

            flutterEngine.platformViewsController.registry.registerViewFactory(
                "com.yourapp.face_scan/camera_preview",
                CameraPreviewViewFactory(channelInstance.cameraManager)
            )

            channelInstance.cameraManager.setListener { frame ->
                when (channelInstance.cameraManager.mode) {
                    "landmark" -> {
                        channelInstance.processLandmarkFrame(frame)
                    }
                    "gesture" -> {
                        channelInstance.ensureGestureRecognizerHelper().detect(frame) { result ->
                            channelInstance.sendGestureEvent(result)
                        }
                    }
                }
            }
        }

        fun release() {
            instance?.dispose()
            instance = null
        }
    }

    private val gestureStreamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            gestureEventSink = events
        }

        override fun onCancel(arguments: Any?) {
            gestureEventSink = null
        }
    }

    private val tongueStreamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            tongueEventSink = events
        }

        override fun onCancel(arguments: Any?) {
            tongueEventSink = null
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "face/startDetection" -> {
                if (!cameraManager.hasCameraPermission()) {
                    result.error("PERMISSION_DENIED", "Camera permission not granted", null)
                    return
                }
                cameraManager.mode = "landmark"
                cameraManager.startCamera()
                result.success(null)
            }
            "face/stopDetection" -> {
                cameraManager.mode = "none"
                cameraManager.stopCamera()
                result.success(null)
            }
            "face/toggleCamera" -> {
                cameraManager.toggleCamera()
                result.success(null)
            }
            "gesture/startDetection" -> {
                if (!cameraManager.hasCameraPermission()) {
                    result.error("PERMISSION_DENIED", "Camera permission not granted", null)
                    return
                }
                cameraManager.mode = "gesture"
                cameraManager.startCamera()
                result.success(null)
            }
            "tongue/startDetection" -> {
                if (!cameraManager.hasCameraPermission()) {
                    result.error("PERMISSION_DENIED", "Camera permission not granted", null)
                    return
                }
                cameraManager.mode = "landmark"
                sendTongueEvent(buildEmptyTongueEvent())
                cameraManager.startCamera()
                result.success(null)
            }
            "gesture/stopDetection" -> {
                cameraManager.mode = "none"
                cameraManager.stopCamera()
                result.success(null)
            }
            "tongue/stopDetection" -> {
                cameraManager.mode = "none"
                cameraManager.stopCamera()
                sendTongueEvent(buildEmptyTongueEvent())
                result.success(null)
            }
            "scan/capture" -> {
                val stage = call.argument<String>("stage")
                val guideRect = call.argument<Map<String, Any?>>("guideRect")
                val generationId = call.argument<Number>("generationId")?.toLong()
                val requestedLandmarks = parseNormalizedPoints(call.argument<List<Any?>>("landmarks"))
                val analysisImageWidth = call.argument<Number>("analysisImageWidth")?.toInt()
                val analysisImageHeight = call.argument<Number>("analysisImageHeight")?.toInt()
                val isBackCamera = call.argument<Boolean>("isBackCamera")
                val mirrored = call.argument<Boolean>("mirrored")
                val timestampMs = call.argument<Number>("timestampMs")?.toLong()
                val preferVisibleRegion = call.argument<Boolean>("preferVisibleRegion") == true

                if (stage.isNullOrBlank()) {
                    result.error("INVALID_STAGE", "Missing capture stage", null)
                    return
                }

                val contractError = validateCaptureGeneration(stage, generationId)
                if (contractError != null) {
                    result.error(
                        contractError.code,
                        contractError.message,
                        mapOf(
                            "stage" to stage,
                            "guideRect" to guideRect,
                        ),
                    )
                    return
                }

                val normalizedRect = parseNormalizedRect(guideRect)
                if (normalizedRect == null) {
                    result.error("INVALID_GUIDE_RECT", "Missing or invalid guideRect", guideRect)
                    return
                }

                val canCaptureStoredSnapshot =
                    generationId != null &&
                        requestedLandmarks.isNotEmpty() &&
                        analysisImageWidth != null &&
                        analysisImageHeight != null &&
                        isBackCamera != null &&
                        mirrored != null

                if (!preferVisibleRegion && canCaptureStoredSnapshot) {
                    cameraManager.captureAcceptedFaceSnapshot(
                        stage = stage,
                        request = AcceptedFaceCaptureRequest(
                            generationId = generationId,
                            guideRect = normalizedRect,
                            landmarks = requestedLandmarks,
                            analysisImageWidth = analysisImageWidth,
                            analysisImageHeight = analysisImageHeight,
                            isBackCamera = isBackCamera,
                            mirrored = mirrored,
                            timestampMs = timestampMs,
                        ),
                        onSuccess = { payload ->
                            (context as? MainActivity)?.runOnUiThread {
                                result.success(payload)
                            }
                        },
                        onNoSnapshot = { error ->
                            (context as? MainActivity)?.runOnUiThread {
                                result.error(
                                    FACE_CAPTURE_NO_SNAPSHOT_CODE,
                                    error,
                                    mapOf(
                                        "stage" to stage,
                                        "generationId" to generationId,
                                        "guideRect" to guideRect,
                                    ),
                                )
                            }
                        },
                        onError = { error ->
                            (context as? MainActivity)?.runOnUiThread {
                                result.error("CAPTURE_FAILED", error, guideRect)
                            }
                        },
                    )
                    return
                }

                if (stage == FACE_CAPTURE_STAGE && !preferVisibleRegion) {
                    if (
                        requestedLandmarks.isEmpty() ||
                        analysisImageWidth == null ||
                        analysisImageHeight == null ||
                        isBackCamera == null ||
                        mirrored == null
                    ) {
                        result.error(
                            FACE_CAPTURE_NO_SNAPSHOT_CODE,
                            "Missing accepted face snapshot metadata.",
                            mapOf(
                                "stage" to stage,
                                "generationId" to generationId,
                                "guideRect" to guideRect,
                            ),
                        )
                        return
                    }
                }

                cameraManager.captureVisibleRegion(
                    stage = stage,
                    normalizedRect = normalizedRect,
                    onSuccess = { payload ->
                        (context as? MainActivity)?.runOnUiThread {
                            result.success(payload)
                        }
                    },
                    onError = { error ->
                        (context as? MainActivity)?.runOnUiThread {
                            result.error("CAPTURE_FAILED", error, guideRect)
                        }
                    },
                )
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun processLandmarkFrame(frame: ImageProxy) {
        val preparedFrame = cameraManager.prepareFaceFrame(frame)
        try {
            val detection = ensureFaceLandmarkerHelper().detect(
                bitmap = preparedFrame.bitmap,
                generationId = preparedFrame.generationId,
            )
            if (detection.detected && detection.landmarks.isNotEmpty()) {
                cameraManager.storeFaceSnapshot(
                    FaceCaptureSnapshot(
                        generationId = detection.generationId,
                        timestampMs = preparedFrame.timestampMs,
                        frameSource = preparedFrame.bitmap,
                        imageWidth = preparedFrame.imageWidth,
                        imageHeight = preparedFrame.imageHeight,
                        isBackCamera = preparedFrame.isBackCamera,
                        mirrored = preparedFrame.mirrored,
                        landmarks = detection.landmarks.mapNotNull(::normalizedPointFromPayload),
                    ),
                )
            } else if (!preparedFrame.bitmap.isRecycled) {
                preparedFrame.bitmap.recycle()
            }

            val event = detection.toEventPayload(
                timestampMs = preparedFrame.timestampMs,
                isBackCamera = preparedFrame.isBackCamera,
                mirrored = preparedFrame.mirrored,
            )
            sendFaceEvent(event)
            sendTongueEvent(event)
        } catch (error: Exception) {
            if (!preparedFrame.bitmap.isRecycled) {
                preparedFrame.bitmap.recycle()
            }
            val errorEvent = mapOf(
                "detected" to false,
                "generationId" to preparedFrame.generationId,
                "timestampMs" to preparedFrame.timestampMs,
                "isBackCamera" to preparedFrame.isBackCamera,
                "mirrored" to preparedFrame.mirrored,
                "landmarks" to emptyList<Map<String, Double>>(),
                "blendshapes" to emptyMap<String, Double>(),
                "imageWidth" to preparedFrame.imageWidth,
                "imageHeight" to preparedFrame.imageHeight,
                "mouthLandmarks" to emptyList<Map<String, Double>>(),
                "mouthCenter" to null,
            )
            sendFaceEvent(errorEvent)
            sendTongueEvent(errorEvent)
        }
    }

    private fun sendFaceEvent(data: Map<String, Any?>) {
        (context as? MainActivity)?.runOnUiThread {
            eventSink?.success(data)
        }
    }

    private fun sendGestureEvent(data: Map<String, Any?>) {
        (context as? MainActivity)?.runOnUiThread {
            gestureEventSink?.success(data)
        }
    }

    private fun sendTongueEvent(data: Map<String, Any?>) {
        val blendshapePayload = (data["blendshapes"] as? Map<*, *>)
            ?.mapNotNull { (key, value) ->
                val name = key as? String
                val score = (value as? Number)?.toDouble()
                if (name != null && score != null) {
                    name to score
                } else {
                    null
                }
            }
            ?.toMap()
            ?: emptyMap<String, Double>()
        val tonguePayload = mapOf(
            "blendshapes" to blendshapePayload,
            "mouthLandmarks" to (data["mouthLandmarks"] as? List<*> ?: emptyList<Any>()),
            "faceLandmarks" to (data["faceLandmarks"] as? List<*> ?: data["landmarks"] as? List<*> ?: emptyList<Any>()),
            "landmarks" to (data["faceLandmarks"] as? List<*> ?: data["landmarks"] as? List<*> ?: emptyList<Any>()),
            "imageWidth" to ((data["imageWidth"] as? Number)?.toDouble() ?: 0.0),
            "imageHeight" to ((data["imageHeight"] as? Number)?.toDouble() ?: 0.0),
            "mouthCenter" to data["mouthCenter"],
            "generationId" to data["generationId"],
            "timestampMs" to data["timestampMs"],
            "isBackCamera" to data["isBackCamera"],
            "mirrored" to data["mirrored"],
        )

        (context as? MainActivity)?.runOnUiThread {
            tongueEventSink?.success(tonguePayload)
        }
    }

    private fun buildEmptyTongueEvent(): Map<String, Any?> {
        return mapOf(
            "blendshapes" to emptyMap<String, Double>(),
            "mouthLandmarks" to emptyList<Map<String, Double>>(),
            "faceLandmarks" to emptyList<Map<String, Double>>(),
            "landmarks" to emptyList<Map<String, Double>>(),
            "imageWidth" to 0,
            "imageHeight" to 0,
            "mouthCenter" to null,
            "generationId" to null,
            "timestampMs" to null,
            "isBackCamera" to null,
            "mirrored" to null,
        )
    }

    private fun ensureFaceLandmarkerHelper(): FaceLandmarkerHelper {
        val existing = faceLandmarkerHelper
        if (existing != null) {
            return existing
        }

        return FaceLandmarkerHelper(context).also {
            faceLandmarkerHelper = it
        }
    }

    private fun ensureGestureRecognizerHelper(): GestureRecognizerHelper {
        val existing = gestureRecognizerHelper
        if (existing != null) {
            return existing
        }

        return GestureRecognizerHelper(context).also {
            gestureRecognizerHelper = it
        }
    }

    private fun dispose() {
        cameraManager.stopCamera()
        faceLandmarkerHelper?.close()
        faceLandmarkerHelper = null
        gestureRecognizerHelper?.close()
        gestureRecognizerHelper = null
        eventSink = null
        gestureEventSink = null
        tongueEventSink = null
    }

    private fun parseNormalizedRect(raw: Map<String, Any?>?): RectFCompat? {
        if (raw == null) {
            return null
        }

        fun readDouble(key: String): Double? {
            val value = raw[key]
            return when (value) {
                is Number -> value.toDouble()
                else -> null
            }
        }

        val left = readDouble("left") ?: return null
        val top = readDouble("top") ?: return null
        val width = readDouble("width") ?: return null
        val height = readDouble("height") ?: return null

        if (width <= 0 || height <= 0) {
            return null
        }

        return RectFCompat(
            left = left,
            top = top,
            width = width,
            height = height,
        )
    }

    private fun parseNormalizedPoints(raw: List<Any?>?): List<NormalizedPoint> {
        if (raw == null) {
            return emptyList()
        }

        return raw.mapNotNull { item ->
            normalizedPointFromPayload(item)
        }
    }

    private fun normalizedPointFromPayload(raw: Any?): NormalizedPoint? {
        val map = raw as? Map<*, *> ?: return null
        val x = (map["x"] as? Number)?.toDouble() ?: return null
        val y = (map["y"] as? Number)?.toDouble() ?: return null
        val z = (map["z"] as? Number)?.toDouble()
        return NormalizedPoint(x = x, y = y, z = z)
    }
}
