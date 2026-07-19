#if canImport(Foundation)
import Foundation
#endif

/// The optimal rigid similarity (scale + rotation + translation, no
/// reflection) mapping one pose's coordinates onto another's — the transform
/// Procrustes analysis minimizes over, recovered explicitly so the reference
/// pose can be drawn ON the detected body ("the ghost snaps to you").
public struct SimilarityTransform: Equatable, Sendable {
    public let scale: Float
    public let rotation: Float      // radians
    public let translation: SIMD2<Float>

    /// Least-squares transform taking `reference` points onto `live` points.
    /// nil when fewer than `minimumJoints` joints are shared or the reference
    /// configuration is degenerate.
    public static func mapping(reference: PoseVector, live: PoseVector,
                               minimumJoints: Int = 8) -> SimilarityTransform? {
        let joints = reference.commonJoints(with: live)
        guard joints.count >= minimumJoints else { return nil }

        let x = joints.map { reference.points[$0]! }
        let z = joints.map { live.points[$0]! }
        let n = Float(joints.count)

        var cx = SIMD2<Float>.zero, cz = SIMD2<Float>.zero
        for p in x { cx += p }
        for p in z { cz += p }
        cx /= n
        cz /= n

        var a: Float = 0, b: Float = 0, normX: Float = 0
        for i in x.indices {
            let xi = x[i] - cx, zi = z[i] - cz
            a += xi.x * zi.x + xi.y * zi.y
            b += xi.x * zi.y - xi.y * zi.x
            normX += xi.x * xi.x + xi.y * xi.y
        }
        guard normX > 1e-9 else { return nil }

        let scale = (a * a + b * b).squareRoot() / normX
        let rotation = atan2f(b, a)
        // t = cz − s·R·cx
        let c = cosf(rotation), s = sinf(rotation)
        let rcx = SIMD2<Float>(c * cx.x - s * cx.y, s * cx.x + c * cx.y)
        let translation = cz - rcx * scale

        return SimilarityTransform(scale: scale, rotation: rotation, translation: translation)
    }

    public func apply(_ p: SIMD2<Float>) -> SIMD2<Float> {
        let c = cosf(rotation), s = sinf(rotation)
        let r = SIMD2<Float>(c * p.x - s * p.y, s * p.x + c * p.y)
        return r * scale + translation
    }
}
