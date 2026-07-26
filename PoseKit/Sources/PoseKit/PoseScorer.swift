/// Combined pose similarity score with per-limb coaching feedback.
public struct PoseScore: Equatable, Sendable {
    public let overall: Float      // 0...1
    public let procrustes: Float   // 0...1, global shape
    public let limbMean: Float     // 0...1, mean per-bone direction match
    public let worstBone: Bone?
    /// Score of `worstBone`. Carried here so callers gating on the worst limb
    /// (readiness, auto-capture) don't run a second pass over every bone.
    public let worstLimb: Float
    /// Per-region worst-bone scores — the body map's data.
    public let regions: [BodyRegion: Float]
    public let hint: String?

    /// Regions the map marks. Empty whenever readiness is `.hold`, since both
    /// gate on the same worst-limb threshold.
    public var offRegions: Set<BodyRegion> {
        Set(regions.filter { $0.value < LimbSimilarity.regionOffThreshold }.keys)
    }
}

public enum PoseScorer {
    public static let procrustesWeight: Float = 0.7
    public static let limbWeight: Float = 0.3
    static let hintBoneThreshold: Float = 0.85

    public static func score(reference: PoseVector, live: PoseVector) -> PoseScore? {
        guard let proc = ProcrustesAnalyzer.similarity(reference: reference, live: live) else {
            return nil
        }
        // One pass over the bones feeds the mean, the worst limb, and the
        // region map — the caller used to recompute the worst limb per frame.
        let bones = LimbSimilarity.boneScores(reference: reference, live: live)
        let limbMean = bones.isEmpty ? proc : bones.values.reduce(0, +) / Float(bones.count)
        let worst = bones.min { $0.value < $1.value }.map { (bone: $0.key, score: $0.value) }

        var regions: [BodyRegion: Float] = [:]
        for (bone, score) in bones {
            let region = bone.region
            regions[region] = min(regions[region] ?? score, score)
        }

        let overall = procrustesWeight * proc + limbWeight * limbMean

        var hint: String?
        if let w = worst, w.score < hintBoneThreshold {
            hint = "adjust your \(w.bone.coachingName)"
        }
        return PoseScore(overall: overall, procrustes: proc, limbMean: limbMean,
                         worstBone: worst?.bone, worstLimb: worst?.score ?? 0,
                         regions: regions, hint: hint)
    }
}
