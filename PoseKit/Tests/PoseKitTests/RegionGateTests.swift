import XCTest
@testable import PoseKit

final class RegionGateTests: XCTestCase {

    func testStartsEmpty() {
        let gate = RegionGate()
        XCTAssertTrue(gate.committed.isEmpty)
    }

    func testDoesNotMarkBeforeTheStreakCompletes() {
        var gate = RegionGate(framesToCommit: 4)
        for _ in 0..<3 {
            XCTAssertTrue(gate.update([.leftArm]).isEmpty)
        }
    }

    func testMarksOnTheCommitFrame() {
        var gate = RegionGate(framesToCommit: 4)
        for _ in 0..<3 { gate.update([.leftArm]) }
        XCTAssertEqual(gate.update([.leftArm]), [.leftArm])
    }

    func testClearingAlsoRequiresAStreak() {
        var gate = RegionGate(framesToCommit: 4)
        for _ in 0..<4 { gate.update([.leftArm]) }
        XCTAssertEqual(gate.committed, [.leftArm])

        for _ in 0..<3 {
            XCTAssertEqual(gate.update([]), [.leftArm], "must not clear early")
        }
        XCTAssertTrue(gate.update([]).isEmpty)
    }

    /// A single good frame in the middle of a bad run must not reset progress
    /// to zero and then re-earn it — but it must not sneak a commit through
    /// either. The streak restarts.
    func testInterruptingFrameResetsTheStreak() {
        var gate = RegionGate(framesToCommit: 4)
        gate.update([.leftArm])
        gate.update([.leftArm])
        gate.update([])            // dissent broken
        gate.update([.leftArm])
        gate.update([.leftArm])
        XCTAssertTrue(gate.committed.isEmpty, "streak restarted, so no commit yet")
        gate.update([.leftArm])
        gate.update([.leftArm])
        XCTAssertEqual(gate.committed, [.leftArm])
    }

    /// The failure this gate exists to prevent: a score sitting exactly on the
    /// threshold, alternating every frame. Nothing may ever commit.
    func testAlternatingFramesNeverCommit() {
        var gate = RegionGate(framesToCommit: 4)
        for i in 0..<40 {
            gate.update(i.isMultiple(of: 2) ? [.rightLeg] : [])
        }
        XCTAssertTrue(gate.committed.isEmpty, "a strobing region must never mark")
    }

    func testRegionsAreTrackedIndependently() {
        var gate = RegionGate(framesToCommit: 3)
        for _ in 0..<3 { gate.update([.leftArm]) }
        XCTAssertEqual(gate.committed, [.leftArm])

        // torso now goes off while leftArm stays off
        for _ in 0..<3 { gate.update([.leftArm, .torso]) }
        XCTAssertEqual(gate.committed, [.leftArm, .torso])

        // leftArm recovers, torso stays
        for _ in 0..<3 { gate.update([.torso]) }
        XCTAssertEqual(gate.committed, [.torso])
    }

    func testResetClearsEverything() {
        var gate = RegionGate(framesToCommit: 2)
        for _ in 0..<2 { gate.update([.head, .torso]) }
        XCTAssertFalse(gate.committed.isEmpty)
        gate.reset()
        XCTAssertTrue(gate.committed.isEmpty)
    }

    func testFramesToCommitIsClampedToAtLeastOne() {
        var gate = RegionGate(framesToCommit: 0)
        XCTAssertEqual(gate.update([.head]), [.head])
    }
}
