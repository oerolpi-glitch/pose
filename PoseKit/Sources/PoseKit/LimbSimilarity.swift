/// Skeleton bones used for per-limb directional comparison and coaching hints.
public enum Bone: String, CaseIterable, Sendable {
    case leftUpperArm, leftForearm, rightUpperArm, rightForearm
    case leftThigh, leftShin, rightThigh, rightShin
    case torso, neck

    public var endpoints: (Joint, Joint) {
        switch self {
        case .leftUpperArm:  return (.leftShoulder, .leftElbow)
        case .leftForearm:   return (.leftElbow, .leftWrist)
        case .rightUpperArm: return (.rightShoulder, .rightElbow)
        case .rightForearm:  return (.rightElbow, .rightWrist)
        case .leftThigh:     return (.leftHip, .leftKnee)
        case .leftShin:      return (.leftKnee, .leftAnkle)
        case .rightThigh:    return (.rightHip, .rightKnee)
        case .rightShin:     return (.rightKnee, .rightAnkle)
        case .torso:         return (.neck, .root)
        case .neck:          return (.nose, .neck)
        }
    }

    public var coachingName: String {
        switch self {
        case .leftUpperArm, .leftForearm:   return "left arm"
        case .rightUpperArm, .rightForearm: return "right arm"
        case .leftThigh, .leftShin:         return "left leg"
        case .rightThigh, .rightShin:       return "right leg"
        case .torso:                        return "torso"
        case .neck:                         return "head"
        }
    }
}

/// Per-bone cosine similarity between reference and live pose directions.
public enum LimbSimilarity {

    /// Cosine similarity per bone, remapped from [-1,1] to [0,1].
    /// Bones whose endpoints are missing in either pose are omitted.
    public static func boneScores(reference: PoseVector, live: PoseVector) -> [Bone: Float] {
        var out: [Bone: Float] = [:]
        for bone in Bone.allCases {
            let (a, b) = bone.endpoints
            guard let ra = reference.points[a], let rb = reference.points[b],
                  let la = live.points[a], let lb = live.points[b] else { continue }
            let rv = rb - ra, lv = lb - la
            let rm = (rv.x * rv.x + rv.y * rv.y).squareRoot()
            let lm = (lv.x * lv.x + lv.y * lv.y).squareRoot()
            guard rm > 1e-6, lm > 1e-6 else { continue }
            let cos = (rv.x * lv.x + rv.y * lv.y) / (rm * lm)
            out[bone] = (min(max(cos, -1), 1) + 1) / 2
        }
        return out
    }

    public static func meanScore(reference: PoseVector, live: PoseVector) -> Float? {
        let scores = boneScores(reference: reference, live: live)
        guard !scores.isEmpty else { return nil }
        return scores.values.reduce(0, +) / Float(scores.count)
    }

    public static func worstBone(reference: PoseVector, live: PoseVector) -> (bone: Bone, score: Float)? {
        boneScores(reference: reference, live: live).min { $0.value < $1.value }
            .map { (bone: $0.key, score: $0.value) }
    }
}
