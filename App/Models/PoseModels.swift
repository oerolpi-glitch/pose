import Foundation

/// The two camera coaching modes.
enum ShootingMode: String, CaseIterable, Identifiable, Hashable {
    case poseMe   // target pose + ghost overlay + score
    case guideMe  // standalone live coaching

    var id: String { rawValue }

    var title: String {
        switch self {
        case .poseMe: return "pose me"
        case .guideMe: return "guide me"
        }
    }

    var subtitle: String {
        switch self {
        case .poseMe: return "posing guidance"
        case .guideMe: return "live coaching"
        }
    }
}
