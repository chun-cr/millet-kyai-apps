package com.millet.kyai.apps

internal const val FACE_CAPTURE_STAGE = "face"
internal const val FACE_CAPTURE_NO_SNAPSHOT_CODE = "NO_SNAPSHOT"

data class NormalizedPoint(
    val x: Double,
    val y: Double,
    val z: Double? = null,
)

data class FaceCaptureSnapshot<FrameT>(
    val generationId: Long,
    val timestampMs: Long,
    val frameSource: FrameT,
    val imageWidth: Int,
    val imageHeight: Int,
    val isBackCamera: Boolean,
    val mirrored: Boolean,
    val landmarks: List<NormalizedPoint>,
)

data class AcceptedFaceCaptureRequest(
    val generationId: Long,
    val guideRect: RectFCompat,
    val landmarks: List<NormalizedPoint>,
    val analysisImageWidth: Int,
    val analysisImageHeight: Int,
    val isBackCamera: Boolean,
    val mirrored: Boolean,
    val timestampMs: Long?,
)

data class AcceptedFaceCaptureSnapshot<FrameT>(
    val generationId: Long,
    val timestampMs: Long,
    val frameSource: FrameT,
    val guideRect: RectFCompat,
    val landmarks: List<NormalizedPoint>,
    val analysisImageWidth: Int,
    val analysisImageHeight: Int,
    val isBackCamera: Boolean,
    val mirrored: Boolean,
)

data class CaptureContractError(
    val code: String,
    val message: String,
)

class FaceCaptureSnapshotStore<FrameT>(private val maxEntries: Int = 16) {
    private val snapshots = LinkedHashMap<Long, FaceCaptureSnapshot<FrameT>>()
    private val pinCounts = mutableMapOf<Long, Int>()
    private val retiredGenerations = linkedSetOf<Long>()

    init {
        require(maxEntries > 0) { "maxEntries must be greater than zero." }
    }

    @Synchronized
    fun put(snapshot: FaceCaptureSnapshot<FrameT>): List<FaceCaptureSnapshot<FrameT>> {
        val evicted = mutableListOf<FaceCaptureSnapshot<FrameT>>()
        snapshots.put(snapshot.generationId, snapshot)?.let { previous ->
            if (isPinned(snapshot.generationId)) {
                retiredGenerations.add(snapshot.generationId)
            } else {
                evicted.add(previous)
            }
        }
        evicted += evictRetiredUnlocked()
        evicted += evictOverflowUnlocked()
        return evicted
    }

    @Synchronized
    fun acquire(generationId: Long): FaceCaptureSnapshot<FrameT>? {
        val snapshot = snapshots[generationId] ?: return null
        pinCounts[generationId] = (pinCounts[generationId] ?: 0) + 1
        return snapshot
    }

    @Synchronized
    fun release(generationId: Long): List<FaceCaptureSnapshot<FrameT>> {
        val currentCount = pinCounts[generationId]
        if (currentCount != null) {
            if (currentCount <= 1) {
                pinCounts.remove(generationId)
            } else {
                pinCounts[generationId] = currentCount - 1
            }
        }

        val released = mutableListOf<FaceCaptureSnapshot<FrameT>>()
        released += evictRetiredUnlocked()
        released += evictOverflowUnlocked()
        return released
    }

    @Synchronized
    fun resolve(generationId: Long): FaceCaptureSnapshot<FrameT>? = snapshots[generationId]

    @Synchronized
    fun clear(): List<FaceCaptureSnapshot<FrameT>> {
        val cleared = mutableListOf<FaceCaptureSnapshot<FrameT>>()
        val iterator = snapshots.entries.iterator()
        while (iterator.hasNext()) {
            val entry = iterator.next()
            if (isPinned(entry.key)) {
                retiredGenerations.add(entry.key)
            } else {
                cleared.add(entry.value)
                iterator.remove()
            }
        }
        return cleared
    }

    private fun evictOverflowUnlocked(): List<FaceCaptureSnapshot<FrameT>> {
        val evicted = mutableListOf<FaceCaptureSnapshot<FrameT>>()
        while (snapshots.size > maxEntries) {
            val candidate = snapshots.entries.firstOrNull { !isPinned(it.key) } ?: break
            retiredGenerations.remove(candidate.key)
            snapshots.remove(candidate.key)?.let(evicted::add)
        }
        return evicted
    }

