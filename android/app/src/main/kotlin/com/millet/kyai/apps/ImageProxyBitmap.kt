package com.millet.kyai.apps

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import androidx.camera.core.ImageProxy
import java.io.ByteArrayOutputStream

internal fun ImageProxy.toRgbBitmap(): Bitmap {
    require(format == ImageFormat.YUV_420_888) {
        "Unsupported ImageProxy format for bitmap conversion: $format"
    }

    val nv21 = toNv21ByteArray()
    val yuvImage = YuvImage(nv21, ImageFormat.NV21, width, height, null)
    val jpegBytes = ByteArrayOutputStream().use { output ->
        check(yuvImage.compressToJpeg(Rect(0, 0, width, height), 100, output)) {
            "Failed to compress YUV image to JPEG."
        }
        output.toByteArray()
    }

    return BitmapFactory.decodeByteArray(jpegBytes, 0, jpegBytes.size)
        ?: error("Failed to decode JPEG bytes from camera frame.")
}

private fun ImageProxy.toNv21ByteArray(): ByteArray {
    val imageWidth = width
    val imageHeight = height
    val ySize = imageWidth * imageHeight
    val uvWidth = imageWidth / 2
    val uvHeight = imageHeight / 2
    val nv21 = ByteArray(ySize + (uvWidth * uvHeight * 2))

    copyPlane(
        plane = planes[0],
        output = nv21,
        outputOffset = 0,
        planeWidth = imageWidth,
        planeHeight = imageHeight,
    )

    val uPlane = planes[1]
    val vPlane = planes[2]
    val uBuffer = uPlane.buffer
    val vBuffer = vPlane.buffer
    var outputIndex = ySize

    for (row in 0 until uvHeight) {
        val uRowOffset = row * uPlane.rowStride
        val vRowOffset = row * vPlane.rowStride
        for (col in 0 until uvWidth) {
            val uIndex = uRowOffset + (col * uPlane.pixelStride)
            val vIndex = vRowOffset + (col * vPlane.pixelStride)
            nv21[outputIndex++] = vBuffer.get(vIndex)
            nv21[outputIndex++] = uBuffer.get(uIndex)
        }
    }

    return nv21
}

private fun copyPlane(
    plane: ImageProxy.PlaneProxy,
    output: ByteArray,
    outputOffset: Int,
    planeWidth: Int,
    planeHeight: Int,
) {
    val buffer = plane.buffer
    var outputIndex = outputOffset

    for (row in 0 until planeHeight) {
        val rowOffset = row * plane.rowStride
        for (col in 0 until planeWidth) {
            val index = rowOffset + (col * plane.pixelStride)
            output[outputIndex++] = buffer.get(index)
        }
    }
}
