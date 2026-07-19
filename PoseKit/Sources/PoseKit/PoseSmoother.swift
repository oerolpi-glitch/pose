/// One Euro filter (Casiez, Roussel, Vogel 2012) — the standard low-latency
/// jitter filter for interactive tracking. At low speeds it smooths hard
/// (killing detector noise); at high speeds it opens up (following the body
/// with minimal lag). Applied per joint coordinate.
struct OneEuroFilter {
    let minCutoff: Float
    let beta: Float
    let derivativeCutoff: Float

    private var lastValue: Float?
    private var lastDerivative: Float = 0

    init(minCutoff: Float, beta: Float, derivativeCutoff: Float) {
        self.minCutoff = minCutoff
        self.beta = beta
        self.derivativeCutoff = derivativeCutoff
    }

    private static func alpha(cutoff: Float, dt: Float) -> Float {
        let tau = 1 / (2 * Float.pi * cutoff)
        return 1 / (1 + tau / dt)
    }

    mutating func filter(_ value: Float, dt: Float) -> Float {
        guard let last = lastValue, dt > 0 else {
            lastValue = value
            return value
        }
        let dAlpha = Self.alpha(cutoff: derivativeCutoff, dt: dt)
        let derivative = (value - last) / dt
        lastDerivative = dAlpha * derivative + (1 - dAlpha) * lastDerivative

        let cutoff = minCutoff + beta * abs(lastDerivative)
        let a = Self.alpha(cutoff: cutoff, dt: dt)
        let smoothed = a * value + (1 - a) * last
        lastValue = smoothed
        return smoothed
    }
}

/// Smooths a stream of detected poses. Stateful: feed every frame in order
/// with its timestamp. Joints that drop out (occlusion) have their filter
/// state discarded so they re-enter crisply instead of interpolating from a
/// stale position across the gap.
public final class PoseSmoother {
    public static let defaultMinCutoff: Float = 1.2
    public static let defaultBeta: Float = 0.6
    public static let defaultDerivativeCutoff: Float = 1.0

    private let minCutoff: Float
    private let beta: Float
    private let derivativeCutoff: Float

    private var filters: [Joint: (x: OneEuroFilter, y: OneEuroFilter)] = [:]
    private var lastTimestamp: Double?

    public init(minCutoff: Float = PoseSmoother.defaultMinCutoff,
                beta: Float = PoseSmoother.defaultBeta,
                derivativeCutoff: Float = PoseSmoother.defaultDerivativeCutoff) {
        self.minCutoff = minCutoff
        self.beta = beta
        self.derivativeCutoff = derivativeCutoff
    }

    public func reset() {
        filters.removeAll()
        lastTimestamp = nil
    }

    /// - Parameter timestamp: seconds, monotonically increasing (frame time).
    public func smooth(_ pose: PoseVector, timestamp: Double) -> PoseVector {
        defer { lastTimestamp = timestamp }
        let dt = Float(timestamp - (lastTimestamp ?? timestamp))

        var out: [Joint: SIMD2<Float>] = [:]
        var next: [Joint: (x: OneEuroFilter, y: OneEuroFilter)] = [:]
        for (joint, p) in pose.points {
            var pair = filters[joint] ?? (
                x: OneEuroFilter(minCutoff: minCutoff, beta: beta, derivativeCutoff: derivativeCutoff),
                y: OneEuroFilter(minCutoff: minCutoff, beta: beta, derivativeCutoff: derivativeCutoff)
            )
            let sx = pair.x.filter(p.x, dt: dt)
            let sy = pair.y.filter(p.y, dt: dt)
            out[joint] = SIMD2<Float>(sx, sy)
            next[joint] = pair
        }
        filters = next // joints absent this frame lose their state (crisp re-entry)
        return PoseVector(points: out)
    }
}

/// Exponential smoothing for the on-screen match score, so the readout climbs
/// and settles instead of flickering with per-frame detector noise.
public struct ScoreSmoother {
    public let alpha: Float
    private var value: Float?

    public init(alpha: Float = 0.3) {
        self.alpha = alpha
    }

    public mutating func reset() { value = nil }

    public mutating func smooth(_ score: Float) -> Float {
        let next = value.map { alpha * score + (1 - alpha) * $0 } ?? score
        value = next
        return next
    }
}
