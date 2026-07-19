package com.oerol.pose.camera

import com.oerol.posekit.Vec2

/**
 * Maps normalized pose coordinates ([0,1], y-down, already mirrored for the
 * front camera by PoseAnalyzer) into view pixels for an aspect-fill preview —
 * the same center-crop math as the iOS CoordinateMapper, minus the Vision
 * y-flip (ML Kit is already y-down).
 */
class CoordinateMapper(
    private val bufferWidth: Float,   // upright (rotation-applied) buffer dims
    private val bufferHeight: Float,
    private val viewWidth: Float,
    private val viewHeight: Float,
) {
    private val scale = maxOf(viewWidth / bufferWidth, viewHeight / bufferHeight)
    private val offsetX = (viewWidth - bufferWidth * scale) / 2
    private val offsetY = (viewHeight - bufferHeight * scale) / 2

    fun viewX(normalizedX: Float): Float = normalizedX * bufferWidth * scale + offsetX
    fun viewY(normalizedY: Float): Float = normalizedY * bufferHeight * scale + offsetY

    fun viewPoint(p: Vec2): Vec2 = Vec2(viewX(p.x), viewY(p.y))
}
