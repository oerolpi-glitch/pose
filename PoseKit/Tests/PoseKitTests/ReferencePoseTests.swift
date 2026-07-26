import Foundation
import XCTest
@testable import PoseKit

final class ReferencePoseTests: XCTestCase {
    func testJointHas19Cases() {
        XCTAssertEqual(Joint.allCases.count, 19)
    }

    func testFixtureHasAllJoints() {
        XCTAssertEqual(Fixtures.standing.points.count, 19)
    }

    func testDecodeFromJSON() throws {
        let json = """
        {"id":"test-pose","title":"test pose","tags":["mirror"],
         "joints":{"nose":[0.5,0.14],"neck":[0.5,0.22]}}
        """.data(using: .utf8)!
        let pose = try JSONDecoder().decode(ReferencePose.self, from: json)
        XCTAssertEqual(pose.id, "test-pose")
        XCTAssertEqual(pose.poseVector.points[.nose], SIMD2<Float>(0.5, 0.14))
        XCTAssertEqual(pose.poseVector.points.count, 2)
    }

    func testUnknownJointKeysSkipped() throws {
        let json = """
        {"id":"x","title":"x","tags":[],
         "joints":{"nose":[0.5,0.14],"tail":[0.1,0.2],"neck":[0.5]}}
        """.data(using: .utf8)!
        let pose = try JSONDecoder().decode(ReferencePose.self, from: json)
        XCTAssertEqual(pose.poseVector.points.count, 1) // tail unknown, neck malformed
    }

    func testDecodesCollectionsAndFree() throws {
        let json = """
        {"id":"x","title":"x","tags":["a"],"collections":["dating","fullbody"],
         "free":true,"joints":{"nose":[0.5,0.1]}}
        """.data(using: .utf8)!
        let pose = try JSONDecoder().decode(ReferencePose.self, from: json)
        XCTAssertEqual(pose.collections, ["dating", "fullbody"])
        XCTAssertTrue(pose.free)
    }

    func testLegacyJsonDefaultsCollectionsEmptyAndNotFree() throws {
        let json = """
        {"id":"x","title":"x","tags":["a"],"joints":{"nose":[0.5,0.1]}}
        """.data(using: .utf8)!
        let pose = try JSONDecoder().decode(ReferencePose.self, from: json)
        XCTAssertEqual(pose.collections, [])
        XCTAssertFalse(pose.free)
    }
}
