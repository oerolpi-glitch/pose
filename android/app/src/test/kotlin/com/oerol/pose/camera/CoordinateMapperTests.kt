package com.oerol.pose.camera

import com.oerol.posekit.Vec2
import org.junit.Assert.assertEquals
import org.junit.Test

class CoordinateMapperTests {

    @Test
    fun matchingAspectMapsDirectly() {
        // Buffer 1080x1920 into a 540x960 view: uniform 0.5 scale, no offset.
        val m = CoordinateMapper(1080f, 1920f, 540f, 960f)
        val p = m.viewPoint(Vec2(0.5f, 0.5f))
        assertEquals(270f, p.x, 1e-3f)
        assertEquals(480f, p.y, 1e-3f)
    }

    @Test
    fun widerViewCropsVertically() {
        // View wider than buffer aspect: fill by width, vertical overflow
        // centered — y=0 maps above the visible top (negative offset).
        val m = CoordinateMapper(1080f, 1920f, 1080f, 1080f)
        assertEquals(0f, m.viewX(0f), 1e-3f)
        assertEquals(1080f, m.viewX(1f), 1e-3f)
        assertEquals((1080f - 1920f) / 2, m.viewY(0f), 1e-3f)
        assertEquals(1080f + (1920f - 1080f) / 2, m.viewY(1f), 1e-3f)
    }

    @Test
    fun tallerViewCropsHorizontally() {
        // View taller than buffer aspect: fill by height, x overflow centered.
        val m = CoordinateMapper(1080f, 1920f, 400f, 1920f)
        assertEquals(1920f / 1920f * 1920f, m.viewY(1f), 1e-3f)
        assertEquals((400f - 1080f) / 2, m.viewX(0f), 1e-3f)
        assertEquals(400f + (1080f - 400f) / 2, m.viewX(1f), 1e-3f)
    }

    @Test
    fun centerStaysCenteredUnderAnyCrop() {
        val m = CoordinateMapper(1080f, 1920f, 700f, 900f)
        val p = m.viewPoint(Vec2(0.5f, 0.5f))
        assertEquals(350f, p.x, 1e-3f)
        assertEquals(450f, p.y, 1e-3f)
    }
}
