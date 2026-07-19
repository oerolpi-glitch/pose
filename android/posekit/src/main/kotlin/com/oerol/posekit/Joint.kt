package com.oerol.posekit

/**
 * The 19 body joints tracked by the pose detector. Constant names are the JSON
 * keys used in bundled reference pose files (mirrors PoseKit's Swift `Joint`
 * raw values exactly — do not rename).
 */
@Suppress("EnumEntryName")
enum class Joint {
    nose, leftEye, rightEye, leftEar, rightEar,
    neck, leftShoulder, rightShoulder,
    leftElbow, rightElbow, leftWrist, rightWrist,
    root, leftHip, rightHip,
    leftKnee, rightKnee, leftAnkle, rightAnkle;

    companion object {
        fun fromKey(key: String): Joint? = entries.firstOrNull { it.name == key }
    }
}