    private fun evictRetiredUnlocked(): List<FaceCaptureSnapshot<FrameT>> {
        val evicted = mutableListOf<FaceCaptureSnapshot<FrameT>>()
        val iterator = retiredGenerations.iterator()
        while (iterator.hasNext()) {
            val generationId = iterator.next()
            if (isPinned(generationId)) {
                continue
            }
            snapshots.remove(generationId)?.let(evicted::add)
            iterator.remove()
        }
        return evicted
    }

    private fun isPinned(generationId: Long): Boolean = (pinCounts[generationId] ?: 0) > 0
}

internal fun validateCaptureGeneration(
    stage: String,
    generationId: Long?,
): CaptureContractError? {
    if (stage == FACE_CAPTURE_STAGE && generationId == null) {
        return noSnapshotError("Missing accepted face snapshot generationId.")
    }
    return null
}

internal fun validateAcceptedFaceCaptureRequest(
    snapshot: FaceCaptureSnapshot<*>,
    request: AcceptedFaceCaptureRequest,
): CaptureContractError? {
    if (snapshot.generationId != request.generationId) {
        return noSnapshotError("Accepted face snapshot generation mismatch.")
    }
    if (
        snapshot.imageWidth != request.analysisImageWidth ||
        snapshot.imageHeight != request.analysisImageHeight
    ) {
        return noSnapshotError(
            "Accepted face snapshot analysis size mismatch for generationId=${request.generationId}.",
        )
    }
    if (
        snapshot.isBackCamera != request.isBackCamera ||
        snapshot.mirrored != request.mirrored
    ) {
        return noSnapshotError(
            "Accepted face snapshot camera metadata mismatch for generationId=${request.generationId}.",
        )
    }
    if (request.timestampMs != null && snapshot.timestampMs != request.timestampMs) {
        return noSnapshotError(
            "Accepted face snapshot timestamp mismatch for generationId=${request.generationId}.",
        )
    }
    if (!landmarksMatch(snapshot.landmarks, request.landmarks)) {
        return noSnapshotError(
            "Accepted face snapshot landmark mismatch for generationId=${request.generationId}.",
        )
    }
    return null
}

internal fun <FrameT> resolveAcceptedFaceCaptureSnapshot(
    snapshot: FaceCaptureSnapshot<FrameT>,
    request: AcceptedFaceCaptureRequest,
): Pair<AcceptedFaceCaptureSnapshot<FrameT>?, CaptureContractError?> {
    val validationError = validateAcceptedFaceCaptureRequest(snapshot, request)
    if (validationError != null) {
        return null to validationError
    }

    return AcceptedFaceCaptureSnapshot(
        generationId = snapshot.generationId,
        timestampMs = snapshot.timestampMs,
        frameSource = snapshot.frameSource,
        guideRect = request.guideRect,
        landmarks = request.landmarks,
        analysisImageWidth = snapshot.imageWidth,
        analysisImageHeight = snapshot.imageHeight,
        isBackCamera = snapshot.isBackCamera,
        mirrored = snapshot.mirrored,
    ) to null
}

internal fun buildScanCapturePayload(
    stage: String,
    sourcePath: String,
    croppedPath: String,
    framePath: String,
    sourceWidth: Int,
    sourceHeight: Int,
    cropLeft: Int,
    cropTop: Int,
    cropWidth: Int,
    cropHeight: Int,
): Map<String, Any> {
    return mapOf(
        "stage" to stage,
        "sourcePath" to sourcePath,
        "croppedPath" to croppedPath,
        "framePath" to framePath,
        "sourceWidth" to sourceWidth.toDouble(),
        "sourceHeight" to sourceHeight.toDouble(),
        "cropLeft" to cropLeft.toDouble(),
        "cropTop" to cropTop.toDouble(),
        "cropWidth" to cropWidth.toDouble(),
        "cropHeight" to cropHeight.toDouble(),
    )
}

private fun landmarksMatch(
    stored: List<NormalizedPoint>,
    requested: List<NormalizedPoint>,
    tolerance: Double = 1e-6,
): Boolean {
    if (stored.size != requested.size) {
        return false
    }

    return stored.zip(requested).all { (left, right) ->
        almostEqual(left.x, right.x, tolerance) &&
            almostEqual(left.y, right.y, tolerance)
    }
}

private fun almostEqual(left: Double, right: Double, tolerance: Double): Boolean {
    return kotlin.math.abs(left - right) <= tolerance
}

private fun noSnapshotError(message: String): CaptureContractError {
    return CaptureContractError(
        code = FACE_CAPTURE_NO_SNAPSHOT_CODE,
        message = message,
    )
}
