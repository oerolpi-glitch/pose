package com.oerol.posekit

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ScorerTests {
    private val standing = Fixtures.standing

    @Test
    fun perfectMatch() {
        val s = PoseScorer.score(standing, standing)!!
        assertEquals(1.0f, s.overall, 1e-4f)
        assertNull(s.hint)
    }

    @Test
    fun weighting() {
        val s = PoseScorer.score(standing, standing)!!
        assertEquals(0.7f * s.procrustes + 0.3f * s.limbMean, s.overall, 1e-5f)
    }

    @Test
    fun badLimbProducesHint() {
        val p = standing.points.toMutableMap()
        val elbow = p.getValue(Joint.leftElbow)
        val wrist = p.getValue(Joint.leftWrist)
        p[Joint.leftWrist] = elbow - (wrist - elbow)
        val s = PoseScorer.score(standing, PoseVector(p))!!
        assertEquals(Bone.LEFT_FOREARM, s.worstBone)
        assertEquals("adjust your left arm", s.hint)
    }

    @Test
    fun insufficientJointsReturnsNull() {
        val tiny = PoseVector(mapOf(Joint.nose to Vec2(0.5f, 0.1f)))
        assertNull(PoseScorer.score(standing, tiny))
    }

    @Test
    fun scoreIsTransformInvariant() {
        val t = Fixtures.transformed(standing, scale = 1.8f, rotation = 0.3f, translation = Vec2(2f, 1f))
        val s = PoseScorer.score(standing, t)!!
        // Procrustes invariant; limb cosine changes under rotation — overall still high.
        assertTrue(s.overall > 0.9f)
    }
}
