import XCTest
@testable import PoseKit

final class SimilarityTransformTests: XCTestCase {
    let standing = Fixtures.standing

    func testIdentityRecovered() {
        let t = SimilarityTransform.mapping(reference: standing, live: standing)!
        XCTAssertEqual(t.scale, 1, accuracy: 1e-4)
        XCTAssertEqual(t.rotation, 0, accuracy: 1e-4)
        XCTAssertEqual(t.translation.x, 0, accuracy: 1e-4)
        XCTAssertEqual(t.translation.y, 0, accuracy: 1e-4)
    }

    func testKnownTransformRecovered() {
        let live = Fixtures.transformed(standing, scale: 1.7, rotation: 0.4,
                                        translation: [0.25, -0.1])
        let t = SimilarityTransform.mapping(reference: standing, live: live)!
        XCTAssertEqual(t.scale, 1.7, accuracy: 1e-3)
        XCTAssertEqual(t.rotation, 0.4, accuracy: 1e-3)
        // The recovered transform must land every reference joint on its live twin.
        for (j, p) in standing.points {
            let mapped = t.apply(p)
            XCTAssertEqual(mapped.x, live.points[j]!.x, accuracy: 1e-3, "\(j).x")
            XCTAssertEqual(mapped.y, live.points[j]!.y, accuracy: 1e-3, "\(j).y")
        }
    }

    func testPartialOverlapStillMaps() {
        // Live pose missing legs (upper body only) still yields a transform
        // that projects the FULL reference onto the body.
        let upper: [Joint] = [.nose, .leftEye, .rightEye, .neck, .leftShoulder,
                              .rightShoulder, .leftElbow, .rightElbow, .leftWrist,
                              .rightWrist, .root]
        let live = Fixtures.transformed(standing, scale: 2.0, translation: [1, 1])
        var partial: [Joint: SIMD2<Float>] = [:]
        for j in upper { partial[j] = live.points[j]! }
        let t = SimilarityTransform.mapping(reference: standing,
                                            live: PoseVector(points: partial))!
        // Check a LEG joint (absent from live) projects to where live legs are.
        let mappedAnkle = t.apply(standing.points[.leftAnkle]!)
        XCTAssertEqual(mappedAnkle.x, live.points[.leftAnkle]!.x, accuracy: 1e-3)
        XCTAssertEqual(mappedAnkle.y, live.points[.leftAnkle]!.y, accuracy: 1e-3)
    }

    func testTooFewJointsReturnsNil() {
        let tiny = PoseVector(points: [.nose: [0.5, 0.1], .neck: [0.5, 0.2]])
        XCTAssertNil(SimilarityTransform.mapping(reference: standing, live: tiny))
    }

    func testDegenerateReferenceReturnsNil() {
        var p: [Joint: SIMD2<Float>] = [:]
        for j in Joint.allCases { p[j] = [0.5, 0.5] }
        XCTAssertNil(SimilarityTransform.mapping(reference: PoseVector(points: p),
                                                 live: standing))
    }
}
