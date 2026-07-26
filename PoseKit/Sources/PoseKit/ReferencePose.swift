#if canImport(Foundation)
import Foundation
#endif

/// An authored target pose bundled with the app as JSON.
public struct ReferencePose: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let tags: [String]
    /// Intent-collection ids this pose belongs to (e.g. "dating", "mirror").
    public let collections: [String]
    /// Free tier: usable without a Pose+ subscription.
    public let free: Bool
    public let joints: [String: [Float]]

    public init(id: String, title: String, tags: [String],
                collections: [String] = [], free: Bool = false,
                joints: [String: [Float]]) {
        self.id = id
        self.title = title
        self.tags = tags
        self.collections = collections
        self.free = free
        self.joints = joints
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, tags, collections, free, joints
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        tags = try c.decode([String].self, forKey: .tags)
        collections = try c.decodeIfPresent([String].self, forKey: .collections) ?? []
        free = try c.decodeIfPresent(Bool.self, forKey: .free) ?? false
        joints = try c.decode([String: [Float]].self, forKey: .joints)
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
