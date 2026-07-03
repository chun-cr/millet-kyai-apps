package com.example.stitch_diag_demo

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ScanCaptureContractsTest {
    @Test
    fun `face capture request requires generation id`() {
        val error = validateCaptureGeneration(FACE_CAPTURE_STAGE, null)

        assertEquals(FACE_CAPTURE_NO_SNAPSHOT_CODE, error?.code)
        assertTrue(error?.message?.contains("generationId") == true)
    }

    @Test
    fun `non-face capture request does not require generation id`() {
        val error = validateCaptureGeneration("tongue", null)

        assertNull(error)
    }

    @Test
    fun `snapshot record preserves metadata`() {
        val snapshot = snapshot(generationId = 11L, frameSource = "frame-ref")

        assertEquals(11L, snapshot.generationId)
        assertEquals(12L, snapshot.timestampMs)
        assertEquals("frame-ref", snapshot.frameSource)
        assertEquals(640, snapshot.imageWidth)
        assertEquals(480, snapshot.imageHeight)
        assertFalse(snapshot.isBackCamera)
        assertTrue(snapshot.mirrored)
        assertEquals(2, snapshot.landmarks.size)
    }

    @Test
    fun `pinned snapshots are not recycled until release after clear`() {
        val store = FaceCaptureSnapshotStore<String>(maxEntries = 1)
        store.put(snapshot(generationId = 100L, frameSource = "first"))

        val acquired = store.acquire(100L)
        val clearedWhilePinned = store.clear()

        assertEquals("first", acquired?.frameSource)
        assertTrue(clearedWhilePinned.isEmpty())

        val released = store.release(100L)

        assertEquals(1, released.size)
        assertEquals("first", released.single().frameSource)
        assertNull(store.resolve(100L))
    }

    @Test
    fun `snapshot store resolves only the requested generation`() {
        val store = FaceCaptureSnapshotStore<String>(maxEntries = 2)
        store.put(snapshot(generationId = 100L, frameSource = "first"))
        store.put(snapshot(generationId = 101L, frameSource = "second"))
        store.put(snapshot(generationId = 102L, frameSource = "third"))

        assertNull(store.resolve(100L))
        assertEquals("second", store.resolve(101L)?.frameSource)
        assertEquals("third", store.resolve(102L)?.frameSource)
    }

    @Test
    fun `accepted face capture request rejects stale landmark payloads`() {
        val snapshot = snapshot(generationId = 44L, frameSource = "frame-ref")
        val request = captureRequest(
            snapshot = snapshot,
            landmarks = listOf(
                NormalizedPoint(x = 0.1, y = 0.1),
                NormalizedPoint(x = 0.9, y = 0.9),
            ),
        )

        val error = validateAcceptedFaceCaptureRequest(snapshot, request)

        assertEquals(FACE_CAPTURE_NO_SNAPSHOT_CODE, error?.code)
        assertTrue(error?.message?.contains("landmark mismatch") == true)
    }

    @Test
    fun `accepted face capture request rejects generation mismatch`() {
        val snapshot = snapshot(generationId = 44L, frameSource = "frame-ref")
        val request = captureRequest(
            snapshot = snapshot,
            generationId = 45L,
        )

        val error = validateAcceptedFaceCaptureRequest(snapshot, request)

        assertEquals(FACE_CAPTURE_NO_SNAPSHOT_CODE, error?.code)
        assertTrue(error?.message?.contains("generation mismatch") == true)
    }

    @Test
    fun `accepted face capture request accepts matching metadata`() {
        val snapshot = snapshot(generationId = 51L, frameSource = "frame-ref")
        val request = captureRequest(snapshot = snapshot)

        val error = validateAcceptedFaceCaptureRequest(snapshot, request)

        assertNull(error)
    }

    @Test
    fun `resolved accepted face snapshot preserves boundary fields`() {
        val snapshot = snapshot(generationId = 51L, frameSource = "frame-ref")
        val guideRect = RectFCompat(left = 0.2, top = 0.1, width = 0.5, height = 0.6)
        val request = captureRequest(
            snapshot = snapshot,
            guideRect = guideRect,
        )

        val (acceptedSnapshot, error) = resolveAcceptedFaceCaptureSnapshot(snapshot, request)

        assertNull(error)
        assertEquals(51L, acceptedSnapshot?.generationId)
        assertEquals(52L, acceptedSnapshot?.timestampMs)
        assertEquals("frame-ref", acceptedSnapshot?.frameSource)
        assertEquals(guideRect, acceptedSnapshot?.guideRect)
        assertEquals(snapshot.landmarks, acceptedSnapshot?.landmarks)
        assertEquals(640, acceptedSnapshot?.analysisImageWidth)
        assertEquals(480, acceptedSnapshot?.analysisImageHeight)
        assertFalse(acceptedSnapshot?.isBackCamera ?: true)
        assertTrue(acceptedSnapshot?.mirrored == true)
    }

    @Test
    fun `capture payload preserves the expected key contract`() {
        val payload = buildScanCapturePayload(
            stage = FACE_CAPTURE_STAGE,
            sourcePath = "/tmp/source.jpg",
            croppedPath = "/tmp/crop.jpg",
            framePath = "/tmp/frame.jpg",
            sourceWidth = 640,
            sourceHeight = 480,
            cropLeft = 10,
            cropTop = 20,
            cropWidth = 200,
            cropHeight = 220,
        )

        assertEquals(
            setOf(
                "stage",
                "sourcePath",
                "croppedPath",
                "framePath",
                "sourceWidth",
                "sourceHeight",
                "cropLeft",
                "cropTop",
                "cropWidth",
                "cropHeight",
            ),
            payload.keys,
        )
        assertEquals(FACE_CAPTURE_STAGE, payload["stage"])
        assertEquals(640.0, payload["sourceWidth"])
        assertEquals(220.0, payload["cropHeight"])
    }

    private fun snapshot(
        generationId: Long,
        frameSource: String,
    ): FaceCaptureSnapshot<String> {
        return FaceCaptureSnapshot(
            generationId = generationId,
            timestampMs = generationId + 1,
            frameSource = frameSource,
            imageWidth = 640,
            imageHeight = 480,
            isBackCamera = false,
            mirrored = true,
            landmarks = listOf(
                NormalizedPoint(x = 0.2, y = 0.2),
                NormalizedPoint(x = 0.6, y = 0.7),
            ),
        )
    }

    private fun captureRequest(
        snapshot: FaceCaptureSnapshot<String>,
        generationId: Long = snapshot.generationId,
        guideRect: RectFCompat = RectFCompat(left = 0.2, top = 0.1, width = 0.5, height = 0.6),
        landmarks: List<NormalizedPoint> = snapshot.landmarks,
        analysisImageWidth: Int = snapshot.imageWidth,
        analysisImageHeight: Int = snapshot.imageHeight,
        isBackCamera: Boolean = snapshot.isBackCamera,
        mirrored: Boolean = snapshot.mirrored,
        timestampMs: Long? = snapshot.timestampMs,
    ): AcceptedFaceCaptureRequest {
        return AcceptedFaceCaptureRequest(
            generationId = generationId,
            guideRect = guideRect,
            landmarks = landmarks,
            analysisImageWidth = analysisImageWidth,
            analysisImageHeight = analysisImageHeight,
            isBackCamera = isBackCamera,
            mirrored = mirrored,
            timestampMs = timestampMs,
        )
    }
}
