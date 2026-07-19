package com.oerol.posekit

/**
 * A detected or authored 2D pose. Coordinates are normalized [0,1], y-down.
 * Joints may be missing (occluded / low confidence / not authored).
 */
data class PoseVector(val points: Map<Joint, Vec2>) {

    /** Joints present in both poses, in declaration order. */
    fun commonJoints(other: PoseVector): List<Joint> =
        Joint.entries.filter { it in points && it in other.points }
}
