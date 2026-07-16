import XCTest
@testable import PoseKit

final class LimbTests: XCTestCase {
    let standing = Fixtures.standing

    func testIdenticalPoseAllBonesScoreOne() {
        let scores = LimbSimilarity.boneScores(reference: standing, live: standing)
        XCTAssertEqual(scores.count, 10)
        for (_, s) in scores { XCTAssertEqual(s, 1.0, accuracy: 1e-5) }
    }

    func testOppositeLimbScoresZero() {
        var p = standing.points
        // Point left forearm straight up instead of down (opposite direction).
        let elbow = p[.leftElbow]!
        let wrist = p[.leftWrist]!
        p[.leftWrist] = elbow - (wrist - elbow)
        let live = PoseVector(points: p)
        let scores = LimbSimilarity.boneScores(reference: standing, live: live)
        XCTAssertEqual(scores[.leftForearm]!, 0.0, accuracy: 1e-5)
        XCTAssertEqual(scores[.rightForearm]!, 1.0, accuracy: 1e-5)
    }

    func testPerpendicularLimbScoresHalf() {
        var p = standing.points
        let elbow = p[.leftElbow]!
        let wrist = p[.leftWrist]!
        let d = wrist - elbow
        p[.leftWrist] = elbow + SIMD2<Float>(-d.y, d.x) // rotate bone 90°
        let scores = LimbSimilarity.boneScores(reference: standing, live: PoseVector(points: p))
        XCTAssertEqual(scores[.leftForearm]!, 0.5, accuracy: 1e-5)
    }

    func testMissingEndpointOmitsBone() {
        var p = standing.points
        p[.leftWrist] = nil
        let scores = LimbSimilarity.boneScores(reference: standing, live: PoseVector(points: p))
        XCTAssertNil(scores[.leftForearm])
        XCTAssertEqual(scores.count, 9)
    }

    func testWorstBoneIdentified() {
        var p = standing.points
        let elbow = p[.rightElbow]!
        let wrist = p[.rightWrist]!
        p[.rightWrist] = elbow - (wrist - elbow)
        let worst = LimbSimilarity.worstBone(reference: standing, live: PoseVector(points: p))
        XCTAssertEqual(worst?.bone, .rightForearm)
    }

    func testMeanScoreNilWhenNoBones() {
        let empty = PoseVector(points: [.nose: [0.5, 0.1]])
        XCTAssertNil(LimbSimilarity.meanScore(reference: standing, live: empty))
    }
}
