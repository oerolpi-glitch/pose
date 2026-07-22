/// How ready the live pose is, as one honest signal shared by the camera HUD
/// and auto-capture. Deliberately not a percentage: the overall score is
/// Procrustes-dominated and reads ~0.9 for any upright body, so a number
/// invites false confidence. Three states the user can act on instead.
public enum PoseReadiness: String, Sendable, Equatable, CaseIterable {
    case adjust, almost, hold

    /// User-facing label. Lives here so the HUD and any future surface cannot drift.
    public var label: String {
        switch self {
        case .adjust: return "adjust"
        case .almost: return "almost"
        case .hold:   return "hold"
        }
    }
}

public enum ReadinessThresholds {
    /// `hold` requires BOTH the global shape and the worst individual limb to
    /// match. The worst-limb term is what stops an upright body with the arms
    /// in the wrong place from reading as correct.
    public static let holdOverall: Float = 0.92
    public static let holdWorstLimb: Float = 0.8
    public static let almostOverall: Float = 0.80
    public static let almostWorstLimb: Float = 0.6
}

public extension PoseReadiness {
    /// Single source of truth. Auto-capture arms exactly when this is `.hold`.
    static func from(overall: Float, worstLimb: Float) -> PoseReadiness {
        if overall >= ReadinessThresholds.holdOverall,
           worstLimb >= ReadinessThresholds.holdWorstLimb { return .hold }
        if overall >= ReadinessThresholds.almostOverall,
           worstLimb >= ReadinessThresholds.almostWorstLimb { return .almost }
        return .adjust
    }
}
