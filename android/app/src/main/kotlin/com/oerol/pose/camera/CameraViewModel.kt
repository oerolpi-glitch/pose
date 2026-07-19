package com.oerol.pose.camera

import android.os.SystemClock
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import com.oerol.posekit.Bone
import com.oerol.posekit.PoseScorer
import com.oerol.posekit.PoseSmoother
import com.oerol.posekit.PoseVector
import com.oerol.posekit.PostureHeuristics
import com.oerol.posekit.ReferencePose
import com.oerol.posekit.ScoreSmoother
import com.oerol.posekit.SimilarityTransform
import com.oerol.posekit.Vec2

/**
 * Mirrors the iOS CameraViewModel: smooths detector output, scores against the
 * target pose, projects the aligned ghost, and drives hands-free auto-capture.
 * All coordinates it exposes are normalized [0,1] y-down; the screen maps them
 * to view pixels with CoordinateMapper.
 */
class CameraViewModel(val targetPose: ReferencePose?) : ViewModel() {

    var livePose by mutableStateOf<PoseVector?>(null)
        private set
    var ghostSegments by mutableStateOf<List<Pair<Vec2, Vec2>>>(emptyList())
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

    /** Set by the screen; invoked when the hold completes. */
    var onAutoCapture: (() -> Unit)? = null
    /** Screen sets true while a capture is in flight or previewing. */
    var captureBlocked = false

    private val poseSmoother = PoseSmoother()
    private val scoreSmoother = ScoreSmoother()
    private var holdStartMs: Long? = null

    companion object {
        const val AUTO_CAPTURE_THRESHOLD = 0.85f
        const val AUTO_CAPTURE_HOLD_MS = 1000L
    }

    fun onFrame(pose: PoseVector?, width: Int, height: Int) {
        bufferWidth = width
        bufferHeight = height

        if (pose == null) {
            livePose = null
            ghostSegments = emptyList()
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
            updateGhost(smoothed)
            val result = PoseScorer.score(targetPose.poseVector, smoothed)
            if (result != null) {
                val display = scoreSmoother.smooth(result.overall)
                score = display
                hintText = result.hint
                updateHold(display)
            } else {
                score = null
                hintText = null
                scoreSmoother.reset()
                updateHold(null)
            }
        } else {
            score = null
            hintText = PostureHeuristics.hints(smoothed).firstOrNull()?.message
        }
    }

    /** Projects the reference pose onto the detected body — the gold ghost
     *  stands where the user stands, at their size. */
    private fun updateGhost(live: PoseVector) {
        val target = targetPose ?: return
        val transform = SimilarityTransform.mapping(target.poseVector, live)
        if (transform == null) {
            ghostSegments = emptyList()
            return
        }
        val reference = target.poseVector
        ghostSegments = Bone.entries.mapNotNull { bone ->
            val (a, b) = bone.endpoints
            val pa = reference.points[a] ?: return@mapNotNull null
            val pb = reference.points[b] ?: return@mapNotNull null
            transform.apply(pa) to transform.apply(pb)
        }
    }

    private fun updateHold(displayScore: Float?) {
        if (targetPose == null) return
        if (captureBlocked) {
            holdStartMs = null
            autoCaptureProgress = 0f
            return
        }
        if (displayScore != null && displayScore >= AUTO_CAPTURE_THRESHOLD) {
            val start = holdStartMs ?: SystemClock.elapsedRealtime().also { holdStartMs = it }
            val held = SystemClock.elapsedRealtime() - start
            autoCaptureProgress = (held.toFloat() / AUTO_CAPTURE_HOLD_MS).coerceAtMost(1f)
            if (held >= AUTO_CAPTURE_HOLD_MS) {
                holdStartMs = null
                autoCaptureProgress = 0f
                onAutoCapture?.invoke()
            }
        } else {
            holdStartMs = null
            autoCaptureProgress = 0f
        }
    }
}
