import Foundation

/// The two camera coaching modes.
enum ShootingMode: String, CaseIterable, Identifiable, Hashable {
    case poseMe   // target pose + ghost overlay + score
    case guideMe  // standalone live coaching

    var id: String { rawValue }
}
