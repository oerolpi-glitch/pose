package com.oerol.posekit

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class SimilarityTransformTests {
    private val standing = Fixtures.standing

    @Test
    fun identityRecovered() {
        val t = SimilarityTransform.mapping(standing, standing)!!
        assertEquals(1f, t.scale, 1e-4f)
        assertEquals(0f, t.rotation, 1e-4f)
        assertEquals(0f, t.translation.x, 1e-4f)
        assertEquals(0f, t.translation.y, 1e-4f)
    }

    @Test
    fun knownTransformRecovered() {
        val live = Fixtures.transformed(standing, scale = 1.7f, rotation = 0.4f,
                                        translation = Vec2(0.25f, -0.1f))
        val t = SimilarityTransform.mapping(standing, live)!!
        assertEquals(1.7f, t.scale, 1e-3f)
        assertEquals(0.4f, t.rotation, 1e-3f)
        for ((j, p) in standing.points) {
            val mapped = t.apply(p)
            assertEquals("$j.x", live.points.getValue(j).x, mapped.x, 1e-3f)
            assertEquals("$j.y", live.points.getValue(j).y, mapped.y, 1e-3f)
        }
    }

    @Test
    fun partialOverlapStillMaps() {
        val upper = listOf(
            Joint.nose, Joint.leftEye, Joint.rightEye, Joint.neck,
            Joint.leftShoulder, Joint.rightShoulder, Joint.leftElbow,
            Joint.rightElbow, Joint.leftWrist, Joint.rightWrist, Joint.root,
        )
        val live = Fixtures.transformed(standing, scale = 2.0f, translation = Vec2(1f, 1f))
        val partial = upper.associateWith { live.points.getValue(it) }
        val t = SimilarityTransform.mapping(standing, PoseVector(partial))!!
        val mappedAnkle = t.apply(standing.points.getValue(Joint.leftAnkle))
        assertEquals(live.points.getValue(Joint.leftAnkle).x, mappedAnkle.x, 1e-3f)
        assertEquals(live.points.getValue(Joint.leftAnkle).y, mappedAnkle.y, 1e-3f)
    }

    @Test
    fun tooFewJointsReturnsNull() {
        val tiny = PoseVector(mapOf(Joint.nose to Vec2(0.5f, 0.1f), Joint.neck to Vec2(0.5f, 0.2f)))
        assertNull(SimilarityTransform.mapping(standing, tiny))
    }

    @Test
    fun degenerateReferenceReturnsNull() {
        val p = Joint.entries.associateWith { Vec2(0.5f, 0.5f) }
        assertNull(SimilarityTransform.mapping(PoseVector(p), standing))
    }
}
