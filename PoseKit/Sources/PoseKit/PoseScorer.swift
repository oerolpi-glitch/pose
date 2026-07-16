/// Combined pose similarity score with per-limb coaching feedback.
public struct PoseScore: Equatable, Sendable {
    public let overall: Float      // 0...1
    public let procrustes: Float   // 0...1, global shape
    public let limbMean: Float     // 0...1, mean per-bone direction match
    public let worstBone: Bone?
    public let hint: String?
}

public enum PoseScorer {
    public static let procrustesWeight: Float = 0.7
    public static let limbWeight: Float = 0.3
    static let hintBoneThreshold: Float = 0.85

    public static func score(reference: PoseVector, live: PoseVector) -> PoseScore? {
        guard let proc = ProcrustesAnalyzer.similarity(reference: reference, live: live) else {
            return nil
        }
        let limbMean = LimbSimilarity.meanScore(reference: reference, live: live) ?? proc
        let worst = LimbSimilarity.worstBone(reference: reference, live: live)
        let overall = procrustesWeight * proc + limbWeight * limbMean

        var hint: String?
        if let w = worst, w.score < hintBoneThreshold {
            hint = "adjust your \(w.bone.coachingName)"
        }
        return PoseScore(overall: overall, procrustes: proc, limbMean: limbMean,
                         worstBone: worst?.bone, hint: hint)
    }
}
