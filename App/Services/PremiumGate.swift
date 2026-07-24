import PoseKit

/// Resolves whether a pose is behind the Pose+ paywall. Pure so it can be
/// reasoned about without Superwall — the SDK only decides what happens when a
/// locked pose is tapped, not what counts as locked.
enum PremiumGate {
    static func isLocked(_ pose: ReferencePose, subscribed: Bool) -> Bool {
        !pose.free && !subscribed
    }
}
