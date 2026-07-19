package com.oerol.posekit

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class HeuristicsTests {

    @Test
    fun neutralStandingNoHints() {
        assertTrue(PostureHeuristics.hints(Fixtures.standing).isEmpty())
    }

    @Test
    fun tiltedShouldersDetected() {
        val p = Fixtures.standing.points.toMutableMap()
        p[Joint.leftShoulder] = Vec2(0.585f, 0.20f)   // left shoulder raised
        p[Joint.rightShoulder] = Vec2(0.415f, 0.27f)
        val hints = PostureHeuristics.hints(PoseVector(p))
        assertEquals("level your shoulders", hints.firstOrNull()?.message)
    }

    @Test
    fun tiltedHeadDetected() {
        val p = Fixtures.standing.points.toMutableMap()
        p[Joint.leftEye] = Vec2(0.53f, 0.10f)
        p[Joint.rightEye] = Vec2(0.47f, 0.145f)
        val hints = PostureHeuristics.hints(PoseVector(p))
        assertTrue(hints.any { it.message == "straighten your head" })
    }

    @Test
    fun armsGluedDetected() {
        val p = Fixtures.standing.points.toMutableMap()
        p[Joint.leftWrist] = Vec2(0.565f, 0.475f)   // wrists right next to hips
        p[Joint.rightWrist] = Vec2(0.435f, 0.475f)
        val hints = PostureHeuristics.hints(PoseVector(p))
        assertTrue(hints.any { it.message == "create space between arms and body" })
    }

    @Test
    fun offCenterDetected() {
        val shifted = Fixtures.transformed(Fixtures.standing, translation = Vec2(0.25f, 0f))
        val hints = PostureHeuristics.hints(shifted)
        assertTrue(hints.any { it.message == "step toward the center" })
    }

    @Test
    fun maxTwoHints() {
        val p = Fixtures.standing.points.toMutableMap()
        p[Joint.leftShoulder] = Vec2(0.585f, 0.19f)
        p[Joint.rightShoulder] = Vec2(0.415f, 0.28f)
        p[Joint.leftEye] = Vec2(0.53f, 0.09f)
        p[Joint.rightEye] = Vec2(0.47f, 0.15f)
        p[Joint.leftWrist] = Vec2(0.565f, 0.475f)
        p[Joint.rightWrist] = Vec2(0.435f, 0.475f)
        val hints = PostureHeuristics.hints(PoseVector(p))
        assertEquals(2, hints.size)
        assertEquals(0, hints[0].priority)
    }

    @Test
    fun tooCloseDetected() {
        val shifted = Fixtures.transformed(Fixtures.standing, translation = Vec2(0f, -0.10f))
        val hints = PostureHeuristics.hints(shifted)
        assertTrue(hints.any { it.message == "step back a little" })
    }

    @Test
    fun subjectLowInFrameDetected() {
        val p = Fixtures.standing.points.toMutableMap()
        p[Joint.nose] = Vec2(0.5f, 0.36f)
        val hints = PostureHeuristics.hints(PoseVector(p))
        assertTrue(hints.any { it.message == "raise the camera" })
    }
}
