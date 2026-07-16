import XCTest
@testable import PoseKit

final class ProcrustesTests: XCTestCase {
    let standing = Fixtures.standing

    func testIdentityScoresOne() {
        let s = ProcrustesAnalyzer.similarity(reference: standing, live: standing)
        XCTAssertEqual(s!, 1.0, accuracy: 1e-5)
    }

    func testTranslationInvariant() {
        let moved = Fixtures.transformed(standing, translation: [0.3, -0.2])
        XCTAssertEqual(ProcrustesAnalyzer.similarity(reference: standing, live: moved)!, 1.0, accuracy: 1e-5)
    }

    func testScaleInvariant() {
        let scaled = Fixtures.transformed(standing, scale: 2.7)
        XCTAssertEqual(ProcrustesAnalyzer.similarity(reference: standing, live: scaled)!, 1.0, accuracy: 1e-5)
    }

    func testRotationInvariant() {
        let rotated = Fixtures.transformed(standing, rotation: 0.6)
        XCTAssertEqual(ProcrustesAnalyzer.similarity(reference: standing, live: rotated)!, 1.0, accuracy: 1e-4)
    }

    func testCombinedTransformInvariant() {
        let t = Fixtures.transformed(standing, scale: 0.4, rotation: -1.1, translation: [5, 3])
        XCTAssertEqual(ProcrustesAnalyzer.similarity(reference: standing, live: t)!, 1.0, accuracy: 1e-4)
    }

    func testDifferentPoseScoresLower() {
        // Raise both wrists above head — clearly different shape.
        var p = standing.points
        p[.leftWrist] = [0.60, 0.02]; p[.rightWrist] = [0.40, 0.02]
        p[.leftElbow] = [0.62, 0.12]; p[.rightElbow] = [0.38, 0.12]
        let armsUp = PoseVector(points: p)
        let s = ProcrustesAnalyzer.similarity(reference: standing, live: armsUp)!
        XCTAssertLessThan(s, 0.97)
        XCTAssertGreaterThan(s, 0.5) // still same person shape, not garbage
    }

    func testMirrorScoresBelowIdentity() {
        var p: [Joint: SIMD2<Float>] = [:]
        for (j, pt) in standing.points { p[j] = [1 - pt.x, pt.y] }
        let mirrored = PoseVector(points: p)
        // Symmetric standing pose mirrors to near-itself geometrically, but joint
        // LABELS swap sides, so left wrist maps where right wrist was → penalized.
        var asym = standing.points
        asym[.leftWrist] = [0.70, 0.30] // make pose asymmetric first
        let asymPose = PoseVector(points: asym)
        var mirroredAsym: [Joint: SIMD2<Float>] = [:]
        for (j, pt) in asymPose.points { mirroredAsym[j] = [1 - pt.x, pt.y] }
        let s = ProcrustesAnalyzer.similarity(reference: asymPose, live: PoseVector(points: mirroredAsym))!
        XCTAssertLessThan(s, 0.99)
        _ = mirrored
    }

    func testTooFewCommonJointsReturnsNil() {
        let tiny = PoseVector(points: [.nose: [0.5, 0.1], .neck: [0.5, 0.2]])
        XCTAssertNil(ProcrustesAnalyzer.similarity(reference: standing, live: tiny))
    }

    func testDegenerateAllSamePointReturnsNil() {
        var p: [Joint: SIMD2<Float>] = [:]
        for j in Joint.allCases { p[j] = [0.5, 0.5] }
        XCTAssertNil(ProcrustesAnalyzer.similarity(reference: standing, live: PoseVector(points: p)))
    }

    func testSubsetOfJointsStillScores() {
        // Upper-body-only live pose (11 joints) vs full reference.
        let upper: [Joint] = [.nose, .leftEye, .rightEye, .neck, .leftShoulder, .rightShoulder,
                              .leftElbow, .rightElbow, .leftWrist, .rightWrist, .root]
        var p: [Joint: SIMD2<Float>] = [:]
        for j in upper { p[j] = standing.points[j]! }
        let s = ProcrustesAnalyzer.similarity(reference: standing, live: PoseVector(points: p))
        XCTAssertEqual(s!, 1.0, accuracy: 1e-5)
    }
}
