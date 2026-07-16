import XCTest
@testable import PoseKit

final class ReferencePoseTests: XCTestCase {
    func testJointHas19Cases() {
        XCTAssertEqual(Joint.allCases.count, 19)
    }

    func testFixtureHasAllJoints() {
        XCTAssertEqual(Fixtures.standing.points.count, 19)
    }
}
