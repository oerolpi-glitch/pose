package com.oerol.posekit

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ProcrustesTests {
    private val standing = Fixtures.standing

    @Test
    fun identityScoresOne() {
        val s = ProcrustesAnalyzer.similarity(standing, standing)
        assertEquals(1.0f, s!!, 1e-5f)
    }

    @Test
    fun translationInvariant() {
        val moved = Fixtures.transformed(standing, translation = Vec2(0.3f, -0.2f))
        assertEquals(1.0f, ProcrustesAnalyzer.similarity(standing, moved)!!, 1e-5f)
    }

    @Test
    fun scaleInvariant() {
        val scaled = Fixtures.transformed(standing, scale = 2.7f)
        assertEquals(1.0f, ProcrustesAnalyzer.similarity(standing, scaled)!!, 1e-5f)
    }

    @Test
    fun rotationInvariant() {
        val rotated = Fixtures.transformed(standing, rotation = 0.6f)
        assertEquals(1.0f, ProcrustesAnalyzer.similarity(standing, rotated)!!, 1e-4f)
    }

    @Test
    fun combinedTransformInvariant() {
        val t = Fixtures.transformed(standing, scale = 0.4f, rotation = -1.1f, translation = Vec2(5f, 3f))
        assertEquals(1.0f, ProcrustesAnalyzer.similarity(standing, t)!!, 1e-4f)
    }

    @Test
    fun differentPoseScoresLower() {
        // Raise both wrists above head — clearly different shape.
        val p = standing.points.toMutableMap()
        p[Joint.leftWrist] = Vec2(0.60f, 0.02f)
        p[Joint.rightWrist] = Vec2(0.40f, 0.02f)
        p[Joint.leftElbow] = Vec2(0.62f, 0.12f)
        p[Joint.rightElbow] = Vec2(0.38f, 0.12f)
        val armsUp = PoseVector(p)
        val s = ProcrustesAnalyzer.similarity(standing, armsUp)!!
        assertTrue(s < 0.97f)
        assertTrue(s > 0.5f) // still same person shape, not garbage
    }

    @Test
    fun mirrorScoresBelowIdentity() {
        // Symmetric standing pose mirrors to near-itself geometrically, but joint
        // LABELS swap sides, so left wrist maps where right wrist was → penalized.
        val asym = standing.points.toMutableMap()
        asym[Joint.leftWrist] = Vec2(0.70f, 0.30f) // make pose asymmetric first
        val asymPose = PoseVector(asym)
        val mirroredAsym = asymPose.points.mapValues { (_, pt) -> Vec2(1f - pt.x, pt.y) }
        val s = ProcrustesAnalyzer.similarity(asymPose, PoseVector(mirroredAsym))!!
        assertTrue(s < 0.99f)
    }

    @Test
    fun tooFewCommonJointsReturnsNull() {
        val tiny = PoseVector(mapOf(Joint.nose to Vec2(0.5f, 0.1f), Joint.neck to Vec2(0.5f, 0.2f)))
        assertNull(ProcrustesAnalyzer.similarity(standing, tiny))
    }

    @Test
    fun degenerateAllSamePointReturnsNull() {
        val p = Joint.entries.associateWith { Vec2(0.5f, 0.5f) }
        assertNull(ProcrustesAnalyzer.similarity(standing, PoseVector(p)))
    }

    @Test
    fun subsetOfJointsStillScores() {
        // Upper-body-only live pose (11 joints) vs full reference.
        val upper = listOf(
            Joint.nose, Joint.leftEye, Joint.rightEye, Joint.neck,
            Joint.leftShoulder, Joint.rightShoulder,
            Joint.leftElbow, Joint.rightElbow, Joint.leftWrist, Joint.rightWrist, Joint.root,
        )
        val p = upper.associateWith { standing.points.getValue(it) }
        val s = ProcrustesAnalyzer.similarity(standing, PoseVector(p))
        assertEquals(1.0f, s!!, 1e-5f)
    }
}
