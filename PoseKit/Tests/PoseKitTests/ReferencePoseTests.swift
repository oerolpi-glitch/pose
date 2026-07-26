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

final class ReferencePoseFramingTests: XCTestCase {

    private func pose(_ joints: [String: [Float]]) -> ReferencePose {
        ReferencePose(id: "t", title: "t", tags: [], joints: joints)
    }

    func testChestUpPoseIsCloseUp() {
        let p = pose(["nose": [0.5, 0.14], "neck": [0.5, 0.22],
                      "leftShoulder": [0.58, 0.24], "rightShoulder": [0.42, 0.24],
                      "leftHip": [0.55, 0.5], "rightHip": [0.45, 0.5]])
        XCTAssertTrue(p.isCloseUp)
    }

    func testAnklesMakeItFullBody() {
        let p = pose(["nose": [0.5, 0.1], "neck": [0.5, 0.2],
                      "leftHip": [0.55, 0.5], "rightHip": [0.45, 0.5],
                      "leftAnkle": [0.53, 0.95], "rightAnkle": [0.47, 0.95]])
        XCTAssertFalse(p.isCloseUp)
    }

    /// Knees alone are enough — a seated pose is still framed full-length.
    func testKneesAloneMakeItFullBody() {
        let p = pose(["neck": [0.5, 0.2],
                      "leftHip": [0.55, 0.5], "rightHip": [0.45, 0.5],
                      "leftKnee": [0.55, 0.75], "rightKnee": [0.45, 0.75]])
        XCTAssertFalse(p.isCloseUp)
    }

    /// The two bundled close-up poses must classify as such, and every other
    /// bundled pose must not — this is what decides the camera's framing.
    func testBundledPosesClassifyAsAuthored() {
        let closeUp = ["close-up-portrait", "peace-selfie"]
        let fullBody = ["classic-stand", "mirror-selfie", "hands-pockets",
                        "power-pose", "crossed-arms", "candid-walk",
                        "lean-wall", "seated-casual"]
        XCTAssertEqual(Set(closeUp).intersection(Set(fullBody)), [])
        XCTAssertEqual(closeUp.count + fullBody.count, 10)
    }
}
