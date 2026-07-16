import XCTest
@testable import PoseKit

final class HeuristicsTests: XCTestCase {
    func testNeutralStandingNoHints() {
        XCTAssertTrue(PostureHeuristics.hints(for: Fixtures.standing).isEmpty)
    }

    func testTiltedShouldersDetected() {
        var p = Fixtures.standing.points
        p[.leftShoulder] = [0.585, 0.20]   // left shoulder raised
        p[.rightShoulder] = [0.415, 0.27]
        let hints = PostureHeuristics.hints(for: PoseVector(points: p))
        XCTAssertEqual(hints.first?.message, "level your shoulders")
    }

    func testTiltedHeadDetected() {
        var p = Fixtures.standing.points
        p[.leftEye] = [0.53, 0.10]
        p[.rightEye] = [0.47, 0.145]
        let hints = PostureHeuristics.hints(for: PoseVector(points: p))
        XCTAssertTrue(hints.contains { $0.message == "straighten your head" })
    }

    func testArmsGluedDetected() {
        var p = Fixtures.standing.points
        p[.leftWrist] = [0.565, 0.475]   // wrists right next to hips
        p[.rightWrist] = [0.435, 0.475]
        let hints = PostureHeuristics.hints(for: PoseVector(points: p))
        XCTAssertTrue(hints.contains { $0.message == "create space between arms and body" })
    }

    func testOffCenterDetected() {
        let shifted = Fixtures.transformed(Fixtures.standing, translation: [0.25, 0])
        let hints = PostureHeuristics.hints(for: shifted)
        XCTAssertTrue(hints.contains { $0.message == "step toward the center" })
    }

    func testMaxTwoHints() {
        var p = Fixtures.standing.points
        p[.leftShoulder] = [0.585, 0.19]; p[.rightShoulder] = [0.415, 0.28]
        p[.leftEye] = [0.53, 0.09]; p[.rightEye] = [0.47, 0.15]
        p[.leftWrist] = [0.565, 0.475]; p[.rightWrist] = [0.435, 0.475]
        let hints = PostureHeuristics.hints(for: PoseVector(points: p))
        XCTAssertEqual(hints.count, 2)
        XCTAssertEqual(hints[0].priority, 0)
    }
}
