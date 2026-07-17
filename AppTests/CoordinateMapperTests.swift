import XCTest
@testable import Pose

final class CoordinateMapperTests: XCTestCase {
    // Buffer 720x1280 portrait, view 360x640 — same aspect, scale 0.5, no crop.
    func testSameAspectScales() {
        let m = CoordinateMapper(bufferSize: CGSize(width: 720, height: 1280),
                                 viewSize: CGSize(width: 360, height: 640),
                                 isMirrored: false)
        // Vision (0.5, 0.5) center → view center
        XCTAssertEqual(m.viewPoint(fromVisionPoint: CGPoint(x: 0.5, y: 0.5)),
                       CGPoint(x: 180, y: 320))
        // Vision origin is bottom-left: (0,0) → bottom-left of view
        XCTAssertEqual(m.viewPoint(fromVisionPoint: .zero), CGPoint(x: 0, y: 640))
    }

    func testAspectFillCropsHeight() {
        // Buffer 720x1280 into square view 400x400:
        // fill scale = max(400/720, 400/1280) = 0.5556; scaled = 400 x 711.1;
        // vertical overflow (711.1 - 400) is cropped equally: offsetY = -155.55.
        let m = CoordinateMapper(bufferSize: CGSize(width: 720, height: 1280),
                                 viewSize: CGSize(width: 400, height: 400),
                                 isMirrored: false)
        let center = m.viewPoint(fromVisionPoint: CGPoint(x: 0.5, y: 0.5))
        XCTAssertEqual(center.x, 200, accuracy: 0.01)
        XCTAssertEqual(center.y, 200, accuracy: 0.01)
        let topCenter = m.viewPoint(fromVisionPoint: CGPoint(x: 0.5, y: 1.0))
        XCTAssertEqual(topCenter.y, -155.55, accuracy: 0.1) // cropped above view top
    }

    func testMirroring() {
        let m = CoordinateMapper(bufferSize: CGSize(width: 720, height: 1280),
                                 viewSize: CGSize(width: 360, height: 640),
                                 isMirrored: true)
        let p = m.viewPoint(fromVisionPoint: CGPoint(x: 0.25, y: 0.5))
        XCTAssertEqual(p.x, 0.75 * 360, accuracy: 0.01)
    }

    func testPoseKitConversionFlipsY() {
        let m = CoordinateMapper(bufferSize: CGSize(width: 720, height: 1280),
                                 viewSize: CGSize(width: 360, height: 640),
                                 isMirrored: false)
        let p = m.poseKitPoint(fromVisionPoint: CGPoint(x: 0.3, y: 0.9))
        XCTAssertEqual(p.x, 0.3, accuracy: 1e-5)
        XCTAssertEqual(p.y, 0.1, accuracy: 1e-5)
    }
}
