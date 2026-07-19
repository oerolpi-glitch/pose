package com.oerol.posekit

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class LimbTests {
    private val standing = Fixtures.standing

    @Test
    fun identicalPoseAllBonesScoreOne() {
        val scores = LimbSimilarity.boneScores(standing, standing)
        assertEquals(10, scores.size)
        for ((_, s) in scores) assertEquals(1.0f, s, 1e-5f)
    }

    @Test
    fun oppositeLimbScoresZero() {
        val p = standing.points.toMutableMap()
        // Point left forearm straight up instead of down (opposite direction).
        val elbow = p.getValue(Joint.leftElbow)
        val wrist = p.getValue(Joint.leftWrist)
        p[Joint.leftWrist] = elbow - (wrist - elbow)
        val live = PoseVector(p)
        val scores = LimbSimilarity.boneScores(standing, live)
        assertEquals(0.0f, scores.getValue(Bone.LEFT_FOREARM), 1e-5f)
        assertEquals(1.0f, scores.getValue(Bone.RIGHT_FOREARM), 1e-5f)
    }

    @Test
    fun perpendicularLimbScoresHalf() {
        val p = standing.points.toMutableMap()
        val elbow = p.getValue(Joint.leftElbow)
        val wrist = p.getValue(Joint.leftWrist)
        val d = wrist - elbow
        p[Joint.leftWrist] = elbow + Vec2(-d.y, d.x) // rotate bone 90°
        val scores = LimbSimilarity.boneScores(standing, PoseVector(p))
        assertEquals(0.5f, scores.getValue(Bone.LEFT_FOREARM), 1e-5f)
    }

    @Test
    fun missingEndpointOmitsBone() {
        val p = standing.points.toMutableMap()
        p.remove(Joint.leftWrist)
        val scores = LimbSimilarity.boneScores(standing, PoseVector(p))
        assertNull(scores[Bone.LEFT_FOREARM])
        assertEquals(9, scores.size)
    }

    @Test
    fun worstBoneIdentified() {
        val p = standing.points.toMutableMap()
        val elbow = p.getValue(Joint.rightElbow)
        val wrist = p.getValue(Joint.rightWrist)
        p[Joint.rightWrist] = elbow - (wrist - elbow)
        val worst = LimbSimilarity.worstBone(standing, PoseVector(p))
        assertEquals(Bone.RIGHT_FOREARM, worst?.first)
    }

    @Test
    fun meanScoreNullWhenNoBones() {
        val empty = PoseVector(mapOf(Joint.nose to Vec2(0.5f, 0.1f)))
        assertNull(LimbSimilarity.meanScore(standing, empty))
    }
}
