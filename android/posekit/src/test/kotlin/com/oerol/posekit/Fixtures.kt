package com.oerol.posekit

import kotlin.math.cos
import kotlin.math.sin

object Fixtures {
    /** Neutral standing pose, normalized [0,1], y-down. All 19 joints. */
    val standing = PoseVector(
        mapOf(
            Joint.nose to Vec2(0.5f, 0.14f),
            Joint.leftEye to Vec2(0.53f, 0.12f),
            Joint.rightEye to Vec2(0.47f, 0.12f),
            Joint.leftEar to Vec2(0.555f, 0.135f),
            Joint.rightEar to Vec2(0.445f, 0.135f),
            Joint.neck to Vec2(0.5f, 0.22f),
            Joint.leftShoulder to Vec2(0.585f, 0.235f),
            Joint.rightShoulder to Vec2(0.415f, 0.235f),
            Joint.leftElbow to Vec2(0.615f, 0.36f),
            Joint.rightElbow to Vec2(0.385f, 0.36f),
            Joint.leftWrist to Vec2(0.63f, 0.475f),
            Joint.rightWrist to Vec2(0.37f, 0.475f),
            Joint.root to Vec2(0.5f, 0.5f),
            Joint.leftHip to Vec2(0.555f, 0.5f),
            Joint.rightHip to Vec2(0.445f, 0.5f),
            Joint.leftKnee to Vec2(0.55f, 0.68f),
            Joint.rightKnee to Vec2(0.45f, 0.68f),
            Joint.leftAnkle to Vec2(0.55f, 0.86f),
            Joint.rightAnkle to Vec2(0.45f, 0.86f),
        )
    )

    /** Apply an affine transform (scale, rotation radians, translation) to every point. */
    fun transformed(
        pose: PoseVector,
        scale: Float = 1f,
        rotation: Float = 0f,
        translation: Vec2 = Vec2.ZERO,
    ): PoseVector {
        val c = cos(rotation)
        val s = sin(rotation)
        val out = mutableMapOf<Joint, Vec2>()
        for ((j, p) in pose.points) {
            val r = Vec2(c * p.x - s * p.y, s * p.x + c * p.y)
            out[j] = r * scale + translation
        }
        return PoseVector(out)
    }
}
