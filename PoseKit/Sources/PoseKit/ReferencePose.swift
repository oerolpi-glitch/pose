#if canImport(Foundation)
import Foundation
#endif

/// An authored target pose bundled with the app as JSON.
public struct ReferencePose: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let tags: [String]
    public let joints: [String: [Float]]

    public init(id: String, title: String, tags: [String], joints: [String: [Float]]) {
        self.id = id
        self.title = title
        self.tags = tags
        self.joints = joints
    }

    /// Typed pose. Unknown joint names and arrays without exactly 2 values are skipped.
    public var poseVector: PoseVector {
        var pts: [Joint: SIMD2<Float>] = [:]
        for (key, arr) in joints {
            guard let joint = Joint(rawValue: key), arr.count == 2 else { continue }
            pts[joint] = SIMD2<Float>(arr[0], arr[1])
        }
        return PoseVector(points: pts)
    }
}
