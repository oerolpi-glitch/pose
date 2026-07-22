/// Debounces `PoseReadiness` so the HUD does not strobe between states while
/// the user holds still. A candidate state must repeat `framesToCommit` times
/// before it is committed.
public struct ReadinessGate {
    public private(set) var committed: PoseReadiness
    private var candidate: PoseReadiness
    private var streak: Int
    private let framesToCommit: Int

    public init(initial: PoseReadiness = .adjust, framesToCommit: Int = 4) {
        self.committed = initial
        self.candidate = initial
        self.streak = 0
        self.framesToCommit = max(1, framesToCommit)
    }

    /// Feeds one frame's raw readiness; returns the committed state.
    @discardableResult
    public mutating func update(_ raw: PoseReadiness) -> PoseReadiness {
        if raw == committed {
            candidate = raw
            streak = 0
            return committed
        }
        if raw == candidate {
            streak += 1
        } else {
            candidate = raw
            streak = 1
        }
        if streak >= framesToCommit {
            committed = candidate
            streak = 0
        }
        return committed
    }

    public mutating func reset() {
        committed = .adjust
        candidate = .adjust
        streak = 0
    }
}
