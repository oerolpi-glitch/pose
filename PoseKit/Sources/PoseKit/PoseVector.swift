/// A detected or authored 2D pose. Coordinates are normalized [0,1], y-down.
/// Joints may be missing (occluded / low confidence / not authored).
public struct PoseVector: Equatable, Sendable {
    public var points: [Joint: SIMD2<Float>]

    public init(points: [Joint: SIMD2<Float>]) {
        self.points = points
    }

    /// Joints present in both poses.
    public func commonJoints(with other: PoseVector) -> [Joint] {
        Joint.allCases.filter { points[$0] != nil && other.points[$0] != nil }
    }
}
