package com.oerol.pose.camera

import android.annotation.SuppressLint
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.pose.Pose
import com.google.mlkit.vision.pose.PoseDetection
import com.google.mlkit.vision.pose.PoseLandmark
import com.google.mlkit.vision.pose.defaults.PoseDetectorOptions
import com.oerol.posekit.Joint
import com.oerol.posekit.PoseVector
import com.oerol.posekit.Vec2
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Runs ML Kit body-pose detection on camera frames and emits PoseKit poses in
 * normalized [0,1] y-down coordinates (mirrored horizontally for the front
 * camera so the pose matches the mirrored preview, like the iOS pipeline).
 *
 * Backpressure mirrors the iOS PoseDetectionService: while the detector is
 * busy, incoming frames are dropped — the preview never lags real time.
 */
class PoseAnalyzer(
    private val isFront: () -> Boolean,
    private val onPose: (pose: PoseVector?, bufferWidth: Int, bufferHeight: Int) -> Unit,
) : ImageAnalysis.Analyzer {

    private val detector = PoseDetection.getClient(
        PoseDetectorOptions.Builder()
            .setDetectorMode(PoseDetectorOptions.STREAM_MODE)
            .build()
    )
    private val busy = AtomicBoolean(false)
    private val minimumLikelihood = 0.5f

    /** ML Kit's 33 landmarks — the 17 that PoseKit's Joint set names directly.
     *  neck and root are synthesized from shoulder/hip midpoints below. */
    private val landmarkMap = mapOf(
        PoseLandmark.NOSE to Joint.nose,
        PoseLandmark.LEFT_EYE to Joint.leftEye,
        PoseLandmark.RIGHT_EYE to Joint.rightEye,
        PoseLandmark.LEFT_EAR to Joint.leftEar,
        PoseLandmark.RIGHT_EAR to Joint.rightEar,
        PoseLandmark.LEFT_SHOULDER to Joint.leftShoulder,
        PoseLandmark.RIGHT_SHOULDER to Joint.rightShoulder,
        PoseLandmark.LEFT_ELBOW to Joint.leftElbow,
        PoseLandmark.RIGHT_ELBOW to Joint.rightElbow,
        PoseLandmark.LEFT_WRIST to Joint.leftWrist,
        PoseLandmark.RIGHT_WRIST to Joint.rightWrist,
        PoseLandmark.LEFT_HIP to Joint.leftHip,
        PoseLandmark.RIGHT_HIP to Joint.rightHip,
        PoseLandmark.LEFT_KNEE to Joint.leftKnee,
        PoseLandmark.RIGHT_KNEE to Joint.rightKnee,
        PoseLandmark.LEFT_ANKLE to Joint.leftAnkle,
        PoseLandmark.RIGHT_ANKLE to Joint.rightAnkle,
    )

    @SuppressLint("UnsafeOptInUsageError")
    override fun analyze(proxy: ImageProxy) {
        if (!busy.compareAndSet(false, true)) {
            proxy.close() // drop frame, detector busy
            return
        }
        val media = proxy.image
        if (media == null) {
            busy.set(false)
            proxy.close()
            return
        }
        val rotation = proxy.imageInfo.rotationDegrees
        // Landmark coordinates come back in the upright (rotation-applied)
        // frame, so normalize against the upright dimensions.
        val width = if (rotation % 180 == 0) proxy.width else proxy.height
        val height = if (rotation % 180 == 0) proxy.height else proxy.width
        val front = isFront()

        detector.process(InputImage.fromMediaImage(media, rotation))
            .addOnSuccessListener { pose -> onPose(convert(pose, width, height, front), width, height) }
            .addOnFailureListener { onPose(null, width, height) }
            .addOnCompleteListener {
                busy.set(false)
                proxy.close()
            }
    }

    private fun convert(pose: Pose, width: Int, height: Int, front: Boolean): PoseVector? {
        val points = mutableMapOf<Joint, Vec2>()
        for ((landmarkType, joint) in landmarkMap) {
            val lm = pose.getPoseLandmark(landmarkType) ?: continue
            if (lm.inFrameLikelihood < minimumLikelihood) continue
            var x = lm.position.x / width
            if (front) x = 1f - x
            points[joint] = Vec2(x, lm.position.y / height)
        }
        // Vision provides neck and root directly; ML Kit doesn't — synthesize
        // them as segment midpoints so both platforms score the same skeleton.
        points[Joint.leftShoulder]?.let { ls ->
            points[Joint.rightShoulder]?.let { rs -> points[Joint.neck] = (ls + rs) / 2f }
        }
        points[Joint.leftHip]?.let { lh ->
            points[Joint.rightHip]?.let { rh -> points[Joint.root] = (lh + rh) / 2f }
        }
        return if (points.isEmpty()) null else PoseVector(points)
    }
}
