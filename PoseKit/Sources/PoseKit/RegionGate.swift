/// Debounces the set of marked regions so a limb hovering at the threshold
/// does not strobe on and off. Same hysteresis idea as `ReadinessGate`, but
/// per region: each region flips only after its raw state has disagreed with
/// the committed one for `framesToCommit` consecutive frames.
///
/// `PoseSmoother` smooths joint positions, which damps the underlying scores
/// but cannot stop a score that sits right on the boundary from crossing it
/// every other frame.
public struct RegionGate {
    public private(set) var committed: Set<BodyRegion>
    /// Consecutive frames each region's raw state has disagreed with `committed`.
    private var dissent: [BodyRegion: Int]
    private let framesToCommit: Int

    public init(framesToCommit: Int = 4) {
        self.committed = []
        self.dissent = [:]
        self.framesToCommit = max(1, framesToCommit)
    }

    @discardableResult
    public mutating func update(_ raw: Set<BodyRegion>) -> Set<BodyRegion> {
        for region in BodyRegion.allCases {
            if raw.contains(region) == committed.contains(region) {
                dissent[region] = 0
                continue
            }
            let streak = (dissent[region] ?? 0) + 1
            if streak >= framesToCommit {
                dissent[region] = 0
                if committed.contains(region) {
                    committed.remove(region)
                } else {
                    committed.insert(region)
                }
            } else {
                dissent[region] = streak
            }
        }
        return committed
    }

    public mutating func reset() {
        committed = []
        dissent = [:]
    }
}
