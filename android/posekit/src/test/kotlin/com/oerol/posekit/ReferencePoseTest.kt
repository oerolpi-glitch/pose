package com.oerol.posekit

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ReferencePoseTest {
    @Test fun parsesCollectionsAndFree() {
        val json = """
            {"id":"x","title":"x","tags":["a"],"collections":["dating","fullbody"],
             "free":true,"joints":{"nose":[0.5,0.1]}}
        """.trimIndent()
        val pose = ReferencePose.fromJson(json)
        assertEquals(listOf("dating", "fullbody"), pose.collections)
        assertTrue(pose.free)
    }

    @Test fun legacyJsonDefaults() {
        val json = """{"id":"x","title":"x","tags":["a"],"joints":{"nose":[0.5,0.1]}}"""
        val pose = ReferencePose.fromJson(json)
        assertEquals(emptyList<String>(), pose.collections)
        assertFalse(pose.free)
    }
}
