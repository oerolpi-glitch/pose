#if canImport(Foundation)
import Foundation
#endif

/// A standalone coaching suggestion for guide-me mode (no target pose needed).
public struct CoachingHint: Equatable, Sendable {
    public let message: String
    public let priority: Int
}

/// Rule-based posture and framing analysis on a single live pose.
public enum PostureHeuristics {
    static let shoulderTiltDegrees: Float = 6
    static let headTiltDegrees: Float = 8
    static let gluedArmsRatio: Float = 0.35
    static let centerBand: ClosedRange<Float> = 0.38...0.62

    public static func hints(for pose: PoseVector) -> [CoachingHint] {
        var out: [CoachingHint] = []
        let p = pose.points

        if let ls = p[.leftShoulder], let rs = p[.rightShoulder],
           lineTiltDegrees(ls, rs) > shoulderTiltDegrees {
            out.append(CoachingHint(message: "level your shoulders", priority: 0))
        }
        if let le = p[.leftEye], let re = p[.rightEye],
           lineTiltDegrees(le, re) > headTiltDegrees {
            out.append(CoachingHint(message: "straighten your head", priority: 1))
        }
        if let lw = p[.leftWrist], let rw = p[.rightWrist],
           let lh = p[.leftHip], let rh = p[.rightHip],
           let ls = p[.leftShoulder], let rs = p[.rightShoulder] {
            let shoulderWidth = abs(ls.x - rs.x)
            if shoulderWidth > 1e-4 {
                let leftGap = min(abs(lw.x - lh.x), abs(lw.x - rh.x))
                let rightGap = min(abs(rw.x - rh.x), abs(rw.x - lh.x))
                if leftGap < gluedArmsRatio * shoulderWidth,
                   rightGap < gluedArmsRatio * shoulderWidth {
                    out.append(CoachingHint(message: "create space between arms and body", priority: 2))
                }
            }
        }
        if !p.isEmpty {
            let cx = p.values.reduce(Float(0)) { $0 + $1.x } / Float(p.count)
            if !centerBand.contains(cx) {
                out.append(CoachingHint(message: "step toward the center", priority: 3))
            }
        }
        if let top = p.values.map(\.y).min(), top < 0.03 {
            out.append(CoachingHint(message: "step back a little", priority: 4))
        } else if let nose = p[.nose], nose.y > 0.35 {
            out.append(CoachingHint(message: "raise the camera", priority: 4))
        }

        return Array(out.sorted { $0.priority < $1.priority }.prefix(2))
    }

    /// Absolute tilt of the line a→b vs horizontal, in degrees.
    private static func lineTiltDegrees(_ a: SIMD2<Float>, _ b: SIMD2<Float>) -> Float {
        let dx = abs(a.x - b.x), dy = abs(a.y - b.y)
        guard dx > 1e-6 else { return 90 }
        return atanf(dy / dx) * 180 / Float.pi
    }
}
