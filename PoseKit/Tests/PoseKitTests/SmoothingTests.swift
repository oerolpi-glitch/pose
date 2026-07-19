import XCTest
@testable import PoseKit

final class SmoothingTests: XCTestCase {

    func testConstantInputPassesThrough() {
        let smoother = PoseSmoother()
        var out = Fixtures.standing
        for i in 0..<30 {
            out = smoother.smooth(Fixtures.standing, timestamp: Double(i) / 30)
        }
        for (j, p) in Fixtures.standing.points {
            XCTAssertEqual(out.points[j]!.x, p.x, accuracy: 1e-4, "\(j)")
            XCTAssertEqual(out.points[j]!.y, p.y, accuracy: 1e-4, "\(j)")
        }
    }

    func testJitterVarianceReduced() {
        // Deterministic pseudo-noise around a fixed point; smoothed output
        // must deviate from the true position less than the raw input does.
        let smoother = PoseSmoother()
        let base = SIMD2<Float>(0.5, 0.5)
        var rawDev: Float = 0, smoothDev: Float = 0
        var seed: UInt32 = 1
        for i in 0..<120 {
            seed = seed &* 1664525 &+ 1013904223
            let nx = (Float(seed % 1000) / 1000 - 0.5) * 0.02   // ±1% jitter
            seed = seed &* 1664525 &+ 1013904223
            let ny = (Float(seed % 1000) / 1000 - 0.5) * 0.02
            let noisy = PoseVector(points: [.nose: base + SIMD2<Float>(nx, ny)])
            let out = smoother.smooth(noisy, timestamp: Double(i) / 30)
            if i >= 10 { // after warm-up
                rawDev += (nx * nx + ny * ny).squareRoot()
                let d = out.points[.nose]! - base
                smoothDev += (d.x * d.x + d.y * d.y).squareRoot()
            }
        }
        XCTAssertLessThan(smoothDev, rawDev * 0.6,
                          "smoothing should cut jitter by >40% (raw \(rawDev), smooth \(smoothDev))")
    }

    func testFastMotionTracksWithLowLag() {
        // A joint sweeping across the frame in 1s: the filter must open up and
        // stay close to the moving target (One Euro's defining property).
        let smoother = PoseSmoother()
        var lastOut: Float = 0
        var target: Float = 0
        for i in 0..<30 {
            target = Float(i) / 30 // 1.0 units/sec — fast for normalized space
            let pose = PoseVector(points: [.nose: SIMD2<Float>(target, 0.5)])
            lastOut = smoother.smooth(pose, timestamp: Double(i) / 30).points[.nose]!.x
        }
        XCTAssertEqual(lastOut, target, accuracy: 0.08, "lag too high on fast motion")
    }

    func testDroppedJointReentersCrisply() {
        let smoother = PoseSmoother()
        let a = PoseVector(points: [.nose: SIMD2<Float>(0.2, 0.2)])
        _ = smoother.smooth(a, timestamp: 0)
        _ = smoother.smooth(a, timestamp: 1.0 / 30)
        // Joint disappears for a frame...
        _ = smoother.smooth(PoseVector(points: [:]), timestamp: 2.0 / 30)
        // ...and re-enters far away: must snap there, not interpolate from 0.2.
        let far = PoseVector(points: [.nose: SIMD2<Float>(0.8, 0.8)])
        let out = smoother.smooth(far, timestamp: 3.0 / 30)
        XCTAssertEqual(out.points[.nose]!.x, 0.8, accuracy: 1e-5)
    }

    func testScoreSmootherConvergesAndDamps() {
        var s = ScoreSmoother(alpha: 0.3)
        XCTAssertEqual(s.smooth(0.9), 0.9, accuracy: 1e-6) // first value passes through
        let second = s.smooth(0.5) // big drop is damped
        XCTAssertEqual(second, 0.3 * 0.5 + 0.7 * 0.9, accuracy: 1e-6)
        var converged: Float = second
        for _ in 0..<40 { converged = s.smooth(0.5) }
        XCTAssertEqual(converged, 0.5, accuracy: 1e-3)
    }
}
