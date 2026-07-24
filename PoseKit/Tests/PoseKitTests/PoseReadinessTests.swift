import XCTest
@testable import PoseKit

final class PoseReadinessTests: XCTestCase {

    func testHighOverallWithBadLimbIsNotHold() {
        // The exact bug being fixed: Procrustes-dominated overall reads high
        // even when one limb is completely wrong.
        XCTAssertNotEqual(PoseReadiness.from(overall: 0.95, worstLimb: 0.5), .hold)
    }

    func testHighOverallWithGoodLimbIsHold() {
        XCTAssertEqual(PoseReadiness.from(overall: 0.95, worstLimb: 0.85), .hold)
    }

    func testMidRangeIsAlmost() {
        XCTAssertEqual(PoseReadiness.from(overall: 0.85, worstLimb: 0.7), .almost)
    }

    func testLowScoresAreAdjust() {
        XCTAssertEqual(PoseReadiness.from(overall: 0.5, worstLimb: 0.5), .adjust)
    }

    func testGateDoesNotChangeBeforeFramesToCommit() {
        var gate = ReadinessGate(initial: .adjust, framesToCommit: 4)
        XCTAssertEqual(gate.update(.hold), .adjust)
        XCTAssertEqual(gate.update(.hold), .adjust)
        XCTAssertEqual(gate.update(.hold), .adjust)
        XCTAssertEqual(gate.committed, .adjust)
    }

    func testGateCommitsAfterExactlyFramesToCommit() {
        var gate = ReadinessGate(initial: .adjust, framesToCommit: 4)
        XCTAssertEqual(gate.update(.hold), .adjust)
        XCTAssertEqual(gate.update(.hold), .adjust)
        XCTAssertEqual(gate.update(.hold), .adjust)
        XCTAssertEqual(gate.update(.hold), .hold)
        XCTAssertEqual(gate.committed, .hold)
    }

    func testInterruptingDifferentStateResetsStreak() {
        var gate = ReadinessGate(initial: .adjust, framesToCommit: 4)
        XCTAssertEqual(gate.update(.hold), .adjust)
        XCTAssertEqual(gate.update(.hold), .adjust)
        XCTAssertEqual(gate.update(.almost), .adjust) // interruption resets the streak
        XCTAssertEqual(gate.update(.hold), .adjust)
        XCTAssertEqual(gate.update(.hold), .adjust)
        XCTAssertEqual(gate.update(.hold), .adjust) // only 3 consecutive so far
        XCTAssertEqual(gate.update(.hold), .hold)   // 4th consecutive commits
    }

    func testResetReturnsToAdjust() {
        var gate = ReadinessGate(initial: .adjust, framesToCommit: 1)
        _ = gate.update(.hold)
        XCTAssertEqual(gate.committed, .hold)
        gate.reset()
        XCTAssertEqual(gate.committed, .adjust)
    }
}
