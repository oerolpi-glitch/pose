package com.oerol.posekit

import kotlin.math.sqrt

/** 2D float vector — Kotlin stand-in for Swift's SIMD2<Float>. */
data class Vec2(val x: Float, val y: Float) {
    operator fun plus(o: Vec2) = Vec2(x + o.x, y + o.y)
    operator fun minus(o: Vec2) = Vec2(x - o.x, y - o.y)
    operator fun times(s: Float) = Vec2(x * s, y * s)
    operator fun div(s: Float) = Vec2(x / s, y / s)

    fun dot(o: Vec2): Float = x * o.x + y * o.y
    /** 2D cross product (z component). */
    fun cross(o: Vec2): Float = x * o.y - y * o.x
    fun length(): Float = sqrt(x * x + y * y)

    companion object {
        val ZERO = Vec2(0f, 0f)
    }
}
