package com.oerol.posekit

/** Combined pose similarity score with per-limb coaching feedback. */
data class PoseScore(
    val overall: Float,      // 0...1
    val procrustes: Float,   // 0...1, global shape
    val limbMean: Float,     // 0...1, mean per-bone direction match
    val worstBone: Bone?,
    val hint: String?,
)

object PoseScorer {
    const val PROCRUSTES_WEIGHT: Float = 0.7f
    const val LIMB_WEIGHT: Float = 0.3f
    internal const val HINT_BONE_THRESHOLD: Float = 0.85f

    fun score(reference: PoseVector, live: PoseVector): PoseScore? {
        val proc = ProcrustesAnalyzer.similarity(reference, live) ?: return null
        val limbMean = LimbSimilarity.meanScore(reference, live) ?: proc
        val worst = LimbSimilarity.worstBone(reference, live)
        val overall = PROCRUSTES_WEIGHT * proc + LIMB_WEIGHT * limbMean

        var hint: String? = null
        if (worst != null && worst.second < HINT_BONE_THRESHOLD) {
            hint = "adjust your ${worst.first.coachingName}"
        }
        return PoseScore(overall, proc, limbMean, worst?.first, hint)
    }
}
