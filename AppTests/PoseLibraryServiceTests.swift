import XCTest
@testable import Pose
import PoseKit

final class PoseLibraryServiceTests: XCTestCase {
    func testLoadsTenPosesFromBundle() {
        let lib = PoseLibraryService()
        XCTAssertEqual(lib.allPoses().count, 10)
    }

    func testEveryPoseHasEnoughJointsToScore() {
        for pose in PoseLibraryService().allPoses() {
            XCTAssertGreaterThanOrEqual(pose.poseVector.points.count, 8, pose.id)
        }
    }

    func testSearchByTitle() {
        let results = PoseLibraryService().poses(matching: "mirror", tag: nil)
        XCTAssertTrue(results.contains { $0.id == "mirror-selfie" })
    }

    func testTagFilter() {
        let results = PoseLibraryService().poses(matching: "", tag: "selfie")
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.allSatisfy { $0.tags.contains("selfie") })
    }

    func testPriorityTagsFirst() {
        let tags = PoseLibraryService().allTags()
        XCTAssertEqual(Array(tags.prefix(3)), ["mirror", "close-up", "selfie"])
    }

    func testFavoritesToggleAndPersist() {
        let defaults = UserDefaults(suiteName: "fav-test-\(UUID().uuidString)")!
        let store = FavoritesStore(defaults: defaults)
        XCTAssertFalse(store.isFavorite("power-pose"))
        store.toggle("power-pose")
        XCTAssertTrue(store.isFavorite("power-pose"))
        let reloaded = FavoritesStore(defaults: defaults)
        XCTAssertTrue(reloaded.isFavorite("power-pose"))
    }
}
