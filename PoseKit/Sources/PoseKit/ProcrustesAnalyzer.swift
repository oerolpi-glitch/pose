/// Generalized Procrustes similarity between two 2D poses.
/// Invariant to translation, uniform scale, and rotation (not reflection).
public enum ProcrustesAnalyzer {

    /// - Returns: similarity in [0,1]; nil if < minimumJoints common joints
    ///   or either configuration is degenerate (zero centroid size).
    public static func similarity(reference: PoseVector, live: PoseVector,
                                  minimumJoints: Int = 8) -> Float? {
        let joints = reference.commonJoints(with: live)
        guard joints.count >= minimumJoints else { return nil }

        var x = joints.map { reference.points[$0]! }
        var z = joints.map { live.points[$0]! }

        center(&x)
        center(&z)
        guard normalize(&x), normalize(&z) else { return nil }

        var a: Float = 0, b: Float = 0
        for i in x.indices {
            a += x[i].x * z[i].x + x[i].y * z[i].y   // dot
            b += x[i].x * z[i].y - x[i].y * z[i].x   // 2D cross
        }
        let corr = (a * a + b * b).squareRoot()
        return min(max(corr, 0), 1)
    }

    private static func center(_ pts: inout [SIMD2<Float>]) {
        var c = SIMD2<Float>.zero
        for p in pts { c += p }
        c /= Float(pts.count)
        for i in pts.indices { pts[i] -= c }
    }

    /// Divide by centroid size. Returns false if size is ~0 (degenerate).
    private static func normalize(_ pts: inout [SIMD2<Float>]) -> Bool {
        var ss: Float = 0
        for p in pts { ss += p.x * p.x + p.y * p.y }
        let size = ss.squareRoot()
        guard size > 1e-6 else { return false }
        for i in pts.indices { pts[i] /= size }
        return true
    }
}
