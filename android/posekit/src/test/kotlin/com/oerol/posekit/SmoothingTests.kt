package com.oerol.posekit

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.sqrt

class SmoothingTests {

    @Test
    fun constantInputPassesThrough() {
        val smoother = PoseSmoother()
        var out = Fixtures.standing
        for (i in 0 until 30) {
            out = smoother.smooth(Fixtures.standing, i / 30.0)
        }
        for ((j, p) in Fixtures.standing.points) {
            assertEquals("$j.x", p.x, out.points.getValue(j).x, 1e-4f)
            assertEquals("$j.y", p.y, out.points.getValue(j).y, 1e-4f)
        }
    }

    @Test
    fun jitterVarianceReduced() {
        val smoother = PoseSmoother()
        val base = Vec2(0.5f, 0.5f)
        var rawDev = 0f
        var smoothDev = 0f
        var seed = 1L
        for (i in 0 until 120) {
            seed = (seed * 1664525 + 1013904223) and 0xFFFFFFFFL
            val nx = ((seed % 1000) / 1000f - 0.5f) * 0.02f
            seed = (seed * 1664525 + 1013904223) and 0xFFFFFFFFL
            val ny = ((seed % 1000) / 1000f - 0.5f) * 0.02f
            val noisy = PoseVector(mapOf(Joint.nose to base + Vec2(nx, ny)))
            val out = smoother.smooth(noisy, i / 30.0)
            if (i >= 10) {
                rawDev += sqrt(nx * nx + ny * ny)
                val d = out.points.getValue(Joint.nose) - base
                smoothDev += sqrt(d.x * d.x + d.y * d.y)
            }
        }
        assertTrue(
            "smoothing should cut jitter by >40% (raw $rawDev, smooth $smoothDev)",
            smoothDev < rawDev * 0.6f,
        )
    }

    @Test
    fun fastMotionTracksWithLowLag() {
        val smoother = PoseSmoother()
        var lastOut = 0f
        var target = 0f
        for (i in 0 until 30) {
            target = i / 30f
            val pose = PoseVector(mapOf(Joint.nose to Vec2(target, 0.5f)))
            lastOut = smoother.smooth(pose, i / 30.0).points.getValue(Joint.nose).x
        }
        assertEquals("lag too high on fast motion", target, lastOut, 0.08f)
    }

    @Test
    fun droppedJointReentersCrisply() {
        val smoother = PoseSmoother()
        val a = PoseVector(mapOf(Joint.nose to Vec2(0.2f, 0.2f)))
        smoother.smooth(a, 0.0)
        smoother.smooth(a, 1.0 / 30)
        smoother.smooth(PoseVector(emptyMap()), 2.0 / 30)
        val far = PoseVector(mapOf(Joint.nose to Vec2(0.8f, 0.8f)))
        val out = smoother.smooth(far, 3.0 / 30)
        assertEquals(0.8f, out.points.getValue(Joint.nose).x, 1e-5f)
    }

    @Test
    fun scoreSmootherConvergesAndDamps() {
        val s = ScoreSmoother(alpha = 0.3f)
        assertEquals(0.9f, s.smooth(0.9f), 1e-6f)
        val second = s.smooth(0.5f)
        assertEquals(0.3f * 0.5f + 0.7f * 0.9f, second, 1e-6f)
        var converged = second
        for (i in 0 until 40) converged = s.smooth(0.5f)
        assertEquals(0.5f, converged, 1e-3f)
    }
}
