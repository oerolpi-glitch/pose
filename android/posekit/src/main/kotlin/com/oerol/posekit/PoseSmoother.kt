package com.oerol.posekit

import kotlin.math.abs

/**
 * One Euro filter (Casiez, Roussel, Vogel 2012) — the standard low-latency
 * jitter filter for interactive tracking. At low speeds it smooths hard
 * (killing detector noise); at high speeds it opens up (following the body
 * with minimal lag). Applied per joint coordinate. Mirrors the Swift
 * PoseSmoother one-to-one.
 */
internal class OneEuroFilter(
    private val minCutoff: Float,
    private val beta: Float,
    private val derivativeCutoff: Float,
) {
    private var lastValue: Float? = null
    private var lastDerivative = 0f

    private fun alpha(cutoff: Float, dt: Float): Float {
        val tau = 1f / (2f * Math.PI.toFloat() * cutoff)
        return 1f / (1f + tau / dt)
    }

    fun filter(value: Float, dt: Float): Float {
        val last = lastValue
        if (last == null || dt <= 0f) {
            lastValue = value
            return value
        }
        val dAlpha = alpha(derivativeCutoff, dt)
        val derivative = (value - last) / dt
        lastDerivative = dAlpha * derivative + (1 - dAlpha) * lastDerivative

        val cutoff = minCutoff + beta * abs(lastDerivative)
        val a = alpha(cutoff, dt)
        val smoothed = a * value + (1 - a) * last
        lastValue = smoothed
        return smoothed
    }
}

/**
 * Smooths a stream of detected poses. Stateful: feed every frame in order
 * with its timestamp. Joints that drop out (occlusion) have their filter
 * state discarded so they re-enter crisply.
 */
class PoseSmoother(
    private val minCutoff: Float = DEFAULT_MIN_CUTOFF,
    private val beta: Float = DEFAULT_BETA,
    private val derivativeCutoff: Float = DEFAULT_DERIVATIVE_CUTOFF,
) {
    companion object {
        const val DEFAULT_MIN_CUTOFF = 1.2f
        const val DEFAULT_BETA = 0.6f
        const val DEFAULT_DERIVATIVE_CUTOFF = 1.0f
    }

    private var filters = mutableMapOf<Joint, Pair<OneEuroFilter, OneEuroFilter>>()
    private var lastTimestamp: Double? = null

    fun reset() {
        filters.clear()
        lastTimestamp = null
    }

    /** @param timestamp seconds, monotonically increasing (frame time). */
    fun smooth(pose: PoseVector, timestamp: Double): PoseVector {
        val dt = (timestamp - (lastTimestamp ?: timestamp)).toFloat()
        lastTimestamp = timestamp

        val out = mutableMapOf<Joint, Vec2>()
        val next = mutableMapOf<Joint, Pair<OneEuroFilter, OneEuroFilter>>()
        for ((joint, p) in pose.points) {
            val pair = filters[joint] ?: Pair(
                OneEuroFilter(minCutoff, beta, derivativeCutoff),
                OneEuroFilter(minCutoff, beta, derivativeCutoff),
            )
            out[joint] = Vec2(pair.first.filter(p.x, dt), pair.second.filter(p.y, dt))
            next[joint] = pair
        }
        filters = next // joints absent this frame lose their state (crisp re-entry)
        return PoseVector(out)
    }
}

/**
 * Exponential smoothing for the on-screen match score, so the readout climbs
 * and settles instead of flickering with per-frame detector noise.
 */
class ScoreSmoother(private val alpha: Float = 0.3f) {
    private var value: Float? = null

    fun reset() { value = null }

    fun smooth(score: Float): Float {
        val next = value?.let { alpha * score + (1 - alpha) * it } ?: score
        value = next
        return next
    }
}
