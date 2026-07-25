/// The six body regions coaching speaks in. Ten bones are too fine a grain for
/// a person mid-pose to act on — "left arm" is actionable, "left forearm" reads
/// as a diagnostic. One region per thing the user can move as a unit.
public enum BodyRegion: String, Sendable, Equatable, CaseIterable {
    case head, torso, leftArm, rightArm, leftLeg, rightLeg

    /// User-facing name. The single source for both the hint sentence and the
    /// body map, so the two can never name the same limb differently.
    public var label: String {
        switch self {
        case .head:     return "head"
        case .torso:    return "torso"
        case .leftArm:  return "left arm"
        case .rightArm: return "right arm"
        case .leftLeg:  return "left leg"
        case .rightLeg: return "right leg"
        }
    }
}

public extension Bone {
    var region: BodyRegion {
        switch self {
        case .leftUpperArm, .leftForearm:   return .leftArm
        case .rightUpperArm, .rightForearm: return .rightArm
        case .leftThigh, .leftShin:         return .leftLeg
        case .rightThigh, .rightShin:       return .rightLeg
        case .torso:                        return .torso
        case .neck:                         return .head
        }
    }
}
