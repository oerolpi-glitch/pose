import PoseKit

enum Fixtures {
    /// Neutral standing pose, normalized [0,1], y-down. All 19 joints.
    static let standing = PoseVector(points: [
        .nose: [0.5, 0.14], .leftEye: [0.53, 0.12], .rightEye: [0.47, 0.12],
        .leftEar: [0.555, 0.135], .rightEar: [0.445, 0.135],
        .neck: [0.5, 0.22],
        .leftShoulder: [0.585, 0.235], .rightShoulder: [0.415, 0.235],
        .leftElbow: [0.615, 0.36], .rightElbow: [0.385, 0.36],
        .leftWrist: [0.63, 0.475], .rightWrist: [0.37, 0.475],
        .root: [0.5, 0.5], .leftHip: [0.555, 0.5], .rightHip: [0.445, 0.5],
        .leftKnee: [0.55, 0.68], .rightKnee: [0.45, 0.68],
        .leftAnkle: [0.55, 0.86], .rightAnkle: [0.45, 0.86]
    ])

    /// Apply an affine transform (scale, rotation radians, translation) to every point.
    static func transformed(_ pose: PoseVector, scale: Float = 1, rotation: Float = 0,
                            translation: SIMD2<Float> = .zero) -> PoseVector {
        let c = cosf(rotation), s = sinf(rotation)
        var out: [Joint: SIMD2<Float>] = [:]
        for (j, p) in pose.points {
            let r = SIMD2<Float>(c * p.x - s * p.y, s * p.x + c * p.y)
            out[j] = r * scale + translation
        }
        return PoseVector(points: out)
    }
}

#if canImport(Foundation)
import Foundation
#endif
