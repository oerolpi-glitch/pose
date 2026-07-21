package com.oerol.pose.camera

import android.os.SystemClock
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import com.oerol.posekit.LimbSimilarity
import com.oerol.posekit.PoseScorer
import com.oerol.posekit.PoseSmoother
import com.oerol.posekit.PoseVector
import com.oerol.posekit.PostureHeuristics
import com.oerol.posekit.ReferencePose
import com.oerol.posekit.ScoreSmoother

/**
 * Mirrors the iOS CameraViewModel: smooths detector output, scores against the
 * target pose, projects the aligned ghost, and drives hands-free auto-capture.
 * All coordinates it exposes are normalized [0,1] y-down; the screen maps them
 * to view pixels with CoordinateMapper.
 */
class CameraViewModel(val targetPose: ReferencePose?) : ViewModel() {

    var livePose by mutableStateOf<PoseVector?>(null)
        private set
    var score by mutableStateOf<Float?>(null)
        private set
    var hintText by mutableStateOf<String?>(null)
        private set
    var bodyDetected by mutableStateOf(true)
        private set
    var autoCaptureProgress by mutableStateOf(0f)
        private set
    var bufferWidth by mutableStateOf(1080)
        private set
    var bufferHeight by mutableStateOf(1920)
        private set
    /** Hands-free auto-capture. Off by default — the shutter is manual unless
     *  the user opts in, because pose-match confidence isn't yet good enough
     *  to fire unattended without occasional false positives. */
    var handsFree by mutableStateOf(false)

    /** Set by the screen; invoked when the hold completes. */
    var onAutoCapture: (() -> Unit)? = null
    /** Screen sets true while a capture is in flight or previewing. */
    var captureBlocked = false

    private val poseSmoother = PoseSmoother()
    private val scoreSmoother = ScoreSmoother()
    private var holdStartMs: Long? = null
    /** Auto-capture fires once per matched pose; it re-arms only after the
     *  score drops back below REARM (you break the pose), so holding a good
     *  pose takes exactly one photo instead of a burst. */
    private var armed = true

    companion object {
        const val AUTO_CAPTURE_THRESHOLD = 0.92f
        // Every scored limb must also match this well, so the shape — not just
        // the Procrustes average — is right before an unattended shot fires.
        const val AUTO_CAPTURE_WORST_LIMB = 0.8f
        const val AUTO_CAPTURE_REARM = 0.7f
        const val AUTO_CAPTURE_HOLD_MS = 1200L
    }

    fun onFrame(pose: PoseVector?, width: Int, height: Int) {
        bufferWidth = width
        bufferHeight = height

        if (pose == null) {
            livePose = null
            score = null
            bodyDetected = false
            scoreSmoother.reset()
            updateHold(null)
            return
        }
        bodyDetected = true

        val smoothed = poseSmoother.smooth(pose, SystemClock.elapsedRealtime() / 1000.0)
        livePose = smoothed

        if (targetPose != null) {
            val result = PoseScorer.score(targetPose.poseVector, smoothed)
            if (result != null) {
                val display = scoreSmoother.smooth(result.overall)
                score = display
                hintText = result.hint
                val worstLimb = LimbSimilarity.worstBone(targetPose.poseVector, smoothed)?.second ?: 0f
                updateHold(display, worstLimb)
            } else {
                score = null
                hintText = null
                scoreSmoother.reset()
                updateHold(null, 0f)
            }
        } else {
            score = null
            hintText = PostureHeuristics.hints(smoothed).firstOrNull()?.message
        }
    }

    private fun updateHold(displayScore: Float?, worstLimb: Float = 0f) {
        if (targetPose == null) return
        // Re-arm once the pose is broken, so one held pose = one photo.
        if (displayScore != null && displayScore < AUTO_CAPTURE_REARM) armed = true

        if (!handsFree || captureBlocked || !armed) {
            holdStartMs = null
            autoCaptureProgress = 0f
            return
        }
        if (displayScore != null && displayScore >= AUTO_CAPTURE_THRESHOLD &&
            worstLimb >= AUTO_CAPTURE_WORST_LIMB) {
            val start = holdStartMs ?: SystemClock.elapsedRealtime().also { holdStartMs = it }
            val held = SystemClock.elapsedRealtime() - start
            autoCaptureProgress = (held.toFloat() / AUTO_CAPTURE_HOLD_MS).coerceAtMost(1f)
            if (held >= AUTO_CAPTURE_HOLD_MS) {
                holdStartMs = null
                autoCaptureProgress = 0f
                armed = false // won't fire again until the pose breaks and re-arms
                onAutoCapture?.invoke()
            }
        } else {
            holdStartMs = null
            autoCaptureProgress = 0f
        }
    }
}
