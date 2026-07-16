import XCTest
@testable import PoseKit

final class ScorerTests: XCTestCase {
    let standing = Fixtures.standing

    func testPerfectMatch() {
        let s = PoseScorer.score(reference: standing, live: standing)!
        XCTAssertEqual(s.overall, 1.0, accuracy: 1e-4)
        XCTAssertNil(s.hint)
    }

    func testWeighting() {
        let s = PoseScorer.score(reference: standing, live: standing)!
        XCTAssertEqual(s.overall, 0.7 * s.procrustes + 0.3 * s.limbMean, accuracy: 1e-5)
    }

    func testBadLimbProducesHint() {
        var p = standing.points
        let elbow = p[.leftElbow]!, wrist = p[.leftWrist]!
        p[.leftWrist] = elbow - (wrist - elbow)
        let s = PoseScorer.score(reference: standing, live: PoseVector(points: p))!
        XCTAssertEqual(s.worstBone, .leftForearm)
        XCTAssertEqual(s.hint, "adjust your left arm")
    }

    func testInsufficientJointsReturnsNil() {
        let tiny = PoseVector(points: [.nose: [0.5, 0.1]])
        XCTAssertNil(PoseScorer.score(reference: standing, live: tiny))
    }

    func testScoreIsTransformInvariant() {
        let t = Fixtures.transformed(standing, scale: 1.8, rotation: 0.3, translation: [2, 1])
        let s = PoseScorer.score(reference: standing, live: t)!
        // Procrustes invariant; limb cosine changes under rotation — overall still high.
        XCTAssertGreaterThan(s.overall, 0.9)
    }
}
