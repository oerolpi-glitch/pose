package com.oerol.posekit

import org.junit.Assert.assertEquals
import org.junit.Test

class ReferencePoseTests {

    @Test
    fun jointHas19Cases() {
        assertEquals(19, Joint.entries.size)
    }

    @Test
    fun fixtureHasAllJoints() {
        assertEquals(19, Fixtures.standing.points.size)
    }

    @Test
    fun decodeFromJson() {
        val json = """
            {"id":"test-pose","title":"test pose","tags":["mirror"],
             "joints":{"nose":[0.5,0.14],"neck":[0.5,0.22]}}
        """.trimIndent()
        val pose = ReferencePose.fromJson(json)
        assertEquals("test-pose", pose.id)
        assertEquals(Vec2(0.5f, 0.14f), pose.poseVector.points[Joint.nose])
        assertEquals(2, pose.poseVector.points.size)
    }

    @Test
    fun unknownJointKeysSkipped() {
        val json = """
            {"id":"x","title":"x","tags":[],
             "joints":{"nose":[0.5,0.14],"tail":[0.1,0.2],"neck":[0.5]}}
        """.trimIndent()
        val pose = ReferencePose.fromJson(json)
        assertEquals(1, pose.poseVector.points.size) // tail unknown, neck malformed
    }
}
