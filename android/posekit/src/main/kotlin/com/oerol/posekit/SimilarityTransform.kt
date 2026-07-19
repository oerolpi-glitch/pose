package com.oerol.posekit

import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * The optimal rigid similarity (scale + rotation + translation, no
 * reflection) mapping one pose's coordinates onto another's — recovered
 * explicitly so the reference pose can be drawn ON the detected body.
 * Mirrors the Swift SimilarityTransform one-to-one.
 */
data class SimilarityTransform(
    val scale: Float,
    val rotation: Float,       // radians
    val translation: Vec2,
) {
    fun apply(p: Vec2): Vec2 {
        val c = cos(rotation)
        val s = sin(rotation)
        val r = Vec2(c * p.x - s * p.y, s * p.x + c * p.y)
        return r * scale + translation
    }

    companion object {
        /**
         * Least-squares transform taking [reference] points onto [live] points.
         * null when fewer than [minimumJoints] joints are shared or the
         * reference configuration is degenerate.
         */
        fun mapping(
            reference: PoseVector,
            live: PoseVector,
            minimumJoints: Int = 8,
        ): SimilarityTransform? {
            val joints = reference.commonJoints(live)
            if (joints.size < minimumJoints) return null

            val x = joints.map { reference.points.getValue(it) }
            val z = joints.map { live.points.getValue(it) }
            val n = joints.size.toFloat()

            var cx = Vec2.ZERO
            var cz = Vec2.ZERO
            for (p in x) cx += p
            for (p in z) cz += p
            cx /= n
            cz /= n

            var a = 0f
            var b = 0f
            var normX = 0f
            for (i in x.indices) {
                val xi = x[i] - cx
                val zi = z[i] - cz
                a += xi.x * zi.x + xi.y * zi.y
                b += xi.x * zi.y - xi.y * zi.x
                normX += xi.x * xi.x + xi.y * xi.y
            }
            if (normX <= 1e-9f) return null

            val scale = sqrt(a * a + b * b) / normX
            val rotation = atan2(b, a)
            // t = cz − s·R·cx
            val c = cos(rotation)
            val s = sin(rotation)
            val rcx = Vec2(c * cx.x - s * cx.y, s * cx.x + c * cx.y)
            val translation = cz - rcx * scale

            return SimilarityTransform(scale, rotation, translation)
        }
    }
}
