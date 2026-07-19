package com.oerol.posekit

import kotlin.math.sqrt

/**
 * Generalized Procrustes similarity between two 2D poses.
 * Invariant to translation, uniform scale, and rotation (not reflection).
 */
object ProcrustesAnalyzer {

    /**
     * @return similarity in [0,1]; null if fewer than [minimumJoints] common
     *   joints or either configuration is degenerate (zero centroid size).
     */
    fun similarity(reference: PoseVector, live: PoseVector, minimumJoints: Int = 8): Float? {
        val joints = reference.commonJoints(live)
        if (joints.size < minimumJoints) return null

        val x = joints.map { reference.points.getValue(it) }.toMutableList()
        val z = joints.map { live.points.getValue(it) }.toMutableList()

        center(x)
        center(z)
        if (!normalize(x) || !normalize(z)) return null

        var a = 0f
        var b = 0f
        for (i in x.indices) {
            a += x[i].dot(z[i])
            b += x[i].cross(z[i])
        }
        val corr = sqrt(a * a + b * b)
        return corr.coerceIn(0f, 1f)
    }

    private fun center(pts: MutableList<Vec2>) {
        var c = Vec2.ZERO
        for (p in pts) c += p
        c /= pts.size.toFloat()
        for (i in pts.indices) pts[i] -= c
    }

    /** Divide by centroid size. Returns false if size is ~0 (degenerate). */
    private fun normalize(pts: MutableList<Vec2>): Boolean {
        var ss = 0f
        for (p in pts) ss += p.x * p.x + p.y * p.y
        val size = sqrt(ss)
        if (size <= 1e-6f) return false
        for (i in pts.indices) pts[i] /= size
        return true
    }
}
