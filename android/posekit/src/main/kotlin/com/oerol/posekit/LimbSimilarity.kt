package com.oerol.posekit

/** Skeleton bones used for per-limb directional comparison and coaching hints. */
enum class Bone(val endpoints: Pair<Joint, Joint>, val coachingName: String) {
    LEFT_UPPER_ARM(Joint.leftShoulder to Joint.leftElbow, "left arm"),
    LEFT_FOREARM(Joint.leftElbow to Joint.leftWrist, "left arm"),
    RIGHT_UPPER_ARM(Joint.rightShoulder to Joint.rightElbow, "right arm"),
    RIGHT_FOREARM(Joint.rightElbow to Joint.rightWrist, "right arm"),
    LEFT_THIGH(Joint.leftHip to Joint.leftKnee, "left leg"),
    LEFT_SHIN(Joint.leftKnee to Joint.leftAnkle, "left leg"),
    RIGHT_THIGH(Joint.rightHip to Joint.rightKnee, "right leg"),
    RIGHT_SHIN(Joint.rightKnee to Joint.rightAnkle, "right leg"),
    TORSO(Joint.neck to Joint.root, "torso"),
    NECK(Joint.nose to Joint.neck, "head");
}

/** Per-bone cosine similarity between reference and live pose directions. */
object LimbSimilarity {

    /**
     * Cosine similarity per bone, remapped from [-1,1] to [0,1].
     * Bones whose endpoints are missing in either pose are omitted.
     */
    fun boneScores(reference: PoseVector, live: PoseVector): Map<Bone, Float> {
        val out = mutableMapOf<Bone, Float>()
        for (bone in Bone.entries) {
            val (a, b) = bone.endpoints
            val ra = reference.points[a] ?: continue
            val rb = reference.points[b] ?: continue
            val la = live.points[a] ?: continue
            val lb = live.points[b] ?: continue
            val rv = rb - ra
            val lv = lb - la
            val rm = rv.length()
            val lm = lv.length()
            if (rm <= 1e-6f || lm <= 1e-6f) continue
            val cos = rv.dot(lv) / (rm * lm)
            out[bone] = (cos.coerceIn(-1f, 1f) + 1f) / 2f
        }
        return out
    }

    fun meanScore(reference: PoseVector, live: PoseVector): Float? {
        val scores = boneScores(reference, live)
        if (scores.isEmpty()) return null
        return scores.values.sum() / scores.size
    }

    fun worstBone(reference: PoseVector, live: PoseVector): Pair<Bone, Float>? =
        boneScores(reference, live).minByOrNull { it.value }?.toPair()
}
