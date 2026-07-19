package com.oerol.posekit

import kotlin.math.abs
import kotlin.math.atan
import kotlin.math.min

/** A standalone coaching suggestion for guide-me mode (no target pose needed). */
data class CoachingHint(val message: String, val priority: Int)

/** Rule-based posture and framing analysis on a single live pose. */
object PostureHeuristics {
    internal const val SHOULDER_TILT_DEGREES: Float = 6f
    internal const val HEAD_TILT_DEGREES: Float = 8f
    internal const val GLUED_ARMS_RATIO: Float = 0.35f
    internal val CENTER_BAND: ClosedFloatingPointRange<Float> = 0.38f..0.62f

    fun hints(pose: PoseVector): List<CoachingHint> {
        val out = mutableListOf<CoachingHint>()
        val p = pose.points

        val ls = p[Joint.leftShoulder]
        val rs = p[Joint.rightShoulder]
        if (ls != null && rs != null && lineTiltDegrees(ls, rs) > SHOULDER_TILT_DEGREES) {
            out.add(CoachingHint("level your shoulders", 0))
        }
        val le = p[Joint.leftEye]
        val re = p[Joint.rightEye]
        if (le != null && re != null && lineTiltDegrees(le, re) > HEAD_TILT_DEGREES) {
            out.add(CoachingHint("straighten your head", 1))
        }
        val lw = p[Joint.leftWrist]
        val rw = p[Joint.rightWrist]
        val lh = p[Joint.leftHip]
        val rh = p[Joint.rightHip]
        if (lw != null && rw != null && lh != null && rh != null && ls != null && rs != null) {
            val shoulderWidth = abs(ls.x - rs.x)
            if (shoulderWidth > 1e-4f) {
                val leftGap = min(abs(lw.x - lh.x), abs(lw.x - rh.x))
                val rightGap = min(abs(rw.x - rh.x), abs(rw.x - lh.x))
                if (leftGap < GLUED_ARMS_RATIO * shoulderWidth &&
                    rightGap < GLUED_ARMS_RATIO * shoulderWidth
                ) {
                    out.add(CoachingHint("create space between arms and body", 2))
                }
            }
        }
        if (p.isNotEmpty()) {
            val cx = p.values.fold(0f) { acc, v -> acc + v.x } / p.size
            if (cx !in CENTER_BAND) {
                out.add(CoachingHint("step toward the center", 3))
            }
        }
        val top = p.values.minOfOrNull { it.y }
        val nose = p[Joint.nose]
        if (top != null && top < 0.03f) {
            out.add(CoachingHint("step back a little", 4))
        } else if (nose != null && nose.y > 0.35f) {
            out.add(CoachingHint("raise the camera", 4))
        }

        return out.sortedBy { it.priority }.take(2)
    }

    /** Absolute tilt of the line a→b vs horizontal, in degrees. */
    private fun lineTiltDegrees(a: Vec2, b: Vec2): Float {
        val dx = abs(a.x - b.x)
        val dy = abs(a.y - b.y)
        if (dx <= 1e-6f) return 90f
        return atan(dy / dx) * 180f / Math.PI.toFloat()
    }
}
